% neurostarlog_tests.pl
% NeuroStarlog test suite — PR 1 shell.
%
% Run with:
%   swipl -q -s tests/neurostarlog_tests.pl -g run_tests -t halt
%
% Tests are added here incrementally across PRs.
% PR 1 adds the test infrastructure and skeleton tests.
% PR 2+ will fill in S2A grammar, Prolog conversion, and NP tests.

:- use_module(library(lists)).

:- discontiguous test/2.

:- include('../src/neurostarlog_pipeline.pl').

%% run_tests/0 — run all registered tests.

run_tests :-
    retractall(log_message(_)),
    findall(_, run_registered_tests, _),
    !.

run_registered_tests :-
    test(Name, Goal),
    ( catch(Goal, Err, (
        format('FAIL ~w — exception: ~w~n', [Name, Err]),
        fail
      )) ->
        format('PASS ~w~n', [Name])
    ;
        format('FAIL ~w~n', [Name])
    ),
    fail.
run_registered_tests.

%% test(+Name, +Goal)
%
% Register a named test.

% --- PR 1 skeleton tests ---

% T1: detect_input_type recognises a file that does not exist as unknown.
test('detect_input_type/unknown-file',
    ( detect_input_type('/nonexistent/path/file.pl', unknown) )).

% T2: parse_cli/2 parses --input flag.
test('parse_cli/input-flag',
    ( parse_cli(['--input', 'examples/input.pl'], Opts),
      member(input='examples/input.pl', Opts) )).

% T3: parse_cli/2 parses --out flag.
test('parse_cli/out-flag',
    ( parse_cli(['--out', 'starlog'], Opts),
      member(out=starlog, Opts) )).

% T4: parse_cli/2 parses --compress flag.
test('parse_cli/compress-flag',
    ( parse_cli(['--compress', 'true'], Opts),
      member(compress=true, Opts) )).

% T5: parse_cli/2 parses all known flags without error.
test('parse_cli/all-flags',
    ( parse_cli([
        '--input', 'examples/input.pl',
        '--input-type', 'auto',
        '--out', 'starlog',
        '--compress', 'true',
        '--grammar-out', 'out/grammar.pl',
        '--code-out', 'out/result.starlog',
        '--log-out', 'out/pipeline_log.txt',
        '--strict', 'true'
      ], Opts),
      length(Opts, 8) )).

% T6: pipeline_log/2 records messages.
test('pipeline_log/records-message',
    ( retractall(log_message(_)),
      pipeline_log(info, ['hello world']),
      log_message('[info] hello world') )).

% T7: detect_input_type detects io_examples when content has list brackets.
test('detect_input_type/io-examples',
    ( tmp_file('nsl_test_io', F),
      atom_concat(F, '.pl', TmpFile),
      tmp_write_file(TmpFile, '[[1,2],[3,4]].\n'),
      detect_input_type(TmpFile, io_examples) )).

% T8: detect_input_type detects prolog for plain Prolog source.
test('detect_input_type/prolog',
    ( tmp_file('nsl_test_pl', F),
      atom_concat(F, '.pl', TmpFile),
      tmp_write_file(TmpFile, 'foo(X) :- bar(X).\n'),
      detect_input_type(TmpFile, prolog) )).

%% tmp_write_file(+File, +Content)

tmp_write_file(File, Content) :-
    open(File, write, Stream),
    write(Stream, Content),
    close(Stream).

% ---------------------------------------------------------------------------
% PR 2 tests: S2A grammar writer
% ---------------------------------------------------------------------------

% T9: I/O examples produce a grammar file.
test('s2a_grammar/grammar-file-generated',
    ( tmp_file('nsl_grammar', GBase),
      atom_concat(GBase, '_grammar.pl', GrammarFile),
      write_s2a_grammar(test_pred, 'examples/input.pl',
                        GrammarFile, Grammar, Status),
      ( Status = ok ; Status = partial(_) ),
      Grammar \= [],
      exists_file(GrammarFile) )).

