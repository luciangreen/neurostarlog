% neurostarlog_pipeline.pl
% Main pipeline for NeuroStarlog.
% PR 1: Integration skeleton — input-type detection and basic pipeline log.
% PR 2: S2A grammar output — grammar writer integrated into S2A path.
% PR 3: S2A → Prolog converter — grammar converted to runnable Prolog predicates.
% PR 4: S2A → Starlog converter — generated Prolog optionally converted to Starlog.
% PR 5: NP full-pipeline integration — correctness-preserving optimiser with plateau stopping.
% PR 7: Hybrid mode — S2A reconstruction + NP optimisation + preserved auxiliary clauses.

:- include('s2a_grammar_writer.pl').
:- include('s2a_to_prolog_converter.pl').
:- include('s2a_to_starlog_converter.pl').
:- include('gaussian_optimiser.pl').
:- include('np_optimiser.pl').

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
%   input=File, input_type=auto|prolog|starlog|io|hybrid,
%   aux_input=File (auxiliary Prolog for hybrid mode),
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
    option(aux_input=AuxInput, Options, ''),

    % Resolve input type
    ( InputTypeOpt = auto ->
        detect_input_type(InputFile, DetectedType),
        % If an auxiliary input is also supplied, promote to hybrid.
        ( AuxInput \= '' , DetectedType = io_examples ->
            InputType = hybrid
        ;
            InputType = DetectedType
        )
    ;
        InputType = InputTypeOpt
    ),
    pipeline_log(info, ['Input type detected: ', InputType]),

    % Dispatch to appropriate path
    ( InputType = hybrid ->
        pipeline_log(info, ['Using hybrid S2A+NP path.']),
        run_hybrid_path(InputFile, AuxInput, OutMode, Compress, GrammarOut, CodeOut)
    ; InputType = io_examples ->
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
% PR 3: Convert generated grammar to runnable Prolog predicates.
% PR 4: Optionally convert generated Prolog predicates to Starlog.

run_s2a_path(InputFile, OutMode, _Compress, GrammarOut, CodeOut) :-
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
    write_s2a_grammar(PredName, InputFile, GrammarFile, Grammar, GrammarStatus),

    % Log grammar outcome.
    ( GrammarStatus = ok ->
        pipeline_log(info, ['S2A: grammar generation completed successfully.']),
        pipeline_log(info, ['S2A: generated grammar and wrote it to ', GrammarFile, '.'])
    ;
        GrammarStatus = partial(GrammarErrors),
        pipeline_log(info, ['S2A: partial grammar written to ', GrammarFile, '.']),
        forall(
            member(error(GType, GDetail), GrammarErrors),
            ( format(atom(GMsg), '~w: ~w', [GType, GDetail]),
              pipeline_log(error, ['S2A grammar error — ', GMsg]) )
        )
    ),

    % PR 3: Convert grammar to runnable Prolog predicates.
    ( CodeOut \= '' ->
        PrologFile = CodeOut
    ;
        atom_concat('out/', PredName, PrologPrefix),
        atom_concat(PrologPrefix, '_generated.pl', PrologFile)
    ),
    write_s2a_prolog(PredName, Grammar, PrologFile, PrologStatus),

    % Log Prolog conversion outcome.
    ( PrologStatus = ok ->
        pipeline_log(info, ['S2A: Prolog conversion completed successfully.']),
        pipeline_log(info, ['S2A: generated Prolog and wrote it to ', PrologFile, '.'])
    ;
        PrologStatus = partial(PrologErrors),
        pipeline_log(info, ['S2A: partial Prolog written to ', PrologFile, '.']),
        forall(
            member(error(PType, PDetail), PrologErrors),
            ( format(atom(PMsg), '~w: ~w', [PType, PDetail]),
              pipeline_log(error, ['S2A Prolog error — ', PMsg]) )
        )
    ),

    % PR 4: If output mode is starlog, also convert the Prolog clauses to Starlog.
    ( OutMode = starlog ->
        ( CodeOut \= '' ->
            % Derive a .starlog filename from CodeOut by replacing extension.
            file_name_extension(CodeOutBase, _, CodeOut),
            atom_concat(CodeOutBase, '.starlog', StarlogFile)
        ;
            atom_concat('out/', PredName, StarlogPrefix),
            atom_concat(StarlogPrefix, '_generated.starlog', StarlogFile)
        ),
        convert_s2a_grammar_to_prolog(PredName, Grammar, ClauseTexts, _),
        write_s2a_starlog(PredName, ClauseTexts, StarlogFile, StarlogStatus),
        ( StarlogStatus = ok ->
            pipeline_log(info, ['S2A: Starlog conversion completed successfully.']),
            pipeline_log(info, ['S2A: generated Starlog and wrote it to ', StarlogFile, '.'])
        ;
            StarlogStatus = partial(StarlogErrors),
            pipeline_log(info, ['S2A: partial Starlog written to ', StarlogFile, '.']),
            forall(
                member(error(SType, SDetail), StarlogErrors),
                ( format(atom(SMsg), '~w: ~w', [SType, SDetail]),
                  pipeline_log(error, ['S2A Starlog error — ', SMsg]) )
            )
        )
    ; true ).

%% run_np_path(+InputFile, +InputType, +OutMode, +Compress, +CodeOut)
%
% PR 5: Full NP optimiser pipeline.
% Reads Prolog/Starlog source, applies correctness-preserving optimisations
% with plateau stopping, and writes the result.

run_np_path(InputFile, InputType, OutMode, Compress, CodeOut) :-
    pipeline_log(info,
        ['NP: reading ', InputType, ' source from ', InputFile, '.']),
    % Resolve code output file when not specified.
    ( CodeOut \= '' ->
        OutFile = CodeOut
    ;
        file_base_name(InputFile, BaseName),
        file_name_extension(PredName, _, BaseName),
        atom_concat('out/', PredName, OutPrefix),
        atom_concat(OutPrefix, '_np_optimised.pl', OutFile)
    ),
    np_optimise_file(InputFile, InputType, OutMode, Compress, OutFile, Status),
    ( Status = ok ->
        pipeline_log(info, ['NP: optimisation completed successfully.'])
    ;
        Status = partial(Errors),
        pipeline_log(info, ['NP: optimisation completed with errors.']),
        forall(
            member(error(EType, EDetail), Errors),
            ( format(atom(EMsg), '~w: ~w', [EType, EDetail]),
              pipeline_log(error, ['NP error — ', EMsg]) )
        )
    ).

%% run_hybrid_path(+IOFile, +AuxFile, +OutMode, +Compress, +GrammarOut, +CodeOut)
%
% PR 7: Hybrid mode.
% Reconstructs an algorithm from I/O examples using S2A, then applies the NP
% optimiser to the reconstructed clauses.  Any predicates in AuxFile are loaded
% unchanged and appended to the output, preserving unoptimisable sections.
%
% Steps:
%   1. Run S2A grammar generation on IOFile.
%   2. Convert grammar to runnable Prolog (written to a temp file).
%   3. Load the temp Prolog file as clause terms.
%   4. Apply NP plateau optimiser to the S2A-generated clauses.
%   5. Load AuxFile clauses unchanged (if AuxFile is non-empty and exists).
%   6. Merge optimised S2A clauses with preserved auxiliary clauses.
%   7. Write merged output.

run_hybrid_path(IOFile, AuxFile, OutMode, _Compress, GrammarOut, CodeOut) :-
    pipeline_log(info, ['Hybrid: running S2A on I/O examples from ', IOFile, '.']),

    % Derive predicate name from the IO examples file.
    file_base_name(IOFile, BaseName),
    file_name_extension(PredName, _, BaseName),

    % Grammar output path.
    ( GrammarOut \= '' ->
        GrammarFile = GrammarOut
    ;
        atom_concat('out/', PredName, GP),
        atom_concat(GP, '_grammar.pl', GrammarFile)
    ),

    % Step 1: S2A grammar generation.
    write_s2a_grammar(PredName, IOFile, GrammarFile, Grammar, GrammarStatus),
    ( GrammarStatus = ok ->
        pipeline_log(info, ['Hybrid: S2A grammar generated and wrote to ', GrammarFile, '.'])
    ;
        pipeline_log(info, ['Hybrid: S2A grammar partially generated.'])
    ),

    % Step 2: Convert grammar to Prolog, write to a temporary file.
    tmp_file('hybrid_s2a', TmpBase),
    atom_concat(TmpBase, '.pl', TmpPrologFile),
    write_s2a_prolog(PredName, Grammar, TmpPrologFile, _PrologStatus),

    % Step 3: Load S2A-generated Prolog as clause terms.
    ( exists_file(TmpPrologFile) ->
        np_load_clauses(TmpPrologFile, S2AClauses, S2ALoadErrors)
    ;
        S2AClauses = [],
        S2ALoadErrors = [error(hybrid_s2a_load, 'No S2A Prolog file generated.')]
    ),
    ( S2ALoadErrors \= [] ->
        pipeline_log(info, ['Hybrid: S2A clause loading encountered issues.'])
    ; true ),

    % Step 4: Apply NP plateau optimiser to S2A-generated clauses.
    pipeline_log(info, ['Hybrid: applying NP optimiser to S2A-generated clauses.']),
    np_plateau_optimise(S2AClauses, OptimisedS2A, 100, OptLog),
    forall(member(LM, OptLog), pipeline_log(info, [LM])),

    % Step 5: Load auxiliary Prolog predicates unchanged.
    ( AuxFile \= '' ->
        ( exists_file(AuxFile) ->
            np_load_clauses(AuxFile, AuxClauses, _AuxErrors),
            pipeline_log(info,
                ['Hybrid: loaded auxiliary Prolog from ', AuxFile, ' (preserved unchanged).'])
        ;
            AuxClauses = [],
            pipeline_log(info,
                ['Hybrid: auxiliary file not found, skipping: ', AuxFile])
        )
    ;
        AuxClauses = []
    ),

    % Step 6: Merge optimised S2A clauses + unchanged auxiliary clauses.
    append(OptimisedS2A, AuxClauses, AllClauses),
    pipeline_log(info, ['Hybrid: merged S2A-optimised and auxiliary sections.']),

    % Step 7: Resolve output file path.
    ( CodeOut \= '' ->
        OutFile = CodeOut
    ;
        atom_concat('out/', PredName, OP),
        atom_concat(OP, '_hybrid.pl', OutFile)
    ),

    % Step 8: Write merged output.
    np_write_output(OutMode, AllClauses, OutFile, WriteErrors),
    ( WriteErrors = [] ->
        pipeline_log(info, ['Hybrid: output written to ', OutFile, '.'])
    ;
        pipeline_log(info, ['Hybrid: output writing encountered issues.'])
    ).

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
parse_cli_tokens(['--input-aux', V | Rest], [aux_input=V | Opts]) :-
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
    writeln('  --input-type TYPE      auto (default) | prolog | starlog | io | hybrid'),
    writeln('  --input-aux FILE       Auxiliary Prolog file for hybrid mode (preserved unchanged)'),
    writeln('  --out FORMAT           starlog (default) | prolog'),
    writeln('  --compress BOOL        true (default) | false'),
    writeln('  --grammar-out FILE     Write generated grammar to FILE'),
    writeln('  --code-out FILE        Write generated code to FILE'),
    writeln('  --log-out FILE         Write pipeline log to FILE'),
    writeln('  --strict BOOL          true (default) | false').
