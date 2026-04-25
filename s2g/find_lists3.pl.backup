/*
split
[1,[2],1,[2,2]]

into [[1,[2]],[1,[2,2]]]

try dividing the levels up
find if make a repeating unit

*
^
|

find_lists3

try dividing into lists of lists
incl adding []

*
^
|

s2g:

s2l

find all repeating units of selections in each string
 with fl3
 
- go through term bottom up, creating var nums, insert brackets,  finding gs, keeping brackets intact
- dec tree for other terms from s2l

* fl3a with non repeating parts
- not '&r' but optional in fl3

- takes a long time unless short data so do a part of the grammar at a time

dec tree
on s2l levels x at all (bottom up (x dfs po)) xx
- checks whether to make a cp same or different x sort the levels of repeating structs, see if they match
- goes around s2l brackets etc
- dec tree merges branches with same structure


**

only close ] if finished pattern
no []
rec'ively proc term

test that parts repeat, signal bracket or repeating list with smallest unit

*/

% find_lists3a([1,2,2,1,2],A).
% A = [[1, ['&r', [2]]]].

% find_lists3a([1,2,3,2,3,1,2,3,2,3],L).
% L = [['&r', [1, ['&r', [2, 3]]]]]

% includes [] and recurse. structs when inserted

% find_lists3a([1,2,1,3,2],A).
% A = [[1, ['&r', [3]], 2]].

% find_lists3a([1,2,3,1,3],A).
% A = [[1, ['&r', [2]], 3]].

find_lists3a(L1,L32,Rest) :-
%writeln1(find_lists3a(L1,L3)),
%trace,
	%trace,
	%findall(L91,
	find_lists3(L1,[],L91,_Rest_a),%,L100),
	%trace,
	(fail%L91=[['&r', L92]]
	->(L4=_L92,Flag=true);
	(L4=L91,Flag=false)),
	%trace,
	(L4=[]->L4=L3;
	(L4=[_L2]->L4=L3;
	(L4=[L2|L31],
	%trace,
	
	check14(L31,L2,[],L5,Rest
	),
	%Rest=[],
	(L5=[['&r'|_]|_]->L5=L3;
	((L5=[L51]->true;L51=L5),
	L3=[['&r',L51]]))
	))),

	(Flag=true->L32=[['&r',L3]];L32=L3),
	!.

% find_lists3([1,2,2,1,2],[],L2).
% L2 = [[1, ['&r', [2]]], [1, 2]]

% find_lists3([1,2,3,2,3,1,2,3,2,3],[],L).
% L = [['&r', [1, ['&r', [2, 3]]]]]

find_lists3([],L,L,_) :- !.
find_lists3(L1,L2,L3,Rest) :-
%trace,
	repeating_unit(L1,U,Rest),
	(U=['&r',U1]->
	%find_lists3(U1,[],U2);
	try(U1,U2);
	U2=U),
	append(L2,[['&r',U2]],L3).


match_char("[","]").
match_char("(",")").
match_char("{","}").
match_char(A,A).

find_lists3(L1,L2,L3,Rest) :-
	%reverse(L1,L11),
	L1=[L4|L5],
	match_char(L4,L41),
	%reverse(L5,L511),
	find_lists4(L2,L5,L4,L41,L3,Rest).

find_lists4(L2,L5,L4,L41,L3,Rest) :-
	member(L4,L5),
	sub_list(L5,Before_list,[L41],After_list),
	Before_list1=[L4|Before_list],After_list1=[L41|After_list],
	%Before_list1=[L4],After_list1=[])),
	find_lists32(Before_list1,[],L6,_),
	%(After_list=[]->L7=[];
	%(%find_lists31([L4|After_list],[],L7)->true;
	%split13(L6,After_list,L3),!.
	find_lists3(After_list1,[],L7,Rest),
	%fail,
	%trace,
	foldr(append,[[L6,L7]],L8),
	foldr(append,[L2,L8],L33),
	L3=L33.
find_lists4(L2,L5,L4,L41,L3,Rest) :-
	not((member(L41,L5),
	sub_list(L5,_Before_list,[L4],_After_list))),	
	%foldr(append,[L2,[L6,L7]],L3));
	append(L2,[L4],L6),
	find_lists3(L5,L6,L3,Rest).%find_lists3(L1,L2,L3) :-
%	append(L1,L2,L3).

/*find_lists3(L1,L2,L3) :-
	L1=[L4|L5],
	append(L2,[L4],L6),
	find_lists3(L5,L6,L3),!.
*/

/*
find_lists32(L1,L2,L3) :-
	repeating_unit(L1,U),
	append(L2,[U],L3),!.
*/
find_lists32(L1,L2,L3,Rest) :-
	find_lists3(L1,L2,L3,Rest).


% repeating_unit([2,2],U).
% U = ['&r',[2]]). or [2]
repeating_unit(L1,U,Rest) :-
	(only_item(L1)->fail;
	(length(L1,L),
	L2 is (floor(L/2)),
	%L2 is L-1,
	numbers(L2,1,[],Ns),
	find_first((member(N,Ns),
	split12(L1,N,[],A,Rest),
	maplist(=(_),A))),
	(N=L->U=L1;
	(length(L21,N),
	append(L21,_,L1),
	U=['&r',L21])))),!.
	
