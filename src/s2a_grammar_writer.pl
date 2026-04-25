% s2a_grammar_writer.pl
% PR 2: S2A grammar output writer.
%
% Accepts I/O examples, detects repeated [r,...] and non-deterministic [nd,...]
% patterns, generates grammar rules, and writes them to a file.
%
% Grammar rules are written to:
%   out/<predicate>_grammar.pl
%
% Rule format (written to file):
%   grammar_rule(PredName, LHS, '->', RHS).
%
% where LHS is a non-terminal [n, Name] and RHS is a list of grammar items.
% Grammar items may include:
%   [r, NT]       — repeated (recursive) sub-pattern
%   [nd, Alts]    — non-deterministic alternatives list
%   [[]]          — empty production (base case)
%   [X]           — terminal element X

%% write_s2a_grammar(+PredName, +ExamplesFile, +GrammarOutFile, -Grammar, -Status)
%
% Main entry point.  Read I/O examples from ExamplesFile, generate grammar rules
% for predicate PredName, write them to GrammarOutFile.
%
% Grammar is the list of generated grammar_rule/4 terms.
% Status = ok | partial(Errors)
%   where Errors is a list of error(Type, Detail) terms.
%
% When GrammarOutFile = '' no file is written.
% On partial failure the grammar (even if empty) is still written so that
% unsupported sections are clearly marked.

write_s2a_grammar(PredName, ExamplesFile, GrammarOutFile, Grammar, Status) :-
    read_io_examples_safe(ExamplesFile, Examples, ReadErrors),
    ( ReadErrors \= [] ->
        Grammar = [],
        write_grammar_safe(PredName, Grammar, GrammarOutFile, _),
        Status = partial(ReadErrors)
    ;
        generate_grammar_safe(PredName, Examples, Grammar, GenErrors),
        write_grammar_safe(PredName, Grammar, GrammarOutFile, WriteErrors),
        append(GenErrors, WriteErrors, AllErrors),
        ( AllErrors = [] -> Status = ok ; Status = partial(AllErrors) )
    ).

%% read_io_examples_safe(+File, -Examples, -Errors)

read_io_examples_safe(File, Examples, Errors) :-
    catch(
        ( read_io_examples(File, Examples), Errors = [] ),
        Err,
        ( Examples = [], Errors = [error(read_examples, Err)] )
    ).

%% generate_grammar_safe(+PredName, +Examples, -Grammar, -Errors)

generate_grammar_safe(PredName, Examples, Grammar, Errors) :-
    catch(
        generate_s2a_grammar(PredName, Examples, Grammar, Errors),
        Err,
        ( Grammar = [], Errors = [error(generate_grammar, Err)] )
    ).

%% write_grammar_safe(+PredName, +Grammar, +OutFile, -Errors)

write_grammar_safe(_PredName, _Grammar, '', []) :- !.
write_grammar_safe(PredName, Grammar, OutFile, Errors) :-
    catch(
        ( ensure_out_dir(OutFile),
          write_grammar_file(PredName, Grammar, OutFile),
          Errors = [] ),
        Err,
        Errors = [error(write_grammar, Err)]
    ).

% ---------------------------------------------------------------------------
% I/O example reader
% ---------------------------------------------------------------------------

%% read_io_examples(+File, -Examples)
%
% Read I/O example pairs from File.
% Accepts two term formats per example:
%   [Input, Output]                         — simple pair
%   [[input, Input], [output, Output]]      — labelled pair

read_io_examples(File, Examples) :-
    read_terms_from_file(File, Terms),
    maplist(normalise_io_example, Terms, Examples).

read_terms_from_file(File, Terms) :-
    open(File, read, Stream),
    catch(
        ( read_terms_stream(Stream, [], Terms), close(Stream) ),
        Err,
        ( close(Stream), throw(Err) )
    ).

read_terms_stream(Stream, Acc, Terms) :-
    read_term(Stream, T, []),
    ( T = end_of_file ->
        reverse(Acc, Terms)
    ;
        read_terms_stream(Stream, [T | Acc], Terms)
    ).

normalise_io_example([Input, Output],
                     [[input, Input], [output, Output]]) :- !.
normalise_io_example([[input, In], [output, Out]],
                     [[input, In], [output, Out]]) :- !.
normalise_io_example(T, [[input, T], [output, []]]).

% ---------------------------------------------------------------------------
% Grammar generation
% ---------------------------------------------------------------------------

%% generate_s2a_grammar(+PredName, +Examples, -Rules, -Errors)
%
% Analyse Examples and produce a list of grammar_rule/4 terms in Rules.
% Errors accumulates partial-failure descriptors.

generate_s2a_grammar(_PredName, [], [], [error(no_examples, 'No I/O examples provided.')]) :- !.

generate_s2a_grammar(PredName, Examples, Rules, Errors) :-
    extract_inputs(Examples, Inputs),
    extract_outputs(Examples, Outputs),
    detect_repeated_subpatterns(Inputs, HasRepeated),
    detect_nondeterminism(Inputs, Outputs, HasND),
    detect_list_growth(Inputs, HasGrowth),
    build_grammar_rules(PredName, HasRepeated, HasGrowth, HasND, Rules, Errors).

