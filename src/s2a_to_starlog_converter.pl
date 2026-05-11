% s2a_to_starlog_converter.pl
% PR 4: Prolog clause text → Starlog notation.
%
% Conversion rules (from pr1.txt Section 6.2):
%   string_concat(A,B,C) → C is A:B
%   append(A,B,C)        → C is A&B
%   atom_concat(A,B,C)   → C is A•B
%
% Default output mode: compress(true), method_chaining.
% Output file: out/<predicate>_generated.starlog
%
% When OutFile = '' no file is written.

% Starlog-specific operators.
% & for append, • for atom_concat.
% : is SWI-Prolog's built-in op(200,xfy,:) which we reuse for string_concat.

:- op(300, yfx, &).    % append(A,B,C) → C is A&B
:- op(300, yfx, •).    % atom_concat(A,B,C) → C is A•B

%% write_s2a_starlog(+PredName, +ClauseTexts, +OutFile, -Status)
%
% Convert ClauseTexts (Prolog clause atoms) to Starlog and write to OutFile.
% Status = ok | partial(Errors).

write_s2a_starlog(PredName, ClauseTexts, OutFile, Status) :-
    convert_clauses_to_starlog(ClauseTexts, StarlogTexts, ConvErrors),
    write_starlog_generated_safe(PredName, StarlogTexts, OutFile, WriteErrors),
    append(ConvErrors, WriteErrors, AllErrors),
    ( AllErrors = [] -> Status = ok ; Status = partial(AllErrors) ).

%% convert_clauses_to_starlog(+ClauseTexts, -StarlogTexts, -Errors)
%
% Convert a list of Prolog clause text atoms to Starlog text atoms.
% Errors is a list of error(Type, Detail) for any conversion failures.

convert_clauses_to_starlog([], [], [error(no_clauses,
        'No Prolog clauses to convert to Starlog.')]) :- !.
convert_clauses_to_starlog(Clauses, Starlog, []) :-
    maplist(convert_prolog_to_starlog, Clauses, Starlog).

%% convert_prolog_to_starlog(+PrologText, -StarlogText)
%
% Convert a single Prolog clause text atom to Starlog notation.
% Applies Starlog rules and method chaining (compress(true) by default).
% Falls back to the original text when the clause cannot be parsed.

convert_prolog_to_starlog(PrologText, StarlogText) :-
    ( sub_atom(PrologText, _, _, _, 'UNRESOLVED') ->
        % Preserve clauses containing UNRESOLVED markers unchanged.
        StarlogText = PrologText
    ; sub_atom(PrologText, 0, 1, _, '%') ->
        % Pure comment lines pass through unchanged.
        StarlogText = PrologText
    ;
        catch(
            convert_clause_term(PrologText, StarlogText),
            _,
            StarlogText = PrologText
        )
    ).

% Parse the Prolog clause text as a term, apply Starlog rules and method
% chaining, then write the result back to an atom.

convert_clause_term(PrologText, StarlogText) :-
    strip_trailing_period(PrologText, PrologBody),
    term_to_atom(ClauseTerm, PrologBody),
    transform_term_to_starlog(ClauseTerm, StarlogTerm),
    apply_method_chaining_term(StarlogTerm, ChainedTerm),
    write_starlog_term_to_atom(ChainedTerm, StarlogBody),
    atom_concat(StarlogBody, '.', StarlogText).

%% starlog_to_prolog(+StarlogText, -PrologText)
%
% Reverse conversion: parse a Starlog clause text back to standard Prolog.
% Used for roundtrip testing.
% Falls back to the original text when the clause cannot be parsed.

starlog_to_prolog(StarlogText, PrologText) :-
    ( sub_atom(StarlogText, _, _, _, 'UNRESOLVED') ->
        PrologText = StarlogText
    ; sub_atom(StarlogText, 0, 1, _, '%') ->
        PrologText = StarlogText
    ;
        catch(
            revert_clause_term(StarlogText, PrologText),
            _,
            PrologText = StarlogText
        )
    ).

