% get input, put into output

% input is data, converted to an rs, moved using a mapping from another i/o pair

find_mapping(T1,T2,Map) :-
%trace,
	findall(T12,(findall(T11,remove_nd(T1,T11),T13),remove_dups(T13,T14),
	member(T15,T14),
	sub_term_types_wa([heuristic(is_var_s2a(A),A)],T15,In1),
	sub_term_types_wa([heuristic(is_var_s2a(A),A)],T2,In2),
	findall([Ad1,In21],(member([Ad1,Item],In1),
	findall(Ad2,member([Ad2,Item],In2),In21),
	(In21=[]->fail;true)
	),T12)),Map).
	

move_vars([],_T1,T2_old,T2_old) :- !.
move_vars(Map,T1,T2_old,Out2) :-
	move_vars1(Map,T1,T2_old,Out2).
	
move_vars1(Map, T1, T2_old, Out2) :-
    foldr(move_vars_pred(T1), Map, T2_old, Out2).

% Wrapper predicate to fit foldl/4's requirements
%move_vars_pred_wrapper(T1, MapElem, T2_old, Out) :-
%    move_vars_pred(T1, MapElem, T2_old, Out).
/*	
move_vars1([],_T1,_T2_old,Out,Out) :-!.
move_vars1(Map,T1,T2_old,_Out1,Out2) :-

	%foldl(move_vars_pred,[T1,T2_old],Map,Out).
	Map=[Map1|Map2],
	move_vars_pred(T1,T2_old,Map1,Out),
	%append(Out1,[Out],Out3),
	move_vars1(Map2,T1,Out%T2_old
	,Out,Out2).
*/
		
move_vars_pred(T1,Map,T2_old,T2_Old2) :-
	%member
	([Ad1,Ads2]=Map),
	get_sub_term_wa(T1,Ad1,It1),
	findall([Ad2,It1],member(Ad2,Ads2),Ads3),
	foldr(put_sub_term_wa_ae,Ads3,T2_old,T2_Old2).