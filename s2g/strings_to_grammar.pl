/*

Decision tree, with recurring parts

strings_to_grammar(["[aaa]"],G).
G = [[1,>,[]],
	 [1,>,a,1]
	]

strings_to_grammar(["[ab]","[ac]"],G).
G = [[1,>,a,1]
	 [1,>,b],
	 [1,>,c]
	]

*/

:-use_module(library(clpfd)).
:-include('../../listprologinterpreter/listprolog.pl').
%:-include('../luciancicd/find_dependencies2-cgpt1.pl').
:-include('../sub_term_with_address.pl').
%:-include('test15.pl').
:-include('find_lists3.pl').
:-include('minimise_alg.pl').
:-include('optimise_alg.pl').
:-include('flatten_keep_brackets.pl').
:-include('../decision_tree.pl').
:-dynamic var_num/1.
:-dynamic s2g_mode/1.
:-dynamic optional_s2g/1.
:-dynamic table_s2g/1.

test_s2g :-

findall(_,(member([N,L,G2],
[

[1,["[1,2,3,2,3,1,2,3,2,3]"],
[[[n,a1],"->",[[]]],
[[n,a1],"->",[[1],[[n,a2]],[[n,a1]]]],
[[n,a2],"->",[[]]],
[[n,a2],"->",[[2],[3],[[n,a2]]]]]],

[2,["[1,2,2,1,2]"],
[[[n,a1],"->",[[]]],
[[n,a1],"->",[[1],[[n,a2]],[[n,a1]]]],
[[n,a2],"->",[[]]],
[[n,a2],"->",[[2],[[n,a2]]]]]],

[3,["[1,2,1,3,2]"],
[[[n,a1],"->",[[]]],
[[n,a1],"->",[[1],[[n,a2]],[2],[[n,a1]]]],
[[n,a2],"->",[[]]],
[[n,a2],"->",[[3]]]]],

[4,["[1,2,3,1,3]"],
[[[n,a1],"->",[[]]],
[[n,a1],"->",[[1],[[n,a2]],[3],[[n,a1]]]],
[[n,a2],"->",[[]]],
[[n,a2],"->",[[2]]]]],

[5,["[1,2,3,2,3,4,5,1,2,3,4,5]"],
[[[n, a1], "->", [[1], [2], [[n, a2]], [3], [4], [5]]], 
[[n, a2], "->", [[]]], 
[[n, a2], "->", [[3], [[n, a3]], [2], [[n, a2]]]], 
[[n, a3], "->", [[]]], 
[[n, a3], "->", [[4], [5], [1]]]]],

[6,["[1,2,3,2,3,4,5,1,2,3,4,5,1,2,3,2,3,4,5,1,2,3,4,5]"],
[[[n,a1],"->",[[]]],
[[n,a1],"->",[[1],[2],[[n,a2]],[3],[4],[5],[[n,a1]]]],
[[n,a2],"->",[[]]],
[[n,a2],"->",[[3],[[n,a3]],[2],[[n,a2]]]],
[[n,a3],"->",[[]]],
[[n,a3],"->",[[4],[5],[1]]]]],

[7,["[0,0,1,0,0]"],
[[[n, a1], "->", [[[n, a2]], [1], [[n, a2]]]], 
[[n, a2], "->", [[]]], 
[[n, a2], "->", [[0], [[n, a2]]]]]],

[8,["[a,b]", "[a,c]"], 
[[[n, a1], "->", [[a], [[n, a2]]]], 
[[n, a2], "->", [[b]]], 
[[n, a2], "->", [[c]]]]],

[9,["[a,b]", "[a,d,e]", "[a,d,f]"], 
[[[n, a1], "->", [[a], [[n, a2]]]], 
[[n, a2], "->", [[b]]], 
[[n, a2], "->", [[d], [[n, a4]]]], 
[[n, a4], "->", [[e]]], 
[[n, a4], "->", [[f]]]]],

[10,["[a,b]", "[a,d,d,e]", "[a,d,d,f]"], 
[[[n, a1], "->", [[a], [[n, a2]]]], 
[[n, a2], "->", [[b]]], 
[[n, a2], "->", [[[n, a4]], [[n, a5]]]], 
[[n, a4], "->", [[]]], 
[[n, a4], "->", [[d], [[n, a4]]]], 
[[n, a5], "->", [[e]]], 
[[n, a5], "->", [[f]]]]],

[11,["[a]", "[[a]]", "[[[a]]]"], 
[[[n,a1],"->",[["["],["["],[a],["]"],["]"]]],
[[n,a1],"->",[["["],[a],["]"]]],
[[n,a1],"->",[[a]]]]],

[12,["[a]", "[[a]]", "[[[a]]]", "[[[[a]]]]"], 
[[[n,a1],"->",[["["],["["],["["],[a],["]"],["]"],["]"]]],
[[n,a1],"->",[["["],["["],[a],["]"],["]"]]],
[[n,a1],"->",[["["],[a],["]"]]],
[[n,a1],"->",[[a]]]]],

[13,["[a]", "[[a]]", "[[[a]]]", "[[[[a]]]]", "[[[[[a]]]]]"], 
[[[n,a1],"->",[["["],["["],["["],["["],[a],["]"],["]"],["]"],["]"]]],
[[n,a1],"->",[["["],["["],["["],[a],["]"],["]"],["]"]]],
[[n,a1],"->",[["["],["["],[a],["]"],["]"]]],
[[n,a1],"->",[["["],[a],["]"]]],
[[n,a1],"->",[[a]]]]],

[14,["[[[f,g]]]"],
[[[n,a1],"->",[["["],["["],[f],[g],["]"],["]"]]]]],

[15,["[[[[],g],[]],[],a]"],
[[[n,a1],"->",[[[n,a2]],[a]]],
[[n,a2],"->",[[]]],
[[n,a2],"->",[["["],[[n,a4]],["]"],[[n,a2]]]],
[[n,a4],"->",[[]]],
[[n,a4],"->",[["["],[[n,a5]],["]"],[[n,a4]]]],
[[n,a5],"->",[[]]],
[[n,a5],"->",[["["],["]"],[g]]]]],

[16,["[[a],',',[a],',',[a]]"],
[[[n,a1],"->",[["["],[a],["]"],[[n,a2]]]],
[[n,a2],"->",[[]]],
[[n,a2],"->",[[','],["["],[a],["]"],[[n,a2]]]]]],

[17,["[a,',',a,',',a]"],
[[[n,a1],"->",[[a],[[n,a2]]]],
[[n,a2],"->",[[]]],
[[n,a2],"->",[[','],[a],[[n,a2]]]]]]

]),

 strings_to_grammar(L,G1),%writeln1(G1),
 ((G1=G2)->R=success;R=fail
 ),
 writeln([R,N,strings_to_grammar,test]),
 
 (check_grammar(L,G1)->R1=success;R1=fail),
  writeln([R1,N,strings_to_grammar,check_grammar,test]),
  nl) 
 ,_),!.

