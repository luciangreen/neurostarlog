% * turn off optional in output

% * copy var vals to out
% A1 is not always the same x

term_to_list(T,L%,N
) :-
%trace,
	%flatten(T,T1),
	%(false%(N=4->true;N=6)%member('&r',T1)
	%->
	%term_to_list2(T,L);
	term_to_list1(T,L)%)
	,!.

term_to_list1(T,L) :-
	%catch(call_with_time_limit(3,
	term_to_list1(T,[],L).%),
	%time_limit_exceeded,
	%fail).
term_to_list1([],L1,L1) :-!.
term_to_list1(T,L1,L2) :-

	((T=[T1|T2],not(only_item1(T)));(T=[Type,T3],type_s2a1(Type),T=T1,T2=[])),
	%/*
	((T1=[Type,T3],type_s2a1(Type),
	join_san(T3,Type,L21),
	L31=[L21],
	append(L1,L31,L3));
	
	(T1=['&r',[T3]],
	(foldr(append,T3,L31),
	append(L1,L31,L3));
	/*numbers(9,0,[],Ns),
	member(N,Ns),
	length(L,N),
	append([T3],L,L4),
	maplist(=(_),L4),
	append(L1,L4,L2));
	*/
	%(T1=[nd,T3s]->
	%(member(T3,T3s),
	%foldr(append,T3,T31),
	%append(L1,T31,L3));
	(T1=[],append(L1,[[]],L3);
	((is_list(T1),term_to_list1(T1,[],L32)),
	(L31=[L32],no_rt(L32),append(L1,L31,L3));
	(no_rt(T1),append(L1,[T1],L3)))))),
	
	term_to_list1(T2,L3,L2).

/*
term_to_list1(T,L) :-
	term_to_list1(T,[],L).

term_to_list1([],L1,L1) :-!.
term_to_list1(T,L1,L2) :-

	T=[T1|T2],
	(T1=['&r',[_V,T3]]->
	(foldr(append,T3,T31),
	append(L1,T31,L3));
	%(T1=[nd,T3s]->
	%(member(T3,T3s),
	%foldr(append,T3,T31),
	%append(L1,T31,L3));
	(T1=[]->append(L1,[[]],L3);
	((is_list(T1),term_to_list1(T1,[],L32))->
	(L31=[L32],append(L1,L31,L3));
	append(L1,[T1],L3)))),
	
	term_to_list1(T2,L3,L2).
*/
/* 
term_to_list2(T,L) :-
	%catch(call_with_time_limit(3,
	term_to_list2(T,[],L).%),
	%time_limit_exceeded,
	%fail).
term_to_list2([],L1,L1) :-!.
term_to_list2(T,L1,L2) :-

	((T=[T1|T2],not(only_item1(T)));(T=[Type,T3],type_s2a1(Type),T=T1,T2=[])),
	
	(T1=[Type,T3],type_s2a1(Type),
	(join_san(T3,Type,L31),
	append(L1,[L31],L3),
	term_to_list2(T2,[],L21),
	append(L3,L21,L22),
	append(L1,L22,L2),no_rt(L2));
	
	(T1=['&r',[T3]],
	(%foldr(append,T3,T31),
	numbers(9,0,[],Ns),
	member(N,Ns),
	length(L,N),
	append([T3],L,L4),
	maplist(=(_),L4),
	append(L1,L4,L3),
	term_to_list2(T2,L3,L2));
	%(T1=[nd,T3s]->
	%(member(T3,T3s),
	%foldr(append,T3,T31),
	%append(L1,T31,L3));
	((T1=[],append(L1,[[]],L3),
	term_to_list2(T2,L3,L2));
	((is_list(T1),term_to_list2(T1,[],L32)),
	(L31=[L32],no_rt(L32),append(L1,L31,L3),
	term_to_list2(T2,L3,L2));
	(no_rt(T1),append(L1,[T1],L3),
	term_to_list2(T2,L3,L2)))))).
	*/ 
	%term_to_list2(T2,L3,L2).

no_rt(NR) :-flatten(NR,NR1),not(member('&r',NR1)),type_s2a1(Type),not(member(Type,NR1)),!.

