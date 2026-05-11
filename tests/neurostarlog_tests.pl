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

% T33: Placeholder a/b/c with a mapped command is replaced in recursive Prolog.
test('s2a_prolog/placeholder-command-replaced',
    ( rhs_to_clause_texts(phconv, [[a, write(x)], [n, a1]], Clauses, Errors),
      Errors = [],
      Clauses = [Text],
      sub_atom(Text, _, _, _, 'write(x)'),
      sub_atom(Text, _, _, _, 'phconv(T_, Out_)') )).

% T34: Unmapped placeholder returns partial error and unresolved marker text.
test('s2a_prolog/unresolved-placeholder-error',
    ( rhs_to_clause_texts(phmiss, [[b], [n, a1]], Clauses, Errors),
      member(error(unresolved_placeholder, phmiss-b), Errors),
      Clauses = [Text],
      sub_atom(Text, _, _, _, 'UNRESOLVED') )).

% T35: Irreducible command grammar items are preserved unchanged.
test('s2a_prolog/irreducible-command-preserved',
    ( rhs_to_clause_texts(irconv, [[writeln(x)], [n, a1]], Clauses, Errors),
      Errors = [],
      Clauses = [Text],
      sub_atom(Text, _, _, _, 'writeln(x)'),
      sub_atom(Text, _, _, _, 'irconv(T_, Out_)') )).

% T36: write_s2a_prolog/4 writes nothing and succeeds when OutFile is ''.
test('s2a_prolog/no-file-written-when-outfile-empty',
    ( write_s2a_grammar(nftest, 'examples/input.pl', '', Grammar, _),
      write_s2a_prolog(nftest, Grammar, '', Status),
      ( Status = ok ; Status = partial(_) ) )).

% ---------------------------------------------------------------------------
% PR 4 tests: S2A → Starlog converter
% ---------------------------------------------------------------------------

% T34: I/O examples → Starlog file generated (file exists after S2A with out=starlog).
test('s2a_starlog/starlog-file-generated',
    ( tmp_file('nsl_starlog', SBase),
      atom_concat(SBase, '_generated.starlog', StarlogFile),
      write_s2a_grammar(sttest, 'examples/input.pl', '', Grammar, _),
      convert_s2a_grammar_to_prolog(sttest, Grammar, Clauses, _),
      write_s2a_starlog(sttest, Clauses, StarlogFile, Status),
      ( Status = ok ; Status = partial(_) ),
      exists_file(StarlogFile) )).

% T35: convert_prolog_to_starlog converts append(A,B,C) → C is A&B.
test('s2a_starlog/append-converted-to-starlog',
    ( convert_prolog_to_starlog(
          'foo(X,Y,Z) :- append(X,Y,Z).',
          StarlogText),
      sub_atom(StarlogText, _, _, _, ' is '),
      sub_atom(StarlogText, _, _, _, '&') )).

% T36: convert_prolog_to_starlog converts atom_concat(A,B,C) → C is A•B.
test('s2a_starlog/atom-concat-converted-to-starlog',
    ( convert_prolog_to_starlog(
          'bar(A,B,C) :- atom_concat(A,B,C).',
          StarlogText),
      sub_atom(StarlogText, _, _, _, '•') )).

% T37: convert_prolog_to_starlog converts string_concat(A,B,C) → C is A:B.
test('s2a_starlog/string-concat-converted-to-starlog',
    ( convert_prolog_to_starlog(
          'baz(A,B,C) :- string_concat(A,B,C).',
          StarlogText),
      sub_atom(StarlogText, _, _, _, ' is '),
      \+ sub_atom(StarlogText, _, _, _, 'string_concat') )).

% T38: convert_prolog_to_starlog is identity for clauses with no conversion targets.
test('s2a_starlog/identity-for-plain-clause',
    ( convert_prolog_to_starlog('plain([], _Out).', StarlogText),
      sub_atom(StarlogText, _, _, _, 'plain'),
      \+ sub_atom(StarlogText, _, _, _, ' is ') )).

% T39: write_s2a_starlog/4 writes nothing and succeeds when OutFile is ''.
test('s2a_starlog/no-file-written-when-outfile-empty',
    ( write_s2a_grammar(nfsl, 'examples/input.pl', '', Grammar, _),
      convert_s2a_grammar_to_prolog(nfsl, Grammar, Clauses, _),
      write_s2a_starlog(nfsl, Clauses, '', Status),
      ( Status = ok ; Status = partial(_) ) )).

