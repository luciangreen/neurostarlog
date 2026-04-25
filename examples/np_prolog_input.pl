% examples/np_prolog_input.pl
% Simple Prolog source for NeuroStarlog NP path tests.
%
% Used by tests/neurostarlog_tests.pl PR 5 test cases.
%
% Contains:
%   - A helper predicate eligible for deterministic unfolding.
%   - A clause with a redundant `true` goal.
%   - Predicates with irreducible goals (I/O, random) that must be preserved.
%   - A clause with unsupported arithmetic (preserved unchanged).

% Helper predicate: deterministic, non-recursive, called from main/1.
% Expected: unfolded into main/1 by the NP optimiser.
positive(X) :- X > 0.

% Clause with redundant `true` — expected: `true` removed.
greet(Name) :- true, write(Name), nl.

% Predicate containing I/O — irreducible, must be preserved unchanged.
print_value(X) :- writeln(X).

% Predicate containing random — irreducible, must be preserved unchanged.
roll_die(D) :- random_between(1, 6, D).

% Main predicate calling the helper — used to test unfolding.
main(X) :- positive(X), write(X), nl.

% Predicate with unsupported arithmetic (not a recognised pattern).
% Must be preserved unchanged by the NP optimiser.
square(X, Y) :- Y is X * X.
