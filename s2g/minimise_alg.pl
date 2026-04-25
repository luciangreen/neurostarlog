/* change names
repeat until 2nd time has the same result
dcgs
*/
:-include('replace_vars.pl').
:-include('replace_pred_names.pl').
%:-include('../listprologinterpreter/listprolog.pl').

% delete_duplicate_clauses([[[n,function],[[v,a]],":-",[[[n,+],[[v,a]]]]],[[n,function2],[[v,a]],":-",[[[n,+],[[v,a]]]]],[[n,function3],[[v,a]],":-",[[[n,function2],[[v,a]]]]]],[],L),writeln1(L).
% [[[n,function],[[v,a]],":-",[[[n,+],[[v,a]]]]],[[n,function3],[[v,a]],":-",[[n,function],[[v,a]]]]]

% Processes a list of clauses, removing the same clauses with different names, and replaces instances of the old names of the removed clauses with the name of the remaining clause.

% delete_duplicate_clauses([[[[n,a],":-",[[[n,b]]]],[]],[[[n,c],":-",[[[n,b]]]],[]],[[[n,d],":-",[[[n,c]]]],[]]],[],L),writeln1(L).
% [[[[n,a],":-",[[[n,b]]]],[]],[[[n,d],":-",[[[n,c]]]],[]]]

delete_duplicate_clauses([],List,List) :- !.
delete_duplicate_clauses(List1,List2,List3) :-
%trace,
 List1=[[[[n,N]|_Item1],_VT]|_List4],
 
 get_curr_node(List1,N,Node,List11),
 get_nodes_to_replace(List11,Node,N2,N28,List41),
 %*findall(N1,member([[[n,N1]|Item1],_],List4),N2),

 delete_nodes(List41,N2,List5),
 %*delete(List4,[[[n,_]|Item1],_],List5),
 append_node(List2,Node,List6),
 %*((
 %Item1=[])->append(List2,[[[[n,N]],VT]],List6);
 %append(List2,[[[[n,N]|Item1],VT]],List6)),
 findall([List7,L10],(member([List8,L10],List5),replace_pred_names2(List8,List7,N28,N)),List9),
 %trace,
 findall(List7,(member(List8%,L10]
 ,List6),replace_pred_names2(List8,List7,N28,N)),List12),
 delete_duplicate_clauses(List9,List12,List3),!.

get_curr_node(List1,N,Node,List11) :-
 findall(A,(member(A,List1),A=[[[n,N]|_Item1],_VT]),Node),
 subtract(List1,Node,List11),!.

get_nodes_to_replace(List4,Node,N3,N28,List41) :-
 % all nodes that have all same items as node
  findall(N1,member([[[n,N1]|Item1],_],List4),N21),
  %trace,
  Node=[[[[n,N1]|_]|_]|_],
  findall(Item1,member([[[n,N1]|Item1],_],Node),N21_items),
  sort(N21,N22),
  findall([N26,N23],(member(N23,N22),
  findall(N25,(member(N25,List4),N25=[[[n,N23]|Item1],_]),N26),
  findall(Item1,(member(N25,N26),N25=[[[n,_]|Item1],_]),N26_items),
  %trace,
  sub_term_wa([n,N1],N21_items,In21),
  findall([A,_],member([A,_],In21),In22),
  foldr(put_sub_term_wa_ae,In22,N21_items,N21_items1),
  
  sub_term_wa([n,N23],N26_items,In26),
  findall([A,_],member([A,_],In26),In27),
  foldr(put_sub_term_wa_ae,In27,N26_items,N26_items1),

  sort(N21_items1,A),sort(N26_items1,A)),N2),
  
  findall(A,member([A,_],N2),N29),
  findall(A,member([_,A],N2),N28),
  foldr(append,N29,N3),
  subtract(List4,N3,List41),!.
  
delete_nodes(List4,N2,List5) :-
 subtract(List4,N2,List5),!.

append_node(List2,Node,List6) :-
 append(List2,Node,List6),!.



 /*
delete_duplicate_clauses([],List,List) :- !.
delete_duplicate_clauses(List1,List2,List3) :-
trace,
 List1=[[[[n,N]|Item1],_VT2]|_List4],
 findall(D1,(member(D1,List1),D1=[[[n,N]|Item1a],VTa]),Ns),
 findall([[[n,_]|Item1a],_VTa],(member(D1,List1),D1=[[[n,N]|Item1a],VTa]),Ns1),
 %Item1=[Vars1|Rest],length(Vars1,VL),
 %length(Vars2,VL),Item2=[Vars2|Rest],
      findall(N4,(member(D1,Ns),D1=[[[n,N4]|Item1a],VTa]),NN), 

  findall([[[n,N4]|Item1],_VTa],(member(D1,List1),D1=[[[n,N4]|Item1],VTa],not(N=N4)),Ns5),
%findall([[[n,N5]|Item1a],_VTa],(member(D1,List1),D1=[[[n,N5]|Item1a],VTa]),Ns5),
%subtract(Ns1,Ns,A),

((subtract(Ns,Ns5,[]),subtract(Ns5,Ns,[]))%trace,
%length(NN,NNL),length(Ns1,NNL)))
%maplist(=(_),NN)
->(NN=[NN1|_],subtract(List1,Ns,List4),subtract(List4,Ns1,List5),findall(N1,member([[[n,N1]|Item1],_],List4),N2));(subtract(List1,[],List4),subtract(List4,[],List5),findall(N1,member([[[n,N1]|Item1],_],List4),N2),N2=[NN1|_])),
%findall(N1,member([[[n,N1]|Item1],_],List4),N2),
 
 

 %subtract(List4,[[[[n,_]|Item1],_]],List10),
 %findall(N3,member([[n,N1]|Item1],List4),N2),

 
 %findall(A,(member(A1,List4),
 %subtract(List,[A1],L1),
 
 %(A1=[[[n,A2]|Item1],A3]->
 
 %findall(B,(member(B1,)))
 %[[[n,_]|Item1]|_]

 
  findall([[[n,N3]],VTa],(member(D1,Ns),D1=[[[n,N3]|Item1a],VTa]),Ns3),
  findall([[[n,N3]|Item1a],VTa],(member(D1,Ns),D1=[[[n,N3]|Item1a],VTa]),Ns4),

 
 ((
 Item1=[])->append(List2,Ns3,List6);
 append(List2,Ns4,List6)),
 findall([List7,L10],(member([List8,L10],List5),replace_pred_names2(List8,List7,N2,NN1)),List9),
 delete_duplicate_clauses(List9,List6,List3),!.
 */