get_var_num(N) :-
	var_num(N2),
	atom_concat(a,N2,N),
	N1 is N2+1,
	retractall(var_num(_)),
	assertz(var_num(N1)),!.

strings_to_grammar(L,G) :-

	retractall(optional_s2g(_)),
	assertz(optional_s2g(on)),

	retractall(var_num(_)),
	assertz(var_num(1)),

	retractall(s2g_mode(_)),
	assertz(s2g_mode(off%
	%findall
	)), % off or findall
	
	findall(%['&r',1,
	B%T41%]
	,(member(S,L),%string_strings(S,L2),
	term_to_atom(T1,S),
	%grammar1(L2,T1),
	%string_strings(S,T1),
	group_non_lists1(T1,T4),
	%flatten_keep_brackets(T1,T4),
	process_terms(T4,[],B,[],_R)
	),Gs2),
	%trace,
	decision_tree_s2(Gs2,T42),
	%trace,
	findall(B2,(member(T44,T42),find_g(T44,[],B2)),Gs),
	%foldr(append,T41,T42)
	%,get_var_num(N)
	(Gs=[]->G=Gs;
	(Gs=[G6|Gs1],
	%trace,
	G6=[[[n,N]|_]|_],
	findall(A,(member(A1,Gs1),
	(A1=[[[n,_]|A2]|A21]->A=[[[n,N]|A2]|A21];A=A1)),A3),
	append([G6],A3,Gs3),
	foldr(append,Gs3,Gs4),
	%trace,
	%insert_stub_arguments(Gs4,Gs5),
	%Gs5=Gs6,%
	%trace,
	repeat_until_same(Gs4,G)
	%remove_stub_arguments(Gs6,G)
	)).

repeat_until_same(Gs4,G) :-
	minimise_alg(Gs4,Gs5),
	optimise_alg(Gs5,Gs6),
	(Gs4=Gs6->G=Gs6;
	repeat_until_same(Gs6,G)),!.

/*	
insert_stub_arguments(A,B) :- findall(A2,(member(A1,A),A1=[[n,A23],"->",A22],findall([[n,[a,A24]]],(member(A24,A22)%,(A24=[]->A241=1000;A241=A24)
)
,A25),A2=[[n,A23],[[v,a]],":-",A25]),B).
remove_stub_arguments(A,B) :- findall(A2,(member(A1,A),A1=[[n,A23],_,":-",A22],findall(A24,(member([[n,[a,A24]]],A22)%,(A24=1000->A241=[];A241=A24)
),A25),A2=[[n,A23],"->",A25]),B).
*/	
	%trace,
	%findall(B,(member(B1,Ts),),G1),
	%foldr(append,G1,G).
	/*
	%sub_term_types_wa([all([string])],Ts,In1), % find terminal lists
	%sub_term_types_wa([all_resolution_level([string])],Ts,In2),
	sub_term_types_wa([all([string])],Ts,In1),
	%append(In1,In2,In3),
	
	%findall(A,member([_,A],In1),A1),
	
	find_repeating_structures(In1,A11),
	find_recursive_structures,
	% find f>=2 of list l 2.. 
	
	% find and flatten length 2,3...
	% 
	
	

	sort(A1,A2),
	findall(%[A6L,
	[Ad,A4]%]
	,(member(A4,A2),findall(A5,member([Ad,A4],In),A6),length(A6,A6L),not(A6L=1)),A3),
	findall(A7,(member([Ad,A8],A3),)
	get_var_num).

	%find_g(Ts,[],G).
*/

%)->true;
%	T8=T45))),
	/*
	))
	findall(T6,(member(T7,T1),)

break_on_list(T1,T2,T3) :-!.
	T1=[T4|T5],
	(is_list(T4)->
	append([T2],);
	T5=
	append(T2,T4,T6).
	*/
	
% group_non_lists1([a,[b],c,d,[f],g,h],D).
% D = [[a], ["[", [b], "]"], [c, d], ["[", [f], "]"], [g, h]].

group_non_lists1(A,B) :-
 group_non_lists2(A,[],B),!.
 %sub_term_wa([],B,In),
 %findall(Add,member([Add,_],In),In2),
 %delete_sub_term_wa(In2,B,C).
 