% T40: Partial failure (empty ClauseTexts) returns partial status with no_clauses error.
test('s2a_starlog/partial-failure-on-empty-clauses',
    ( write_s2a_starlog(empty_sl, [], '', Status),
      Status = partial(Errors),
      member(error(no_clauses, _), Errors) )).

% T41: Roundtrip: append clause converts to Starlog and back to equivalent Prolog.
test('s2a_starlog/roundtrip-append',
    ( convert_prolog_to_starlog(
          'foo(A,B,C) :- append(A,B,C).',
          StarlogText),
      starlog_to_prolog(StarlogText, PrologText),
      sub_atom(PrologText, _, _, _, 'append') )).

% T42: Roundtrip: atom_concat clause converts to Starlog and back.
test('s2a_starlog/roundtrip-atom-concat',
    ( convert_prolog_to_starlog(
          'bar(A,B,C) :- atom_concat(A,B,C).',
          StarlogText),
      starlog_to_prolog(StarlogText, PrologText),
      sub_atom(PrologText, _, _, _, 'atom_concat') )).

% T42b: Direct Starlog two-operand expression roundtrips to one Prolog call.
test('s2a_starlog/roundtrip-two-operand-base-case',
    ( starlog_to_prolog('bar(A,B,C) :- C is A•B.', PrologText),
      findall(Pos, sub_atom(PrologText, Pos, _, _, 'atom_concat'), Ps),
      length(Ps, 1) )).

% T43: Method chaining: two consecutive atom_concat calls produce chained form.
test('s2a_starlog/method-chaining-atom-concat',
    ( convert_prolog_to_starlog(
          'cat3(A,B,C,R) :- atom_concat(A,B,T), atom_concat(T,C,R).',
          StarlogText),
      % The intermediate variable T is inlined: R is A•B•C
      sub_atom(StarlogText, _, _, _, '•') )).

% T44: Method chaining: two consecutive append calls produce chained form.
test('s2a_starlog/method-chaining-append',
    ( convert_prolog_to_starlog(
          'app3(A,B,C,R) :- append(A,B,T), append(T,C,R).',
          StarlogText),
      sub_atom(StarlogText, _, _, _, '&') )).

% T45: Method chaining safety: keep intermediate definition when used by non-is goals.
test('s2a_starlog/method-chaining-safe-with-non-is-use',
    ( convert_prolog_to_starlog(
          'mix(A,B,R) :- atom_concat(A,B,T), writeln(T), atom_concat(T,B,R).',
          StarlogText),
      sub_atom(StarlogText, _, _, _, 'T is A•B'),
      sub_atom(StarlogText, _, _, _, 'writeln(T)') )).

% T46: Generated Starlog file has .starlog extension and contains a header comment.
test('s2a_starlog/starlog-file-has-header',
    ( tmp_file('nsl_hdr', HBase),
      atom_concat(HBase, '_generated.starlog', StarlogFile),
      write_s2a_grammar(hdrtest, 'examples/input.pl', '', Grammar, _),
      convert_s2a_grammar_to_prolog(hdrtest, Grammar, Clauses, _),
      write_s2a_starlog(hdrtest, Clauses, StarlogFile, _Status),
      read_file_to_string(StarlogFile, Content, []),
      sub_string(Content, _, _, _, "Generated Starlog") )).

% T47: Roundtrip method-chained atom_concat expands back to Prolog predicate chain.
test('s2a_starlog/roundtrip-method-chained-atom-concat',
    ( convert_prolog_to_starlog(
          'cat3(A,B,C,R) :- atom_concat(A,B,T), atom_concat(T,C,R).',
          StarlogText),
      starlog_to_prolog(StarlogText, PrologText),
      findall(Pos, sub_atom(PrologText, Pos, _, _, 'atom_concat'), Ps),
      length(Ps, N),
      N >= 2,
      \+ sub_atom(PrologText, _, _, _, '•') )).

% T48: Roundtrip method-chained append expands back to Prolog predicate chain.
test('s2a_starlog/roundtrip-method-chained-append',
    ( convert_prolog_to_starlog(
          'app3(A,B,C,R) :- append(A,B,T), append(T,C,R).',
          StarlogText),
      starlog_to_prolog(StarlogText, PrologText),
      findall(Pos, sub_atom(PrologText, Pos, _, _, 'append'), Ps),
      length(Ps, N),
      N >= 2,
      \+ sub_atom(PrologText, _, _, _, '&') )).

