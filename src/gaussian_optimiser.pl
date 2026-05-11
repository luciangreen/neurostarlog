% gaussian_optimiser.pl
% PR 6: Gaussian/index optimisation.
%
% Adds a Gaussian elimination optimisation pass to the NP pipeline.
%
% Pass behaviour:
%   1. Scan all predicates for trace-based recurrence patterns.
%   2. Only if a pattern is confirmed, run Gaussian elimination.
%   3. Replace detected recurrences with direct polynomial formula clauses.
%   4. Leave all other predicates unchanged.
%
% Recognised pattern (2-argument predicate, index first, output last):
%
%   f(0, Base).
%   f(N, Out) :- N > 0, N1 is N-1, f(N1, Out1), Out is <expr(Out1, N)>.
%
% where expr(Out1, N) is an arithmetic expression involving Out1 and
% optionally N.  The recurrence is traced for N = 0..degree+1 to obtain
% sample points; a Vandermonde linear system is then solved via Gaussian
% elimination to find polynomial coefficients.  A single closed-form clause
% replaces the original two clauses when the fit is exact.
%
% Unsupported predicates (non-matching structure, non-polynomial output,
% or non-exact fit) are preserved unchanged.

% ---------------------------------------------------------------------------
% Main pass entry
% ---------------------------------------------------------------------------

%% np_gaussian_optimise_pass(+Clauses, -Clauses2, -Log)
%
% PR 6 optimisation pass.
% Detects index recurrence patterns (trace-based) and replaces them with
% closed-form polynomial clauses via Gaussian elimination.

np_gaussian_optimise_pass(Clauses, Clauses2, Log) :-
    np_find_gaussian_candidates(Clauses, Candidates),
    ( Candidates = [] ->
        Clauses2 = Clauses,
        Log = []
    ;
        np_apply_gaussian_all(Clauses, Candidates, Clauses2, SubLogs),
        ( SubLogs = [] ->
            Log = []
        ;
            Log = ['NP: applied Gaussian elimination.' | SubLogs]
        )
    ).

% ---------------------------------------------------------------------------
% Candidate detection (trace-based pattern detection)
% ---------------------------------------------------------------------------

%% np_find_gaussian_candidates(+Clauses, -Candidates)
%
% Candidates is a sorted list of Name/Arity pairs for predicates that match
% the recognisable index-recurrence pattern.
%
% Only predicates that can be fully traced AND fit a polynomial are included.

np_find_gaussian_candidates(Clauses, Candidates) :-
    findall(Name/Arity,
        ( member(Clause, Clauses),
          np_clause_head(Clause, Head),
          callable(Head),
          functor(Head, Name, Arity),
          Name \= ':-',
          np_is_gaussian_candidate(Clauses, Name, Arity)
        ),
        Candidates0),
    sort(Candidates0, Candidates).

%% np_is_gaussian_candidate(+Clauses, +Name, +Arity)
%
% True when Name/Arity matches the index-recurrence pattern AND the recurrence
% can be evaluated to yield sample points that fit a polynomial exactly.

np_is_gaussian_candidate(Clauses, Name, Arity) :-
    Arity >= 2,
    np_collect_pred_clauses(Clauses, Name, Arity, PredClauses),
    length(PredClauses, 2),
    PredClauses = [C1, C2],
    (   np_match_base_clause(C1, Name, Arity, _BaseVal),
        np_match_step_clause(C2, Name, Arity, _NVar, _Out1Var, _StepExpr)
    ;   np_match_base_clause(C2, Name, Arity, _BaseVal),
        np_match_step_clause(C1, Name, Arity, _NVar, _Out1Var, _StepExpr)
    ),
    % Verify the recurrence can be traced and fits a polynomial
    np_trace_and_fit(Clauses, Name, Arity, 4, _Coeffs).

np_collect_pred_clauses(Clauses, Name, Arity, PredClauses) :-
    include(np_is_clause_for_ga(Name, Arity), Clauses, PredClauses).

np_is_clause_for_ga(Name, Arity, Clause) :-
    np_clause_head(Clause, Head),
    callable(Head),
    functor(Head, Name, Arity).

%% np_match_base_clause(+Clause, +Name, +Arity, -BaseVal)
%
% Match a base clause of the form:
%   f(0, Base).          % fact with numeric output
%   f(0, Out) :- Out is Expr.   % computed base

np_match_base_clause(Clause, Name, Arity, BaseVal) :-
    np_clause_head(Clause, Head),
    functor(Head, Name, Arity),
    arg(1, Head, 0),
    arg(Arity, Head, OutputArg),
    \+ Clause = (_ :- _),
    number(OutputArg),
    !,
    BaseVal = OutputArg.
