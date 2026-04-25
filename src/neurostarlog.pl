% neurostarlog.pl
% CLI entry point for NeuroStarlog.
%
% Usage:
%   swipl -q -s src/neurostarlog.pl -- \
%     --input examples/input.pl \
%     --input-type auto \
%     --out starlog \
%     --compress true \
%     --grammar-out out/grammar.pl \
%     --code-out out/result.starlog \
%     --log-out out/pipeline_log.txt
%
% PR 1: Integration skeleton — CLI entry point.

:- include('neurostarlog_pipeline.pl').

%% main/0 — called via -g main or at program start

main :-
    current_prolog_flag(argv, Args),
    ( parse_cli(Args, Options) ->
        run_pipeline(Options)
    ;
        print_usage,
        halt(1)
    ).

:- initialization(main, main).