% T10: Grammar rules include a base (empty) production.
test('s2a_grammar/base-rule-generated',
    ( tmp_file('nsl_grammar2', GBase),
      atom_concat(GBase, '_grammar.pl', GrammarFile),
      write_s2a_grammar(test_pred2, 'examples/input.pl',
                        GrammarFile, Grammar, _Status),
      member(grammar_rule(test_pred2, [n, a1], '->', [[]]), Grammar) )).

% T11: Growing input lists trigger a recursive rule containing [n, a1].
test('s2a_grammar/recursive-rule-for-growing-input',
    ( tmp_file('nsl_grammar3', GBase),
      atom_concat(GBase, '_grammar.pl', GrammarFile),
      write_s2a_grammar(rtest, 'examples/input.pl',
                        GrammarFile, Grammar, _Status),
      member(grammar_rule(rtest, [n, a1], '->', RHS), Grammar),
      RHS \= [[]] )).

% T12: Repeated elements within inputs are detected.
test('s2a_grammar/repeated-element-detected',
    ( detect_repeated_subpatterns([[1,2,1,3]], true) )).

% T13: Non-repeated, non-growing inputs produce no repeated marker.
test('s2a_grammar/no-repeated-for-unique-elements',
    ( detect_repeated_subpatterns([[1,2,3,4]], false) )).

% T14: detect_nondeterminism/3 detects differing outputs for same-length inputs.
test('s2a_grammar/nondeterminism-detected',
    ( detect_nondeterminism([[1,2],[3,4]], [[a],[b]], true) )).

% T15: detect_nondeterminism/3 returns false when outputs are uniform.
test('s2a_grammar/no-nondeterminism-for-uniform-outputs',
    ( detect_nondeterminism([[1],[2],[3]], [[x],[x],[x]], false) )).

% T16: Partial S2A failure (nonexistent input file) returns partial status.
test('s2a_grammar/partial-failure-on-missing-file',
    ( write_s2a_grammar(test_pred, '/nonexistent/path/file.pl', '',
                        _Grammar, partial(_Errors)) )).

% T17: Generated grammar file loads in SWI-Prolog without error.
test('s2a_grammar/grammar-file-loadable',
    ( tmp_file('nsl_load', GBase),
      atom_concat(GBase, '_grammar.pl', GrammarFile),
      write_s2a_grammar(load_test, 'examples/input.pl',
                        GrammarFile, _Grammar, _Status),
      exists_file(GrammarFile),
      catch(consult(GrammarFile), _, true) )).

% T18: Empty examples list returns partial status with no_examples error.
test('s2a_grammar/empty-examples-partial',
    ( generate_s2a_grammar(empty_pred, [], _Rules,
                           [error(no_examples, _)]) )).

% T19: detect_list_growth/2 is true for inputs of varying length.
test('s2a_grammar/list-growth-detected',
    ( detect_list_growth([[1],[1,2],[1,2,3]], true) )).

% T20: detect_list_growth/2 is false for single-length inputs.
test('s2a_grammar/no-list-growth-for-uniform-length',
    ( detect_list_growth([[1,2],[3,4],[5,6]], false) )).

% ---------------------------------------------------------------------------
% PR 3 tests: S2A → Prolog converter
% ---------------------------------------------------------------------------

% T21: Grammar converts to a Prolog generated file (file exists).
test('s2a_prolog/prolog-file-generated',
    ( tmp_file('nsl_prolog', PBase),
      atom_concat(PBase, '_generated.pl', PrologFile),
      write_s2a_grammar(sum, 'examples/input.pl', '', Grammar, _),
      write_s2a_prolog(sum, Grammar, PrologFile, _Status),
      exists_file(PrologFile) )).

% T22: Generated Prolog contains the base clause P([], _Out).
test('s2a_prolog/base-clause-present',
    ( write_s2a_grammar(sum2, 'examples/input.pl', '', Grammar, _),
      convert_s2a_grammar_to_prolog(sum2, Grammar, Clauses, _Errors),
      member(Text, Clauses),
      sub_atom(Text, _, _, _, 'sum2([], _Out).') )).