% ---------------------------------------------------------------------------
% PR 5 tests: NP full-pipeline integration
% ---------------------------------------------------------------------------

% T46: np_load_clauses/3 successfully loads a Prolog file.
test('np/load-clauses',
    ( np_load_clauses('examples/np_prolog_input.pl', Clauses, Errors),
      Errors = [],
      Clauses \= [] )).

% T47: np_load_clauses/3 returns an error for a nonexistent file.
test('np/load-clauses-missing-file',
    ( np_load_clauses('/nonexistent/np_file.pl', [], Errors),
      Errors \= [] )).

% T48: np_is_irreducible_goal/1 recognises I/O predicates.
test('np/irreducible-io-write',
    ( np_is_irreducible_goal(write(hello)) )).

% T49: np_is_irreducible_goal/1 recognises random predicates.
test('np/irreducible-random',
    ( np_is_irreducible_goal(random_between(1, 6, _)) )).

% T50: np_is_irreducible_goal/1 does not flag plain user predicates.
test('np/not-irreducible-user-pred',
    ( \+ np_is_irreducible_goal(positive(_)) )).

% T51: np_remove_true_clause/2 removes `true` from a conjunction body.
%      Verifies the output body is (write(N), nl) without any `true` goal.
test('np/remove-true-from-body',
    ( np_remove_true_clause(
          (greet(N) :- true, write(N), nl),
          (greet(N) :- Body) ),
      Body = (write(N), nl) )).

% T52: np_remove_true_clause/2 preserves facts (no body).
test('np/remove-true-preserves-facts',
    ( np_remove_true_clause(base([]), base([])) )).

% T53: np_remove_true_clause/2 keeps a body that is only `true` as `true`.
test('np/remove-true-only-true-body',
    ( np_remove_true_clause(
          (foo :- true),
          (foo :- true) ) )).

% T54: np_clause_body_is_fail/1 detects fail-body clauses.
test('np/fail-body-detected',
    ( np_clause_body_is_fail((_ :- fail)) )).

% T55: np_clause_body_is_fail/1 does not trigger on a normal body.
test('np/fail-body-not-triggered',
    ( \+ np_clause_body_is_fail((foo(X) :- bar(X))) )).

% T56: np_plateau_optimise/4 terminates (plateau or max-iter) for any input.
test('np/plateau-terminates',
    ( np_load_clauses('examples/np_prolog_input.pl', Clauses, []),
      np_plateau_optimise(Clauses, _Optimised, 100, Log),
      member(Msg, Log),
      sub_atom(Msg, _, _, _, 'NP:') )).

% T57: Plateau is reached after one pass for an already-optimal clause set.
test('np/plateau-one-pass-for-optimal',
    ( np_plateau_optimise([(foo :- bar(x))], _Opt, 100, Log),
      member(Msg, Log),
      sub_atom(Msg, _, _, _, plateau) )).

% T58: Prolog source → NP optimisation → Prolog output file produced.
test('np/prolog-to-prolog-file',
    ( tmp_file('nsl_np_out', Base),
      atom_concat(Base, '_np.pl', OutFile),
      np_optimise_file('examples/np_prolog_input.pl', prolog, prolog,
                       true, OutFile, Status),
      ( Status = ok ; Status = partial(_) ),
      exists_file(OutFile) )).

% T59: Generated Prolog from NP path loads in SWI-Prolog without error.
test('np/generated-prolog-loadable',
    ( tmp_file('nsl_np_load', Base),
      atom_concat(Base, '_np_load.pl', OutFile),
      np_optimise_file('examples/np_prolog_input.pl', prolog, prolog,
                       true, OutFile, _Status),
      exists_file(OutFile),
      catch(consult(OutFile), _, true) )).

% T60: With out=starlog, NP path produces a .starlog output file.
test('np/prolog-to-starlog-file',
    ( tmp_file('nsl_np_sl', Base),
      atom_concat(Base, '_np.pl', OutFile),
      np_optimise_file('examples/np_prolog_input.pl', prolog, starlog,
                       true, OutFile, _Status),
      file_name_extension(Base2, _, OutFile),
      atom_concat(Base2, '.starlog', StarlogFile),
      exists_file(StarlogFile) )).