revert_clause_term(StarlogText, PrologText) :-
    strip_trailing_period(StarlogText, StarlogBody),
    term_to_atom(StarlogTerm, StarlogBody),
    transform_term_to_prolog(StarlogTerm, PrologTerm),
    term_to_atom(PrologTerm, PrologBody),
    atom_concat(PrologBody, '.', PrologText).

% ---------------------------------------------------------------------------
% Trailing period helper
% ---------------------------------------------------------------------------

%% strip_trailing_period(+Atom, -Body)
%
% Remove the trailing '.' character from a clause atom.
% Leaves the atom unchanged if it does not end with '.'.

strip_trailing_period(Atom, Body) :-
    atom_string(Atom, S),
    string_length(S, Len),
    Len > 0,
    Last is Len - 1,
    sub_string(S, Last, 1, 0, "."),
    !,
    sub_string(S, 0, Last, _, BodyStr),
    atom_string(Body, BodyStr).
strip_trailing_period(Atom, Atom).

% ---------------------------------------------------------------------------
% Term-level Prolog → Starlog transformation
% ---------------------------------------------------------------------------

%% transform_term_to_starlog(+PrologTerm, -StarlogTerm)

transform_term_to_starlog((Head :- Body), (Head :- StarlogBody)) :- !,
    goals_to_list(Body, Goals),
    maplist(transform_goal_to_starlog, Goals, StarlogGoals),
    list_to_goals(StarlogGoals, StarlogBody).
transform_term_to_starlog(Fact, Fact).

%% transform_goal_to_starlog(+PrologGoal, -StarlogGoal)
%
% Apply a single Starlog conversion rule to a goal.

transform_goal_to_starlog(append(A, B, C), (C is A & B)) :- !.
transform_goal_to_starlog(atom_concat(A, B, C), (C is A • B)) :- !.
transform_goal_to_starlog(string_concat(A, B, C), (C is A : B)) :- !.
transform_goal_to_starlog(Goal, Goal).

% ---------------------------------------------------------------------------
% Method chaining
% ---------------------------------------------------------------------------

%% apply_method_chaining_term(+ClauseTerm, -ChainedTerm)
%
% Apply method chaining to all goals in a clause body.
% Consecutive is/2 goals that share an intermediate variable are inlined:
%   (T is A•B), (R is T•C)  →  (R is A•B•C)
% This uses Prolog variable sharing: unifying T=A•B substitutes into the
% second goal automatically.

apply_method_chaining_term((Head :- Body), (Head :- ChainedBody)) :- !,
    goals_to_list(Body, Goals),
    inline_is_intermediates(Goals, ChainedGoals),
    list_to_goals(ChainedGoals, ChainedBody).
apply_method_chaining_term(Term, Term).

%% inline_is_intermediates(+Goals, -ChainedGoals)
%
% Scan the goal list.  When the current goal is (T is Expr) and T is an
% uninstantiated variable that appears inside a later goal's is-expression,
% inline it by unifying T = Expr (which propagates via Prolog's variable
% sharing) and drop the now-redundant current goal.

inline_is_intermediates([], []).
inline_is_intermediates([(T is Expr) | Rest], Result) :-
    var(T),
    safe_to_inline_is_intermediate(Rest, T),
    !,
    T = Expr,          % propagate T's definition into every later reference
    inline_is_intermediates(Rest, Result).
inline_is_intermediates([G | Gs], [G | Rest]) :-
    inline_is_intermediates(Gs, Rest).

%% some_is_rhs_contains(+Goals, +Var)
%
% True when at least one goal of the form (_ is RHS) in Goals contains Var.

some_is_rhs_contains([(_ is RHS) | _], Var) :-
    term_contains_var(RHS, Var), !.
some_is_rhs_contains([_ | Rest], Var) :-
    some_is_rhs_contains(Rest, Var).

%% safe_to_inline_is_intermediate(+Goals, +Var)
%
% Var can be inlined only when:
%   1) It appears in at least one later is/2 RHS.
%   2) It does not appear in any non-is goal.
%   3) It is not assigned again as an is/2 LHS.

