flatten_keep_brackets(A,B) :-
 flatten_keep_brackets2(A,[],B,true),
 !.
 
flatten_keep_brackets2([],B1,B2,true) :- 
 append(B1,["[","]"],B2),!.
%flatten_keep_brackets2([[]],B1,B2,_) :- 
% append(B1,["[","]"],B2),!.
flatten_keep_brackets2([],B,B,_) :- !.
flatten_keep_brackets2(A,B,C,First) :-
 (not(is_list(A))->append(B,[A],C);
 (%trace,%length(A,AL),
 A=[D|E],flatten_keep_brackets2(D,[],F,true),
 %trace,
 %((A=[A1],only_item(A1))->Flag=true;Flag=false),
 flatten_keep_brackets2(E,[],C1,false),
 (First=true->foldr(append,[B,["["],F,C1,["]"]],C);
 foldr(append,[B,F,C1],C)))),!.
