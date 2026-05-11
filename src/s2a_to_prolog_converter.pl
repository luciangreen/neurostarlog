% s2a_to_prolog_converter.pl
% PR 3: S2A grammar → runnable Prolog predicates.
%
% Converts grammar_rule/4 terms (produced by s2a_grammar_writer.pl) into
% SWI-Prolog-compatible clauses written to out/<predicate>_generated.pl.
%
% Conversion rules:
%   grammar_rule(P, [n,a1], '->', [[]])
%       → base case:  P([], _Out).
%
%   grammar_rule(P, [n,a1], '->', [['_X'], [n,a1]])
%       → recursive:  P([_X|T_], Out_) :- P(T_, Out_).
%         % UNRESOLVED: element combination not determined.
%
%   grammar_rule(P, [n,a1], '->', [[r, [n,a1]]])
%       → repeated:   P(Xs_, Out_) :- P(Xs_, Out_).
%         % UNRESOLVED: repeated pattern computation not determined.
%
%   grammar_rule(P, [n,a1], '->', [[nd, Alts]])
%       → one clause per alternative in Alts.
%
%   grammar_rule(P, [n,a1], '->', [[nd, Alts], [n,a1]])
%       → one clause per alternative, each including a recursive call.
%
%   grammar_rule(P, [n,a1], '->', [[a, Cmd], [n,a1]])
%       → placeholder replacement:
%         P([_X|T_], Out_) :- Cmd, P(T_, Out_).
%
%   grammar_rule(P, [n,a1], '->', [[Cmd], [n,a1]])
%       → irreducible command preserved:
%         P([_X|T_], Out_) :- Cmd, P(T_, Out_).
%
% Irreducible grammar items (unrecognised patterns) are preserved with
% an UNRESOLVED comment; partial code is still written to the output file.
%
% Output file: out/<predicate>_generated.pl

%% write_s2a_prolog(+PredName, +Grammar, +OutFile, -Status)
%
% Top-level entry point.
% Convert Grammar rules for PredName to Prolog and write to OutFile.
% Status = ok | partial(Errors)
%
% When OutFile = '' no file is written.

write_s2a_prolog(PredName, Grammar, OutFile, Status) :-
    convert_s2a_grammar_to_prolog(PredName, Grammar, ClauseTexts, ConvErrors),
    write_prolog_generated_safe(PredName, ClauseTexts, OutFile, WriteErrors),
    append(ConvErrors, WriteErrors, AllErrors),
    ( AllErrors = [] -> Status = ok ; Status = partial(AllErrors) ).

%% convert_s2a_grammar_to_prolog(+PredName, +Grammar, -ClauseTexts, -Errors)
%
% Convert a list of grammar_rule/4 terms to a flat list of clause text atoms.
% Errors is a list of error(Type, Detail) terms for unresolved sections.

convert_s2a_grammar_to_prolog(_PredName, [],
        [], [error(no_grammar, 'No grammar rules to convert.')]) :- !.
convert_s2a_grammar_to_prolog(PredName, Grammar, ClauseTexts, Errors) :-
    grammar_rules_to_clauses(PredName, Grammar, ClauseTexts, Errors).

grammar_rules_to_clauses(_Pred, [], [], []).
grammar_rules_to_clauses(Pred, [Rule|Rules], Clauses, Errors) :-
    grammar_rule_to_prolog(Pred, Rule, RuleClauses, RuleErrors),
    grammar_rules_to_clauses(Pred, Rules, RestClauses, RestErrors),
    append(RuleClauses, RestClauses, Clauses),
    append(RuleErrors, RestErrors, Errors).

%% grammar_rule_to_prolog(+PredName, +Rule, -ClauseTexts, -Errors)

grammar_rule_to_prolog(Pred, grammar_rule(Pred, [n, a1], '->', RHS),
                        Clauses, Errors) :-
    !,
    rhs_to_clause_texts(Pred, RHS, Clauses, Errors).
grammar_rule_to_prolog(Pred, Rule, [], [error(unrecognised_rule, Pred-Rule)]).

% ---------------------------------------------------------------------------
% RHS → clause text conversion
% ---------------------------------------------------------------------------

%% rhs_to_clause_texts(+PredName, +RHS, -ClauseTexts, -Errors)
%
% RHS is the list of grammar items from the right-hand side of a grammar_rule.
% Each grammar item is itself a list:
%   [[]]            — empty terminal (base case)
%   ['_X']          — a single variable element
%   ['_Y']          — a second variable element
%   ['_X', [n,a1]]  — variable element + embedded recursive non-terminal
%   [r,  [n,a1]]    — repeated recursive sub-pattern
%   [nd, Alts]      — non-deterministic alternatives (Alts is a list of items)
%   [n,  a1]        — non-terminal (recursive call)

