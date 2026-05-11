% Generated Prolog — NeuroStarlog NP optimiser (PR 5).

positive(A):-A>0.

greet(A):-write(A),nl.

print_value(A):-writeln(A).

roll_die(A):-random_between(1,6,A).

main(A):-A>0,write(A),nl.

square(A,B):-B is A*A.