np_match_base_clause(Clause, Name, Arity, BaseVal) :-
    np_clause_head(Clause, Head),
    functor(Head, Name, Arity),
    arg(1, Head, 0),
    Clause = (_ :- Body),
    np_goals_to_list(Body, Goals),
    arg(Arity, Head, OutVar),
    var(OutVar),
    member(OutVar is Expr, Goals),
    catch(BaseVal is Expr, _, fail),
    number(BaseVal).

%% np_match_step_clause(+Clause, +Name, +Arity, -NVar, -Out1Var, -StepExpr)
%
% Match a recursive step clause:
%   f(N, Out) :- N > 0, N1 is N-1, f(N1, Out1), Out is StepExpr.
%
% NVar is the index variable, Out1Var is the recursive output variable,
% StepExpr is the accumulator expression involving Out1Var and NVar.

np_match_step_clause(Clause, Name, Arity, NVar, Out1Var, StepExpr) :-
    np_clause_head(Clause, Head),
    functor(Head, Name, Arity),
    arg(1, Head, NVar),
    var(NVar),
    arg(Arity, Head, OutVar),
    var(OutVar),
    Clause = (_ :- Body),
    np_goals_to_list(Body, Goals),
    % Guard: N > 0
    member(NVar > 0, Goals),
    % Decrement: N1 is N - 1
    member(N1Var is NVar - 1, Goals),
    var(N1Var),
    N1Var \== NVar,
    % Recursive call with decremented index and fresh output variable
    functor(RecCall, Name, Arity),
    arg(1, RecCall, N1Var),
    arg(Arity, RecCall, Out1Var),
    var(Out1Var),
    Out1Var \== OutVar,
    Out1Var \== NVar,
    member(RecCall, Goals),
    % Accumulator: Out is StepExpr
    member(OutVar is StepExpr, Goals).

% ---------------------------------------------------------------------------
% Trace-based evaluation and polynomial fitting
% ---------------------------------------------------------------------------

%% np_trace_and_fit(+Clauses, +Name, +Arity, +MaxDegree, -Coeffs)
%
% Trace the recurrence for N = 0..MaxDegree+1 and attempt to fit a polynomial.
% Succeeds with the polynomial coefficients when an exact fit is found.

np_trace_and_fit(Clauses, Name, Arity, MaxDegree, Coeffs) :-
    np_extract_recurrence_parts(Clauses, Name, Arity, BaseVal, Out1Var, StepExpr, NVar),
    NumPoints is MaxDegree + 2,
    np_eval_trace(0, NumPoints, BaseVal, Out1Var, StepExpr, NVar, Points),
    gauss_fit_polynomial(Points, MaxDegree, Coeffs).

%% np_extract_recurrence_parts(+Clauses, +Name, +Arity,
%%                              -BaseVal, -Out1Var, -StepExpr, -NVar)
%
% Extract the base value, recursive output variable, step expression, and
% index variable from the two clauses of a recognised recurrence.

np_extract_recurrence_parts(Clauses, Name, Arity, BaseVal, Out1Var, StepExpr, NVar) :-
    np_collect_pred_clauses(Clauses, Name, Arity, [C1, C2]),
    (   np_match_base_clause(C1, Name, Arity, BaseVal),
        np_match_step_clause(C2, Name, Arity, NVar, Out1Var, StepExpr)
    ;   np_match_base_clause(C2, Name, Arity, BaseVal),
        np_match_step_clause(C1, Name, Arity, NVar, Out1Var, StepExpr)
    ).

%% np_eval_trace(+I, +Max, +PrevOut, +Out1Var, +StepExpr, +NVar, -Points)
%
% Compute sample points by symbolically evaluating the recurrence.
% Points = [0-BaseVal, 1-f(1), 2-f(2), ...]

np_eval_trace(I, Max, _PrevOut, _Out1Var, _StepExpr, _NVar, []) :-
    I >= Max, !.
np_eval_trace(0, Max, BaseVal, Out1Var, StepExpr, NVar,
              [0-BaseVal | Rest]) :-
    !,
    np_eval_trace(1, Max, BaseVal, Out1Var, StepExpr, NVar, Rest).
np_eval_trace(I, Max, PrevOut, Out1Var, StepExpr, NVar,
              [I-CurOut | Rest]) :-
    I > 0, I < Max,
    np_eval_step_expr(StepExpr, Out1Var, PrevOut, NVar, I, CurOut),
    I1 is I + 1,
    np_eval_trace(I1, Max, CurOut, Out1Var, StepExpr, NVar, Rest).

