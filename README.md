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
| `--input-type hybrid` | I/O examples + auxiliary Prolog (see `--input-aux`) |
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

## Choosing Prolog vs Starlog output

Use `--out prolog` when:
- you need output that loads directly into SWI-Prolog without any additional tools,
- you are integrating with existing Prolog toolchains, or
- you prefer verbose, explicit predicate syntax.

Use `--out starlog` (the default) when:
- you want fully compressed output with method chaining (`•`, `&`, `:`),
- you are targeting the Starlog runtime, or
- you want the most concise representation of your algorithm.

Starlog output is always generated alongside the Prolog output file (with a `.starlog` extension) when `--out starlog` is active.

## Testing

```sh
swipl -q -s tests/neurostarlog_tests.pl -g run_tests -t halt
```

or

```sh
swipl -q -g "consult('tests/run_tests')" -g "run_all_tests" -t halt
```

## What is supported

### PR 1 — Integration skeleton

* CLI flag parsing (`--input`, `--input-type`, `--out`, `--compress`, `--grammar-out`, `--code-out`, `--log-out`, `--strict`, `--input-aux`)
* Input-type auto-detection (prolog / starlog / io\_examples)
* Pipeline skeleton with simple log output

### PR 2 — S2A grammar output

* I/O example ingestion from `[Input, Output]` list pairs
* Repeated-structure detection (`[r, X]`) and non-deterministic detection (`[nd, X]`)
* Grammar rules written to `out/<predicate>_grammar.pl`
* Partial grammar on failure: saves what was generated and reports errors clearly

### PR 3 — S2A → Prolog converter

* Grammar rules converted to runnable SWI-Prolog predicates
* Base case: `P([], _Out).`
* Recursive case: `P([_X|T], Out) :- P(T, Out).`
* Repeated-structure and non-deterministic rules each generate appropriate clauses
* Unresolved sections marked with `% UNRESOLVED` comments
* Partial Prolog on failure with clear error reporting

### PR 4 — Prolog → Starlog output

The S2A path produces a `.starlog` file alongside the `.pl` file when `--out starlog` is used (the default).

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

### PR 5 — NP full-pipeline integration

* Full NeuroProlog optimisation pipeline for Prolog and Starlog source
* Redundant `true/0` goals are removed
* Deterministic single-clause helpers are unfolded into callers
* Plateau stopping: optimisation halts when no further change is detected
* Irreducible goals (I/O, random, external state) are preserved unchanged

### PR 6 — Gaussian / index optimisation

* Trace-based pattern detection: variable correspondence is identified before Gaussian elimination runs
* Gaussian elimination applied to numeric linear and polynomial recurrences
* `linear/2` recurrence replaced with a single closed-form clause
* `tri/2` triangular-number recurrence replaced with a polynomial formula
* Non-recurrence predicates (e.g. `cube/2`) are left unchanged
* Coefficients are never guessed; Gaussian elimination is the universal polynomial solver

### PR 7 — Hybrid mode

* Combines S2A I/O reconstruction with NP optimisation in a single pipeline
* Activate with `--input-type hybrid` or by supplying `--input-aux FILE` alongside an I/O examples primary input
* S2A reconstructs the algorithm from examples
* NP optimiser improves the reconstructed clauses
* Auxiliary Prolog predicates (`--input-aux`) are appended unchanged to the output

### Example output files

Given `examples/input.pl` containing I/O examples, the pipeline writes:

* `out/input_grammar.pl` — generated grammar rules
* `out/input_generated.pl` — generated Prolog predicates
* `out/input_generated.starlog` — fully compressed Starlog
* `out/input_log.txt` — pipeline log (when `--log-out` is specified)

## What remains unchanged / unsupported

Irreducible commands are always preserved as-is and are never modified:

* **I/O predicates** — `write/1`, `writeln/1`, `read/1`, `nl/0`, and all standard I/O.
* **Random predicates** — `random/1`, `random_between/3`, and similar.
* **External state** — any predicate that reads or writes global state, asserts, or retracts.
* **Unsupported arithmetic** — expressions that are not recognisable polynomial recurrences (e.g. `cube(X, Y) :- Y is X * X * X`).
* **Unsupported predicates** — any predicate not covered by the optimisation rules.

**Not implemented in v1:**

* Natural-language spec input — documented as a future extension.
* Approximate optimisation — intentionally excluded; v1 is strict correctness-only.
* Safety/security critical tagging — intentionally hidden from user-facing output.

## Pipeline logs

Logs use simple English sentences, for example:

```
[info] S2A: detected repeated pattern in input.
[info] S2A: generated grammar and wrote it to out/example_grammar.pl.
[info] NP: applied Gaussian elimination → derived polynomial closed form.
[info] NP: linear/2 replaced with polynomial closed form.
[info] Final: preserved read_string/2 unchanged.
```

Errors include a short user-facing message:

```
[error] Error: S2A could only generate a partial algorithm.
```

Log files are written to the path supplied via `--log-out`.

## Partial failure

When S2A cannot fully reconstruct an algorithm, it:

1. Writes whatever grammar it could produce to `out/<predicate>_grammar.pl`.
2. Writes a partial Prolog file with `% UNRESOLVED` comments for unresolved sections.
3. Reports a clear error with detail.

Example error message:

```
Error: S2A could only generate a partial algorithm.
Detail: unresolved non-deterministic branch did not map to a unique output predicate.
Partial files were written to out/.
```

## Feature completion

Starlog input detection and routing is 90% complete. Full native Starlog optimisation (Starlog-specific operator rewriting) is partial; the NP path treats Starlog source as Prolog for most optimisations.

| Feature | Target completion |
|---------|-------------------|
| NeuroStarlog CLI wrapper | 100% |
| Input-type detection | 100% |
| Prolog input path | 100% |
| Starlog input path | 90% |
| I/O example input path | 90% |
| S2A grammar generation | 90% |
| Separate grammar file output | 100% |
| S2A → Prolog converter | 80% |
| Prolog → Starlog converter integration | 90% |
| Fully compressed Starlog default | 90% |
| Unified hidden IR integration | 80% |
| Full NeuroProlog pipeline integration | 75% |
| Trace-based pattern detection | 75% |
| Gaussian recurrence optimisation | 80% |
| Gaussian index transformation optimisation | 70% |
| General symbolic algebra optimisation | 50% |
| Hybrid S2A + NP mode | 75% |
| Irreducible command preservation | 85% |
| Partial S2A failure with partial code | 85% |
| Simple pipeline logs | 100% |
| User-facing error + developer detail | 90% |
| SWI-Prolog runnable output | 90% |
| Starlog compressed runnable output | 80% |
| Test suite coverage | 85% |
| Documentation without IR internals | 100% |
| Natural-language spec input | 0% / future |
| Approximate optimisation mode | 0% / intentionally excluded |
| Safety/security critical tagging UI | 0% / intentionally hidden |

## Notes

* Default output is fully compressed Starlog.
* Natural-language spec input is not supported in v1.
* Approximate optimisation is intentionally excluded.