group_non_lists2(A,B,C) :-
 ((append(D,E,A),
 append([F],G,E),
 is_list(F))->
 (H=D,group_non_lists2(F,[],G1),
 group_non_lists2(G,[],G2),
 wrap_if_non_empty(G1,G12),
 wrap_if_non_empty(H,H2),
 %wrap_if_non_empty(G2,G21),
 foldr(append,[["["],G12,["]"]],L),
 foldr(append,[H2,[L],G2],J));
 (H=A,
 wrap_if_non_empty(H,H2),
 append(H2,J))),
 append(B,J,C).
 %group_non_lists2(A,B,C) :-

wrap_if_non_empty(A,B) :-
 (A=[]->B=A;B=[A]),!.
 %A=[D|E],
 %()
/*
group_non_lists1(Xs, Ys) :-
%trace,
 group_non_lists2(Xs, Ys).
group_non_lists2(Xs, Ys) :-
%trace,
	group_non_lists([['&item']|Xs], Ys1,true),
	(append([[]],Ys,Ys1)->true;Ys=Ys1).
group_non_lists([['&item'|A]], B,_First) :-(is_list(A)->B=[A];B=[[A]]),!.
group_non_lists([A2], C,_First) :-
 %true%First=true
 %->
 ((A2=[A],%trace,
 only_item(A))->C=[["[",[A],"]"]];
 (%fail,%
 %trace,
 (((append(["["],A4,A2),
 append(A5,["]"],A4))->A21=A5;(%trace,
 A21=A2)),
 %["]"]],A2))),
 is_list(A21),forall(member(A3,A21),only_item(A3)),
 %A2=[A],%trace,
 %only_item(A))->
 C=[["[",A2,"]"]])->true;
 (A2=[A],%
 %trace,
 %is_list(A2),
 %A2=[A3|_],
 %member(A3,A2),only_item(A3),
 group_non_lists([A],[A1],false
 ),
 C=[["[",[A1],"]"]]))),%;
 %(A=A1,C=[["[",[A1],"]"]])),
 !.
group_non_lists(A2, C,_First) :-
 %true%First=true
 %->
 %trace,
 (((append(["["],A4,A2),
 append(A5,["]"],A4))->A21=A5;(%trace,
 A21=A2)),
 %["]"]],A2))),
 is_list(A21),forall(member(A3,A21),only_item(A3)),
 %A2=[A],%trace,
 %only_item(A))->
 C=A2)->true;
 (fail,A2=[A],%
 %trace,
 %is_list(A2),
 %A2=[A3|_],
 %member(A3,A2),only_item(A3),
 group_non_lists([A],[A1],false
 ),
 C=[["[",[A1],"]"]]),%;
 %(A=A1,C=[["[",[A1],"]"]])),
 !. 
group_non_lists([A], [A],_) :-!.
group_non_lists([], [],_) :-!.
group_non_lists([X11, C|Xs], Ys,First) :-
	%catch(number_string(_C1,C),_,false),
	not(is_list(C)),
	%X11="-",
	X11=['&item'|X12],
	(not(is_list(X12))->X13=[X12];X13=X12),
	append(X13,[C],X3),
	X31=['&item'|X3],
    group_non_lists([X31|Xs], Ys,First),!.
group_non_lists([X11,C2|Xs], [X13|Ys],First) :-
%trace,
	%trace,
	%(%true%((C2=[C3|_],only_item(C3))->true;(trace,only_item(C2)))%length(C2,1)
(true%length(C2,1)->)
	->
	group_non_lists(C2,C,false
	);
	group_non_lists2(C2,C%,false
	)),
	(X11=['&item'|X12]->
	(X13=X12,C1=C);
	(%X11=[l|X12],
	X13=["[",X11,"]"],
	C1=['&item'|C])),
	%is_list(X11),%)%(catch(number_string(X1,X11),_,false)
	%->
	%X12=X1;X12=X11),
	
    group_non_lists([C1|Xs], Ys,First),!.
*/
longest_to_shortest_substrings1(A,B) :-
	%findall(C,
	longest_to_shortest_substrings(A,%C),
	B).
	%findall([C,D],append(C,D,A),B),!.
	%sort(D,B1),
	%reverse(B1,B).
%longest_to_shortest_substrings([],A,A) :-!.
longest_to_shortest_substrings(A0,C) :-
	%length(A0,L),L1 is L-3,(L1<3->L11=3;L11=L1),
	%append(D,E,A),
	%not(D=[]),
	append1(3%L11
	,A0,[],A01),
	delete(A01,[],C).
	%longest_to_shortest_substrings(E1,[],F),
	%flatten(D,D2),(D2=[]->D21=[];D21=[D2]),
	%flatten(D1,D3),(D3=[]->D31=[];D31=[D3]),
	%flatten(F,F2),(F2=[]->F21=[];F21=[F2]),
	%subtract()
	%foldr(append,[%B,
	%D21,D31,F21],C).
	%C=[A0,A,C,A1,C1,D1].

append1(0,A0,A01,A02) :- append(A01,[A0],A02),!.
/*append1(L1,A0,A01,A02) :-
	append(A,B,A0),
	append(C,D,B),
	append(A01,[A,C,D],A02).
	%append(A1,B1,D),
	%append(C1,D1,B1).
	*/
