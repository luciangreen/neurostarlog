% np_optimiser.pl
% PR 5: NeuroProlog full-pipeline integration.
% PR 6: Gaussian/index optimisation integrated via np_gaussian_optimise_pass.
%
% Implements a correctness-preserving Prolog optimiser with plateau stopping.
%
% Pipeline:
%   Source → parse clauses → identify irreducibles
%          → optimisation passes (with plateau stopping)
%          → write Prolog or Starlog output
%
% Correctness-preserving optimisations applied:
%   1. Remove `true` goals from conjunctions.
%   2. Remove clauses whose body is `fail` (unreachable dead code).
%   3. Unfold deterministic, non-recursive, non-irreducible helper predicates.
%
% Irreducible predicates are preserved unchanged:
%   I/O: read, write, writeln, nl, format, get_char, put_char, peek_char,
%        read_term, read_string
%   Side-effects: assert, assertz, asserta, retract, retractall,
%                 nb_setval, nb_getval, b_setval, b_getval
%   Random: random, random_between, maybe
%   External: shell, process_create, open, close
%   Control: catch, throw, halt
%
% Plateau stopping rule:
%   Repeat optimisation passes until the clause set is unchanged
%   (compared canonically via numbervars+term_to_atom).
%   A max-iteration guard (default 100) prevents infinite loops.

% ---------------------------------------------------------------------------
% Irreducible predicate registry
% ---------------------------------------------------------------------------

%% np_irreducible_functor(+Name, +Arity)
%
% True when Name/Arity is an irreducible (opaque) predicate that must be
% preserved unchanged by the optimiser.

np_irreducible_functor(read,           1).
np_irreducible_functor(read_term,      2).
np_irreducible_functor(read_term,      3).
np_irreducible_functor(read_string,    2).
np_irreducible_functor(read_string,    3).
np_irreducible_functor(write,          1).
np_irreducible_functor(writeln,        1).
np_irreducible_functor(print,          1).
np_irreducible_functor(nl,             0).
np_irreducible_functor(format,         1).
np_irreducible_functor(format,         2).
np_irreducible_functor(format,         3).
np_irreducible_functor(get_char,       1).
np_irreducible_functor(put_char,       1).
np_irreducible_functor(peek_char,      1).
np_irreducible_functor(assert,         1).
np_irreducible_functor(assertz,        1).
np_irreducible_functor(asserta,        1).
np_irreducible_functor(retract,        1).
np_irreducible_functor(retractall,     1).
np_irreducible_functor(nb_setval,      2).
np_irreducible_functor(nb_getval,      2).
np_irreducible_functor(b_setval,       2).
np_irreducible_functor(b_getval,       2).
np_irreducible_functor(random,         1).
np_irreducible_functor(random_between, 3).
np_irreducible_functor(maybe,          1).
np_irreducible_functor(maybe,          0).
np_irreducible_functor(shell,          1).
np_irreducible_functor(shell,          2).
np_irreducible_functor(process_create, 3).
np_irreducible_functor(open,           3).
np_irreducible_functor(open,           4).
np_irreducible_functor(close,          1).
np_irreducible_functor(catch,          3).
np_irreducible_functor(throw,          1).
np_irreducible_functor(halt,           0).
np_irreducible_functor(halt,           1).

%% np_is_irreducible_goal(+Goal)
%
% True when Goal is an irreducible call that must be preserved unchanged.

np_is_irreducible_goal(Goal) :-
    callable(Goal),
    functor(Goal, Name, Arity),
    np_irreducible_functor(Name, Arity).

%% np_predicate_contains_irreducible(+Name, +Arity, +Clauses)
%
% True when Name/Arity is itself irreducible or its body contains an
% irreducible goal.  Used to exclude such predicates from unfolding targets.

np_predicate_contains_irreducible(Name, Arity, _Clauses) :-
    np_irreducible_functor(Name, Arity), !.
np_predicate_contains_irreducible(Name, Arity, Clauses) :-
    functor(Head, Name, Arity),
    member((Head :- Body), Clauses),
    np_goals_to_list(Body, Goals),
    member(G, Goals),
    np_is_irreducible_goal(G), !.

% ---------------------------------------------------------------------------
% Main entry point
% ---------------------------------------------------------------------------

%% np_optimise_file(+InputFile, +InputType, +OutMode, +Compress, +CodeOut, -Status)
%
% Top-level entry for the NP/NSL optimiser path.
% Reads InputFile, applies correctness-preserving optimisations, and writes
% the result to CodeOut.
%
% Status = ok | partial(Errors)