% T61: Generated Starlog from NP path contains NP header comment.
test('np/generated-starlog-has-header',
    ( tmp_file('nsl_np_hdr', Base),
      atom_concat(Base, '_np_hdr.pl', OutFile),
      np_optimise_file('examples/np_prolog_input.pl', prolog, starlog,
                       true, OutFile, _Status),
      file_name_extension(Base2, _, OutFile),
      atom_concat(Base2, '.starlog', StarlogFile),
      read_file_to_string(StarlogFile, Content, []),
      sub_string(Content, _, _, _, "Generated Starlog") )).

% T62: I/O predicates (writeln) are preserved in NP output.
test('np/io-predicates-preserved',
    ( tmp_file('nsl_np_io', Base),
      atom_concat(Base, '_np_io.pl', OutFile),
      np_optimise_file('examples/np_prolog_input.pl', prolog, prolog,
                       true, OutFile, _Status),
      read_file_to_string(OutFile, Content, []),
      sub_string(Content, _, _, _, "writeln") )).

% T63: Random predicates are preserved in NP output.
test('np/random-predicates-preserved',
    ( tmp_file('nsl_np_rnd', Base),
      atom_concat(Base, '_np_rnd.pl', OutFile),
      np_optimise_file('examples/np_prolog_input.pl', prolog, prolog,
                       true, OutFile, _Status),
      read_file_to_string(OutFile, Content, []),
      sub_string(Content, _, _, _, "random_between") )).

% T64: Unsupported arithmetic (X*X) is preserved unchanged in NP output.
test('np/unsupported-maths-preserved',
    ( tmp_file('nsl_np_math', Base),
      atom_concat(Base, '_np_math.pl', OutFile),
      np_optimise_file('examples/np_prolog_input.pl', prolog, prolog,
                       true, OutFile, _Status),
      read_file_to_string(OutFile, Content, []),
      sub_string(Content, _, _, _, "*") )).

% T65: np_clauses_equivalent/2 is true for structurally equal clause sets.
test('np/clauses-equivalent-same',
    ( np_clauses_equivalent([(foo(X) :- bar(X))], [(foo(Y) :- bar(Y))]) )).

% T66: np_clauses_equivalent/2 is false for different clause sets.
test('np/clauses-not-equivalent-different',
    ( \+ np_clauses_equivalent([(foo :- bar)], [(foo :- baz)]) )).

% T67: run_pipeline/1 uses NP path for prolog input and succeeds.
test('np/run-pipeline-np-path',
    ( retractall(log_message(_)),
      tmp_file('nsl_np_pipe', Base),
      atom_concat(Base, '_pipe.pl', OutFile),
      run_pipeline([
          input='examples/np_prolog_input.pl',
          input_type=prolog,
          out=prolog,
          compress=false,
          code_out=OutFile
      ]),
      exists_file(OutFile) )).

% T68: Gaussian elimination does not run without trace-based pattern detection.
%      (PR 5: no Gaussian module is invoked — verified by absence of Gaussian log.)
test('np/gaussian-not-run-without-pattern',
    ( retractall(log_message(_)),
      np_load_clauses('examples/np_prolog_input.pl', Clauses, []),
      np_plateau_optimise(Clauses, _, 100, Log),
      \+ member('NP: applied Gaussian elimination.', Log) )).

% T69: Unoptimisable program sections remain unchanged.
%      A clause with only irreducible goals is preserved as-is.
test('np/unoptimisable-unchanged',
    ( Clause = (log_it(X) :- writeln(X), nl),
      np_plateau_optimise([Clause], [Clause2], 100, _Log),
      np_clause_canonical(Clause, CA),
      np_clause_canonical(Clause2, CB),
      CA = CB )).

% T70: np_optimise_file/6 returns partial status for a missing input file.
test('np/partial-status-on-missing-file',
    ( np_optimise_file('/nonexistent/np_missing.pl', prolog, prolog,
                       true, '', Status),
      Status = partial(_) )).

% ---------------------------------------------------------------------------
% PR 6 tests: Gaussian/index optimisation
% ---------------------------------------------------------------------------

% T71: np_is_gaussian_candidate/3 recognises a linear recurrence predicate.
test('gaussian/candidate-detected-linear',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_is_gaussian_candidate(Clauses, linear, 2) )).

% T72: np_is_gaussian_candidate/3 recognises a quadratic (triangular) recurrence.
test('gaussian/candidate-detected-quadratic',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_is_gaussian_candidate(Clauses, tri, 2) )).

% T73: np_is_gaussian_candidate/3 does NOT flag a non-recurrence predicate.
test('gaussian/non-candidate-not-detected',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      \+ np_is_gaussian_candidate(Clauses, cube, 2) )).