% with state machine, going backwards from base cases, minimises sm - like minimise decision tree, do groups of clauses together x join clauses together first [x minimise decision tree doesn't have cycles - account for incoming stems (if same inc. stems etc. then delete) and delete references to deleted branches] nd branches have no condition
% stop infinite loop in minimise decision tree by 

% is delete duplicate clauses the same as the second alg but processes preds with different names - no, the second alg processes inside preds
% weird to do clauses together, do them separately (test whether they are the same but have different names) followed by alg 1
% replace pred names with numbers, keeping a list of name-number correspondences, then run alg 1
%  just delete them, move up and repeat until the same (not use alg 1 x also use it)

% a(v2,v1):-b(v2,v1). -> ?(new_v1,new_v2):-b(new_v1,new_v2). - if two instances, delete and replace non a with a
% do with sm x

% minimise_alg([[[n,function],[[v,a],[v,b]],":-",[[[n,+],[[v,a],[v,b]]]]],[[n,function],[[v,b],[v,a]],":-",[[[n,+],[[v,b],[v,a]]]]]],A),writeln1(A).
% [[[n,function],[[v,a],[v,b]],":-",[[[n,+],[[v,a],[v,b]]]]]]

%  minimise_alg([[[n,function],[[v,a],[v,b]],":-",[[[n,+],[[v,a],[v,b]]],[[n,-],[[v,c],[v,d]]]]]],A),writeln1(A).
% [[[n,function],[[v,a],[v,b]],":-",[[[n,+],[[v,a],[v,b]]],[[n,-],[[v,c],[v,d]]]]]]

/*
minimise_alg([[[n,function],[[v,a],[v,b],[v,c]],":-",[[[[n,+],[[v,a],[v,b],[v,d]]],[[n,+],[[v,d],[v,d],[v,e]]]],[[n,-],[[v,e],[v,e],[v,c]]]]]],A),writeln1(A).

[[[n,function],[[v,a],[v,b],[v,c]],":-",[[[[n,+],[[v,a],[v,b],[v,d]]],[[n,+],[[v,d],[v,d],[v,e]]]],[[n,-],[[v,e],[v,e],[v,c]]]]]]


[debug]  ?- minimise_alg([[[n,function],":-",[[[n,not],[[[[n,false]],[[n,false]]]]],[[n,true]]]]],A),writeln1(A).

[[[n,function],":-",[[[n,not],[[[[n,false]],[[n,false]]]]],[[n,true]]]]]


minimise_alg([[[n,function],":-",[[[n,or],[[[n,false]],[[n,true]]]],[[n,true]]]]],A),writeln1(A).

[[[n,function],":-",[[[n,or],[[[n,false]],[[n,true]]]],[[n,true]]]]]


minimise_alg([[[n,function],":-",[[[n,"->"],[[[n,true]],[[n,true]]]],[[n,true]]]]],A),writeln1(A).

[[[n,function],":-",[[[n,"->"],[[[n,true]],[[n,true]]]],[[n,true]]]]]


minimise_alg([[[n,function],":-",[[[n,"->"],[[[n,true]],[[n,true]],[[n,true]]]],[[n,true]]]]],A),writeln1(A).

[[[n,function],":-",[[[n,"->"],[[[n,true]],[[n,true]],[[n,true]]]],[[n,true]]]]]

*/

minimise_alg(Algorithm1,Algorithm2) :-
%trace,
 sort(Algorithm1,Algorithm3),
 minimise_alg1(Algorithm3,Algorithm2).

minimise_alg1(Algorithm1,Algorithm2) :-
 findall([Algorithm3,Var_table],(member(Algorithm0,Algorithm1),replace_vars1(Algorithm0,Algorithm3,1,_,[],Var_table)),Algorithm4),
 %findall(Algorithm,member([Algorithm,_],Algorithm4),Algorithm4a),
 delete_duplicate_clauses(Algorithm4,[],Algorithm5),
length(Algorithm5,L),
 numbers(L,1,[],Ns),
 findall(Algorithm7,(member(N,Ns),
 %trace,
 %get_item_n(Algorithm5,N,Algorithm6),
 
get_item_n(Algorithm5,N,[Algorithm6,Var_table2]),
findall([B,A],member([A,B],Var_table2),Var_table3),
replace_vars1(Algorithm6,Algorithm7,1,_,Var_table3,_)),Algorithm8), 
 (Algorithm1=Algorithm8->Algorithm8=Algorithm2;
 minimise_alg1(Algorithm8,Algorithm2)).

