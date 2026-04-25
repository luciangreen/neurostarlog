%:-dynamic test_n/1.

test_s2a :-

	retractall(num_s2a(_)),
	assertz(num_s2a(1)),

	retractall(vars_s2a(_)),
	assertz(vars_s2a([])),

	retractall(vars_base_s2a(_)),
	assertz(vars_base_s2a('A')),

	retractall(character_breakdown_mode(_)),
	assertz(character_breakdown_mode(off)),

 test_find_unique_variables,
 test_find_constants,
 test_spec_to_algorithm.
 

test_find_unique_variables :-

	%retractall(vars_base_s2a(_)),
	%assertz(vars_base_s2a('A')),

findall(_,(member([N,S,UV2],
[
[1,[['A', [1, 3]]],
 [['A', ['A1', 'A2']]]],
 % A1 represents 1 and A2 represents 3

[2,[['A',[1,3,1]]],
 [['A',['A1','A2','A1']]]]

]),
/*
	retractall(num_s2a(_)),
	assertz(num_s2a(1)),

	retractall(vars_s2a(_)),
	assertz(vars_s2a([])),
*/
 ((find_unique_variables(S,UV1),
 
 %writeln1(find_unique_variables(S,UV1)),
 
 UV1=UV2)->R=success;R=fail),
 writeln([R,N,find_unique_variables,test])),_),!.



test_find_constants :-


findall(_,(member([N,S1,C2],
[

[1, [[['A',[3]],['B',[3]]],[['A',[4]],['B',[6]]]],
[['A',['C1']],['B',['C2']]]],
% These are not the same constant because not(3=3) and not(4=6), they are not 3 and 3, and 4 and 6 because a single pair of variables/values needs to replace them (note: this is just a find constants test), and they are different variables because not((3,4)=(3,6)).

[2, [[['A',[1]],['B',[1]]],[['A',[1]],['B',[1]]]],
[['A',[1]],['B',[1]]]],
% The value 1 recurs because it recurs in the different cases, it is not the constant instances C1, C1 because A=1,B=1 and A=1,B=1 are the same (not e.g. A=1,B=1 and A=2,B=2).

[3, [[['A',[1,3]],['B',[1,3]]],[['A',[1,4]],['B',[1,6]]]],
[['A',[1,'C1']],['B',[1,'C2']]]],
% 1 recurs because it recurs in the different cases

[4,
[[['A',[1,3]],['B',[2,3]]],[['A',[5,4]],['B',[5,6]]]],
[['A',['C1','C2']],['B',['C3','C4']]]]


 
]),

	findall(RS2,(member(S2,S1),
	
	%retractall(num_s2a(_)),
	%assertz(num_s2a(1)),
	%retractall(vars_s2a(_)),
	%assertz(vars_s2a([])),
	% vars base
	
	find_unique_variables(S2,UV),
	findall([UV1,RS],(member([UV1,UV2],UV),
	find_lists3b(UV2,RS)
	),RS2)
	),RS1),
	
((find_constants(S1,RS1,C1),

%writeln1(find_constants(S1,RS1,C1)),

C1=C2)->R=success;R=fail),
 writeln([R,N,find_constants,test])),_),!.


s2a_tests([

[1,algorithm,
[
[[input,[['A',[1,2]]]],[output,[['B',[2,1]]]]],
[[input,[['A',[3,4]]]],[output,[['B',[4,3]]]]]
],character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[['C1','C2'],[output,[['C2','C1']]]]],[[[[1,1],[[1,2]]],[[1,2],[[1,1]]]]],In_vars,Out_var)."
],

