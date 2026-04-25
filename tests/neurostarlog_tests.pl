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
