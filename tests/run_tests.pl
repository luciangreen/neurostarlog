% run_tests.pl
% Master test runner for NeuroStarlog.
%
% Run with:
%   swipl -q -g "consult('tests/run_tests')" -g "run_all_tests" -t halt

:- include('neurostarlog_tests.pl').

run_all_tests :-
    run_tests.