np_optimise_file(InputFile, InputType, OutMode, _Compress, CodeOut, Status) :-
    ( InputType = starlog ->
        np_load_starlog_clauses(InputFile, Clauses, LoadErrors)
    ;
        np_load_clauses(InputFile, Clauses, LoadErrors)
    ),
    ( LoadErrors \= [] ->
        Status = partial(LoadErrors)
    ;
        pipeline_log(info,
            ['NP: loaded ', InputFile, ' — applying optimisation pipeline.']),
        np_preserve_opaque_sections(Clauses, Optimised, 100, OptLog),
        forall(member(LogMsg, OptLog), pipeline_log(info, [LogMsg])),
        np_write_output(OutMode, Optimised, CodeOut, WriteErrors),
        ( WriteErrors = [] ->
            Status = ok
        ;
            Status = partial(WriteErrors)
        )
    ).

%% np_preserve_opaque_sections(+Clauses, -Optimised, +MaxIter, -Log)
%
% Stage 5 boundary: preserve opaque/irreducible sections unchanged while
% optimising only the remaining clauses with plateau stopping.

np_preserve_opaque_sections(Clauses, Optimised, MaxIter, Log) :-
    np_tag_clauses_by_opacity(Clauses, Tagged),
    np_collect_optimisable(Tagged, OptimisableClauses),
    np_collect_opaque_count(Tagged, OpaqueCount),
    np_plateau_optimise(OptimisableClauses, OptimisableOptimised, MaxIter, OptLog),
    np_rebuild_from_tagged(Tagged, OptimisableOptimised, Optimised),
    ( OpaqueCount > 0 ->
        format(atom(OpaqueMsg),
            'NP: preserved ~w opaque section clause(s) unchanged.', [OpaqueCount]),
        Log = [OpaqueMsg | OptLog]
    ;
        Log = OptLog
    ).

np_tag_clauses_by_opacity([], []).
np_tag_clauses_by_opacity([Clause | Rest], [Tag | TaggedRest]) :-
    ( np_clause_is_opaque(Clause) ->
        Tag = opaque(Clause)
    ;
        Tag = optimisable(Clause)
    ),
    np_tag_clauses_by_opacity(Rest, TaggedRest).

np_clause_is_opaque((_ :- Body)) :-
    !,
    np_goals_to_list(Body, Goals),
    member(G, Goals),
    np_is_irreducible_goal(G),
    !.
np_clause_is_opaque(_) :- fail.

np_collect_optimisable([], []).
np_collect_optimisable([opaque(_) | Rest], Clauses) :-
    np_collect_optimisable(Rest, Clauses).
np_collect_optimisable([optimisable(Clause) | Rest], [Clause | Clauses]) :-
    np_collect_optimisable(Rest, Clauses).

np_collect_opaque_count([], 0).
np_collect_opaque_count([opaque(_) | Rest], Count) :-
    np_collect_opaque_count(Rest, Count0),
    Count is Count0 + 1.
np_collect_opaque_count([optimisable(_) | Rest], Count) :-
    np_collect_opaque_count(Rest, Count).

np_rebuild_from_tagged([], _OptimisedPool, []).
np_rebuild_from_tagged([opaque(Clause) | Rest], OptimisedPool, [Clause | OutRest]) :-
    np_rebuild_from_tagged(Rest, OptimisedPool, OutRest).
np_rebuild_from_tagged([optimisable(_Original) | Rest], [Next | OptRest], [Next | OutRest]) :-
    np_rebuild_from_tagged(Rest, OptRest, OutRest).

% ---------------------------------------------------------------------------
% Clause loader
% ---------------------------------------------------------------------------

%% np_load_clauses(+File, -Clauses, -Errors)
%
% Read all terms from a Prolog source file.
% Directives (:- ...) are preserved as-is.
% Errors is a list of error(Type, Detail) for read failures.

np_load_clauses(File, Clauses, Errors) :-
    catch(
        ( np_read_file_terms(File, Clauses), Errors = [] ),
        Err,
        ( Clauses = [], Errors = [error(np_load, Err)] )
    ).

np_read_file_terms(File, Terms) :-
    open(File, read, Stream),
    catch(
        ( np_read_stream(Stream, [], Terms), close(Stream) ),
        Err,
        ( close(Stream), throw(Err) )
    ).

np_read_stream(Stream, Acc, Terms) :-
    read_term(Stream, T, [variable_names(_)]),
    ( T = end_of_file ->
        reverse(Acc, Terms)
    ;
        np_read_stream(Stream, [T | Acc], Terms)
    ).