%/*
append1(L1,A0,A01,A02) :-
	%append(A2,B2,A0),
	%append(C2,D,B2),
	append(A1,B1,A0),
	append(C1,D1,B1),
	append(A01,[A1,C1],A03),
	L2 is L1-1,
	append1(L2,D1,A03,A02).
	
process_terms(T1,T2,T3,R1,R2) :-
%trace,
	process_terms3(T1,T2,T3,R1,R2),
	%remove_brackets1(T4,T3),
	!.
	
process_terms3([],T1,T3,R,R) :- %trace,
try(T1,T3),
%trace,
%remove_brackets1(T2,T3),
!.
process_terms3(T1,T2,T3,R1,R2) :-
%trace,
	%T1=[T4|T51],
	((%fail,
	member(["[",T6,"]"],T1))->
	((append(T4,B,T1),
	append([["[",T6,"]"]],T51,B),
	(process_terms3(T6,[],T5,[],R3),foldr(append,[["["],T5,["]"]],T53),T54=[T53],R6=R3%get_var_num(N),T5=['&r',N],foldr(append,[R1,R5,[T52]],R6)
	%)%;(fail%T51=[],R6=[]
	)));
	((%fail,%trace,
	(member(["[","]"],T1))->
	(append(T4,B,T1),
	append([["[","]"]],T51,B),
	(%process_terms(T6,[],T5,[],R3),
	foldr(append,[["["],["]"]],T53),T54=[T53],R6=[]%get_var_num(N),T5=['&r',N],foldr(append,[R1,R5,[T52]],R6)
	%)%;(fail%T51=[],R6=[]
	));
	(T54=[],T4=T1,T51=[])))),
	%trace,
	(foldr(append,T4,T45)->true;T4=T45),
	(all_distinct1(T45)->T9=T45;
	%trace,
	(s2g_mode(findall)->
	(findall(T8,try(T45,T8),T81),T9=[poss,T81]);
	(try(T45,T9)))
	/*	longest_to_shortest_substrings1(T45,T43),
	%trace,
	(find_first((T44=T43,%member(T44,T43),
	findall(T52,(member(C1,T44),(find_lists3a(C1,T52)->true;fail%
	%C1=T52)
	)
	),T7),length(T7,T7L),length(T44,T7L),foldr(append,T7,T8)

))->true;
	T8=T45))),
	*/
	),
	foldr(append,[T2,T9,T54],T61),
	append(R1,[R6],R7),
	process_terms3(T51,T61,T3,R7,R2),!.
	
	
% stwa each list containing "[".."]"
remove_brackets1(T2,T3) :-
	%writeln1(remove_brackets1(T2,T3)),
	%trace,
