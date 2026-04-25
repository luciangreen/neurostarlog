% neurostarlog_pipeline.pl
% Main pipeline for NeuroStarlog.
% PR 1: Integration skeleton — input-type detection and basic pipeline log.
% PR 2: S2A grammar output — grammar writer integrated into S2A path.

:- include('s2a_grammar_writer.pl').

%% detect_input_type(+File, -Type)
%
% Classify the input file as prolog, starlog, or io_examples.
% Detection rules:
%   - If the file contains a term matching [_,_] list pairs it is io_examples.
%   - If any line contains a Starlog operator (is, •, &, :) it is starlog.
%   - Otherwise it is prolog.

detect_input_type(File, Type) :-
    ( \+ exists_file(File) ->
        pipeline_log(error, ['Input file not found: ', File]),
        Type = unknown
    ;
        read_file_to_string(File, Content, []),
        ( string_contains_io_examples(Content) ->
            Type = io_examples
        ; string_contains_starlog(Content) ->
            Type = starlog
        ;
            Type = prolog
        )
    ).

string_contains_io_examples(Content) :-
    split_string(Content, "\n", " \t", Lines),
    member(Line, Lines),
    string_concat("[", _, Line),
    !.

% Starlog is identified by its unique operators not present in plain Prolog:
%   • (atom_concat shorthand) is the most reliable marker.

string_contains_starlog(Content) :-
    sub_string(Content, _, _, _, "•"),
    !.

%% run_pipeline(+Options)
%
% Execute the NeuroStarlog pipeline according to the given option list.
% Options is a list of Key=Value pairs:
%   input=File, input_type=auto|prolog|starlog|io,
%   out=starlog|prolog, compress=true|false,
%   grammar_out=File, code_out=File, log_out=File, strict=true|false

run_pipeline(Options) :-
    pipeline_log(info, ['NeuroStarlog pipeline starting.']),

    option(input=InputFile,    Options, ''),
    option(input_type=InputTypeOpt, Options, auto),
    option(out=OutMode,        Options, starlog),
    option(compress=Compress,  Options, true),
    option(grammar_out=GrammarOut, Options, ''),
    option(code_out=CodeOut,   Options, ''),
    option(log_out=LogOut,     Options, ''),

    % Resolve input type
    ( InputTypeOpt = auto ->
        detect_input_type(InputFile, InputType)
    ;
        InputType = InputTypeOpt
    ),
    pipeline_log(info, ['Input type detected: ', InputType]),

    % Dispatch to appropriate path
    ( InputType = io_examples ->
        pipeline_log(info, ['Using S2A path for I/O examples.']),
        run_s2a_path(InputFile, OutMode, Compress, GrammarOut, CodeOut)
    ; (InputType = prolog ; InputType = starlog) ->
        pipeline_log(info, ['Using NP/NSL path for source input.']),
        run_np_path(InputFile, InputType, OutMode, Compress, CodeOut)
    ;
        pipeline_log(error, ['Unknown input type. Pipeline aborted.'])
    ),

    % Write log file if requested
    ( LogOut \= '' ->
        write_log_file(LogOut)
    ; true ),

    pipeline_log(info, ['NeuroStarlog pipeline complete.']).

%% run_s2a_path(+InputFile, +OutMode, +Compress, +GrammarOut, +CodeOut)
%
% PR 2: Read I/O examples, detect patterns, and write grammar to file.

run_s2a_path(InputFile, _OutMode, _Compress, GrammarOut, _CodeOut) :-
    pipeline_log(info, ['S2A: reading I/O examples from ', InputFile, '.']),

    % Derive a predicate name from the input file base name.
    file_base_name(InputFile, BaseName),
    file_name_extension(PredName, _, BaseName),

    % Determine grammar output file path.
    ( GrammarOut \= '' ->
        GrammarFile = GrammarOut
    ;
        atom_concat('out/', PredName, Prefix),
        atom_concat(Prefix, '_grammar.pl', GrammarFile)
    ),

    % Generate and write grammar.
    write_s2a_grammar(PredName, InputFile, GrammarFile, _Grammar, Status),

    % Log outcome.
    ( Status = ok ->
        pipeline_log(info, ['S2A: detected repeated pattern in input.']),
        pipeline_log(info, ['S2A: generated grammar and wrote it to ', GrammarFile, '.'])
    ;
        Status = partial(Errors),
        pipeline_log(info, ['S2A: partial grammar written to ', GrammarFile, '.']),
        forall(
            member(error(Type, Detail), Errors),
            ( format(atom(Msg), '~w: ~w', [Type, Detail]),
              pipeline_log(error, ['S2A grammar error — ', Msg]) )
        )
    ).