%% np_eval_step_expr(+Expr, +Out1Var, +Out1Val, +NVar, +NVal, -Result)
%
% Evaluate the step arithmetic expression by substituting:
%   Out1Var → Out1Val  (output of the previous recursive call)
%   NVar    → NVal     (current index value)

np_eval_step_expr(Expr, Out1Var, Out1Val, NVar, NVal, Result) :-
    copy_term(t(Expr, Out1Var, NVar), t(Expr2, O2, N2)),
    O2 = Out1Val,
    N2 = NVal,
    catch(Result is Expr2, _, fail).

% ---------------------------------------------------------------------------
% Vandermonde polynomial fitting via Gaussian elimination
% ---------------------------------------------------------------------------

%% gauss_fit_polynomial(+Points, +MaxDegree, -Coefficients)
%
% Attempt to fit a polynomial to the sample points.
% Try degree 1 up to MaxDegree.  Succeeds with the first exact fit.
%
% Coefficients = [a0, a1, ..., ad] for Out = a0 + a1*N + ... + ad*N^d.

gauss_fit_polynomial(Points, MaxDegree, Coefficients) :-
    between(1, MaxDegree, Degree),
    Degree1 is Degree + 1,
    length(SubPoints, Degree1),
    append(SubPoints, _, Points),
    gauss_build_vandermonde(SubPoints, Degree, Matrix, RHS),
    gauss_solve(Matrix, RHS, Coefficients),
    % Verify ALL sample points fit (not just the ones used for solving)
    forall(
        member(N-Y, Points),
        ( gauss_polynomial_value(Coefficients, N, Val),
          gauss_exact_equal(Y, Val) )
    ),
    !.

%% gauss_build_vandermonde(+Points, +Degree, -Matrix, -RHS)
%
% Build the Vandermonde coefficient matrix and RHS vector.
% Matrix[i][j] = N_i^j, RHS[i] = Y_i.

gauss_build_vandermonde(Points, Degree, Matrix, RHS) :-
    maplist(gauss_vandermonde_row(Degree), Points, RowRHS),
    pairs_keys_values(RowRHS, Matrix, RHS).

gauss_vandermonde_row(Degree, N-Y, Row-Y) :-
    Degree1 is Degree + 1,
    gauss_power_list(N, 0, Degree1, Row).

gauss_power_list(_, _, 0, []) :- !.
gauss_power_list(N, Exp, Rem, [P | Rest]) :-
    Rem > 0,
    P is N ^ Exp,
    Exp1 is Exp + 1,
    Rem1 is Rem - 1,
    gauss_power_list(N, Exp1, Rem1, Rest).

%% gauss_solve(+Matrix, +RHS, -Solution)
%
% Solve the linear system Matrix * x = RHS using Gauss-Jordan elimination
% with exact rational arithmetic (SWI-Prolog rdiv).
%
% Matrix: list of N lists, each of length N.
% RHS:    list of N values.
% Solution: list of N exact values.

gauss_solve(Matrix, RHS, Solution) :-
    maplist(gauss_augment_row, Matrix, RHS, Augmented),
    length(Augmented, N),
    gauss_jordan(Augmented, 0, N, Reduced),
    gauss_read_solution(Reduced, 0, N, Solution).

gauss_augment_row(Row, Val, Aug) :- append(Row, [Val], Aug).

% Gauss-Jordan elimination: bring augmented matrix to reduced row echelon form.
gauss_jordan(M, Pivot, N, Result) :-
    Pivot >= N,
    !,
    Result = M.
gauss_jordan(M0, Pivot, N, Result) :-
    ( gauss_find_pivot_row(M0, Pivot, Pivot, PivIdx) ->
        gauss_swap_rows(M0, Pivot, PivIdx, M1),
        nth0(Pivot, M1, PivRow),
        nth0(Pivot, PivRow, PivVal),
        gauss_elim_col(M1, PivRow, PivVal, Pivot, 0, M2)
    ;
        M2 = M0  % No pivot in this column; skip (degenerate system)
    ),
    Pivot1 is Pivot + 1,
    gauss_jordan(M2, Pivot1, N, Result).

% Find the first row at or below StartRow with a non-zero entry at Col.
gauss_find_pivot_row(Matrix, StartRow, Col, RowIdx) :-
    nth0(RowIdx, Matrix, Row),
    RowIdx >= StartRow,
    nth0(Col, Row, Val),
    \+ Val =:= 0,
    !.