remove_brackets2(T2,[heuristic((append(["["],A1,A),append(_A2,["]"],A1)),A)],T22),
	%remove_brackets2(T21,[heuristic((append(["["],A1,A),append(A2,["]"],A1))],T22),

	(T2=T22->T3=T22;
	remove_brackets1(T22,T3)),!.

remove_brackets2(T2,T,T21) :-
%trace,
	sub_term_types_wa(T,T2,In11),
	%sub_term_types_wa([all([string,number,atom])],T2,In1),
	%findall(A,(member(A,In1),A=[_,["[", _, "]"]]),In11),
	(In11=[]->T2=T21;
	(In11=[In2|_],In3=[In2],
	%trace,
	(In2=[[1],_]->refind_st(T2,T,T21);%* get first
	foldr(put_sub_term_wa_ae_smooth,In3,T2,T21)))),!.
	
refind_st(T2,T,T22) :-
%trace,
	%foldr(append,[[A],T3,[B]],T2),
	append_brackets([A],T3,[B],T2),
	%foldr(append,[[*],T3,[*]],T4),
	append_brackets([*],T3,[*],T4),
	%trace,
	remove_brackets2(T4,T,T21),
	%foldr(append,[[*],T31,[*]],T21),
	append_brackets([*],T31,[*],T21),
	%foldr(append,[[A],T31,[B]],T22),
	append_brackets([A],T31,[B],T22),!.
	
append_brackets(A,T3,B,T2) :-
%trace,
 append(A,A1,T2),append(T3,B,A1),!.

/*get_rows(In1,T2,Before_After) :-
	findall(A,(member([Ad,A1],In1),
	append(A2,[A4],Ad),append(A2,[_],A3),
	sub_term_wa(A3,T2,In2),
	foldr()
*/

/*
process_terms2([],T1,T1,R,R) :- %trace,
%try(T1,T2),
!.
process_terms2(T1,T2,T3,R1,R2) :-
%trace,
	%T1=[T4|T51],
	((%fail,
	member(["[",T6,"]"],T1))->
	((append(T4,B,T1),
	append([["[",T6,"]"]],T51,B),
	(process_terms2(T6,[],T5,[],R3),foldr(append,[["["],T5,["]"]],T53),T54=T53,R6=R3%get_var_num(N),T5=['&r',N],foldr(append,[R1,R5,[T52]],R6)
	%)%;(fail%T51=[],R6=[]
	)));
	((%fail,%trace,
	(member(["[","]"],T1))->
	(append(T4,B,T1),
	append([["[","]"]],T51,B),
	(%process_terms(T6,[],T5,[],R3),
	foldr(append,[["["],["]"]],T53),T54=T53,R6=[]%get_var_num(N),T5=['&r',N],foldr(append,[R1,R5,[T52]],R6)
	%)%;(fail%T51=[],R6=[]
	));
	(T54=[],T4=T1,T51=[])))),
	%trace,
	(foldr(append,T4,T45)->true;T4=T45),
	T9=T45,
	%trace,
	
	
	foldr(append,[T2,T9,T54],T61),
	append(R1,[R6],R7),
	process_terms2(T51,T61,T3,R7,R2),!.
*/
try(T45,T8) :-
%writeln1(try(T45,T8)),
%trace,
(catch(table_s2g(_),_,fail)->
true;(%trace,
retractall(table_s2g(_)),
assertz(table_s2g([])))),
%trace,
	table_s2g(Table),
	(member([T45,Value,Sign],Table)->
	(Sign=positive->
	(%trace,
	T8=Value);
	(Sign=negative->
	(%trace,
	T45=T8)));
	(%trace,
	((%repeating_item_heuristic(C1),
	try1(T45,T8)%find_lists3a(C1,T52,_)
	)->
	true%
	%add_to_table([T45,T8,positive])
	;
	(%trace,
	%add_to_table([T45,T8,negative]),
	T45=T8)))),!.
/*
	%
	(%catch(call_with_time_limit(3.5,
	try1(T45,T8)
	%),
    %_,
    %fail)
    ->true;T45=T8).
*/
try1(T45,T8) :-

	longest_to_shortest_substrings1(T45,T43),
	%[T45]=T43,
	%trace,
	%(find_first((T44=T43,%member(T44,T43),
	findall(T52,(member(C1,T43),(%trace,
	%find_lists3a
	try2(C1,T52,_)->true;fail%
	%C1=T52)
	)
	),T7),length(T7,T7L),(length(T43,T7L)->%(%trace,T7=T8);
	(%trace,
	foldr(append,T7,T8));
	fail),!.

try2(C1,T52,_) :-%trace,
	table_s2g(Table),
	(member([C1,Value,Sign],Table)->
	(Sign=positive->
	T52=Value;
	(Sign=negative->
	fail));
	((
	
	(
	/*not here
	(repeating_item_heuristic(C1)->
	writeln1([repeating_item_heuristic(C1),true]);
	(writeln1([repeating_item_heuristic(C1),false]),fail)
	)
	*/
	true
	),%->
	%trace,
	((%
	/*
	(repeating_item_heuristic(C1)->
	%true);%
	writeln1([repeating_item_heuristic(C1),true]);
	(%
	writeln1([repeating_item_heuristic(C1),false])%,
	%true%
	,fail
	))
	,
	*/
	
	find_lists3a(C1,T52,_))->
	(%writeln([find_lists3a(C1,T52,_),true]),%
	true);%
	%add_to_table([C1,T52,positive]));
	(%add_to_table([C1,_T52,negative]),
	%writeln([find_lists3a(C1,_T52,_),false]),
	fail))%;C1=T52
	))),!.

repeating_item_heuristic(C1) :-
	%not
	((%not(C1=[_]),
	sort(C1,C2),
	not(C1=C2))).
/*	% item in first half is from 1/2-3/4
	length(C1,L),
	L2 is floor(L/2),
	length(List,L2),
	L3 is L2+1,
	L4 is ceiling((3*L)/4),
	numbers(L4,L3,[],Ns),
	findall(X,(member(N,Ns),get_item_n(C1,N,X)),Xs),
	%C1=[C2|C3],
	append(List,_,C1),
	intersection(List,Xs,A),not(A=[]),!.
	*/
	
add_to_table(A) :-
	table_s2g(Table1),
	append(Table1,[A],Table2),
	retractall(table_s2g(_)),
	assertz(table_s2g(Table2)),!.

%*/
/*(find_repeating_structures(List,A11) :-
	findall(A,member([_,A],List),A1),
	maximum_length(A1,Maximum_length),
	%numbers(Maximum_length,1,[],Ns),
	append(Nm1,[_],Ns),
	Position2 is ceiling((Maximum_length/2)-1),
	find_repeating_structures1(1,Position2,2,Nm1,List,[],List2).
	
	% test for f>=2
	% mark items' places with * x can include existing results
	% flatten '&r' structs xx where always same (no different dbcs compared with abcs) x if there is no d in the group of as

% L=['&r',1,["a","b",['&r',2,["c","d"]]]]
% '&r' means recursive struct, i.e. 1-->3,4, referred to elsewhere as ['&r',1]
% L=['&r',1,["a","b","c","d","e","f"]]
% to L=['&r',1,["a","b",['&r',2,["c","d"]],"e","f"]]]]

% eg2. L=['&r',1,["a","b",['&r',2,["c","d"]]]]
% to L=['&r',1,["a","b",['&r',3,["e",['&r',2,["c","d"]]]]]]
% later ['&r',1,["a","b",['&r',3,["e","c","d"]]]] if no non 7s before 3,4s

find_sl(List,Find,Result) :-
	sub_term_types_wa([string],List,Inst1),
	findall(X,member([_,X],Inst1),X1),
	
	%List=[L|Ls],
	%flatten(List,List1),
	%findall(A1,(member(A1,List1),not(A1='&r'),not(number(A1))),B).
	append(C,D,X1),
	append(Find,E,D),
	length(C,L),
	length(Find,FL),
	%L1 is L+1,
	%L2 is L1+FL,
	%numbers(L2,L1,[],Ns),
	%findall(Y,(member(Y1,Ns),get_item_n(X1,Y1,[Ad,X])),Y2),
	get_item_n(Inst1,L,[Ad,X]),
	append(Ad1,[N2],Ad),
	get_sub_term_wa(List,Ad1,It2),
	%N21 is N2,
	length(Before_list,N2),
	length(Sub_list,FL),
	append(Before_list,L1,It2),
	append(Sub_list,After_list,L1),
	get_var_num(N),
	foldr(append,[Before_list,[['&r',N,Sub_list]],After_list],It3),
	put_sub_term_wa(It3,Ad1,List,Result),!.
	% check not cut off
	% add '&r'
	
% find_g(['&r',1,["a","b",['&r',2,["c","d"]]]],G).

% G = [[[n,1],"-->",[]],[[n,1],"-->",[["a"],["b"],[n,2],[n,1]]],[[n,2],"-->",[]],[[n,2],"-->",[["c"],["d"],[n,2]]]]


do outer level, then contained levels until end
- do as predicate
*/

find_g(T,G1,G2) :-
	%retractall(var_num(_)),
	%assertz(var_num(1)),
	(T=[T1]->true;T=T1),
	find_g2(T1,G1,G2).
find_g2([],G,G) :-!.

find_g2(T,G1,G2) :-

%T=[T1|T2],
T=['&r',%N,
T3],
get_var_num(N),

Name=[n,N],
Arrow="->",
Empty=[[]],
find_g1(T3,[],G3,[],Rest),
append(G3,[[Name]],G5),
G4=[[Name,Arrow,Empty],[Name,Arrow,G5]|Rest],
append(G1,G4,G2),
%foldr(append,G2,G21),
!.

find_g2(T,G1,G2) :-

%T=[T1|T2],
T=['&o',%N,
T3],
get_var_num(N),

Name=[n,N],
Arrow="->",
Empty=[[]],
find_g1(T3,[],G3,[],Rest),
%append(G3,[[Name]],G5),
G4=[[Name,Arrow,Empty],[Name,Arrow,G3]|Rest],
append(G1,G4,G2),
%foldr(append,G2,G21),
!.


find_g2(T,G1,G2) :-
%writeln1(find_g2(T,G1,G2)),

%T=[T1|T2],
T=[nd,%N,
T3],
%T3=T,
get_var_num(N),
Name=[n,N],

findall([G4,Name],(member(T31,T3),

Arrow="->",
%Empty=[[]],
%trace,
find_g1(T31,[],G3,[],Rest),
%append(G3,[[Name]],G5),
G4=[%[Name,Arrow,Empty],
[Name,Arrow,G3]|Rest]),G41),
findall(A,member([A,_],G41),G411),
foldr(append,G411,G42),
append(G1,G42,G2),
%foldr(append,G2,G21),
!.
%find_g2(T,G1,G2) :- %delete
%find_g21(T,G1,G2).

find_g2(T,G1,G2) :-

%T=[T1|T2],
not(T=['&r',%N,
T3]),
T3=T,
get_var_num(N),
Name=[n,N],
Arrow="->",
%Empty=[[]],
%trace,
find_g1(T3,[],G3,[],Rest),
%append(G3,[[Name]],G5),
G4=[%[Name,Arrow,Empty],
[Name,Arrow,G3]|Rest],
append(G1,G4,G2),
%foldr(append,G2,G21),
!.

find_g1([],G,G,R,R):-
 !.
find_g1(T,G1,G2,R1,R2) :-
%trace,
T=[T1|T2],
((T1=[L,%N,
_T4],(L='&r'->true;L='&o'))->
(find_g2(T1,[],R3),
R3=[[[n, N]|_]|_],
%get_var_num(N),
append(R1,R3,R4),T1a=[[[n,N]]]);
((%trace,
T1=[nd,%N,
T4]%,trace
)->
(findall(R3,(member(A1,T4),%
%trace,
find_g2([nd,[A1]],[],R3)),R31),
%trace,
R31=[[[[n, N]|_]|_]|_],
findall([[[n, N]|Args]|B]
,member([[[n, _]|Args]|B]
,R31),%B1=[[[n, N3]|_Args]|_B2],replace_term(B1,[n,N3],[n,N],B)),
R33),
/*
findall(B%[[[n, N]|Args]|B]
,(member(B1%[[[n, _]|Args]|B]
,R31),B1=[[[n, N3]|_Args]|_B2],replace_term(B1,[n,N3],[n,N],B)),R33),
*/
%trace,
foldr(append,R33,R32),
%get_var_num(N),
append(R1,R32,R4),T1a=[[[n,N]]]))->true;(%string(T1),
/*
(T1a=[T1],
R1=R4))),
append(G1,[T1a],G3),
find_g1(T2,G3,G2,R4,R2).
*/
(%trace,
(only_item(T1)->(T1a=[[T1]],R1=R4);(%trace,
find_g1(T1,[],T1a,[],R8),
append(R1,R8,R4)))))),
append(G1,T1a,G3),
%trace,
find_g1(T2,G3,G2,R4,R2).





/*
find_g(T,G%,G2]
)	:-
	T=['&r',N0,T1],
	sub_term_wa(['&r',_,_],T1,In),
	findall([X3,[Ad,X]],
	(member([Ad,X1],In),
	X1=['&r',N,A],
	sub_term_wa(['&r',_,_],A,In1),
	findall([Ad1,N1],(member([Ad1,Y1],In1),Y1=['&r',N1,A1]),Y2),
	foldr(put_sub_term_wa_ae,Y2,A,X21),
	X1=[_,_,X31],
	%trace,
	(In=[]->X=[];
	find_g(X31,X)),
	X3=[[N0,"-->"%][X21,"-->"
	,[]],[N0,"-->",X],[X21,"-->",[]],[X21,"-->",X]]),X2),
	findall(Z,member([_,Z],X2),Z1),
	foldr(put_sub_term_wa_ae,Z1,T1,G2),
	findall(Z,member([Z,_],X2),G1),
	foldr(append,G1,G),
	!.
	*/

/*
find_n_length_sublists(A1,SLs) :-
	findall([Ad,A],(member([Ad,A2],A1)
	
	)).

find_repeating_structures1(_Position1,_Position2,_Length1,_Length2,[],List,List) :- !.
find_repeating_structures1(Position1,Position2,Length1,Length2,List,List1,List2) :-
	List=[List3|List4],
	length(List3,L),
	truncate_l(L,Position2,Position22),
	truncate_l(L,Length2,Length22),
	find_repeating_structures2(Position1,Position22,Length1,Length22,List3,List5),
	
	append(List1,[List5],List6),
find_repeating_structures1(Position1,Position2,Length1,Length2,List4,List6,List2).

	find_repeating_structures2(Position2,Position2,Length1,_Length2,List,List) :- !.
	find_repeating_structures2(Position1,Position2,Length1,Length2,List,List2) :-
	
	find_repeating_structures3(Position1,Position2,Length1,Length2,[],List3) ,
	append(List,[List3],List4),
	Position11 is Position1+1,
	find_repeating_structures2(Position11,Position2,Length1,Length2,List4,List2).


	find_repeating_structures3(_Position1,_Position2,Length1,Length1,List,List) :- !.
	find_repeating_structures3(Position1,Position2,Length1,Length2,List,List2) :-
	split11(List,Length1,[],SLs),
	% find n length sublists up to n/2-1 items into list
	find_n_length_sublists(A1,SLs),
	append(List,[SLs],List3),
	Length11 is Length1+1,
	find_repeating_structures3(Position11,Position2,Length11,Length2,List3,List2).
	*/
split11([]%
%List
,_L16,%N,N,
 A,A) :- %L2 is L16*2,length(List,L3),L3=<L2,
 !.
split11(Q2,L16,%N1,N2,
 L20,L17) :-
	%get_items_summing_to_l(Q2,L16,N1,N3,[],L2),
	length(L18,L16),
	append(L18,L19,Q2),
	append(L20,[L18],L21),
	split11(L19,L16,L21,L17),!.
split11(_A,_B,C,C) :-!.
	
truncate_l(N,Max,N2) :-
 (N>Max->N2=Max;N2=N),!.
 /*
is_t(H,A,First0,First) :-
	((%trace,
	First0=true,First=true,member(all_resolution_level(K),H),%trace,
	%trace,%forall(%member(J,H),
	%member(K1,K)),
	is_list(A),
	%writeln1(A),
	%(A=["e", ['&r', 1, ["a"]]]->trace;true),
	member(['&r',_N,_A],A),
	sub_term_wa(['&r',_N,_A],A,Inst2),
	findall([Ad,A3],(member([Ad,_A4],Inst2),A3=0),Inst3),
	foldr(put_sub_term_wa_ae,Inst3,A,A2),
	%trace,
	%A2=A,
	forall(member(A1,A2),is_t([number|K],A1,First0,false))
	
	)),!.
	*/
	%*/

%find_g([],G,G) :-!.
%find_g(Ts,G1,G2) :-
%	Ts=[T1|Ts2].
	
/*
	sub_term_wa(T1,[_,[]],Insts), % find terminals
* see stwa

	find_g1(T1,G1,G3),
	find_g(Ts2,G3,G2).

% 2nd time bbba has 2 bs req branching point
% 
find_g1([],G,G) :-
find_g1(Items,G1,G2) :-
	%Items=[Item1|Items2],
	%is_list()	
	* s2l, 
	ind gs (editing editing aa in baabaa), dt, 
	x dt, do ind gs on branch segments x too difficult to move parts up
	x: backwards: gs
	dt gs with only same first letter
	
	find gs first (loops)
	
	only if subtree exactly the same * use diff gs in diff terms unless same g x always use same gs
	
	train tracks: any config can be accounted for, 
	
	()* do dec trees from Ts at same time - before gs
	decision_tree_s2(Items,T),

	%sub_term_wa(T,[_,[]],Insts), % find terminals
	
	* if rest of tree is same then can merge, otherwise stay separate
	
	try subtrees in case multiple subtrees
	
	* bottom up lists and trees, finished lists are gs
	
	dec tree on lists, backwards
	
	recn on lists
	
	* no quote types " or ' in quotes

	
	% find deps

	
*/

% string to list finds brackets, needs to refer to repeating parts already found

% * other types of brackets incl quotes

% after s2l, puts together g reusing simplest gs first
% dec trees

/*
query_box_2(T):-A="[[\"aa,]\",b,\"c\",[]],1]",string_chars(A,C),findall(G,(member(E,C),atom_string(E,G)),F),grammar1(F,T).
grammar1(U,T):-compound([],T,U,[]),!.
compound213(U,U,T,T).
compound(T,U)-->["["],["]"],compound213(T,U).
compound(T,U)-->["["],compound21(T,V),["]"],compound213(V,U).
compound212(U,U,T,T).
compound21(T,U)-->item(I),lookahead(["]"]),{wrap(I,Itemname1),append(T,Itemname1,V)},compound212(V,U).
compound21(T,U)-->item(I),[","],compound21([],Compound1name),{wrap(I,Itemname1),append(T,Itemname1,V),append(V,Compound1name,U)}.
item(T)-->["\""],word21("",T),["\""].
item(T)-->number21("",U),{stringtonumber(U,T)}.
item(T)-->word21_atom("",T1),{atom_string(T,T1)}.
item(T)-->compound([],T).
number212(U,U,T,T).
number21(T,U)-->[A],commaorrightbracketnext,{((stringtonumber(A,A1),number(A1))->(true);((equals4(A,".")->(true);(equals4(A,"-"))))),stringconcat(T,A,V)},number212(V,U).
number21(T,U)-->[A],{((stringtonumber(A,A1),number(A1))->(true);((equals4(A,".")->(true);(equals4(A,"-"))))),stringconcat(T,A,V)},number21("",Numberstring),{stringconcat(V,Numberstring,U)}.
word212(U,U,T,T).
word21(T,U)-->[A],quote_next,{not((=(A,"\""))),stringconcat(T,A,V)},word212(V,U).
word21(T,U)-->[A],{not((=(A,"\""))),stringconcat(T,A,V)},word21("",Wordstring),{stringconcat(V,Wordstring,U)}.
word212_atom(U,U,T,T).
word21_atom(T,U)-->[A],commaorrightbracketnext,{not((=(A,"\""))),not((=(A,"["))),not((=(A,"]"))),stringconcat(T,A,V)},word212_atom(V,U).
word21_atom(T,U)-->[A],{not((=(A,"\""))),not((=(A,"["))),not((=(A,"]"))),stringconcat(T,A,V)},word21_atom("",Wordstring),{stringconcat(V,Wordstring,U)}.
commaorrightbracketnext-->lookahead([","]).
commaorrightbracketnext-->lookahead(["]"]).
quote_next-->lookahead(["\""]).
lookahead(B,A,A):-append(B,_D,A).

%grammar_part(A,B,C):-string_concat(A,C,B),string_length(A,1).
stringconcat(A,B,C):-string_concat(A,B,C).
stringtonumber(A,B):-number_string(B,A).
equals4(A,B):-A=B.
wrap(A,B):-B=[A].
*/

% start with shortest string at end of strings, build dec tree bottom up
% turn recursion on way into new clauses eg abbbc
% matching brackets at same level

% only branches if 2nd instance needing it x

% turn tree into graph
% dfs post order - replaces same branches

% check simpler trees for recursive parts first, 	x

% decision_tree_s2([[a,b,c],[a,d,e],[f,g,h]],A),writeln(A).

% [[a,[[b,[[c,[]]]],[d,[[e,[]]]]]],[f,[[g,[[h,[]]]]]]]

decision_tree_s2(A0,B):-
remove_dups(A0,A),
	decision_tree_s21(A,C),(length(C,1)->B=C%((P=[]->P1=P;[P1]=P),append([G],P1,GKP)
	;B=[[nd,C]]%foldr(append,[[G,[nd,%K1,
	%P]]],GKP))
	),!.
decision_tree_s21([],[]):-!.
decision_tree_s21(A,B) :-
	findall(C1,(member([C|_D],A),(C=[poss,C2]->member(C1,C2);C1=C)),E),

frequency_list2(E,L),
	findall(GKP,(member([G,K1],L),findall(D,member([G|D],A),D2),decision_tree_s21(D2,P),((K1=1->true;length(P,1))->((P=[]->P1=P;[P1]=P),append([G],P1,GKP));foldr(append,[[G,[nd,%K1,
	P]]],GKP))),B),!.


frequency_list_s2(A,B) :-

%frequency_list1_s2
frequency_list1(A,B).
%frequency_list1_s2(A,C),sort(C,D),reverse(D,B),!.

/*
frequency_list1_s2(E,L) :-

	remove_dups(E,K),
	findall([J,G],(member(G,K),findall(G,member(G,E),H),length(H,J)),L),!.

frequency_list1_s3(E,L) :-

	remove_dups(E,K),
	findall([G,J],(member(G,K),findall(G,member(G,E),H),length(H,J)),L),!.
*/
%frequency_list1_s2(E,L) :-

%frequency_list1(E,L).

/*
msort(E, Sorted),
clumped(Sorted, Freq1),	findall([A,B],member(B-A,Freq1),L),!.
*/

/*
frequency_list1a(E,L) :-

	sort(E,K),
	findall([J,G],(member(G,K),findall(G,member(G,E),H),length(H,J)),L),!.
*/

frequency_list1_s3(E,L) :-

msort(E, Sorted),
clumped(Sorted, Freq1),	findall([B,A],member(B-A,Freq1),L),!.

check_grammar(Strings0,A0) :-
	term_to_atom(Strings0,Strings),
	lp2p1(A0,A),
	foldr(string_concat,[%"#!/usr/bin/swipl -g main -q\n\n",":-include('flatten_keep_brackets.pl').\n","handle_error(_Err):-\n  halt(1).\n",
	"check_grammar(R) :-\n    catch((findall(_,(member(S,",Strings,"),term_to_atom(S2,S),flatten_keep_brackets(S2,S1),append([_],S4,S1),append(S3,[_],S4),once(phrase(a1,S3))),A),((length(",Strings,",L),length(A,L))->R=\"success\";R=\"fail\")),_, fail),\n  !.\n"%,"main :- halt(1).\n"
	,A],String_pp0_3),


foldr(string_concat,[%"../private2/luciancicd-testing/",Repository1b,"/",Go_path5,
"tmp.pl"],GP_pp0_3),
%string_concat(Go_path,"testcicd.pl",GP),
open_s(GP_pp0_3,write,S1_pp0_3),
write(S1_pp0_3,String_pp0_3),close(S1_pp0_3),
consult('tmp.pl'),
check_grammar(Result),/*
foldr(string_concat,["chmod +x ",GP_pp0_3,"\n","swipl -g main -q ./",GP_pp0_3],S3_pp0_3),%,

trace,
((catch(bash_command(S3_pp0_3,T502), _, (foldr(string_concat,["Warning."%%"Error: Can't clone ",User3,"/",Repository3," repository on GitHub."
	],_),%writeln1(Text4),
	fail)))),%abort
*/
	(Result="success"->true;fail),!.