%% np_load_starlog_clauses(+File, -Clauses, -Errors)
%
% Read Starlog source and convert to standard Prolog terms.
% Uses transform_term_to_prolog/2 (from s2a_to_starlog_converter.pl).

np_load_starlog_clauses(File, Clauses, Errors) :-
    catch(
        ( np_read_file_terms(File, RawTerms),
          maplist(transform_term_to_prolog, RawTerms, Clauses),
          Errors = [] ),
        Err,
        ( Clauses = [], Errors = [error(np_load_starlog, Err)] )
    ).

% ---------------------------------------------------------------------------
% Plateau-stopped optimiser
% ---------------------------------------------------------------------------

%% np_plateau_optimise(+Clauses, -Optimised, +MaxIter, -Log)
%
% Apply optimisation passes until no changes occur (plateau) or MaxIter
% is reached.  Log is a list of human-readable messages.

np_plateau_optimise(Clauses, Optimised, MaxIter, Log) :-
    np_plateau_loop(Clauses, Optimised, MaxIter, 0, [], Log).

np_plateau_loop(Clauses, Optimised, MaxIter, Iter, Log0, Log) :-
    np_optimise_pass(Clauses, Clauses2, PassLog),
    Iter1 is Iter + 1,
    append(Log0, PassLog, Log1),
    ( np_clauses_equivalent(Clauses, Clauses2) ->
        format(atom(Msg),
            'NP: optimisation plateau reached after ~w pass(es).', [Iter1]),
        append(Log1, [Msg], Log),
        Optimised = Clauses
    ; Iter1 >= MaxIter ->
        format(atom(Msg),
            'NP: plateau stopping rule applied after ~w passes.', [MaxIter]),
        append(Log1, [Msg], Log),
        Optimised = Clauses2
    ;
        np_plateau_loop(Clauses2, Optimised, MaxIter, Iter1, Log1, Log)
    ).

%% np_clauses_equivalent(+Cs1, +Cs2)
%
% True when two clause lists are structurally equivalent up to variable
% renaming.  Uses canonical form: copy_term + numbervars + term_to_atom.

np_clauses_equivalent(Cs1, Cs2) :-
    length(Cs1, L),
    length(Cs2, L),
    maplist(np_clause_canonical, Cs1, As1),
    maplist(np_clause_canonical, Cs2, As2),
    As1 == As2.

np_clause_canonical(Clause, Atom) :-
    copy_term(Clause, C),
    numbervars(C, 0, _),
    term_to_atom(C, Atom).

% ---------------------------------------------------------------------------
% Optimisation pass
% ---------------------------------------------------------------------------

%% np_optimise_pass(+Clauses, -Clauses2, -Log)
%
% Apply one full pass of all correctness-preserving optimisations.

np_optimise_pass(Clauses, Clauses4, Log) :-
    np_remove_true_pass(Clauses,   Clauses2, Log1),
    np_remove_fail_pass(Clauses2,  Clauses2b, Log1b),
    np_unfold_deterministic_pass(Clauses2b, Clauses3, Log2),
    np_gaussian_optimise_pass(Clauses3,    Clauses4, Log3),
    append(Log1,  Log1b, LogA),
    append(LogA,  Log2,  LogB),
    append(LogB,  Log3,  Log).

% ---------------------------------------------------------------------------
% Optimisation 1: Remove `true` from conjunctions
% ---------------------------------------------------------------------------

%% np_remove_true_pass(+Clauses, -Clauses2, -Log)

np_remove_true_pass(Clauses, Clauses2, Log) :-
    maplist(np_remove_true_clause, Clauses, Clauses2),
    ( np_clauses_equivalent(Clauses, Clauses2) ->
        Log = []
    ;
        Log = ['NP: removed redundant true/0 goals.']
    ).

%% np_remove_true_clause(+Clause, -Clause2)
%
% Remove all `true` goals from the body of a clause.
% A body consisting solely of `true` is left as `true`.

np_remove_true_clause((Head :- Body), (Head :- Body2)) :- !,
    np_goals_to_list(Body, Goals),
    exclude(==(true), Goals, Goals2),
    ( Goals2 = [] ->
        Body2 = true
    ;
        np_list_to_goals(Goals2, Body2)
    ).
np_remove_true_clause(Term, Term).

% ---------------------------------------------------------------------------
% Optimisation 2: Remove fail-body clauses (dead code)
% ---------------------------------------------------------------------------

%% np_remove_fail_pass(+Clauses, -Clauses2, -Log)
%
% Remove clauses whose body is `fail` — they can never succeed.

