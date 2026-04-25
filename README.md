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
* S2A and NP/NSL path stubs (grammar generation and optimisation added in later PRs)
* Test infrastructure

## What remains unchanged / not yet implemented

* S2A grammar generation (PR 2)
* S2A → Prolog converter (PR 3)
* Prolog → Starlog output (PR 4)
* NeuroProlog full optimisation pipeline (PR 5)
* Gaussian elimination / index optimisation (PR 6)
* Hybrid S2A + NP mode (PR 7)

Irreducible commands (I/O, random, external state, unsupported predicates) are always preserved unchanged.

## Notes

* Default output is fully compressed Starlog.
* Natural-language spec input is not supported in v1.
* Approximate optimisation is intentionally excluded.
