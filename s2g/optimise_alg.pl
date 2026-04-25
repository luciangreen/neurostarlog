/*

optimise_alg([[[n, 1], "->", [[[n, 21]], [1], [[n, 21]]]], [[n, 2], "->", [[]]], [[n, 2], "->", [[0], [[n, 2]]]], [[n, 21], "->", [[[n, 2]]]]],A).
A = [[[n, 1], "->", [[[n, 2]], [1], [[n, 2]]]], [[n, 2], "->", [[]]], [[n, 2], "->", [[0], [[n, 2]]]]]

optimise_alg([[[n, 1], "->", [[[n, 21]], [1], [[n, 21]]]], [[n, 2], "->", [[]]], [[n, 2], "->", [[0], [[n, 2]]]], [[n, 21], "->", [[[n, 2]]]], [[n, 21], "->", [[[n, 23]]]]], A).
A = [[[n, 1], "->", [[[n, 21]], [1], [[n, 21]]]], [[n, 2], "->", [[]]], [[n, 2], "->", [[0], [[n, 2]]]], [[n, 21], "->", [[[n, 2]]]], [[n, 21], "->", [[[n, 23]]]]]

The second case shouldn't work because there are at least two [n,21] clauses that cannot be replaced with one.

*/
optimise_alg(A,B) :-
%trace,
 (optimise_alg1(A,C)->
 (
 A=C->C=B;
 %trace,
 optimise_alg(C,B))%->true;C=B))))
 ;
 A=B
 ),!.

optimise_alg1(A,G) :-
 find_first((member(B,A),
 ((B=[[n, D], Symbol, [[[n, E]|Arg]]],
 (Symbol=":-"->true;Symbol="->"),
 not((member(B1,A),B1=[[n, D], Symbol, [[[n, E1]|Arg1]]],
 not((E1=E,Arg=Arg1)))))->
 (%trace,
 delete(A,B,F),
 replace_term(F,[n, D],[n, E],G));
 ((B=[[n, D], Arg2,Symbol, [[[n, E]|Arg]]],
 (Symbol=":-"->true;Symbol="->"),
 not((member(B1,A),B1=[[n, D], Arg21,Symbol, [[[n, E1]|Arg1]]]),
 Arg2=Arg21,not((E1=E,Arg=Arg1))))->
 (delete(A,B,F),
 replace_term(F,[n, D],[n, E],G)))))),
 !.
 