split12([],_,A,A,[]):-!.	
split12(L%
%List
,L16,%N,N,
 A1,A2,_Rest) :- length(L,LL),LL<L16,%A1=A2,Rest=L,%
 append(A1,L,A2),
 %L2 is L16*2,length(List,L3),L3=<L2,
 !.
split12(Q2,L16,%N1,N2,
 L20,L17,Rest) :-
	%get_items_summing_to_l(Q2,L16,N1,N3,[],L2),
	length(L18,L16),
	append(L18,L19,Q2),
	append(L20,[L18],L21),
	split12(L19,L16,L21,L17,Rest),!.
split12(A,_B,C,C,A) :-!.

% Checks that each item is a copy of the first item, and inserts optional items where necessary to make them the same.
	
check14([],_,A,A,[]
):-!.
check14(A0,B,C,D1,Rest
) :-
	A0=[A01|A02],
	check141(A01,B,[],D),
	append(C,[D],C1),
	%trace,
	(check14(A02,B,C1,D1,Rest
	)%->true;
	%(A02=Rest,C1=D1)
	),
	%(D2=[])
	!.
check141([],[],A,A):-!.
/*check141(A,B,C,D1) :-
%trace,
 ((A=[],_A52=[[o,B]])->true;
 (B=[],_A52=[[o,A]])),
 %trace,
 	%(A51=[]->A52=[];A52=[[o,A51]]),
	foldr(append,[%A52
	],C1),
	append(C,C1,D1),
	%check141(A2,B2,C1,D1),
	!.
*/
check141(A,B,C,D1) :-

append(A31,B3,A),append([A1],A2,B3),
append(A41,B4,B),append([B1],B2,B4),

((A31=[],A41=[])->A51=[];
(A31=[],not(A41=[]))->A51=A41;
(not(A31=[]),A41=[])->A51=A31),

%(A1z=[['&r',A1z1]]->A1=['&r',A1z1];A1=A1z),
%(B1z=[['&r',B1z1]]->B1=['&r',B1z1];B1=B1z),
	%A=[A1|A2],
	%B=[B1|B2],
	(A1=B1->(A3=A1,A2=A22,B2=B22
	);
	((not(A1=['&r',_]),not(B1=['&r',_]))->fail;
	(
	((A1=['&r',A11]->true;A1=A11),
	(B1=['&r',B11]->true;B1=B11),
	(not(is_list(A11))->(A11=A13%,A14=[]
	,(append([A21],A22,A2)->append([A13],[A21],A23);(A22=[],A23=[A13])%
	));(A11=A23,%[A13|A14],
	A22=A2%,A23=[A13]
	)),
	(not(is_list(B11))->(B11=B13%,B14=[]
	,(append([B21],B22,B2)->append([B13],[B21],B23);(B22=[],B23=[B13])%
	));(B11=B23,%[B13|B14],
	B22=B2%,B23=[B13]
	)),
	%append(A14,A2,A21),
	%append(B14,B2,B21),
	check141(A23,B23,[],D),A3=['&r',D])))),
	%((A1=['&r',A11],B1=->(check141(A1,B1,[],D),A3=['&r',D]);
	%(B1=['&r',A1]->(check141(A1,B1,[],D),A3=['&r',D]);
	%(A1=['&r',[B1]]->(check141(A1,[B1],[],D),A3=['&r',D]);
	%(B1=['&r',[A1]]->(check141([A1],B1,[],D),A3=['&r',D])))))),
	(optional_s2g(on)->
	(A51=[]->A52=[];A52=[['&o',A51]]
	);
	(A51=[]->A52=[];fail
	)),
	foldr(append,[C,A52,[A3]],C1),
	
	check141(A22,B22,C1,D1),!.
%check14(A,B,C,D) :-
%	A=[A1|A2],
%	B=[B1|B2],
	
%	append(C,[A1],C1),
%	check14(A2,B2,C1,D),!.

	
/*
split13([],_,A,A):-!.	
split13(L%
%List
,L16,%N,N,
 A1,A2) :- length(L,LL),LL<L16,append(A1,L,A2),
 %L2 is L16*2,length(List,L3),L3=<L2,
 !.
split13(Q2,L16,%N1,N2,
 L20,L17) :-
	%get_items_summing_to_l(Q2,L16,N1,N3,[],L2),
	length(L18,L16),
	append(L18,L19,Q2),
	append(L20,[L18],L21),
	split13(L19,L16,L21,L17),!.
split13(_A,_B,C,C) :-!.
*/
	
%find_lists3()