safe_to_inline_is_intermediate(Goals, Var) :-
    some_is_rhs_contains(Goals, Var),
    \+ appears_in_non_is_goal(Goals, Var),
    \+ appears_as_is_lhs(Goals, Var).

appears_in_non_is_goal([G | _], Var) :-
    \+ is_is_goal(G),
    term_contains_var(G, Var), !.
appears_in_non_is_goal([_ | Rest], Var) :-
    appears_in_non_is_goal(Rest, Var).

appears_as_is_lhs([(LHS is _) | _], Var) :-
    LHS == Var, !.
appears_as_is_lhs([_ | Rest], Var) :-
    appears_as_is_lhs(Rest, Var).

is_is_goal((_ is _)).

%% term_contains_var(+Term, +Var)
%
% True when Var appears inside Term (identity check via ==).

term_contains_var(Term, Var) :-
    Term == Var, !.
term_contains_var(Term, Var) :-
    compound(Term),
    Term =.. [_ | Args],
    member(Arg, Args),
    term_contains_var(Arg, Var), !.

% ---------------------------------------------------------------------------
% Term-level Starlog → Prolog transformation (for roundtrip)
% ---------------------------------------------------------------------------

%% transform_term_to_prolog(+StarlogTerm, -PrologTerm)

transform_term_to_prolog((Head :- Body), (Head :- PrologBody)) :- !,
    goals_to_list(Body, Goals),
    maplist(transform_goal_to_prolog, Goals, PrologGoals),
    list_to_goals(PrologGoals, PrologBody).
transform_term_to_prolog(Fact, Fact).

%% transform_goal_to_prolog(+StarlogGoal, -PrologGoal)
%
% Reverse the Starlog rules back to standard Prolog predicates.

transform_goal_to_prolog((C is Expr), PrologGoal) :-
    starlog_expr_to_prolog_goals(Expr, C, PrologGoal), !.
transform_goal_to_prolog(Goal, Goal).

%% starlog_expr_to_prolog_goals(+Expr, +OutVar, -Goals)
%
% Expand Starlog operator expressions into equivalent Prolog predicate goals.
% Supports method-chained expressions:
%   R is A•B•C  ->  atom_concat(A,B,T), atom_concat(T,C,R)
%   R is A&B&C  ->  append(A,B,T), append(T,C,R)
%   R is A:B:C  ->  string_concat(A,B,T), string_concat(T,C,R)

starlog_expr_to_prolog_goals(Expr, OutVar, Goals) :-
    expr_operands(&, Expr, Ops), Ops = [_,_|_], !,
    build_chain_goals(append, Ops, OutVar, GoalList),
    list_to_goals(GoalList, Goals).
starlog_expr_to_prolog_goals(Expr, OutVar, Goals) :-
    expr_operands(•, Expr, Ops), Ops = [_,_|_], !,
    build_chain_goals(atom_concat, Ops, OutVar, GoalList),
    list_to_goals(GoalList, Goals).
starlog_expr_to_prolog_goals(Expr, OutVar, Goals) :-
    expr_operands(:, Expr, Ops), Ops = [_,_|_], !,
    build_chain_goals(string_concat, Ops, OutVar, GoalList),
    list_to_goals(GoalList, Goals).

expr_operands(Op, Expr, Ops) :-
    compound(Expr),
    functor(Expr, Op, 2),
    Expr =.. [Op, L, R],
    !,
    expr_operands(Op, L, LeftOps),
    expr_operands(Op, R, RightOps),
    append(LeftOps, RightOps, Ops).
expr_operands(_Op, Expr, [Expr]).

build_chain_goals(Functor, [A, B], OutVar, [Goal]) :-
    Goal =.. [Functor, A, B, OutVar].
build_chain_goals(Functor, [A, B | Rest], OutVar, [Goal | Goals]) :-
    Goal =.. [Functor, A, B, TempVar],
    build_chain_goals(Functor, [TempVar | Rest], OutVar, Goals).

% ---------------------------------------------------------------------------
% Goal list helpers
% ---------------------------------------------------------------------------