% Base case: empty production → P([], _Out).
rhs_to_clause_texts(Pred, [[]], [Text], []) :-
    format(atom(Text), '~w([], _Out).', [Pred]).

% Single variable head + recursive tail: [['_X'], [n,a1]]
rhs_to_clause_texts(Pred, [['_X'], [n, a1]], [Text],
                    [error(unresolved_combination, Pred)]) :-
    format(atom(Text),
        '~w([_X|T_], Out_) :-\n    % UNRESOLVED: element combination not determined.\n    ~w(T_, Out_).',
        [Pred, Pred]).

% Repeated structure: [[r, [n,a1]]]
rhs_to_clause_texts(Pred, [[r, [n, a1]]], [Text],
                    [error(unresolved_repeated, Pred)]) :-
    format(atom(Text),
        '~w(Xs_, Out_) :-\n    % UNRESOLVED: repeated pattern computation not determined.\n    % WARNING: Replace this placeholder before executing — do not run as-is.\n    fail, ~w(Xs_, Out_).',
        [Pred, Pred]).

% Embedded recursive item: ['_X', [n,a1]] (produced as FallbackItem in nd).
% Treated the same as [['_X'], [n,a1]].
rhs_to_clause_texts(Pred, [['_X', [n, a1]]], [Text],
                    [error(unresolved_combination, Pred)]) :-
    format(atom(Text),
        '~w([_X|T_], Out_) :-\n    % UNRESOLVED: element combination not determined.\n    ~w(T_, Out_).',
        [Pred, Pred]).

% Non-deterministic alternatives followed by a recursive call:
% [[nd, Alts], [n,a1]]
rhs_to_clause_texts(Pred, [[nd, Alts], [n, a1]], Clauses, Errors) :-
    convert_nd_alts(Pred, [[n, a1]], Alts, Clauses, Errors).

% Non-deterministic alternatives only: [[nd, Alts]]
rhs_to_clause_texts(Pred, [[nd, Alts]], Clauses, Errors) :-
    convert_nd_alts(Pred, [], Alts, Clauses, Errors).

% Placeholder replacement with command and recursion:
% [[a|b|c, Cmd], [n,a1]]
rhs_to_clause_texts(Pred, [[Placeholder, Cmd], [n, a1]], [Text], []) :-
    placeholder_symbol(Placeholder),
    callable(Cmd),
    !,
    cmd_to_atom(Cmd, CmdAtom),
    format(atom(Text),
        '~w([_X|T_], Out_) :-\n    ~w,\n    ~w(T_, Out_).',
        [Pred, CmdAtom, Pred]).

% Placeholder replacement with command only:
% [[a|b|c, Cmd]]
rhs_to_clause_texts(Pred, [[Placeholder, Cmd]], [Text], []) :-
    placeholder_symbol(Placeholder),
    callable(Cmd),
    !,
    cmd_to_atom(Cmd, CmdAtom),
    format(atom(Text),
        '~w(_In, _Out) :-\n    ~w.',
        [Pred, CmdAtom]).

% Placeholder without a command mapping (recursive form) -> partial failure.
rhs_to_clause_texts(Pred, [[Placeholder], [n, a1]], [Text],
                    [error(unresolved_placeholder, Pred-Placeholder)]) :-
    placeholder_symbol(Placeholder),
    !,
    format(atom(Text),
        '~w([_X|T_], Out_) :-\n    % UNRESOLVED: placeholder ~w had no command mapping.\n    ~w(T_, Out_).',
        [Pred, Placeholder, Pred]).

% Placeholder without a command mapping (non-recursive form) -> partial failure.
rhs_to_clause_texts(Pred, [[Placeholder]], [Text],
                    [error(unresolved_placeholder, Pred-Placeholder)]) :-
    placeholder_symbol(Placeholder),
    !,
    format(atom(Text),
        '% UNRESOLVED: ~w placeholder ~w had no command mapping.',
        [Pred, Placeholder]).

% Preserve an irreducible command with recursion:
% [[Cmd], [n,a1]]
rhs_to_clause_texts(Pred, [[Cmd], [n, a1]], [Text], []) :-
    callable(Cmd),
    \+ grammar_reserved_item(Cmd),
    !,
    cmd_to_atom(Cmd, CmdAtom),
    format(atom(Text),
        '~w([_X|T_], Out_) :-\n    ~w,\n    ~w(T_, Out_).',
        [Pred, CmdAtom, Pred]).