np_remove_fail_pass(Clauses, Clauses2, Log) :-
    exclude(np_clause_body_is_fail, Clauses, Clauses2),
    ( length(Clauses, L1), length(Clauses2, L2), L1 \= L2 ->
        D is L1 - L2,
        format(atom(Msg), 'NP: removed ~w unreachable fail-body clause(s).', [D]),
        Log = [Msg]
    ;
        Log = []
    ).

np_clause_body_is_fail((_ :- fail)).

% ---------------------------------------------------------------------------
% Optimisation 3: Deterministic unfolding
% ---------------------------------------------------------------------------

%% np_unfold_deterministic_pass(+Clauses, -Clauses2, -Log)
%
% Find predicates eligible for unfolding and inline them into all call sites.
%
% A predicate P/N is eligible when:
%   - It has exactly one clause.
%   - It has no cut.
%   - It is not recursive.
%   - It does not contain irreducible goals.
%   - It is called from at least one other clause.

np_unfold_deterministic_pass(Clauses, Clauses2, Log) :-
    np_find_unfoldable(Clauses, Unfoldable),
    ( Unfoldable = [] ->
        Clauses2 = Clauses, Log = []
    ;
        np_unfold_all(Clauses, Unfoldable, Clauses2),
        length(Unfoldable, N),
        format(atom(Msg),
            'NP: unfolded ~w deterministic helper predicate(s).', [N]),
        Log = [Msg]
    ).

%% np_find_unfoldable(+Clauses, -Unfoldable)
%
% Collect Name/Arity pairs eligible for unfolding.

np_find_unfoldable(Clauses, Unfoldable) :-
    findall(Name/Arity,
        ( member(Clause, Clauses),
          np_clause_head(Clause, Head),
          callable(Head),
          functor(Head, Name, Arity),
          \+ np_predicate_contains_irreducible(Name, Arity, Clauses),
          np_count_clauses_for(Clauses, Name, Arity, 1),
          \+ np_clause_contains_cut(Clause),
          \+ np_clause_is_recursive(Clause, Name, Arity),
          np_is_called_from_other(Clauses, Name, Arity)
        ),
        Unfoldable0),
    sort(Unfoldable0, Unfoldable).

np_clause_head((Head :- _), Head) :- !.
np_clause_head(Head, Head) :- callable(Head), Head \= (:- _).

np_count_clauses_for(Clauses, Name, Arity, Count) :-
    findall(C,
        ( member(C, Clauses),
          np_clause_head(C, H),
          functor(H, Name, Arity)
        ),
        Matching),
    length(Matching, Count).

np_clause_contains_cut((_ :- Body)) :- !,
    np_goals_to_list(Body, Goals),
    member(!, Goals).
np_clause_contains_cut(_) :- fail.

np_clause_is_recursive((_ :- Body), Name, Arity) :- !,
    np_goals_to_list(Body, Goals),
    member(Goal, Goals),
    callable(Goal),
    functor(Goal, Name, Arity).
np_clause_is_recursive(_, _, _) :- fail.

np_is_called_from_other(Clauses, Name, Arity) :-
    member(OtherClause, Clauses),
    \+ ( np_clause_head(OtherClause, H), callable(H), functor(H, Name, Arity) ),
    OtherClause = (_ :- OtherBody),
    np_goals_to_list(OtherBody, Goals),
    member(Goal, Goals),
    callable(Goal),
    functor(Goal, Name, Arity),
    !.

%% np_unfold_all(+Clauses, +Unfoldable, -Clauses2)
%
% Apply unfolding for every predicate in Unfoldable.

np_unfold_all(Clauses, [], Clauses).
np_unfold_all(Clauses, [Pred|Rest], Result) :-
    np_unfold_pred(Clauses, Pred, Clauses2),
    np_unfold_all(Clauses2, Rest, Result).

np_unfold_pred(Clauses, Name/Arity, Clauses2) :-
    findall(C,
        ( member(C, Clauses),
          np_clause_head(C, H),
          functor(H, Name, Arity)
        ),
        [DefClause]),
    maplist(np_unfold_clause(Name, Arity, DefClause), Clauses, Clauses2).

%% np_unfold_clause(+Name, +Arity, +DefClause, +Clause, -Clause2)
%
% Inline all calls to Name/Arity in Clause with the body of DefClause.