%% goals_to_list(+Goals, -List)
%
% Flatten a conjunction of goals into a list.

goals_to_list((G1, G2), [G1 | Rest]) :- !,
    goals_to_list(G2, Rest).
goals_to_list(G, [G]).

%% list_to_goals(+List, -Goals)
%
% Rebuild a conjunction from a list.

list_to_goals([G], G) :- !.
list_to_goals([G | Gs], (G, Rest)) :-
    list_to_goals(Gs, Rest).

% ---------------------------------------------------------------------------
% Custom Starlog writer
% ---------------------------------------------------------------------------

%% write_starlog_term_to_atom(+Term, -Atom)
%
% Write a Starlog term to an atom, using Starlog operator notation for
% is/2 expressions.

write_starlog_term_to_atom(Term, Atom) :-
    with_output_to(atom(Atom), write_starlog_term(Term)).

write_starlog_term((Head :- Body)) :- !,
    write_term(Head, [quoted(true), numbervars(true)]),
    write(' :-'),
    nl, write('    '),
    write_starlog_goals(Body).
write_starlog_term(Term) :-
    write_term(Term, [quoted(true), numbervars(true)]).

write_starlog_goals((G1, G2)) :- !,
    write_starlog_goal(G1),
    write(','),
    nl, write('    '),
    write_starlog_goals(G2).
write_starlog_goals(G) :-
    write_starlog_goal(G).

write_starlog_goal(G) :-
    compound(G), G = (C is Expr), !,
    write_term(C, [quoted(true), numbervars(true)]),
    write(' is '),
    write_starlog_expr(Expr).
write_starlog_goal(G) :-
    write_term(G, [quoted(true), numbervars(true)]).

write_starlog_expr(E) :-
    compound(E), E = &(A, B), !,
    write_starlog_expr(A), write('&'), write_starlog_expr(B).
write_starlog_expr(E) :-
    compound(E), E = •(A, B), !,
    write_starlog_expr(A), write('•'), write_starlog_expr(B).
write_starlog_expr(E) :-
    compound(E), E = :(A, B), !,
    write_starlog_expr(A), write(':'), write_starlog_expr(B).
write_starlog_expr(E) :-
    write_term(E, [quoted(true), numbervars(true)]).

% ---------------------------------------------------------------------------
% File writer
% ---------------------------------------------------------------------------

%% write_starlog_generated_safe(+PredName, +StarlogTexts, +OutFile, -Errors)

write_starlog_generated_safe(_Pred, _Texts, '', []) :- !.
write_starlog_generated_safe(Pred, Texts, OutFile, Errors) :-
    catch(
        ( ensure_out_dir_starlog(OutFile),
          write_starlog_generated(Pred, Texts, OutFile),
          Errors = [] ),
        Err,
        Errors = [error(write_starlog, Err)]
    ).

%% write_starlog_generated(+PredName, +StarlogTexts, +File)
%
% Write the converted Starlog clauses to File with a standard header.

write_starlog_generated(Pred, Texts, File) :-
    open(File, write, Stream),
    format(Stream,
        '% Generated Starlog for predicate: ~w~n', [Pred]),
    format(Stream,
        '% Generated by NeuroStarlog S2A → Starlog converter (PR 4).~n', []),
    format(Stream,
        '% Conversion: append→&, atom_concat→•, string_concat→:~n', []),
    format(Stream,
        '% compress(true), method_chaining enabled.~n~n', []),
    ( Texts = [] ->
        format(Stream,
            '% UNRESOLVED: No clauses could be generated for ~w.~n', [Pred])
    ;
        forall(
            member(Text, Texts),
            ( write(Stream, Text), nl(Stream), nl(Stream) )
        )
    ),
    close(Stream).

%% ensure_out_dir_starlog(+File)
%
% Create the directory that will contain File if it does not already exist.

ensure_out_dir_starlog(File) :-
    file_directory_name(File, Dir),
    ( Dir = '' -> true
    ; exists_directory(Dir) -> true
    ; make_directory(Dir)
    ).
