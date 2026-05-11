# NeuroStarlog — Examples

This directory contains example input files for all three NeuroStarlog input paths.

---

## `input.pl` — I/O example pairs (S2A path)

A list of `[Input, Output]` pairs used to demonstrate S2A algorithm reconstruction.

```prolog
[[1], [1]].
[[1, 2], [3]].
[[1, 2, 3], [6]].
[[1, 2, 3, 4], [10]].
```

### Run

```sh
swipl -q -s src/neurostarlog.pl -- \
  --input examples/input.pl \
  --input-type auto \
  --out starlog \
  --compress true \
  --grammar-out out/input_grammar.pl \
  --code-out out/input_generated.pl \
  --log-out out/input_log.txt
```

### Output files produced

| File | Description |
|------|-------------|
| `out/input_grammar.pl` | Generated grammar rules (`grammar_rule/4` facts) |
| `out/input_generated.pl` | Generated Prolog predicates |
| `out/input_generated.starlog` | Fully compressed Starlog (default) |
| `out/input_log.txt` | Pipeline log |

### Sample generated grammar (`out/input_grammar.pl`)

```prolog
grammar_rule(input,[n,a1],->,[ [] ]).
grammar_rule(input,[n,a1],->,[ ['_X'], [n,a1] ]).
```

### Sample generated Prolog (`out/input_generated.pl`)

```prolog
:- dynamic input/2.

input([], _Out).

input([_X|T_], Out_) :-
    % UNRESOLVED: element combination not determined.
    input(T_, Out_).
```

The `% UNRESOLVED` comment indicates a section where the output combination rule (sum, product, concatenation, etc.) could not be determined from the grammar structure alone. The partial code is still written so you can inspect what was generated.

### Sample pipeline log (`out/input_log.txt`)

```
[info] NeuroStarlog pipeline starting.
[info] Input type detected: io_examples
[info] Using S2A path for I/O examples.
[info] S2A: reading I/O examples from examples/input.pl.
[info] S2A: grammar generation completed successfully.
[info] S2A: generated grammar and wrote it to out/input_grammar.pl.
[info] S2A: partial Prolog written to out/input_generated.pl.
[error] S2A Prolog error — unresolved_combination: input
[info] S2A: Starlog conversion completed successfully.
[info] S2A: generated Starlog and wrote it to out/input_generated.starlog.
[info] NeuroStarlog pipeline complete.
```

This is a **partial failure** example: the grammar was successfully generated but the Prolog converter could not determine the element combination rule.  The Starlog converter still ran on the partial Prolog.

---

## `np_prolog_input.pl` — Prolog source (NP path)

A Prolog file containing predicates suitable for NP optimisation.

```prolog
positive(X) :- X > 0.
greet(Name) :- true, write(Name), nl.
print_value(X) :- writeln(X).
roll_die(D) :- random_between(1, 6, D).
main(X) :- positive(X), write(X), nl.
square(X, Y) :- Y is X * X.
```

### Run

```sh
swipl -q -s src/neurostarlog.pl -- \
  --input examples/np_prolog_input.pl \
  --input-type prolog \
  --out starlog \
  --compress true \
  --code-out out/np_prolog_optimised.pl \
  --log-out out/np_prolog_log.txt
```

### What the NP optimiser does

| Predicate | Action | Reason |
|-----------|--------|--------|
| `positive/1` | Helper is unfolded into `main/1` | Deterministic single-clause helper |
| `greet/1` | `true` goal removed | Redundant goal elimination |
| `print_value/1` | Preserved unchanged | Irreducible I/O predicate |
| `roll_die/1` | Preserved unchanged | Irreducible random predicate |
| `main/1` | `positive(X)` inlined as `X > 0` | Helper unfolding |
| `square/2` | Preserved unchanged | Unsupported arithmetic (not a recurrence) |

### Sample optimised Prolog (`out/np_prolog_optimised.pl`)

```prolog
positive(A) :- A>0.
greet(A) :- write(A), nl.
print_value(A) :- writeln(A).
roll_die(A) :- random_between(1,6,A).
main(A) :- A>0, write(A), nl.
square(A,B) :- B is A*A.
```

---

## `gaussian_input.pl` — Prolog source (Gaussian optimisation)

A Prolog file with linear and quadratic numeric recurrences, plus an unsupported predicate.

```prolog
linear(0, 2).
linear(N, Out) :- N > 0, N1 is N-1, linear(N1, Out1), Out is Out1 + 3.

tri(0, 0).
tri(N, Out) :- N > 0, N1 is N-1, tri(N1, Out1), Out is Out1 + N.

cube(X, Y) :- Y is X * X * X.
```

### Run

```sh
swipl -q -s src/neurostarlog.pl -- \
  --input examples/gaussian_input.pl \
  --input-type prolog \
  --out prolog \
  --code-out out/gaussian_optimised.pl \
  --log-out out/gaussian_log.txt
```

### What Gaussian optimisation does

| Predicate | Optimised form | Notes |
|-----------|----------------|-------|
| `linear/2` | `B is 2+3*A` | Closed form from linear recurrence |
| `tri/2` | `B is 1r2*A+1r2*(A*A)` | Polynomial `N*(N+1)/2` derived by Gaussian elimination |
| `cube/2` | Preserved unchanged | Cubic expression, not a recognisable polynomial recurrence |

Gaussian elimination runs **only after** trace-based pattern detection confirms a recurrence structure.  It never guesses coefficients and never hardcodes special-case forms.

### Sample optimised Prolog (`out/gaussian_optimised.pl`)

```prolog
cube(A,B) :- B is A*A*A.
linear(A,B) :- B is 2+3*A.
tri(A,B) :- B is 1r2*A+1r2*(A*A).
```

---

## Hybrid mode

Hybrid mode combines S2A reconstruction with NP optimisation plus an unchanged auxiliary Prolog file.

### Run

```sh
swipl -q -s src/neurostarlog.pl -- \
  --input examples/input.pl \
  --input-type hybrid \
  --input-aux examples/np_prolog_input.pl \
  --out prolog \
  --code-out out/hybrid_output.pl
```

Or let auto-detection promote to hybrid when `--input-aux` is supplied:

```sh
swipl -q -s src/neurostarlog.pl -- \
  --input examples/input.pl \
  --input-type auto \
  --input-aux examples/np_prolog_input.pl \
  --out prolog \
  --code-out out/hybrid_output.pl
```

The output file contains:
1. The S2A-reconstructed clauses, optimised by the NP plateau optimiser.
2. The auxiliary predicates from `examples/np_prolog_input.pl`, appended unchanged.