% Eliminate column PivCol from all rows, skipping the pivot row (index PivCol).
gauss_elim_col([], _, _, _, _, []).
gauss_elim_col([Row | Rest], PivRow, PivVal, PivCol, RowIdx,
               [NewRow | NewRest]) :-
    ( RowIdx =:= PivCol ->
        NewRow = Row          % Do not eliminate the pivot row itself
    ;
        gauss_eliminate_row(PivRow, PivVal, PivCol, Row, NewRow)
    ),
    RowIdx1 is RowIdx + 1,
    gauss_elim_col(Rest, PivRow, PivVal, PivCol, RowIdx1, NewRest).

% Swap row I and row J in the matrix.
gauss_swap_rows(M, I, I, M) :- !.
gauss_swap_rows(M0, I, J, M2) :-
    nth0(I, M0, RowI),
    nth0(J, M0, RowJ),
    gauss_list_set(M0, I, RowJ, M1),
    gauss_list_set(M1, J, RowI, M2).

% Set element at index Idx in list to Val.
gauss_list_set([_|T], 0, Val, [Val|T]) :- !.
gauss_list_set([H|T], Idx, Val, [H|T2]) :-
    Idx > 0, Idx1 is Idx - 1,
    gauss_list_set(T, Idx1, Val, T2).

%% gauss_eliminate_row(+PivotRow, +PivotVal, +PivotCol, +Row, -NewRow)
%
% Eliminate the PivotCol entry from Row using PivotRow:
%   NewRow = Row - (Row[PivotCol] / PivotVal) * PivotRow

gauss_eliminate_row(PivRow, PivVal, PivCol, Row, NewRow) :-
    nth0(PivCol, Row, RowVal),
    ( RowVal =:= 0 ->
        NewRow = Row   % Nothing to eliminate
    ;
        Factor is RowVal rdiv PivVal,
        maplist(gauss_sub_scaled(Factor), Row, PivRow, NewRow)
    ).

gauss_sub_scaled(Factor, X, P, Y) :-
    Y is X - Factor * P.

%% gauss_read_solution(+RREF, +Row, +N, -Solution)
%
% Read off the solution from the reduced row echelon form.
% Each row Row has pivot at column Row; solution element = last element / pivot.

gauss_read_solution(_, N, N, []) :- !.
gauss_read_solution(RREF, Row, N, [X | Rest]) :-
    nth0(Row, RREF, AugRow),
    last(AugRow, B),
    nth0(Row, AugRow, Pivot),
    ( Pivot =:= 0 ->
        X = 0
    ;
        X is B rdiv Pivot
    ),
    Row1 is Row + 1,
    gauss_read_solution(RREF, Row1, N, Rest).

%% gauss_polynomial_value(+Coeffs, +N, -Val)
%
% Evaluate the polynomial a0 + a1*N + a2*N^2 + ... at N.

gauss_polynomial_value(Coeffs, N, Val) :-
    gauss_poly_val(Coeffs, N, 0, 0, Val).

gauss_poly_val([], _, _, Acc, Acc).
gauss_poly_val([C | Rest], N, Exp, Acc, Val) :-
    Term is C * (N ^ Exp),
    Acc1 is Acc + Term,
    Exp1 is Exp + 1,
    gauss_poly_val(Rest, N, Exp1, Acc1, Val).

%% gauss_exact_equal(+X, +Y)
%
% True when X and Y are numerically equal (exact, handling rationals).

gauss_exact_equal(X, Y) :-
    catch(X =:= Y, _, fail).

% ---------------------------------------------------------------------------
% Apply Gaussian optimisation to detected candidates
% ---------------------------------------------------------------------------

%% np_apply_gaussian_all(+Clauses, +Candidates, -Clauses2, -Logs)

np_apply_gaussian_all(Cs, Candidates, Cs2, Logs) :-
    np_apply_gaussian_all_(Cs, Candidates, Cs2, [], Logs).

np_apply_gaussian_all_(Cs, [], Cs, LogAcc, LogAcc).
np_apply_gaussian_all_(Cs0, [Name/Arity | Rest], Cs2, LogAcc, Logs) :-
    ( np_gaussian_optimise_pred(Cs0, Name, Arity, NewClauses, PredLog) ->
        gauss_replace_pred_clauses(Cs0, Name, Arity, NewClauses, Cs1),
        append(LogAcc, PredLog, LogAcc1)
    ;
        Cs1 = Cs0,
        LogAcc1 = LogAcc
    ),
    np_apply_gaussian_all_(Cs1, Rest, Cs2, LogAcc1, Logs).

%% np_gaussian_optimise_pred(+Clauses, +Name, +Arity, -NewClauses, -Log)
%
% Produce a single closed-form clause replacing the base+step pair.