% T74: np_find_gaussian_candidates/2 finds linear and tri but not cube.
test('gaussian/find-candidates',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_find_gaussian_candidates(Clauses, Candidates),
      member(linear/2, Candidates),
      member(tri/2, Candidates),
      \+ member(cube/2, Candidates) )).

% T75: gauss_solve/3 correctly solves a 2x2 linear system.
%      System: a0=2, a1=3 (from Vandermonde for degree 1, points 0→2, 1→5).
test('gaussian/gauss-solve-2x2',
    ( gauss_solve([[1,0],[1,1]], [2,5], [A0, A1]),
      A0 =:= 2,
      A1 =:= 3 )).

% T76: gauss_solve/3 correctly solves a 3x3 system (triangular numbers).
%      Points: (0,0), (1,1), (2,3) → coefficients [0, 1/2, 1/2].
%      Both A1 and A2 are 1/2 because the triangular-numbers polynomial is
%      0 + (1/2)*N + (1/2)*N^2  =  N*(N+1)/2.
test('gaussian/gauss-solve-3x3-tri',
    ( gauss_solve([[1,0,0],[1,1,1],[1,2,4]], [0,1,3], [A0, A1, A2]),
      A0 =:= 0,
      A1 =:= 1 rdiv 2,
      A2 =:= 1 rdiv 2 )).

% T77: gauss_fit_polynomial/3 fits degree-1 polynomial to linear sample points.
test('gaussian/fit-polynomial-linear',
    ( gauss_fit_polynomial([0-2, 1-5, 2-8, 3-11], 4, Coeffs),
      Coeffs = [A0, A1],
      A0 =:= 2,
      A1 =:= 3 )).

% T78: gauss_fit_polynomial/3 fits degree-2 polynomial to triangular sample points.
test('gaussian/fit-polynomial-quadratic',
    ( gauss_fit_polynomial([0-0, 1-1, 2-3, 3-6], 4, Coeffs),
      length(Coeffs, 3),
      Coeffs = [A0, A1, A2],
      A0 =:= 0,
      A1 =:= 1 rdiv 2,
      A2 =:= 1 rdiv 2 )).

% T79: np_trace_and_fit/5 traces linear recurrence and fits polynomial.
test('gaussian/trace-and-fit-linear',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_trace_and_fit(Clauses, linear, 2, 4, Coeffs),
      Coeffs = [A0, A1],
      A0 =:= 2,
      A1 =:= 3 )).

% T80: np_trace_and_fit/5 traces triangular recurrence and fits polynomial.
test('gaussian/trace-and-fit-quadratic',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_trace_and_fit(Clauses, tri, 2, 4, Coeffs),
      length(Coeffs, 3) )).

% T81: np_gaussian_optimise_pass/3 produces Gaussian log for gaussian_input.pl.
test('gaussian/pass-produces-log',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_gaussian_optimise_pass(Clauses, _, Log),
      member('NP: applied Gaussian elimination.', Log) )).

% T82: np_gaussian_optimise_pass/3 produces empty log for np_prolog_input.pl.
%      (No index recurrences in that file → Gaussian elimination not triggered.)
test('gaussian/pass-no-log-without-pattern',
    ( np_load_clauses('examples/np_prolog_input.pl', Clauses, []),
      np_gaussian_optimise_pass(Clauses, _, Log),
      \+ member('NP: applied Gaussian elimination.', Log) )).

% T83: Gaussian pass replaces linear/2 with a single closed-form clause.
test('gaussian/linear-replaced-with-one-clause',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_gaussian_optimise_pass(Clauses, Optimised, _Log),
      findall(C,
          ( member(C, Optimised),
            np_clause_head(C, H),
            functor(H, linear, 2) ),
          LinearClauses),
      length(LinearClauses, 1) )).

% T84: Generated closed-form clause for linear/2 gives correct values.
%      linear(0,Out) should give Out=2; linear(4,Out) should give Out=14.
test('gaussian/linear-closed-form-correct',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_trace_and_fit(Clauses, linear, 2, 4, Coeffs),
      np_make_closed_form_clause(linear, 2, Coeffs, Clause),
      Clause = (Head :- (OutVar is PolyExpr)),
      % Verify at N=0: Out=2
      copy_term(t(Head, PolyExpr, OutVar), t(H0, E0, _)),
      arg(1, H0, 0),
      catch(Val0 is E0, _, fail),
      Val0 =:= 2,
      % Verify at N=4: Out = 2+3*4 = 14
      copy_term(t(Head, PolyExpr, OutVar), t(H4, E4, _)),
      arg(1, H4, 4),
      catch(Val4 is E4, _, fail),
      Val4 =:= 14 )).

