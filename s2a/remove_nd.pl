
remove_nd(T,L) :-
	remove_nd(T,[],L).

remove_nd([],L1,L1) :-!.
remove_nd(T,L1,L2) :-

	T=[T1|T2],
	%(T1=['&r',[_V,T3]]->
	%(foldr(append,T3,T31),
	%append(L1,T31,L3));
	(T1=[nd,T3s],
	(member(T3,T3s),
	%foldr(append,T3,T31),
	remove_nd(T3,[],L32),
	no_nds(L32),
	append(L1,L32,L3));
	(T1=[]->append(L1,[[]],L3);
	((is_list(T1),remove_nd(T1,[],L32)),
	(fail,%not(L32=nd),
	L31=[L32],append(L1,L31,L3));
	(no_nds(T1),append(L1,[T1],L3))))),
	
	remove_nd(T2,L3,L2).

no_nds(A) :- flatten(A,B),not(member(nd,B)),!.