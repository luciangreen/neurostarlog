term_to_brackets(A,B,split=Split) :-
%trace,
 (is_list(A)->
 ((A=[Word,_Args],type_s2a1(Word))->
 (term_to_brackets2([A],[],[B],split=Split)
 %single_results(SR1),
 %append(SR1,[A],SR2),
 %retractall(single_results(_)),
 %assertz(single_results(SR2))
 );
 (term_to_brackets2(A,[],B,split=Split)));
 A=B),!.
 %sub_term_wa([],B,In),
 %findall(Add,member([Add,_],In),In2),
 %delete_sub_term_wa(In2,B,C).
 
term_to_brackets2(A,B,C,split=Split) :-
 ((append(D,E,A),
 append([F],G,E),
 is_list(F))->
 (H=D,
 ((F=[Word,_Args],type_s2a1(Word))->
 (F=G1,Wrap=true);
 (term_to_brackets2(F,[],G1,split=Split),Wrap=false)),
 term_to_brackets2(G,[],G2,split=Split),
 (G1=G12),
 (H=H2),
 %wrap_if_non_empty_s2a(G2,G21,split=Split),
 %trace,
 (false%Split=on
 ->
 (LB=[string,["["]],RB=[string,["]"]]);
 (LB="[",RB="]")),
 (Wrap=true->L=[G12];
 (foldr(append,[[LB],G12,[RB]],L1),
 (Split=on->L=[[split,L1]];L=L1))),
 foldr(append,[H2,L,G2],J));
 (H=A,
 wrap_if_non_empty(H,H2),
 append(H2,J))),
 append(B,J,C).
 
wrap_if_non_empty_s2a(A,B,split=Split) :-
%writeln1(wrap_if_non_empty_s2a(A,B,split=Split)),
%trace,
 (A=[]->B=A;((Split=on->
 B=[[split,A]];B=[A]))),!.

split_string_if_split(A,H,split=Split) :-
%A=H.
%/*
%trace,
 (Split=on
 ->
 %trace,
 %findall(D,(member(D1,A),(
 %string(A)->
 (split_list_on_item(A,",",B),
 (length(B,1)->B=[H];findall([split1,C],member(C,B),H)%,(H1=[[[split1,H]]]->true;H1=H)
 ))%;H=A%[[[split1,A]]]
 
 ;A=H),!.
%*/