extract_inputs(Examples, Inputs) :-
    findall(In, member([[input, In], [output, _]], Examples), Inputs).

extract_outputs(Examples, Outputs) :-
    findall(Out, member([[input, _], [output, Out]], Examples), Outputs).

%% detect_repeated_subpatterns(+Inputs, -HasRepeated)
%
% HasRepeated = true when any input list contains a repeated element.

detect_repeated_subpatterns(Inputs, true) :-
    member(Input, Inputs),
    is_list(Input),
    length(Input, L), L > 1,
    find_repeated_element(Input),
    !.
detect_repeated_subpatterns(_, false).

find_repeated_element(List) :-
    append(_, [X | Rest], List),
    X \= [],
    member(X, Rest).

%% detect_nondeterminism(+Inputs, +Outputs, -HasND)
%
% HasND = true when two examples share the same input length but produce
% different outputs, indicating a non-deterministic choice.

detect_nondeterminism(Inputs, Outputs, HasND) :-
    zip_pairs(Inputs, Outputs, Pairs),
    ( member(In1-Out1, Pairs),
      member(In2-Out2, Pairs),
      In1 \= In2,
      is_list(In1), is_list(In2),
      length(In1, L), length(In2, L),
      Out1 \= Out2 ->
        HasND = true
    ;
        HasND = false
    ).

zip_pairs([], [], []).
zip_pairs([H1 | T1], [H2 | T2], [H1-H2 | T3]) :-
    zip_pairs(T1, T2, T3).

%% detect_list_growth(+Inputs, -HasGrowth)
%
% HasGrowth = true when input lists grow in length across examples,
% indicating a recursive list structure.

detect_list_growth(Inputs, true) :-
    include(is_list, Inputs, ListInputs),
    length(ListInputs, N), N > 1,
    maplist(length, ListInputs, Lengths),
    sort(Lengths, Sorted),
    length(Sorted, M), M > 1,
    !.
detect_list_growth(_, false).

% ---------------------------------------------------------------------------
% Grammar rule builder
% ---------------------------------------------------------------------------

%% build_grammar_rules(+PredName, +HasRepeated, +HasGrowth, +HasND, -Rules, -Errors)

build_grammar_rules(PredName, HasRepeated, HasGrowth, HasND, Rules, []) :-
    BaseRule = grammar_rule(PredName, [n, a1], '->', [[]]),
    build_recursive_rule(PredName, HasRepeated, HasGrowth, HasND, RecRule),
    ( RecRule = none ->
        Rules = [BaseRule]
    ;
        Rules = [BaseRule, RecRule]
    ).

%% build_recursive_rule(+PredName, +HasRepeated, +HasGrowth, +HasND, -Rule)
%
% Selects the most appropriate recursive grammar rule:
%   HasRepeated=true → [r, [n, a1]] (repeated sub-pattern)
%   HasGrowth=true   → ['_X', [n, a1]] (single-element recursion)
%   both false       → no recursive rule

build_recursive_rule(PredName, true, _, HasND, Rule) :-
    % Detected a repeated element within at least one input → use [r, ...]
    ( HasND = true ->
        Rule = grammar_rule(PredName, [n, a1], '->', [[nd, [[r, [n, a1]], ['_X', [n, a1]]]]])
    ;
        Rule = grammar_rule(PredName, [n, a1], '->', [[r, [n, a1]]])
    ).
build_recursive_rule(PredName, false, true, HasND, Rule) :-
    % Input length grows across examples → recursive list grammar
    ( HasND = true ->
        Rule = grammar_rule(PredName, [n, a1], '->', [[nd, [['_X'], ['_Y']]], [n, a1]])
    ;
        Rule = grammar_rule(PredName, [n, a1], '->', [['_X'], [n, a1]])
    ).
build_recursive_rule(_PredName, false, false, _HasND, none).

% ---------------------------------------------------------------------------
% Grammar file writer
% ---------------------------------------------------------------------------

%% write_grammar_file(+PredName, +Rules, +File)
%
% Write grammar rules to File as Prolog terms that can be consulted.

write_grammar_file(PredName, Rules, File) :-
    open(File, write, Stream),
    format(Stream, '% Grammar for predicate: ~w~n', [PredName]),
    format(Stream, '% Generated by NeuroStarlog S2A grammar writer.~n~n', []),
    format(Stream, ':- dynamic grammar_rule/4.~n~n', []),
    ( Rules = [] ->
        format(Stream, '% UNRESOLVED: No grammar rules could be generated.~n', [])
    ;
        forall(
            member(Rule, Rules),
            ( write_term(Stream, Rule, [quoted(true)]),
              write(Stream, '.'),
              nl(Stream) )
        )
    ),
    close(Stream).

% ---------------------------------------------------------------------------
% Utilities
% ---------------------------------------------------------------------------

%% ensure_out_dir(+File)
%
% Create the directory that will contain File if it does not already exist.

ensure_out_dir(File) :-
    file_directory_name(File, Dir),
    ( Dir = '' -> true
    ; exists_directory(Dir) -> true
    ; make_directory(Dir)
    ).