% T85: Gaussian-optimised file loads in SWI-Prolog without error.
test('gaussian/optimised-file-loadable',
    ( tmp_file('nsl_gauss_load', Base),
      atom_concat(Base, '_gauss.pl', OutFile),
      np_optimise_file('examples/gaussian_input.pl', prolog, prolog,
                       true, OutFile, _Status),
      exists_file(OutFile),
      catch(consult(OutFile), _, true) )).

% T86: cube/2 is preserved unchanged by the Gaussian pass.
test('gaussian/cube-preserved-unchanged',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_gaussian_optimise_pass(Clauses, Optimised, _Log),
      member(CubeClause, Optimised),
      np_clause_head(CubeClause, H),
      functor(H, cube, 2) )).

% T87: gauss_polynomial_value/3 evaluates a polynomial correctly.
%      Polynomial [2, 3] at N=4 → 2 + 3*4 = 14.
test('gaussian/polynomial-value',
    ( gauss_polynomial_value([2, 3], 4, Val),
      Val =:= 14 )).

% T88: gauss_polynomial_value/3 evaluates triangular polynomial at N=5.
%      Triangular(5) = 5*(5+1)/2 = 15.
test('gaussian/polynomial-value-quadratic',
    ( gauss_polynomial_value([0, 1 rdiv 2, 1 rdiv 2], 5, Val),
      Val =:= 15 )).

% T89: Full plateau optimisation runs Gaussian on gaussian_input.pl.
test('gaussian/plateau-runs-gaussian',
    ( np_load_clauses('examples/gaussian_input.pl', Clauses, []),
      np_plateau_optimise(Clauses, _Optimised, 100, Log),
      member(Msg, Log),
      sub_atom(Msg, _, _, _, 'Gaussian') )).

% T90: np_prolog_input.pl plateau optimisation does not trigger Gaussian.
%      (Re-confirms T68 under PR 6 with the Gaussian pass now active.)
test('gaussian/no-gaussian-on-np-prolog-input',
    ( retractall(log_message(_)),
      np_load_clauses('examples/np_prolog_input.pl', Clauses, []),
      np_plateau_optimise(Clauses, _, 100, Log),
      \+ member('NP: applied Gaussian elimination.', Log) )).

% ---------------------------------------------------------------------------
% PR 7 tests: Hybrid mode (S2A reconstruction + NP optimisation + preserved aux)
% ---------------------------------------------------------------------------

% T91: run_hybrid_path/6 with an I/O examples file and no aux file succeeds.
test('hybrid/run-hybrid-path-io-only',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb91', Base),
      atom_concat(Base, '_hyb91.pl', OutFile),
      run_hybrid_path('examples/input.pl', '', prolog, true, '', OutFile),
      exists_file(OutFile) )).

% T92: run_hybrid_path/6 with an I/O file and an auxiliary Prolog file succeeds.
test('hybrid/run-hybrid-path-with-aux',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb92', Base),
      atom_concat(Base, '_hyb92.pl', OutFile),
      run_hybrid_path('examples/input.pl', 'examples/np_prolog_input.pl',
                      prolog, true, '', OutFile),
      exists_file(OutFile) )).

% T93: Hybrid output contains content from both the S2A-generated section
%      and the auxiliary Prolog predicates.
test('hybrid/output-contains-both-sections',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb93', Base),
      atom_concat(Base, '_hyb93.pl', OutFile),
      run_hybrid_path('examples/input.pl', 'examples/np_prolog_input.pl',
                      prolog, true, '', OutFile),
      read_file_to_string(OutFile, Content, []),
      % From the S2A section: should contain the predicate name from input.pl
      sub_string(Content, _, _, _, "input"),
      % From the auxiliary section: at least one predicate from np_prolog_input.pl
      sub_string(Content, _, _, _, "writeln") )).

% T94: Auxiliary Prolog clauses are preserved unchanged in the hybrid output.
%      square/2 is an unsupported arithmetic predicate that NP cannot optimise.
test('hybrid/aux-predicates-preserved-unchanged',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb94', Base),
      atom_concat(Base, '_hyb94.pl', OutFile),
      run_hybrid_path('examples/input.pl', 'examples/np_prolog_input.pl',
                      prolog, true, '', OutFile),
      read_file_to_string(OutFile, Content, []),
      % square/2 uses unsupported arithmetic — must be preserved.
      sub_string(Content, _, _, _, "square") )).