[2,algorithm,
[
[[input,[['A',[1,2,3,2,3,1,2,3,2,3]]]],[output,[['B',[3]]]]],
[[input,[['A',[1,2,4,2,4,1,2,4,2,4]]]],[output,[['B',[4]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[['&r',[1,['&r',[2,'C1']]]]],[output,[['C1']]]]],[[[[1,2,2,2,2],[[1,1]]]]],In_vars,Out_var)."
],

% r(2,C1) is 2,3,2,3 and 2,4,2,4, where C1 is either 3 or 4. r(1,(r(2,C1))) is 1,2,3,2,3,1,2,3,2,3, or 1,2,4,2,4,1,2,4,2,4, where 1 and 2,3,2,3 are repeated, etc.

[3,algorithm,
[
[[input,[['A',[1]],['B',[2]]]],[output,[['C',[1]]]]],
[[input,[['A',[3]],['B',[4]]]],[output,[['C',[3]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[['C1'],['C2'],[output,[['C1']]]]],[[[[1,1,1],[[1,1]]]]],In_vars,Out_var)."
],

[4,algorithm,
[
[[input,[['A',[[1]]],['B',[[2]]]]],[output,[['C',[[1,[]]]]]]],
[[input,[['A',[[3]]],['B',[[4]]]]],[output,[['C',[[3,[]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",'C1',\"]\"],[\"[\",'C2',\"]\"],[output,[[\"[\",'C1',\"[\",\"]\",\"]\"]]]]],[[[[1,1,2],[[1,2]]]]],In_vars,Out_var)."
],

[5,algorithm,
[
[[input,[['A',[1,3]],['B',[2,3]]]],[output,[['C',[3]]]]],
[[input,[['A',[4,3]],['B',[5,3]]]],[output,[['C',[3]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[['C1',3],['C2',3],[output,[[3]]]]],[[]],In_vars,Out_var)."
],

% The value 3, rather than a variable is used because variations were not detected.

[6,algorithm,
[
[[input,[['A',[[1]]],['B',[[2]]]]],[output,[['C',[[1,[[]]]]]]]],
[[input,[['A',[[3]]],['B',[[4]]]]],[output,[['C',[[3,[[]]]]]]]]
% [[]] not [] at end
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",'C1',\"]\"],[\"[\",'C2',\"]\"],[output,[[\"[\",'C1',\"[\",\"[\",\"]\",\"]\",\"]\"]]]]],[[[[1,1,2],[[1,2]]]]],In_vars,Out_var)."
],

[7,algorithm,
[
[[input,[['A',[[1]]],['B',[[2]]]]],[output,[['C',[[1]]]]]],
[[input,[['A',[[3]]],['B',[[4]]]]],[output,[['C',[[3]]]]]],
[[input,[['A',[[1,3]]],['B',[[1,4]]]]],[output,[['C',[[1]]]]]],
[[input,[['A',[[1,3]]],['B',[[1,4]]]]],[output,[['C',[[3]]]]]] % separate outputs for find_constants, even though the inputs ((1,3),(1,4))=((1,3),(1,4))
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[nd,[[[\"[\",1,3,\"]\"],[\"[\",1,4,\"]\"],[nd,[[[output,[[\"[\",1,\"]\"]]]],[[output,[[\"[\",3,\"]\"]]]]]]],[[\"[\",'C1',\"]\"],[\"[\",'C2',\"]\"],[output,[[\"[\",'C1',\"]\"]]]]]]],[[],[],[[[1,1,2],[[1,2]]]]],In_vars,Out_var)."
],

% nd=non-deterministic and means that A,B and C in nd(A,B,C) are different cases. nd([1],[3]) in output means the same input can have multiple outputs.

[8,algorithm,
[
[[input,[['A',[[1]]],['B',[[2]]]]],[output,[['C',[[1]]]]]],
[[input,[['A',[[3]]],['B',[[4]]]]],[output,[['C',[[3]]]]]],
[[input,[['A',[[1,1,1]]],['B',[[1,1,2]]]]],[output,[['C',[[1]]]]]],
[[input,[['A',[[1,1,3]]],['B',[[1,1,4]]]]],[output,[['C',[[3]]]]]],
[[input,[['A',[[1,3]]],['B',[[1,4]]]]],[output,[['C',[[1,3]]]]]],
[[input,[['A',[[1,3]]],['B',[[1,4]]]]],[output,[['C',[[1,3]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[nd,[[[\"[\",1,3,\"]\"],[\"[\",1,4,\"]\"],[output,[[\"[\",1,3,\"]\"]]]],[[\"[\",'C1',\"]\"],[\"[\",'C2',\"]\"],[output,[[\"[\",'C1',\"]\"]]]],[[\"[\",['&r',[1]],3,\"]\"],[\"[\",['&r',[1]],4,\"]\"],[output,[[\"[\",3,\"]\"]]]],[[\"[\",['&r',[1]],\"]\"],[\"[\",['&r',[1]],2,\"]\"],[output,[[\"[\",1,\"]\"]]]]]]],[[[[1,1,2],[[1,2]]]],[],[],[],[]],In_vars,Out_var)."
],
% nd splits the decision tree at each point. 

[9,algorithm,
[
[[input,[['A',[11,aa]],['B',["B",aa]]]],[output,[['C',[a1]]]]],
[[input,[['A',[44,aa]],['B',["C",aa]]]],[output,[['C',[a4]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[[number,[['&r',['C1']]]],[atom,[['&r',[\"a\"]]]]],[[string,['C2']],[atom,[['&r',[\"a\"]]]]],[output,[[[atom,[\"a\",'C1']]]]]]],[[[[1,1,1,2,2,1],[[1,2,2]]]]],In_vars,Out_var)."
],

[10,algorithm,
[
[[input,[['A',[1,2]],['B',[3,2]]]],[output,[['C',[2]]]]],
[[input,[['A',[4,2]],['B',[5,2]]]],[output,[['C',[2]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[[number,['C1']],[number,[\"2\"]]],[[number,['C2']],[number,[\"2\"]]],[output,[[[number,[\"2\"]]]]]]],[[]],In_vars,Out_var)."
],

[11,algorithm,
[
[[input,[['A',[[["aa,]",b,"c",[]],1]]]]],[output,[['B',["aa,]",b]]]]],
[[input,[['A',[[["cc,]",d,"e",[]],1]]]]],[output,[['B',["cc,]",d]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",\"[\",'C1','C2','C3',\"[\",\"]\",\"]\",1,\"]\"],[output,[['C1','C2']]]]],[[[[1,3],[[1,1]]],[[1,4],[[1,2]]]]],In_vars,Out_var)."
],
% doesn't work with nested brackets in output yet
% can work with multiple specs to form variables and constants
% doesn't convert characters from upper to lower yet

[12,algorithm,
[
[[input,[['A',[a,is,1,"+",1]]]],[output,[['B',[
[[n,"+"],[1,1,[v,a]]]]]]]],
[[input,[['A',[b,is,3,"+",4]]]],[output,[['B',[
[[n,"+"],[3,4,[v,b]]]]]]]],
[[input,[['A',[a,is,1,"-",1]]]],[output,[['B',[
[[n,"-"],[1,1,[v,a]]]]]]]],
[[input,[['A',[b,is,3,"-",4]]]],[output,[['B',[
[[n,"-"],[3,4,[v,b]]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[['C1',is,'C2','C3','C4'],[output,[[\"[\",\"[\",n,'C3',\"]\",\"[\",'C2','C4',\"[\",v,'C1',\"]\",\"]\",\"]\"]]]]],[[[[1,1],[[1,11]]],[[1,3],[[1,7]]],[[1,4],[[1,4]]],[[1,5],[[1,8]]]]],In_vars,Out_var)."

],
% actually a converter
% decision trees as the alg being converted, recursion with series of decision trees in DFA
% can't recognise upper and lower case as the same character yet

[13,algorithm,
[
[[input,[['A',[1,2]]]],[output,[['B',[21]]]]], [[input,[['A',[3,4]]]],[output,[['B',[43]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[[number,['C1']],[number,['C2']]],[output,[[[number,['C2','C1']]]]]]],[[[[1,1,2,1],[[1,2,2]]],[[1,2,2,1],[[1,2,1]]]]],In_vars,Out_var)."
],

[14,algorithm,
[
[[input,[['A',[1+2]]]],[output,[['B',[21]]]]], [[input,[['A',[3+4]]]],[output,[['B',[43]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[[compound,['C1',\"+\",'C2']]],[output,[[[number,['C2','C1']]]]]]],[[[[1,2,1],[[1,2,2]]],[[1,2,3],[[1,2,1]]]]],In_vars,Out_var)."
],

[15,algorithm,
[
[[input,[['A',["1+2"]]]],[output,[['B',[21]]]]], [[input,[['A',["3+4"]]]],[output,[['B',[43]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[[string,['C1',\"+\",'C2']]],[output,[[[number,['C2','C1']]]]]]],[[[[1,2,1],[[1,2,2]]],[[1,2,3],[[1,2,1]]]]],In_vars,Out_var)."
],


[16,algorithm,
[
[[input,[['A',"Ci"]]],[output,[['B','C']]]],
[[input,[['A',"Di"]]],[output,[['B','D']]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[string,['C1',\"i\"]],[output,[[atom,['C1']]]]]],[[[[1,2,1],[[1,2,1]]]]],In_vars,Out_var)."
],


[17,algorithm,
[
[[input,[['A',["A is 1+2,B is A+3."]]]],[output,[['B',[[[+,[1,2,[lower,["A"]]]],[+,[[lower,["A"]],3,[lower,["B"]]]]]]]]]],
[[input,[['A',["C is 3+4,D is C+3."]]]],[output,[['B',[[[+,[3,4,[lower,["C"]]]],[+,[[lower,["C"]],3,[lower,["D"]]]]]]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[[string,['C1',\" \",\"i\",\"s\",\" \",'C2',\"+\",'C3',\",\",'C4',\" \",\"i\",\"s\",\" \",'C1',\"+\",\"3\",\".\"]]],[output,[[\"[\",\"[\",[atom,[\"+\"]],\"[\",[number,['C2']],[number,['C3']],\"[\",[atom,[\"l\",\"o\",\"w\",\"e\",\"r\"]],\"[\",[string,['C1']],\"]\",\"]\",\"]\",\"]\",\"[\",[atom,[\"+\"]],\"[\",\"[\",[atom,[\"l\",\"o\",\"w\",\"e\",\"r\"]],\"[\",[string,['C1']],\"]\",\"]\",[number,[\"3\"]],\"[\",[atom,[\"l\",\"o\",\"w\",\"e\",\"r\"]],\"[\",[string,['C4']],\"]\",\"]\",\"]\",\"]\",\"]\"]]]]],[[[[1,2,1],[[1,10,2,1],[1,21,2,1]]],[[1,2,6],[[1,5,2,1]]],[[1,2,8],[[1,6,2,1]]],[[1,2,10],[[1,28,2,1]]],[[1,2,15],[[1,10,2,1],[1,21,2,1]]]]],In_vars,Out_var)."
],

[18,algorithm,
[
[[input,[['A',"1232312323"]]],[output,[['B',"2"]]]],
[[input,[['A',"1434314343"]]],[output,[['B',"4"]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[string,[['&r',[\"1\",['&r',['C1',\"3\"]]]]]],[output,[[string,['C1']]]]]],[[[[1,2,2,2,2,1],[[1,2,1]]]]],In_vars,Out_var)."
],

[19,algorithm,
[
[[input,[['A',"2"]]],[output,[['B',[2,2]]]]],
[[input,[['A',"4"]]],[output,[['B',[4,4]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[string,['C1']],[output,[[[number,['C1']],[number,['C1']]]]]]],[[[[1,2,1],[[1,1,2,1],[1,2,2,1]]]]],In_vars,Out_var)."
],

[20,algorithm,
[
[[input,[['A',"2"]]],[output,[['B',"22"]]]],
[[input,[['A',"4"]]],[output,[['B',"44"]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[string,['C1']],[output,[[string,['C1','C1']]]]]],[[[[1,2,1],[[1,2,1],[1,2,2]]]]],In_vars,Out_var)."
],

[21,algorithm,
[
[[input,[['A',["2",'A1']]]],[output,[['B',["22",'A1']]]]],
[[input,[['A',["4",'A1']]]],[output,[['B',["44",'A1']]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[[string,['C1']],'A1'],[output,[[[string,['C1','C1']],'A1']]]]],[[[[1,1,2,1],[[1,1,2,1],[1,1,2,2]]],[[1,2],[[1,2]]]]],In_vars,Out_var)."
],

% A1 with & in strings
% A1 or AA11
% A1 doesn't merge in two specs
% need 1 training, 1 testing spec
% formulas such as [var,_]

% parse
[22,algorithm,
[
[[input,[['A',"C is A+B"]]],[output,[['B',[[n,+],[[v,[downcase,"A"]],[v,[downcase,"B"]],[v,[downcase,"C"]]]]]]]],
[[input,[['A',"D is E+F"]]],[output,[['B',[[n,+],[[v,[downcase,"E"]],[v,[downcase,"F"]],[v,[downcase,"D"]]]]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[string,['C1',\" \",\"i\",\"s\",\" \",'C2',\"+\",'C3']],[output,[[\"[\",[atom,[\"n\"]],[atom,[\"+\"]],\"]\",\"[\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C2']],\"]\",\"]\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C3']],\"]\",\"]\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C1']],\"]\",\"]\",\"]\"]]]]],[[[[1,2,1],[[1,24,2,1]]],[[1,2,6],[[1,10,2,1]]],[[1,2,8],[[1,17,2,1]]]]],In_vars,Out_var)."
],

% produce the abstract syntax tree
[23,algorithm,
[
[[input,[['A',"C is A+B"]]],[output,[['B',[[n, assign],[[v,[downcase,"C"]],[[n,+],[[v,[downcase,"A"]],[v,[downcase,"B"]]]]]]]]]],
[[input,[['A',"D is E+F"]]],[output,[['B',[[n, assign],[[v,[downcase,"D"]],[[n,+],[[v,[downcase,"E"]],[v,[downcase,"F"]]]]]]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[string,['C1',\" \",\"i\",\"s\",\" \",'C2',\"+\",'C3']],[output,[[\"[\",[atom,[\"n\"]],[atom,[\"a\",\"s\",\"s\",\"i\",\"g\",\"n\"]],\"]\",\"[\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C1']],\"]\",\"]\",\"[\",\"[\",[atom,[\"n\"]],[atom,[\"+\"]],\"]\",\"[\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C2']],\"]\",\"]\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C3']],\"]\",\"]\",\"]\",\"]\",\"]\"]]]]],[[[[1,2,1],[[1,10,2,1]]],[[1,2,6],[[1,23,2,1]]],[[1,2,8],[[1,30,2,1]]]]],In_vars,Out_var)."
],

% translate
[24,algorithm,
[
[[input,[['A',"C is A-B"]]],[output,[['B',[[n,-],[[v,[downcase,"A"]],[v,[downcase,"B"]],[v,[downcase,"C"]]]]]]]],
[[input,[['A',"D is E-F"]]],[output,[['B',[[n,-],[[v,[downcase,"E"]],[v,[downcase,"F"]],[v,[downcase,"D"]]]]]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[string,['C1',\" \",\"i\",\"s\",\" \",'C2',\"-\",'C3']],[output,[[\"[\",[atom,[\"n\"]],[atom,[\"-\"]],\"]\",\"[\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C2']],\"]\",\"]\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C3']],\"]\",\"]\",\"[\",[atom,[\"v\"]],\"[\",[atom,[\"d\",\"o\",\"w\",\"n\",\"c\",\"a\",\"s\",\"e\"]],[string,['C1']],\"]\",\"]\",\"]\"]]]]],[[[[1,2,1],[[1,24,2,1]]],[[1,2,6],[[1,10,2,1]]],[[1,2,8],[[1,17,2,1]]]]],In_vars,Out_var)."
],


% split on "[", "]", (",") rec'ly do nested brackets
% - () turn [a,b,c] into [a,[b,[c]]]
% split on delimiters in strings incl " " ,;.()[]
% label [split,_]
% [,]+[,]=[,,,]
% ['&r',['&r',a]]=['&r',a]

% debug




[25,algorithm,
[
[[input,[['A',["A","B",[+,["A","B"]]]]]],[output,[['B',"C is A+B"]]]],
[[input,[['A',["E","F",[+,["E","F"]]]]]],[output,[['B',"C is E+F"]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[[string,['C1']],[string,['C2']],\"[\",[atom,[\"+\"]],\"[\",[string,['C1']],[string,['C2']],\"]\",\"]\"],[output,[[string,[\"C\",\" \",\"i\",\"s\",\" \",'C1',\"+\",'C2']]]]]],[[[[1,1,2,1],[[1,2,6]]],[[1,2,2,1],[[1,2,8]]],[[1,6,2,1],[[1,2,6]]],[[1,7,2,1],[[1,2,8]]]]],In_vars,Out_var)."
]

,
[26,algorithm,
[
[[input,[['A',[[n,=],[[v,a],[v,b],[v,c]]]]]],[output,[['B',[[n,+],[[v,a],[v,b],[v,c]]]]]]],
[[input,[['A',[[n,=],[[v,e],[v,f],[v,d]]]]]],[output,[['B',[[n,+],[[v,e],[v,f],[v,d]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",n,=,\"]\",\"[\",\"[\",v,'C1',\"]\",\"[\",v,'C2',\"]\",\"[\",v,'C3',\"]\",\"]\"],[output,[[\"[\",n,+,\"]\",\"[\",\"[\",v,'C1',\"]\",\"[\",v,'C2',\"]\",\"[\",v,'C3',\"]\",\"]\"]]]]],[[[[1,8],[[1,8]]],[[1,12],[[1,12]]],[[1,16],[[1,16]]]]],In_vars,Out_var)."
],

% optimise
[27,algorithm,
[
[[input,[['A',[[[n,+],[[v,a],[v,b],[v,c]]],[[n,=],[[v,c],[v,d]]]]]]],[output,[['B',[[n,+],[[v,a],[v,b],[v,d]]]]]]],
[[input,[['A',[[[n,+],[[v,e],[v,f],[v,g]]],[[n,=],[[v,g],[v,h]]]]]]],[output,[['B',[[n,+],[[v,e],[v,f],[v,h]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",\"[\",n,+,\"]\",\"[\",\"[\",v,'C1',\"]\",\"[\",v,'C2',\"]\",\"[\",v,'C3',\"]\",\"]\",\"]\",\"[\",\"[\",n,=,\"]\",\"[\",\"[\",v,'C3',\"]\",\"[\",v,'C4',\"]\",\"]\",\"]\"],[output,[[\"[\",n,+,\"]\",\"[\",\"[\",v,'C1',\"]\",\"[\",v,'C2',\"]\",\"[\",v,'C4',\"]\",\"]\"]]]]],[[[[1,9],[[1,8]]],[[1,13],[[1,12]]],[[1,33],[[1,16]]]]],In_vars,Out_var)."
],

[28,algorithm,
[
[[input,[['A',[[[n,=],[[v,a],[v,b]]],[[n,=],[[v,b],[v,c]]]]]]],[output,[['B',[[n,=],[[v,a],[v,c]]]]]]],
[[input,[['A',[[[n,=],[[v,e],[v,f]]],[[n,=],[[v,f],[v,g]]]]]]],[output,[['B',[[n,=],[[v,e],[v,g]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",\"[\",n,=,\"]\",\"[\",\"[\",v,'C1',\"]\",\"[\",v,'C2',\"]\",\"]\",\"]\",\"[\",\"[\",n,=,\"]\",\"[\",\"[\",v,'C2',\"]\",\"[\",v,'C3',\"]\",\"]\",\"]\"],[output,[[\"[\",n,=,\"]\",\"[\",\"[\",v,'C1',\"]\",\"[\",v,'C3',\"]\",\"]\"]]]]],[[[[1,9],[[1,8]]],[[1,29],[[1,12]]]]],In_vars,Out_var)."
],

% spreadsheet formula finder
[29,algorithm,
[
[[input,[['A',[["","Jan","Feb","TOTAL"],["$","1","2",[+,["1","2"]]]]]]],[output,[['B',[["","January","February","TOTAL"],["$","A","B",[+,["A","B"]]]]]]]],
[[input,[['A',[["","Jan","Feb","TOTAL"],["$","2","3",[+,["2","3"]]]]]]],[output,[['B',[["","January","February","TOTAL"],["$","A","B",[+,["A","B"]]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",\"\",\"Jan\",\"Feb\",\"TOTAL\",\"]\",\"[\",\"$\",'C1','C2',\"[\",+,\"[\",'C1','C2',\"]\",\"]\",\"]\"],[output,[[\"[\",\"\",\"January\",\"February\",\"TOTAL\",\"]\",\"[\",\"$\",\"A\",\"B\",\"[\",+,\"[\",\"A\",\"B\",\"]\",\"]\",\"]\"]]]]],[[]],In_vars,Out_var)."
],


% ssff 1+2->sum
[30,algorithm,
[
[[input,[['A',[["","Month1","Month2","TOTAL"],["$","1","2",[+,["1","2"]]]]]]],[output,[['B',[["","Month1","Month2","TOTAL"],["$",a,a,[month_sum,[a]]]]]]]],
[[input,[['A',[["","Month1","Month2","Month3","TOTAL"],["$","3","4","5",[+,["3","4","5"]]]]]]],[output,[['B',[["","Month1","Month2","Month3","TOTAL"],["$",a,a,a,[month_sum,[a]]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[nd,[[[\"[\",\"\",\"Month1\",\"Month2\",\"Month3\",\"TOTAL\",\"]\",\"[\",\"$\",\"3\",\"4\",\"5\",\"[\",+,\"[\",\"3\",\"4\",\"5\",\"]\",\"]\",\"]\"],[output,[[\"[\",\"\",\"Month1\",\"Month2\",\"Month3\",\"TOTAL\",\"]\",\"[\",\"$\",a,a,a,\"[\",month_sum,\"[\",a,\"]\",\"]\",\"]\"]]]],[[\"[\",\"\",\"Month1\",\"Month2\",\"TOTAL\",\"]\",\"[\",\"$\",\"1\",\"2\",\"[\",+,\"[\",\"1\",\"2\",\"]\",\"]\",\"]\"],[output,[[\"[\",\"\",\"Month1\",\"Month2\",\"TOTAL\",\"]\",\"[\",\"$\",a,a,\"[\",month_sum,\"[\",a,\"]\",\"]\",\"]\"]]]]]]],[[],[]],In_vars,Out_var)."
],

% to form CFG, separate grammars to be compared, group by type instead of same character in test 30

% ssff sum->compressed
[32,algorithm,
[
[[input,[['A',[["","Month","Month","TOTAL"],["$",a,a,[month_sum,[a]]]]]]],[output,[['B',[["","Month","TOTAL"],["$",a,[month_sum,[a]]]]]]]],
[[input,[['A',[["","Month","Month","TOTAL"],["$",a,a,a,[month_sum,[a]]]]]]],[output,[['B',[["","Month","TOTAL"],["$",a,[month_sum,[a]]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",\"\",['&r',[\"Month\"]],\"TOTAL\",\"]\",\"[\",\"$\",['&r',[a]],\"[\",month_sum,\"[\",a,\"]\",\"]\",\"]\"],[output,[[\"[\",\"\",\"Month\",\"TOTAL\",\"]\",\"[\",\"$\",a,\"[\",month_sum,\"[\",a,\"]\",\"]\",\"]\"]]]]],[[],[]],In_vars,Out_var)."
],


% ssff sum->compressed vertical
[33,algorithm,
[
[[input,[['A',[["","Month"],["$",a],["TOTAL",[vertical_month_sum,[a]]]]]]],[output,[['B',[["","Month"],["$",a],["TOTAL",[vertical_month_sum,[a]]]]]]]],
[[input,[['A',[["","Month"],["$",a],["$",a],["TOTAL",[vertical_month_sum,[a]]]]]]],[output,[['B',[["","Month"],["$",a],["$",a],["$",a],["TOTAL",[vertical_month_sum,[a]]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[nd,[[[\"[\",\"\",\"Month\",\"]\",\"[\",\"$\",a,\"]\",\"[\",\"TOTAL\",\"[\",vertical_month_sum,\"[\",a,\"]\",\"]\",\"]\"],[output,[[\"[\",\"\",\"Month\",\"]\",\"[\",\"$\",a,\"]\",\"[\",\"TOTAL\",\"[\",vertical_month_sum,\"[\",a,\"]\",\"]\",\"]\"]]]],[[\"[\",\"\",\"Month\",\"]\",['&r',[\"[\",\"$\",a,\"]\"]],\"[\",\"TOTAL\",\"[\",vertical_month_sum,\"[\",a,\"]\",\"]\",\"]\"],[output,[[\"[\",\"\",\"Month\",\"]\",\"[\",\"$\",a,\"]\",\"[\",\"$\",a,\"]\",\"[\",\"$\",a,\"]\",\"[\",\"TOTAL\",\"[\",vertical_month_sum,\"[\",a,\"]\",\"]\",\"]\"]]]]]]],[[],[]],In_vars,Out_var)."
],

% ssff sum->compressed horizontal, vertical
[34,algorithm,
[
[[input,[['A',[["","Month","Month","TOTAL"],["$",a,a,[month_sum,[a]]],["$",a,a,[month_sum,[a]]],["TOTAL",[vertical_month_sum,[a]],[vertical_month_sum,[a]],[vertical_month_sum,[month_sum,[a]]]]]]]],[output,[['B',[["","Month","TOTAL"],["$",a,[month_sum,[a]]],["TOTAL",[vertical_month_sum,[a]],[vertical_month_sum,[month_sum,[a]]]]]]]]],
[[input,[['A',[["","Month","Month","Month","TOTAL"],["$",a,a,a,[month_sum,[a]]],["$",a,a,a,[month_sum,[a]]],["$",a,a,a,[month_sum,[a]]],["TOTAL",[vertical_month_sum,[a]],[vertical_month_sum,[a]],[vertical_month_sum,[a]],[vertical_month_sum,[month_sum,[a]]]]]]]],[output,[['B',[["","Month","TOTAL"],["$",a,[month_sum,[a]]],["TOTAL",[vertical_month_sum,[a]],[vertical_month_sum,[month_sum,[a]]]]]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",\"\",['&r',[\"Month\"]],\"TOTAL\",\"]\",['&r',[\"[\",\"$\",['&r',[a]],\"[\",month_sum,\"[\",a,\"]\",\"]\",\"]\"]],\"[\",\"TOTAL\",['&r',[\"[\",vertical_month_sum,\"[\",a,\"]\",\"]\"]],\"[\",vertical_month_sum,\"[\",month_sum,\"[\",a,\"]\",\"]\",\"]\",\"]\"],[output,[[\"[\",\"\",\"Month\",\"TOTAL\",\"]\",\"[\",\"$\",a,\"[\",month_sum,\"[\",a,\"]\",\"]\",\"]\",\"[\",\"TOTAL\",\"[\",vertical_month_sum,\"[\",a,\"]\",\"]\",\"[\",vertical_month_sum,\"[\",month_sum,\"[\",a,\"]\",\"]\",\"]\",\"]\"]]]]],[[],[]],In_vars,Out_var)."
],

% starlog sum (...,S) or S=sum(..)
% r Month where Month becomes variable when in two specs or ds x a variable - in this case a new variable each time it is used as an instance ie nv a_n...m, a_n..m,p..q where n..m usually replaced with a constant (maybe a hidden row number xx use vars n,m,p,q, x given by a_1..m, where these can be referenced using a_1,2 etc.)
% m is determined by the data length
% month to val, subtract first month val from each+1, or leave
% only need a hidden row number if it is needed - need it anyway - this increases from 1..m x just 1..m
%parse this 
% 'CX,1,2,...' as var format
% 'C2_Y' is sum 'C_1..m_1..n_...'
% total
% possibly decreasing counters

[35,algorithm,
[
[[input,[['A',[["a","b","a","b","a"]]]]],[output,[['B',["a"]]]]],
[[input,[['A',[["c","b","c","b","c","b","c"]]]]],[output,[['B',["c"]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",'C1',['&r',[\"b\",'C1']],\"]\"],[output,[['C1']]]]],[[[[1,2],[[1,1]]],[[1,3,2,2],[[1,1]]]]],In_vars,Out_var)."
],


[36,algorithm,
[
[[input,[['A',"1232312323,1232312323"]]],[output,[['B',"1"]]]]
],
character_breakdown_mode=on,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[string,[['&r',[\"1\",['&r',[\"2\",\"3\"]]]],\",\",['&r',[\"1\",['&r',[\"2\",\"3\"]]]]]],[output,[[string,[\"1\"]]]]]],[[]],In_vars,Out_var)."
],

[37,algorithm,

[
[[input,[['A',[["fulfilled", "plus"], ["fulfilled", "plus"], ["fulfilled", "plus"], ["disadvantages", "minus"], ["fulfilled", "plus"]]]]],[output,[['B',success]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[['&r',[\"[\",\"fulfilled\",\"plus\",\"]\"]],\"[\",\"disadvantages\",\"minus\",\"]\",\"[\",\"fulfilled\",\"plus\",\"]\"],[output,[success]]]],[[]],In_vars,Out_var)."
],


[38,algorithm,
[
[[input,[['A',[11,22,33,22,33,11,22,33,22,33]%,11,22,33,22,33,11,22,33,22,33"
]]],[output,[['B',[11]]]]],
[[input,[['A',[41,42,43,42,43,41,42,43,42,43]%,41,42,43,42,43,41,42,43,42,43"
]]],[output,[['B',[41]]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[['&r',['C1',['&r',['C2','C3']]]]],[output,[['C1']]]]],[[[[1,2,1],[[1,1]]]]],In_vars,Out_var)."
]
,


[39,algorithm,
[
[[input,[['A',[['&r',['C1',['&r',['C2',['&r',['C3','C4']]]]]]]%,11,22,33,22,33,11,22,33,22,33"
]]],[output,[['B',['C1']]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",'&r',\"[\",'C1',\"[\",'&r',\"[\",'C2',\"[\",'&r',\"[\",'C3','C4',\"]\",\"]\",\"]\",\"]\",\"]\",\"]\"],[output,[['C1']]]]],[[[[1,4],[[1,1]]]]],In_vars,Out_var)."
]
,


[40,algorithm,
[
[[input,[['A',[['&r',['C1',['&r',['C2',['&r',['C3',[11,22,33,22,33,11,22,33,22,33]]]]]]]]
]]],[output,[['B',['C1']]]]]
],
character_breakdown_mode=off,
"algorithm(In_vars,Out_var) :-\nalgorithm([[[\"[\",'&r',\"[\",'C1',\"[\",'&r',\"[\",'C2',\"[\",'&r',\"[\",'C3',\"[\",['&r',[11,['&r',[22,33]]]],\"]\",\"]\",\"]\",\"]\",\"]\",\"]\",\"]\"],[output,[['C1']]]]],[[[[1,4],[[1,1]]]]],In_vars,Out_var)."
]


]).

test_spec_to_algorithm1(N) :-
/*
	retractall(num_s2a(_)),
	assertz(num_s2a(1)),

	retractall(vars_s2a(_)),
	assertz(vars_s2a([])),

	retractall(vars_base_s2a(_)),
	assertz(vars_base_s2a('A')),
*/
	(catch(algs(Algs),_,false)->
	findall(_,(member(Alg,Algs),
	retractall(algs(Alg))),_);
	true),
	retractall(algs(_)),
	assertz(algs([])),

s2a_tests(Tests),
member([N,Predicate_name,S,
character_breakdown_mode=CBM,Alg2],
Tests),

	
	
((	%retractall(test_n(_)),
	%assertz(test_n(N)),

	string_concat(Predicate_name,N,Predicate_name1),
	%catch(call_with_time_limit(10,
	(spec_to_algorithm(Predicate_name1,S,CBM,Alg1))
	%)%,
    %time_limit_exceeded,
    %fail)

,writeln1(S)
,writeln1(Alg1)
%,trace

,string_concat(Predicate_name,Rest,Alg2),
string_concat(Predicate_name1,Rest,Alg21)
,Alg21=Alg1
)->R=success;R=fail),
 writeln([R,N,spec_to_algorithm,test]),
 
 writeln([Predicate_name1,not,Predicate_name,above]),!.

/*

Necessary to load before running s2a each time:

retractall(vars_table_s2a(_)),                                               assertz(vars_table_s2a([])),                                                    ['spec_to_algorithm'].
*/

test_spec_to_algorithm :-
/*
	retractall(num_s2a(_)),
	assertz(num_s2a(1)),

	retractall(vars_s2a(_)),
	assertz(vars_s2a([])),

	retractall(vars_base_s2a(_)),
	assertz(vars_base_s2a('A')),
*/
	(catch(algs(Algs),_,false)->
	findall(_,(member(Alg,Algs),
	retractall(algs(Alg))),_);
	true),
	retractall(algs(_)),
	assertz(algs([])),

s2a_tests(Tests),

findall([N,R],(member([N,Predicate_name,S,
character_breakdown_mode=CBM,Alg2],
Tests),

	
	
((	%retractall(test_n(_)),
	%assertz(test_n(N)),

	string_concat(Predicate_name,N,Predicate_name1),
	%catch(call_with_time_limit(10,
	(spec_to_algorithm(Predicate_name1,S,CBM,Alg1))
	%)%,
    %time_limit_exceeded,
    %fail)

%,writeln1(S)
%,writeln1(Alg1)
%,trace

,string_concat(Predicate_name,Rest,Alg2),
string_concat(Predicate_name1,Rest,Alg21)
,Alg21=Alg1
)->R=success;R=fail),
 writeln([R,N,spec_to_algorithm,test]),
 nl),R1),
 findall(N,member([N,success],R1),R_success),
 writeln("Successful Tests:"),
 writeln(R_success),
 findall(N,member([N,fail],R1),R_fail),
 writeln("Failed Tests:"),
 writeln(R_fail),!.


