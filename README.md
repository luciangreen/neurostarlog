# NeuroStarlog

Combines the optimisation semantics of NeuroProlog, the syntactical efficiency of Starlog and the algorithm generator Spec to Algorithm.

## Overview

NeuroStarlog is a generator/optimiser that accepts Prolog, Starlog, or I/O examples and outputs runnable SWI-Prolog-compatible Prolog or fully compressed Starlog.

It combines:

* **S2A** for I/O-driven algorithm reconstruction.
* **NeuroProlog** for correctness-preserving optimisation.
* **Starlog** for compressed final syntax and method-chain/nested-call output.

## Supported input types

| Input | Description |
|-------|-------------|
| `--input-type prolog` | SWI-Prolog source file |
| `--input-type starlog` | Starlog source file |
| `--input-type io` | List of `[Input, Output]` I/O example pairs |
| `--input-type auto` | Auto-detect (default) |

## Supported output modes

| Flag | Default | Description |
|------|---------|-------------|
| `--out starlog` | ✓ | Fully compressed Starlog |
| `--out prolog` | | SWI-Prolog-compatible Prolog |
| `--compress true` | ✓ | Enable Starlog compression |
| `--compress false` | | Disable compression |

## Running

```sh
swipl -q -s src/neurostarlog.pl -- \
  --input examples/input.pl \
  --input-type auto \
  --out starlog \
  --compress true \
  --grammar-out out/grammar.pl \
  --code-out out/result.starlog \
  --log-out out/pipeline_log.txt
```

## Testing

```sh
swipl -q -s tests/neurostarlog_tests.pl -g run_tests -t halt
```

or

```sh
swipl -q -g "consult('tests/run_tests')" -g "run_all_tests" -t halt
```

## What is supported (current PR)

* CLI flag parsing (`--input`, `--input-type`, `--out`, `--compress`, `--grammar-out`, `--code-out`, `--log-out`, `--strict`)
* Input-type auto-detection (prolog / starlog / io\_examples)
* Pipeline skeleton with simple log output
* S2A I/O-example path: grammar generation, Prolog output, Starlog output
* Test infrastructure (45 tests across PRs 1–4)

### PR 4 — Prolog → Starlog output

The S2A path now produces a `.starlog` file alongside the `.pl` file when `--out starlog` is used (the default).

**Conversion rules applied:**

| Prolog predicate | Starlog form |
|------------------|-------------|
| `append(A,B,C)` | `C is A&B` |
| `atom_concat(A,B,C)` | `C is A•B` |
| `string_concat(A,B,C)` | `C is A:B` |

**Method chaining:** consecutive `is`-goals sharing an intermediate variable are inlined automatically. For example:

```prolog
% Prolog input:
cat3(A,B,C,R) :- atom_concat(A,B,T), atom_concat(T,C,R).

% Starlog output (method-chained):
cat3(A,B,C,R) :-
    R is A•B•C.
```

**Roundtrip:** `starlog_to_prolog/2` reverses the conversion back to standard Prolog, enabling roundtrip verification.

**Output file:** `out/<predicate>_generated.starlog`

### Example output files

Given `examples/input.pl` containing I/O examples, the pipeline writes:

* `out/input_grammar.pl` — generated grammar rules
* `out/input_generated.pl` — generated Prolog predicates
* `out/input_generated.starlog` — fully compressed Starlog (PR 4)

## What remains unchanged / not yet implemented

* NeuroProlog full optimisation pipeline (PR 5)
* Gaussian elimination / index optimisation (PR 6)
* Hybrid S2A + NP mode (PR 7)

Irreducible commands (I/O, random, external state, unsupported predicates) are always preserved unchanged.

## Notes

* Default output is fully compressed Starlog.
* Natural-language spec input is not supported in v1.
* Approximate optimisation is intentionally excluded.