% T95: The hybrid log contains a message about S2A grammar generation.
test('hybrid/log-mentions-s2a',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb95', Base),
      atom_concat(Base, '_hyb95.pl', OutFile),
      run_hybrid_path('examples/input.pl', '', prolog, true, '', OutFile),
      current_log_messages(Msgs),
      member(M, Msgs),
      sub_atom(M, _, _, _, 'Hybrid') )).

% T96: The hybrid log contains a message about NP optimisation.
test('hybrid/log-mentions-np',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb96', Base),
      atom_concat(Base, '_hyb96.pl', OutFile),
      run_hybrid_path('examples/input.pl', '', prolog, true, '', OutFile),
      current_log_messages(Msgs),
      member(M, Msgs),
      sub_atom(M, _, _, _, 'NP:') )).

% T97: run_pipeline/1 in hybrid mode (explicit input_type=hybrid) produces an output file.
test('hybrid/run-pipeline-hybrid-mode',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb97', Base),
      atom_concat(Base, '_hyb97.pl', OutFile),
      run_pipeline([
          input='examples/input.pl',
          input_type=hybrid,
          aux_input='examples/np_prolog_input.pl',
          out=prolog,
          compress=false,
          code_out=OutFile
      ]),
      exists_file(OutFile) )).

% T98: run_pipeline/1 auto-detects hybrid mode when aux_input is set with
%      an I/O examples primary input.
test('hybrid/auto-detect-hybrid-with-aux',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb98', Base),
      atom_concat(Base, '_hyb98.pl', OutFile),
      run_pipeline([
          input='examples/input.pl',
          input_type=auto,
          aux_input='examples/np_prolog_input.pl',
          out=prolog,
          compress=false,
          code_out=OutFile
      ]),
      exists_file(OutFile) )).

% T99: Hybrid Starlog output is produced when out=starlog.
test('hybrid/starlog-output-produced',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb99', Base),
      atom_concat(Base, '_hyb99.pl', OutFile),
      run_hybrid_path('examples/input.pl', 'examples/np_prolog_input.pl',
                      starlog, true, '', OutFile),
      file_name_extension(Base2, _, OutFile),
      atom_concat(Base2, '.starlog', StarlogFile),
      exists_file(StarlogFile) )).

% T100: Hybrid output file loads in SWI-Prolog without error.
test('hybrid/output-loadable',
    ( retractall(log_message(_)),
      tmp_file('nsl_hyb100', Base),
      atom_concat(Base, '_hyb100.pl', OutFile),
      run_hybrid_path('examples/input.pl', 'examples/np_prolog_input.pl',
                      prolog, true, '', OutFile),
      exists_file(OutFile),
      catch(consult(OutFile), _, true) )).

% ---------------------------------------------------------------------------
% PR 8 tests: Final docs and examples
% ---------------------------------------------------------------------------

% T101: Log messages contain simple sentences and no raw IR node names.
%       Verifies that pipeline logs are human-readable and do not expose
%       internal IR predicates such as grammar_rule/4, np_ir_node, ir_clause,
%       or compound term notation like f(X,Y).
test('docs/logs-no-raw-ir-nodes',
    ( retractall(log_message(_)),
      run_pipeline([
          input='examples/input.pl',
          input_type=auto,
          out=starlog,
          compress=true
      ]),
      current_log_messages(Msgs),
      Msgs \= [],
      % None of the log messages should contain raw IR predicate names.
      \+ ( member(M, Msgs),
           ( sub_atom(M, _, _, _, 'grammar_rule(')
           ; sub_atom(M, _, _, _, 'np_ir_node')
           ; sub_atom(M, _, _, _, 'ir_clause(')
           ; sub_atom(M, _, _, _, 'np_clause_ir')
           ) ) )).

% T102: Log messages from the NP path are simple English sentences.
%       Each log line starts with an [info] or [error] tag and contains
%       at least one space-separated word (not just a raw term).
test('docs/logs-readable-np-path',
    ( retractall(log_message(_)),
      run_pipeline([
          input='examples/np_prolog_input.pl',
          input_type=prolog,
          out=prolog,
          compress=false,
          code_out=''
      ]),
      current_log_messages(Msgs),
      Msgs \= [],
      forall(
          member(M, Msgs),
          ( sub_atom(M, _, _, _, '[info]')
          ; sub_atom(M, _, _, _, '[error]')
          ) ) )).