%% run_np_path(+InputFile, +InputType, +OutMode, +Compress, +CodeOut)
%
% Placeholder NP/NSL path (PR 5 will implement full NP pipeline).

run_np_path(InputFile, InputType, _OutMode, _Compress, _CodeOut) :-
    pipeline_log(info, ['NP: reading ', InputType, ' source from ', InputFile, '.']),
    pipeline_log(info, ['NP: optimisation pipeline not yet implemented (PR 5).']).

%% write_log_file(+File)

write_log_file(File) :-
    current_log_messages(Messages),
    atomic_list_concat(Messages, '\n', Content),
    ( catch(
        ( open(File, write, Stream),
          write(Stream, Content),
          close(Stream) ),
        Err,
        pipeline_log(error, ['Could not write log file: ', File, ' — ', Err])
      ) -> true ; true ).

%% option(+KeyValue, +Options, +Default)

option(Key=Default, Options, Default) :-
    \+ member(Key=_, Options), !.
option(Key=Value, Options, _Default) :-
    member(Key=Value, Options), !.

% Simple in-memory log (accumulated as Prolog facts during a run).

:- dynamic log_message/1.

current_log_messages(Messages) :-
    findall(M, log_message(M), Messages).

pipeline_log(Level, Parts) :-
    atomic_list_concat(Parts, '', Message),
    format(atom(Line), '[~w] ~w', [Level, Message]),
    assertz(log_message(Line)),
    writeln(Line).

%% parse_cli(+Args, -Options)
%
% Convert a flat list of --key value tokens into Key=Value pairs.
% Supported flags:
%   --input FILE
%   --input-type auto|prolog|starlog|io
%   --out starlog|prolog
%   --compress true|false
%   --grammar-out FILE
%   --code-out FILE
%   --log-out FILE
%   --strict true|false

parse_cli(Args, Options) :-
    parse_cli_tokens(Args, Options).

parse_cli_tokens([], []).
parse_cli_tokens(['--input', V | Rest], [input=V | Opts]) :-
    !, parse_cli_tokens(Rest, Opts).
parse_cli_tokens(['--input-type', V | Rest], [input_type=V | Opts]) :-
    !, parse_cli_tokens(Rest, Opts).
parse_cli_tokens(['--out', V | Rest], [out=V | Opts]) :-
    !, parse_cli_tokens(Rest, Opts).
parse_cli_tokens(['--compress', V | Rest], [compress=V | Opts]) :-
    !, parse_cli_tokens(Rest, Opts).
parse_cli_tokens(['--grammar-out', V | Rest], [grammar_out=V | Opts]) :-
    !, parse_cli_tokens(Rest, Opts).
parse_cli_tokens(['--code-out', V | Rest], [code_out=V | Opts]) :-
    !, parse_cli_tokens(Rest, Opts).
parse_cli_tokens(['--log-out', V | Rest], [log_out=V | Opts]) :-
    !, parse_cli_tokens(Rest, Opts).
parse_cli_tokens(['--strict', V | Rest], [strict=V | Opts]) :-
    !, parse_cli_tokens(Rest, Opts).
parse_cli_tokens([Unknown | Rest], Opts) :-
    format(atom(Msg), 'Warning: unknown CLI flag ignored: ~w', [Unknown]),
    writeln(Msg),
    parse_cli_tokens(Rest, Opts).

%% print_usage/0

print_usage :-
    writeln('Usage: swipl -q -s src/neurostarlog.pl -- [options]'),
    writeln(''),
    writeln('Options:'),
    writeln('  --input FILE           Input file (Prolog, Starlog, or I/O examples)'),
    writeln('  --input-type TYPE      auto (default) | prolog | starlog | io'),
    writeln('  --out FORMAT           starlog (default) | prolog'),
    writeln('  --compress BOOL        true (default) | false'),
    writeln('  --grammar-out FILE     Write generated grammar to FILE'),
    writeln('  --code-out FILE        Write generated code to FILE'),
    writeln('  --log-out FILE         Write pipeline log to FILE'),
    writeln('  --strict BOOL          true (default) | false').