np_unfold_clause(_Name, _Arity, _Def, (:- Directive), (:- Directive)) :- !.
np_unfold_clause(Name, Arity, DefClause, (Head :- Body), (Head :- Body2)) :- !,
    np_goals_to_list(Body, Goals),
    maplist(np_unfold_goal(Name, Arity, DefClause), Goals, GoalLists),
    append(GoalLists, Goals2),
    np_list_to_goals(Goals2, Body2).
np_unfold_clause(_, _, _, Clause, Clause).

%% np_unfold_goal(+Name, +Arity, +DefClause, +Goal, -GoalList)
%
% If Goal is a call to Name/Arity, replace it with the body of DefClause.
% Otherwise return [Goal] unchanged.

np_unfold_goal(Name, Arity, DefClause, Goal, GoalList) :-
    callable(Goal),
    functor(Goal, Name, Arity),
    !,
    copy_term(DefClause, DefFresh),
    ( DefFresh = (DefHead :- DefBody) ->
        ( Goal = DefHead ->
            np_goals_to_list(DefBody, GoalList)
        ;
            GoalList = [Goal]
        )
    ;
        % DefClause is a fact (no body).
        ( Goal = DefFresh ->
            GoalList = [true]
        ;
            GoalList = [Goal]
        )
    ).
np_unfold_goal(_, _, _, Goal, [Goal]).

% ---------------------------------------------------------------------------
% Output writer
% ---------------------------------------------------------------------------

%% np_write_output(+OutMode, +Clauses, +CodeOut, -Errors)
%
% Write the optimised clauses to CodeOut.
% OutMode = starlog → also convert to Starlog and write a .starlog file.
% When CodeOut = '' no file is written.

np_write_output(_OutMode, _Clauses, '', []) :- !.
np_write_output(OutMode, Clauses, CodeOut, Errors) :-
    catch(
        ( np_ensure_dir(CodeOut),
          np_write_prolog_to_file(Clauses, CodeOut),
          pipeline_log(info, ['NP: wrote optimised Prolog to ', CodeOut, '.']),
          ( OutMode = starlog ->
              file_name_extension(Base, _, CodeOut),
              atom_concat(Base, '.starlog', StarlogFile),
              np_write_starlog_to_file(Clauses, StarlogFile),
              pipeline_log(info, ['NP: wrote Starlog to ', StarlogFile, '.'])
          ; true ),
          Errors = [] ),
        Err,
        Errors = [error(np_write_output, Err)]
    ).

%% np_write_prolog_to_file(+Clauses, +File)

np_write_prolog_to_file(Clauses, File) :-
    open(File, write, Stream),
    format(Stream,
        '% Generated Prolog — NeuroStarlog NP optimiser (PR 5).~n~n', []),
    forall(
        member(Clause, Clauses),
        ( copy_term(Clause, ClauseCopy),
          numbervars(ClauseCopy, 0, _),
          write_term(Stream, ClauseCopy, [quoted(true), numbervars(true)]),
          write(Stream, '.'),
          nl(Stream), nl(Stream) )
    ),
    close(Stream).

%% np_write_starlog_to_file(+Clauses, +File)
%
% Convert each Prolog clause to Starlog and write to File.

np_write_starlog_to_file(Clauses, File) :-
    maplist(np_clause_to_atom, Clauses, ClauseTexts),
    maplist(convert_prolog_to_starlog, ClauseTexts, StarlogTexts),
    open(File, write, Stream),
    format(Stream,
        '% Generated Starlog — NeuroStarlog NP optimiser (PR 5).~n~n', []),
    forall(
        member(Text, StarlogTexts),
        ( write(Stream, Text), nl(Stream), nl(Stream) )
    ),
    close(Stream).

np_clause_to_atom(Clause, Atom) :-
    copy_term(Clause, C),
    numbervars(C, 0, _),
    with_output_to(atom(Body),
        write_term(C, [quoted(true), numbervars(true)])),
    atom_concat(Body, '.', Atom).

np_ensure_dir(File) :-
    file_directory_name(File, Dir),
    ( Dir = '' -> true
    ; exists_directory(Dir) -> true
    ; make_directory(Dir)
    ).

% ---------------------------------------------------------------------------
% Goal list helpers (np_ prefixed to avoid conflicts with other includes)
% ---------------------------------------------------------------------------

%% np_goals_to_list(+Goals, -List)

np_goals_to_list((G1, G2), [G1 | Rest]) :- !,
    np_goals_to_list(G2, Rest).
np_goals_to_list(G, [G]).

%% np_list_to_goals(+List, -Goals)

np_list_to_goals([G], G) :- !.
np_list_to_goals([G | Gs], (G, Rest)) :-
    np_list_to_goals(Gs, Rest).