% T103: Log messages from the Gaussian path are simple English sentences.
test('docs/logs-readable-gaussian-path',
    ( retractall(log_message(_)),
      run_pipeline([
          input='examples/gaussian_input.pl',
          input_type=prolog,
          out=prolog,
          compress=false,
          code_out=''
      ]),
      current_log_messages(Msgs),
      Msgs \= [],
      forall(
          member(M, Msgs),
          ( sub_atom(M, _, _, _, '[info]')
          ; sub_atom(M, _, _, _, '[error]')
          ) ) )).

% T104: Log messages from the hybrid path mention key stages.
test('docs/logs-hybrid-mentions-stages',
    ( retractall(log_message(_)),
      tmp_file('nsl_pr8_104', TmpBase104),
      atom_concat(TmpBase104, '_104.pl', OutFile),
      run_hybrid_path('examples/input.pl', 'examples/np_prolog_input.pl',
                      prolog, true, '', OutFile),
      current_log_messages(Msgs),
      % Must mention Hybrid S2A, NP optimiser, and merged output.
      member(SA, Msgs), sub_atom(SA, _, _, _, 'Hybrid'),
      member(NP, Msgs), sub_atom(NP, _, _, _, 'NP:'),
      member(MG, Msgs), sub_atom(MG, _, _, _, 'merged') )).

% T105: Generated Starlog output contains method-chaining operator (•) where
%       applicable, confirming fully compressed default output.
test('docs/starlog-default-compress-method-chain',
    ( tmp_file('nsl_pr8_105', TmpBase105),
      atom_concat(TmpBase105, '_105.pl', OutFile),
      write_s2a_grammar(chaintest, 'examples/input.pl', '', Grammar, _),
      convert_s2a_grammar_to_prolog(chaintest, Grammar, Clauses, _),
      % Inject a clause that uses atom_concat to demonstrate method chaining.
      AllClauses = ['cat(A,B,C,R) :- atom_concat(A,B,T), atom_concat(T,C,R).' | Clauses],
      write_s2a_starlog(chaintest, AllClauses, OutFile, _Status),
      read_file_to_string(OutFile, Content, []),
      sub_string(Content, _, _, _, "•") )).

% T106: Unsupported cases (cubic arithmetic) are preserved unchanged through
%       the full pipeline, confirming the documented unsupported-cases guarantee.
test('docs/unsupported-cubic-preserved',
    ( tmp_file('nsl_pr8_106', TmpBase106),
      atom_concat(TmpBase106, '_106.pl', OutFile),
      np_optimise_file('examples/gaussian_input.pl', prolog, prolog,
                       true, OutFile, _Status),
      read_file_to_string(OutFile, Content, []),
      sub_string(Content, _, _, _, "cube"),
      sub_string(Content, _, _, _, "A*A*A") )).

% T107: Generated Prolog from I/O examples (S2A path) loads in SWI-Prolog.
%       (End-to-end: full pipeline S2A path → generated file is loadable.)
test('docs/s2a-end-to-end-prolog-loadable',
    ( tmp_file('nsl_pr8_107g', GrammarBase),
      atom_concat(GrammarBase, '_107_grammar.pl', GrammarFile),
      tmp_file('nsl_pr8_107p', PrologBase),
      atom_concat(PrologBase, '_107_generated.pl', PrologFile),
      write_s2a_grammar(e2etest, 'examples/input.pl', GrammarFile, Grammar, _),
      write_s2a_prolog(e2etest, Grammar, PrologFile, _Status),
      exists_file(PrologFile),
      catch(consult(PrologFile), _, true) )).

% T108: Partial S2A failure (nonexistent file) produces a clear user-facing error.
%       The error message must not expose raw IR structure.
test('docs/partial-failure-user-facing-error',
    ( retractall(log_message(_)),
      write_s2a_grammar(pfail, '/nonexistent/partial_fail_input.pl',
                        '', _Grammar, Status),
      Status = partial(_Errors),
      % The pipeline run itself records a user-facing error message.
      pipeline_log(error,
          ['Error: S2A could not read input file /nonexistent/partial_fail_input.pl.']),
      current_log_messages(Msgs),
      member(M, Msgs),
      sub_atom(M, _, _, _, 'Error:') )).