% Preserve an irreducible command without recursion:
% [[Cmd]]
rhs_to_clause_texts(Pred, [[Cmd]], [Text], []) :-
    callable(Cmd),
    \+ grammar_reserved_item(Cmd),
    !,
    cmd_to_atom(Cmd, CmdAtom),
    format(atom(Text),
        '~w(_In, _Out) :-\n    ~w.',
        [Pred, CmdAtom]).

% Single variable element (irreducible, no recursion): [['_X']]
rhs_to_clause_texts(Pred, [['_X']], [Text],
                    [error(unresolved_element, Pred)]) :-
    format(atom(Text),
        '~w([_X|_], _Out) :-\n    % UNRESOLVED: single element mapping not determined.\n    true.',
        [Pred]).

% Single second variable element: [['_Y']]
rhs_to_clause_texts(Pred, [['_Y']], [Text],
                    [error(unresolved_element, Pred)]) :-
    format(atom(Text),
        '~w([_Y|_], _Out) :-\n    % UNRESOLVED: single element mapping not determined.\n    true.',
        [Pred]).

% Fallback: unrecognised RHS — preserve as UNRESOLVED comment.
rhs_to_clause_texts(Pred, RHS, [Text], [error(unresolved_rhs, Pred-RHS)]) :-
    format(atom(Text),
        '% UNRESOLVED: ~w — unrecognised RHS pattern: ~w', [Pred, RHS]).

% ---------------------------------------------------------------------------
% Non-deterministic alternative expansion
% ---------------------------------------------------------------------------

%% convert_nd_alts(+Pred, +Suffix, +Alts, -Clauses, -Errors)
%
% Suffix is the list of RHS items to append after each alternative.
% Alts is the list of alternative grammar items.

convert_nd_alts(_Pred, _Suffix, [], [], []).
convert_nd_alts(Pred, Suffix, [Alt|Alts], Clauses, Errors) :-
    % Each Alt is a single grammar item (a list); wrap it for rhs_to_clause_texts.
    append([Alt], Suffix, AltRHS),
    rhs_to_clause_texts(Pred, AltRHS, AltClauses, AltErrors),
    convert_nd_alts(Pred, Suffix, Alts, RestClauses, RestErrors),
    append(AltClauses, RestClauses, Clauses),
    append(AltErrors, RestErrors, Errors).

% ---------------------------------------------------------------------------
% Placeholder/command helpers
% ---------------------------------------------------------------------------

placeholder_symbol(a).
placeholder_symbol(b).
placeholder_symbol(c).

grammar_reserved_item('_X').
grammar_reserved_item('_Y').
grammar_reserved_item([n, _]).
grammar_reserved_item([r, _]).
grammar_reserved_item([nd, _]).
grammar_reserved_item(Item) :-
    placeholder_symbol(Item).

cmd_to_atom(Cmd, Atom) :-
    with_output_to(atom(Atom),
        write_term(Cmd, [quoted(true), ignore_ops(false)])).

% ---------------------------------------------------------------------------
% File writer
% ---------------------------------------------------------------------------

%% write_prolog_generated_safe(+PredName, +ClauseTexts, +OutFile, -Errors)

write_prolog_generated_safe(_Pred, _Clauses, '', []) :- !.
write_prolog_generated_safe(Pred, Clauses, OutFile, Errors) :-
    catch(
        ( ensure_out_dir_conv(OutFile),
          write_prolog_generated(Pred, Clauses, OutFile),
          Errors = [] ),
        Err,
        Errors = [error(write_prolog, Err)]
    ).

%% write_prolog_generated(+PredName, +ClauseTexts, +File)
%
% Write the generated Prolog clauses to File.

write_prolog_generated(Pred, Clauses, File) :-
    open(File, write, Stream),
    format(Stream, '% Generated Prolog for predicate: ~w~n', [Pred]),
    format(Stream, '% Generated by NeuroStarlog S2A → Prolog converter (PR 3).~n', []),
    format(Stream, '% UNRESOLVED comments mark sections where the computation~n', []),
    format(Stream, '% could not be determined from the grammar structure alone.~n~n', []),
    format(Stream, ':- dynamic ~w/2.~n~n', [Pred]),
    ( Clauses = [] ->
        format(Stream,
            '% UNRESOLVED: No clauses could be generated for ~w.~n', [Pred])
    ;
        forall(
            member(ClauseText, Clauses),
            ( write(Stream, ClauseText), nl(Stream), nl(Stream) )
        )
    ),
    close(Stream).

%% ensure_out_dir_conv(+File)
%
% Create the directory that will contain File if it does not already exist.

ensure_out_dir_conv(File) :-
    file_directory_name(File, Dir),
    ( Dir = '' -> true
    ; exists_directory(Dir) -> true
    ; make_directory(Dir)
    ).