np_gaussian_optimise_pred(Clauses, Name, Arity, [NewClause], [Msg]) :-
    np_trace_and_fit(Clauses, Name, Arity, 4, Coeffs),
    np_make_closed_form_clause(Name, Arity, Coeffs, NewClause),
    format(atom(Msg), 'NP: ~w/~w replaced with polynomial closed form.',
           [Name, Arity]).

%% gauss_replace_pred_clauses(+Clauses, +Name, +Arity, +NewClauses, -Result)
%
% Remove all clauses for Name/Arity from Clauses and append NewClauses.

gauss_replace_pred_clauses(Clauses0, Name, Arity, NewClauses, Result) :-
    exclude(np_is_clause_for_ga(Name, Arity), Clauses0, Others),
    append(Others, NewClauses, Result).

% ---------------------------------------------------------------------------
% Closed-form clause generation
% ---------------------------------------------------------------------------

%% np_make_closed_form_clause(+Name, +Arity, +Coeffs, -Clause)
%
% Build a Prolog clause of the form:
%   Name(N, Out) :- Out is <polynomial(N)>.
%
% Uses fresh variables for N and Out.

np_make_closed_form_clause(Name, Arity, Coeffs, Clause) :-
    length(Args, Arity),
    Head =.. [Name | Args],
    nth0(0, Args, NVar),         % first arg = index
    nth0(Arity1, Args, OutVar),  % last arg = output
    Arity1 is Arity - 1,
    gauss_build_poly_expr(Coeffs, NVar, PolyExpr),
    Body = (OutVar is PolyExpr),
    Clause = (Head :- Body).

%% gauss_build_poly_expr(+Coeffs, +NVar, -Expr)
%
% Build the arithmetic expression a0 + a1*N + a2*N*N + ...
% Coefficients that are zero are omitted.  The expression uses exact values
% (integers or rational rdiv expressions).

gauss_build_poly_expr(Coeffs, NVar, Expr) :-
    gauss_poly_terms(Coeffs, NVar, 0, Terms),
    ( Terms = [] ->
        Expr = 0
    ;
        gauss_sum_terms(Terms, Expr)
    ).

gauss_poly_terms([], _, _, []).
gauss_poly_terms([C | Rest], NVar, Exp, Terms) :-
    Exp1 is Exp + 1,
    gauss_poly_terms(Rest, NVar, Exp1, RestTerms),
    ( gauss_is_zero(C) ->
        Terms = RestTerms
    ;
        gauss_make_power_term(C, NVar, Exp, Term),
        Terms = [Term | RestTerms]
    ).

gauss_is_zero(0) :- !.
gauss_is_zero(X) :- number(X), X =:= 0.

gauss_make_power_term(C, _NVar, 0, C) :- !.   % constant term
gauss_make_power_term(1, NVar, 1, NVar) :- !. % 1*N → N
gauss_make_power_term(C, NVar, 1, C * NVar) :- !.
gauss_make_power_term(1, NVar, Exp, Pow) :- !,
    gauss_power_expr(NVar, Exp, Pow).
gauss_make_power_term(C, NVar, Exp, C * Pow) :-
    gauss_power_expr(NVar, Exp, Pow).

% Build N * N * ... (Exp times) as a nested * expression.
gauss_power_expr(NVar, 1, NVar) :- !.
gauss_power_expr(NVar, Exp, NVar * Rest) :-
    Exp > 1, Exp1 is Exp - 1,
    gauss_power_expr(NVar, Exp1, Rest).

gauss_sum_terms([T], T) :- !.
gauss_sum_terms([T | Rest], T + RestExpr) :-
    gauss_sum_terms(Rest, RestExpr).

% ---------------------------------------------------------------------------
% Polynomial value verification helper (used externally in tests)
% ---------------------------------------------------------------------------

%% gauss_check_formula(+Clause, +Name, +Arity, +TestPoints)
%
% Verify the closed-form Clause gives correct outputs for TestPoints (N-Y pairs).
% Evaluates the polynomial expression in the clause body by substituting the
% index argument value and checking the result matches the expected output.

gauss_check_formula(Clause, Name, Arity, TestPoints) :-
    Clause = (Head :- (OutVar is PolyExpr)),
    functor(Head, Name, Arity),
    ignore(OutVar),      % suppress singleton warning; OutVar is intentionally unbound
    forall(
        member(N-ExpectedY, TestPoints),
        ( copy_term(t(Head, PolyExpr), t(Head2, Expr2)),
          arg(1, Head2, N),
          catch(Val is Expr2, _, fail),
          gauss_exact_equal(Val, ExpectedY) )
    ).