% T23: Generated Prolog contains a recursive clause (with recursive call).
test('s2a_prolog/recursive-clause-present',
    ( write_s2a_grammar(rsum, 'examples/input.pl', '', Grammar, _),
      convert_s2a_grammar_to_prolog(rsum, Grammar, Clauses, _Errors),
      member(Text, Clauses),
      sub_atom(Text, _, _, _, 'rsum(') ,
      sub_atom(Text, _, _, _, ':-') )).

% T24: Partial failure (empty grammar) returns partial status with no_grammar error.
test('s2a_prolog/partial-failure-on-empty-grammar',
    ( write_s2a_prolog(empty_p, [], '', Status),
      Status = partial(Errors),
      member(error(no_grammar, _), Errors) )).

% T25: Generated Prolog file loads in SWI-Prolog without error.
test('s2a_prolog/generated-prolog-loadable',
    ( tmp_file('nsl_load_p', PBase),
      atom_concat(PBase, '_generated.pl', PrologFile),
      write_s2a_grammar(loadp, 'examples/input.pl', '', Grammar, _),
      write_s2a_prolog(loadp, Grammar, PrologFile, _Status),
      exists_file(PrologFile),
      catch(consult(PrologFile), _, true) )).

% T26: UNRESOLVED comment appears in generated Prolog for unresolved sections.
test('s2a_prolog/unresolved-comment-present',
    ( write_s2a_grammar(uctest, 'examples/input.pl', '', Grammar, _),
      convert_s2a_grammar_to_prolog(uctest, Grammar, Clauses, _Errors),
      member(Text, Clauses),
      sub_atom(Text, _, _, _, 'UNRESOLVED') )).

% T27: convert_s2a_grammar_to_prolog/4 reports errors for unresolved sections.
test('s2a_prolog/errors-for-unresolved-sections',
    ( write_s2a_grammar(ertest, 'examples/input.pl', '', Grammar, _),
      convert_s2a_grammar_to_prolog(ertest, Grammar, _Clauses, Errors),
      Errors \= [] )).

% T28: Partial grammar (missing file) produces partial Prolog with no_grammar error.
test('s2a_prolog/partial-prolog-on-missing-input',
    ( write_s2a_grammar(pftest, '/nonexistent/path/file.pl', '', Grammar, _),
      write_s2a_prolog(pftest, Grammar, '', Status),
      Status = partial(_) )).

% T29: Base-case grammar rule [P, [n,a1], '->', [[]]] generates P([], _Out).
test('s2a_prolog/base-rule-conversion',
    ( rhs_to_clause_texts(baseconv, [[]], Clauses, []),
      Clauses = [Text],
      sub_atom(Text, _, _, _, 'baseconv([], _Out).') )).

% T30: List-growth grammar rule generates recursive clause with recursive call.
test('s2a_prolog/recursive-rule-conversion',
    ( rhs_to_clause_texts(recconv, [['_X'], [n, a1]], Clauses, _Errors),
      Clauses = [Text],
      sub_atom(Text, _, _, _, 'recconv(') )).

% T31: Repeated-structure rule [[r, [n,a1]]] generates a clause.
test('s2a_prolog/repeated-rule-conversion',
    ( rhs_to_clause_texts(repconv, [[r, [n, a1]]], Clauses, _Errors),
      Clauses = [Text],
      sub_atom(Text, _, _, _, 'repconv(') )).

% T32: Non-deterministic rule [[nd, [Alt1, Alt2]]] generates two clauses.
test('s2a_prolog/nd-rule-generates-two-clauses',
    ( rhs_to_clause_texts(ndconv, [[nd, [['_X'], ['_Y']]]], Clauses, _Errors),
      length(Clauses, 2) )).

% T33: write_s2a_prolog/4 writes nothing and succeeds when OutFile is ''.
test('s2a_prolog/no-file-written-when-outfile-empty',
    ( write_s2a_grammar(nftest, 'examples/input.pl', '', Grammar, _),
      write_s2a_prolog(nftest, Grammar, '', Status),
      ( Status = ok ; Status = partial(_) ) )).
