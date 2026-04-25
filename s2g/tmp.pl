check_grammar(R) :-
    catch((findall(_,(member(S,["[a,',',a,',',a]"]),term_to_atom(S2,S),flatten_keep_brackets(S2,S1),append([_],S4,S1),append(S3,[_],S4),once(phrase(a1,S3))),A),((length(["[a,',',a,',',a]"],L),length(A,L))->R="success";R="fail")),_, fail),
  !.
a1-->[a],
a2.
a2-->[].
a2-->[','],
[a],
a2.
