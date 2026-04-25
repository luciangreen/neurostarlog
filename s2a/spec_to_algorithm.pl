% swipl --goal=test_s2a --stand_alone=true -o s2a --stand_alone=true -c spec_to_algorithm.pl
% ./s2a

:-set_prolog_flag(stack_limit, 50000000000).

:-include('auxiliary_s2a_used.pl').
:-include('spec_to_algorithm_test.pl').
%:-include('process_terms_s2a.pl').

:-dynamic num_s2a/1.
:-dynamic vars_s2a/1.
:-dynamic vars_base_s2a/1.
:-dynamic vars_table_s2a/1.
:-dynamic optional_s2g/1.
:-dynamic character_breakdown_mode/1.
:-dynamic single_results/1.
:-dynamic san_no_rs/1.
:-dynamic rec_join_n/1.
:-dynamic rec_join_vars/1.
:-dynamic algs/1.
:-dynamic tmp_join_n/1.
%:-dynamic ampersand_var_n_s2a/1.

% spec_to_algorithm([[['A',[1,3]]],[['B',[1,2]]]],A)
% A = 

% Spec = [[nd,[1,2]],[nd,[3,4]]]
% => Spec [f1,f2]

% don't have ^^ x need for strings
% error checking


spec_to_algorithm(Predicate_name,S0,CBM,Alg) :-

	%retractall(san_no_rs(_)),
	%assertz(san_no_rs(false)),

	retractall(single_results(_)),
	assertz(single_results([])),

	retractall(character_breakdown_mode(_)),
	assertz(character_breakdown_mode(CBM)),

	retractall(optional_s2g(_)),
	assertz(optional_s2g(off)),

	retractall(num_s2a(_)),
	assertz(num_s2a(1)),

	retractall(vars_s2a(_)),
	assertz(vars_s2a([])),

	retractall(vars_base_s2a(_)),
	assertz(vars_base_s2a('A')),
	
	retractall(vars_table_s2a(_)),
	assertz(vars_table_s2a([])),

	%retractall(ampersand_var_n_s2a(_)),
	%assertz(ampersand_var_n_s2a(1)),
	
	% find recursive structures in each spec
	% find constants, unique variables across specs
	% - at same time as finding recursive structures
	%   because need to check whether are constants,
	%   unique variables x uv before, c after
	%   (same value across specs)

	% * change input term - leave as is
	%trace,	
	%findall(RS2,(member(S1,S),
	
	%find_unique_variables(S1,UV),
	%trace,
	%trace,
findall(T1,(member([[input,In2],[output,Out2]],S0),
	findall([A000,[A00]],member([A000,A00],In2),
	%trace,
	%remove_first_and_last_items(A00,A01)),%A00=["[",A01,"]"])
	In24),
	findall([A000,[A00]],member([A000,A00],Out2),%remove_first_and_last_items(A00,A01)),%=["[",A01,"]"])
	Out24),
	foldr(append,[[[input,In24]],[[output,Out24]]],T1)),S),

	findall([[input,Input1],[output,Output1]],(member([[input,Input],[output,Output]],S),
	findall([S10,RS],(member([S10,S11],Input),
	%(string(S11)->string_strings(S11,S12);S11=S12),
	%trace,
	%length(S11,S11L),
	%(S11L=1->true;(writeln(["Error: Variable",S10,"doesn't have length one."]),abort)),
	%trace,
	characterise1(S11,S12),
	%trace,
	strings_atoms_numbers(S12,S13,rs=on),
	term_to_brackets(S13,S14,split=on),
	find_lists3b(S14,RS)
	),Input1),
	findall([S10,RS],(member([S10,S11],Output),
	%length(S11,S11L),
	%(S11L=1->true;(writeln(["Error: Variable",S10,"doesn't have length one."]),abort)),	
	%(string(S11)->string_strings(S11,S12);S11=S12),
	characterise1(S11,S12),
	strings_atoms_numbers(S12,S13,rs=off),
	term_to_brackets(S13,S14,split=off),
	%find_lists3b(S14,RS)
	S14=RS
	),Output1)	
	%change_var_base
	%),RS2)
	),RS10),
	
	/*findall(RS2,(member(S1,OS),
	
	%find_unique_variables(S1,UV),
	findall([S10,RS],(member([S10,S11],S1),
	(string(S11)->string_strings(S11,S12);S11=S12),
	find_lists3b(S12,RS)
	),RS2)
	%change_var_base
	),ORS10),*/

	%findall(RS2,(member(S1,S),
	
	%find_unique_variables(S1,UV),
	
	%trace,
	

	(character_breakdown_mode(off)->
		findall([[input,Input1],[output,Output1]],(member([[input,Input],[output,Output]],S),
		
	%find_unique_variables(Input,UV),
	findall([UV1,RS],(member([UV1,UV2],Input),
	%(string(UV2)->string_strings(UV2,UV3);UV2=UV3),
	characterise1(UV2,UV3),
	strings_atoms_numbers(UV3,UV31,rs=on),
	term_to_brackets(UV31,UV4,split=on),
	find_lists3b(UV4,RS)
	),Input1),
	%find_unique_variables(Output,UVo),
	findall([UV1,RS],(member([UV1,UV2],Output),
	%(string(UV2)->string_strings(UV2,UV3);UV2=UV3),
	characterise1(UV2,UV3),
	strings_atoms_numbers(UV3,UV31,rs=off),
	term_to_brackets(UV31,UV4,split=off),
	%find_lists3b(UV4,RS)
	UV4=RS
	),Output1)
	%change_var_base
	%),RS2),
	),RS1);
	findall([[input,Input1],[output,Output1]],(member([[input,Input],[output,Output]],S),
		
	%find_unique_variables(Input,UV),
	findall([UV1,RS],(member([UV1,UV2],Input),
	%(string(UV2)->string_strings(UV2,UV3);UV2=UV3),
	characterise1(UV2,UV3),
	strings_atoms_numbers(UV3,UV32,rs=on),
	%find_unique_variables(UV31,UV32),	
	term_to_brackets(UV32,UV4,split=on),
	find_lists3b(UV4,RS)
	),Input1),
	%find_unique_variables(Output,UVo),
	findall([UV1,RS],(member([UV1,UV2],Output),
	%(string(UV2)->string_strings(UV2,UV3);UV2=UV3),
	characterise1(UV2,UV3),
	strings_atoms_numbers(UV3,UV32,rs=off),
	%find_unique_variables(UV31,UV32),		
	term_to_brackets(UV32,UV4,split=off),
	%find_lists3b(UV4,RS)
	UV4=RS
	),Output1)
	%change_var_base
	%),RS2),
	),RS1)),
	
	/*findall(RS2,(member(S1,OS),
	
	
	find_unique_variables(S1,UV),
	findall([UV1,RS],(member([UV1,UV2],UV),
	(string(UV2)->string_string(UV2,UV3);UV2=UV3),
	find_lists3b(UV3,RS)
	),RS2)
	%change_var_base
	),ORS1),*/	
%trace,

	% * match specs with same shape x
	% - with same non ro addresses
	% find c, 
	% then dec tree xxx
	% x:
	% nd i - collects if this format
	% nd o - x, det by i format x
	
	% Separate by output shape
	
	%findall
	%find output shapes
	
	% same output shape - has same terminal positions
	%trace,
	length(RS10,RS10L),
	numbers(RS10L,1,[],Ns),
	%*RS1
	%trace,
	findall([Adds,[[input,Input_a],[output,Output_a]],
	[[input,Input_a_rs],[output,Output_a_rs]]],(member(N,Ns),get_item_n(RS10,N,[[input,Input_a],[output,Output_a]]),
	get_item_n(RS1,N,[[input,Input_a_rs],[output,Output_a_rs]]),
	sub_term_types_wa([heuristic(var_or_data(A),A)%string,atom,number
	],Output_a,Inst1),
	findall(A,member([A,_],Inst1),Adds)),Adds1),
	
	findall(A,member([A,_,_],Adds1),Adds2),
	%trace,
	sort(Adds2,Adds3),
	
	findall(A1,(member(Adds4,Adds3),
	findall([A,B],member([Adds4,A,B],Adds1),A1)),A11),
	
%trace,	
	findall(A110,(member(A2,A11),	findall([Adds,[[input,Input_a],[output,Output_a]],
	[[input,Input_a_rs],[output,Output_a_rs]]],(member([[[input,Input_a],[output,Output_a]],
	[[input,Input_a_rs],[output,Output_a_rs]]],A2),
	sub_term_types_wa([heuristic(var_or_data(A),A)%string,atom,number
	],Input_a,Inst10),
	findall(A,member([A,_],Inst10),Adds)),Adds10),
	
	findall(A,member([A,_,_],Adds10),Adds20),
	sort(Adds20,Adds30),
	
	findall(A1,(member(Adds40,Adds30),
	findall([A,B],member([Adds40,A,B],Adds10),A1)),A110)),Separated_by_shape),

	%foldr(append,A10,Separated_by_shape),
	%foldr(append,Separated_by_shape1,Separated_by_shape2),
	%foldr(append,Separated_by_shape2,Separated_by_shape3),
	%foldr(append,Separated_by_shape1,Separated_by_shape),
	
%trace,
	findall(RSC4,(member(A,Separated_by_shape),
	findall(RSC,(member(B,A),
	findall([[Input_a,Input_b],[Output_a,Output_b]%IOa,IOb
	],(member([RS101,RS11],B),
	%findall(RSC,(member([RS101,RS11],Separated_by_shape),
	%findall(RSC,(member(B%[_RS101,RS11]
	%,A),

	%length(RS101,RS101L),
	%numbers(RS101L,1,[],Ns1),
	
	%findall([IOa,IOb]%[[input,Input_c],[output,Output_d]]
	%,(member([[input,Input_b],[output,Output_b]],A),
	%,(member(N1,Ns1),get_item_n(RS101,N1,
	RS101=[[input,Input_a],[output,Output_a]],%),
	%get_item_n(RS11,N1,
	RS11=[[input,Input_b],[output,Output_b]]%),
	%member([[input,Input],[output,Output]],S),
	%length(Input_a,Input_a_L),
	%length(Input_c,Input_a_L),
		
%append(Input_a,Output_a,IOa),
%append(Input_b,Output_b,IOb)
),IOaIOb),
%trace,
	% if Is are same, and different Os, make separate calls to find_constants
	% so they have different nondeterministic results
findall(XY1,member([XY1,_],IOaIOb),XY2),
remove_dups(XY2,XY3),
%trace,
%writeln1([iOaIOb,IOaIOb]),
% if XY1s are same, split
findall(XW6,(member(XW2,XY3),findall([XW2,XW4],member([XW2,XW4],IOaIOb),XW6)),XY8),
%trace,
%writeln1([xy8,XY8]),

findall(XZ1,(member(XZ1,XY8),%member(XZ3,XZ1),XZ3=[XZ2,_],
length(XZ1,XZ1L),%writeln([l1,XZ1L]),%findall(XZ61,(member(XZ6,XZ1),length(XZ6,XZ6L),writeln([l2,XZ6L]),findall(XZ8,(member(XZ8,XZ6),
%length(XZ8,XZ9),writeln([l3,XZ9]),
XZ1L=1),%XZ61)),
XZ7)%)
%,XZ2)
,
subtract(XY8,XZ7,XZ3),
foldr(append,XZ3,XZ31),
%trace,
findall([XZ8],member(XZ8,XZ31),XZ9),
foldr(append,XZ7,XZ4),
(XZ4=[]->XZ5=[];XZ5=[XZ4]),
append(XZ9,XZ5,XY9),

%findall(XY28,(member(XY21,XY3),findall(XY22,member([XY21,XY22],IOaIOb),XY23),remove_dups(XY23,XY24),findall([XY211,XY221],(member(XY221,XY24),member([XY211,XY221],IOaIOb)),XY231),findall(XY232,(member(XY26,XY24),findall([XY27,XY26],member([XY27,XY26],XY231),XY232)),XY28)),XY81),
%foldr(append,XY81,XY82),
%remove_dups(XY82,XY8),
%trace,
%/*
/*
nl,
findall(XZ7,(member(XZ1,XY8),length(XZ1,XZ1L),writeln([l1,XZ1L]),findall(XZ61,(member(XZ6,XZ1),length(XZ6,XZ6L),writeln([l2,XZ6L]),findall(XZ8,(member(XZ8,XZ6),
length(XZ8,XZ9),writeln([l3,XZ9]),XZ9=1),XZ61)),
XZ7))
,XZ2),
subtract(XY8,XZ2,XZ3),
foldr(append,XZ2,XZ4),
(XZ4=[]->XZ5=[];XZ5=[XZ4]),
append(XZ3,XZ5,XY9),
*/
%*/
/*
[]))
findall(%[XY51,XY61]%
XY7
,(member(XY5,XY3),findall([XY5,XY6],
member([XY5,XY6],IOaIOb)%,remove_dups(XY5,XY51),remove_dups(XY6,XY61)%
,XY7)
),XY8),
*/
/*
findall([XY51,XY61]%XY7
,(%member(XY5,XY3),%findall([XY5,XY6],
member([XY5,XY6],IOaIOb),remove_dups(XY5,XY51),remove_dups(XY6,XY61)%XY7)
),XY8),*/
%trace,%remove_dups(XY8,XY81),
%trace,
findall(XY15,(member(XY10,XY9),findall([XY11_XY13,XY12_XY14],(member([[XY11,XY12],[XY13,XY14]],XY10),append(XY11,XY13,XY11_XY13),append(XY12,XY14,XY12_XY14)),XY15)%trace,remove_dups(XY15,XY151)
),XY16),
%sort(XY16,XY161),

%trace,
findall(RSC3,(member(XY19,XY16),%member(XY19,XY18),
findall(A0,member([A0,_],XY19),Data),
findall(A0,member([_,A0],XY19),Vars3),

%trace,
remove_dups(Data,Data1),
remove_dups(Vars3,Vars31),
find_constants(Data1,Vars31,RSC_a),

RS10=[[[input,Input_a],[output,Output_a]]|_],
	length(Input_a,Input_a_L),
	length(Input_c,Input_a_L),

	append(Input_c,Output_d,%RSC_a)),
	RSC_a),
	
	RSC3=[[input,Input_c],[output,Output_d]])
	,RSC))
	,RSC41),foldr(append,RSC41,RSC4)
	),
	RSC1),

	%foldr(append,RSC1,RSC2),

	%find_constants(RS10,RS1,RSC),
	%find_constants(ORS10,ORS1,ORSC),
	
	/*
	length(RSC,RSCL),
	numbers(RSCL,1,[],Ns),
	%trace,
	
	findall([X1,T22],(member(N,Ns),
	
	get_item_n(RSC,N,[X1,X2]),
	findall(T2,(member(X3,RS10),
	member([X1,X21],X3),
	rs_and_data_to_term(X2,X21,_,[],T2)),T21),
	
	
	decision_tree_s2(T21,T22)),T3),
	*/
	%trace,
	
	foldr(append,RSC1,RSC51),
	
	findall(T1,(member([[input,In2],[output,Out2]],RSC51),
	findall([A000,A01],(member([A000,A00],In2),
	%trace,
	remove_first_and_last_brackets(A00,A01)),%A00=["[",A01,"]"])
	In24),
	findall([A000,A01],(member([A000,A00],Out2),remove_first_and_last_brackets(A00,A01)),%=["[",A01,"]"])
	Out24),
	foldr(append,[[[input,In24]],[[output,Out24]]],T1)),RSC5),
	findall(DT1,(member([[input,In2],[output,Out2]],RSC5),
	%trace,
	(not(is_list(In2))
	->In2=In24;
	(%trace,
	findall(A00,member([_,A00],In2),In24))),
	(not(is_list(Out2))
	->Out2=Out24;
	(%trace,
	findall(A00,member([_,A00],Out2),Out24))),
	foldr(append,[In24,[[output,Out24]]],DT1)),C6),
	%double_to_single_brackets(C6,C8),
	decision_tree_s2(C6,In_Out24),
	%double_to_single_brackets(C8,In_Out24),
	%trim_brackets(In_Out241,In_Out24,_),
%trace,
	findall(C5,(member([[input,In2],[output,Out2]],RSC5),
	findall(A00,member([_,A00],In2),In24),
	findall(A00,member([_,A00],Out2),Out24),
	%DT1=[In24,Out24],
	double_to_single_brackets(In24,In25),
	double_to_single_brackets(Out24,Out25),
	find_mapping(In25,Out25,C5)),C61),
	foldr(append,C61,Map),
	
	%trace,
	%remove_dups(Map2,Map),
	%decision_tree_s2(C6,C7),

	/*
	RSC1=[[[[input,In1],[output,Out1]]|_]|_],
	length(In1,In1L),
	numbers(In1L,1,[],In1_Ns),
	length(Out1,Out1L),
	numbers(Out1L,1,[],Out1_Ns),
	
	findall(A00,member([A00,_],In1),_In1VNs),
	findall(A00,member([A00,_],Out1),_Out1VNs),

	findall(In232,%[In23,Out23],
	(member(RSC2,RSC1),
	findall(In222,(member(N,In1_Ns),
	findall(In21,(member([[input,In2],[output,Out2]],RSC2),
	get_item_n(In2,N,[VN,In21])),In22),
	decision_tree_s2(In22,In223),
	foldr(append,In223,In2223)
	,In222=In2223%[var,In2223]
	),In232)
	),In23),%foldr(append,In231,In23),
	%trace,double_to_single_brackets(In234,In23),
	
	findall(Out232,%[In23,Out23],
	(member(RSC2,RSC1),
	findall(Out222,(member(N,Out1_Ns),
	findall(Out21,(member([_,[output,Out2]],RSC2),
	get_item_n(Out2,N,[VN,Out21])),Out22),
	decision_tree_s2(Out22,Out223),
	foldr(append,Out223,Out222)
	%,Out224=[output,Out222]
	),Out232)
	),Out23),%foldr(append,Out231,Out23),
	%),In_Out23),
	%double_to_single_brackets(Out234,Out23),
	
	%trace,
	%findall(A01,(member(A02,)))
	length(In23,In23L),
	numbers(In23L,1,[],In23LNs),
%trace,
	findall([In231,[output,Out231]],(member(In23LN,In23LNs),
	get_item_n(In23,In23LN,In231),
	get_item_n(Out23,In23LN,Out231)),In_Out23),
	
	%foldr(append,In_Out23,In_Out231),
	%trace,
	decision_tree_s2(In_Out23,In_Out241),*/

	%T3=[[input,In_DTs],[output,Out_DTs]],

	%findall([Input,Output],(member([[input,Input],[output,Output]],RSC),
	%T3=RS10,
	term_to_atom(In_Out24,T31),
	%term_to_atom(In23,T31),
	%term_to_atom(T3,T31),
	%term_to_atom(Out23,ORSC1),
	%term_to_atom(In_DTs,T31),
	%term_to_atom(ORSC,ORSC1),
	
	%double_to_single_brackets(In23,In233),
	%double_to_single_brackets(Out23,Out233),
	%find_mapping(In233,Out233,Map),
	term_to_atom(Map,Map1),

%find_mapping(T3,ORSC,Map),
	
	%writeln1([rSC,RSC,"\n",oRSC,ORSC,"\n",rS10,RS10,"\n",oRS10,ORS10,"\n",t3,T3]),
% take input and mapping and produce output
foldr(string_concat,[Predicate_name,"(In_vars,Out_var) :-\nalgorithm(",T31,",",Map1,",In_vars,Out_var)."],Alg),

term_to_atom(Alg1,Alg),
%save_file_s("algorithm.pl",Alg),

%trace,

assertz(Alg1),
algs(Algs),
append(Algs,[Alg1],Algs1),
retractall(algs(_)),
assertz(algs(Algs1)),


findall(_,%(member(Spec,S),
%findall([A1,","]
(member([[input,In4],[output,Out4]],S0),

	retractall(vars_table_s2a(_)),
	assertz(vars_table_s2a([])),

findall(A1,member([_,A1],In4)%,%term_to_atom
%term_to_brackets(A,A1)
,A30),%foldr(append,A2,A3a),append(A3,[_],A3a),
%term_to_brackets(A30,A3),
term_to_atom(A30,A4),%
findall(A1,(member([_,A],Out4),%term_to_atom
term_to_brackets(A,A1,split=off))
,A310),%foldr(append,A21,A31a),append(A31,[_],A31a),
%term_to_brackets(A310,A31),
term_to_atom(A310,A41),

%foldr(string_concat,A3,A4b),
%trace,
foldr(string_concat,[Predicate_name,"(",A4,",Out),",A41,"=Out."
],Str2),

term_to_atom(Term2,Str2),%trace,
(Term2->writeln(success);writeln(fail))),_).


	% * convert term to a string after x before find_lists3b="try", c [before very start if string or leave as list] xx x (x unless run an earlier s2g pred, x for the moment x: can change non single char items to strings, run try on them)
	% find from sublists, substrings
	% use grammars not alg and appends lists to save big term containing input using brackets
	% s2l ... with constants x check specific patterns
	% dec trees contain ["["..."]"] x earlier, turn grammar input into term (big s2l)
	% x use alg not grammar so can more easily make a term - gen alg
	% convert input rec struct to alg with 'AN' variables marked
	
	%* rs and data on self recursively
	
	% use stwa to get variables, try different orders of i vars first, then one part at a time
	
	%* searches o term top down for parts
	% It doesn't matter about brackets
	
	% 1 item that is a list or list with '&r',o xx [], brackets x
	% do bottom level first, find fns to give result
	
	% use format model to transform data
	% - identifies a format used
	% transforms an i item to an o item
	% - neighbours - 1->2
	% - col_ns_to_action - makes change
	% * try a format, assume it is correct
	
	%test_formats(Vs,O,F).

	% use stwa to put variables
	% if list items are in order, 
	% up to where are not, get list 
	% (checks o for parts of i)
	% test
	
	% * input into one big term
	% convert dec tree to alg, like gen alg
	% take input needed from preds for output
	% form of relative stwa x, takes from a pos in rec struct (smooth), output rec struct
	
	% changes rec structs to algs
	% generate code for i,p,(o x) where
	% p = rel bw i,o
	% depends on if part of a term or smooth
	% - get stwa smooth needs sublist or substring
	
	
	% test
	
	% given input, tests
	
	

% formats

% teach neighbours, col_ns_to_action (extract, change - stwa)

% 

get_num_s2a(N) :-
	num_s2a(N),
	N1 is N+1,
	retractall(num_s2a(_)),
	assertz(num_s2a(N1)).

get_rec_join_n(N) :-
	rec_join_n(N),
	N1 is N+1,
	retractall(rec_join_n(_)),
	assertz(rec_join_n(N1)).

get_tmp_join_n(N) :-
	tmp_join_n(N),
	N1 is N+1,
	retractall(tmp_join_n(_)),
	assertz(tmp_join_n(N1)).


put_sub_term_wa_ae_smooth_cycle_s2a(RS3,RS4):-

sub_term_wa([split1,_],RS3,In5),
(In5=[[Ad,[split1,C]]|_]->(
In6=[[Ad,C]],
%findall([Ad,C],member([Ad,[split1,C]],In5),In6),%trace,
foldr(put_sub_term_wa_ae_smooth,In6,RS3,RS41),
put_sub_term_wa_ae_smooth_cycle_s2a(RS41,RS4));
RS3=RS4).

/*
get_ampersand_var_s2a(N) :-
	ampersand_var_n_s2a(N),
	N1 is N+1,
	retractall(ampersand_var_n_s2a(_)),
	assertz(ampersand_var_n_s2a(N1)).
*/

change_var_base :-
	vars_base_s2a(A),
	char_code(A,A2),
	A3 is A2+1,char_code(A1,A3),

	retractall(vars_base_s2a(_)),
	assertz(vars_base_s2a(A1)).




find_lists3b(UV2,RS) :-
% split on "[", "]", (",") rec'ly do nested brackets
% - () turn [a,b,c] into [a,[b,[c]]]
% later: split on delimiters in strings incl " " ,;.()[]
% label [split,_]
% [,]+[,]=[,,,]
% ['&r',['&r',a]]=['&r',a]
retractall(rec_join_n(_)),
assertz(rec_join_n(1)),
retractall(rec_join_vars(_)),
assertz(rec_join_vars([])),

retractall(tmp_join_n(_)),
assertz(tmp_join_n(1)),

%trace,
rec_join(UV2,RS1),
sub_into_rjv(RS1,RS2),
%trace,
remove_nested_tmps(RS2,RS3),

put_sub_term_wa_ae_smooth_cycle_s2a(RS3,RS)

%sub_term_wa([split1,_],RS3,In5),
%findall([Ad,C],member([Ad,[split1,C]],In5),In6),%trace,
%foldr(put_sub_term_wa_ae_smooth,In6,RS3,RS4),
%trace,

%flatten_join1(RS4,RS)
%foldr(append,RS5,RS)
.

remove_nested_tmps_cycle(RS1,RS4):-

sub_term_wa([[tmp,_],_],RS1,In5),
(In5=[[Ad,[[tmp,_],C]]|_]->(
In6=[[Ad,C]],
%findall([Ad,C],member([Ad,[split1,C]],In5),In6),%trace,
foldr(put_sub_term_wa_ae_smooth,In6,RS1,RS41),
remove_nested_tmps_cycle(RS41,RS4));
RS1=RS4).

remove_nested_tmps(RS1,RS6) :-

remove_nested_tmps_cycle(RS1,RS7),

	%sub_term_wa([[tmp,_],_],RS1,In5),

%(In1=[]->rec_join(UV2,RS);

%findall([Ad,C],member([Ad,[[tmp,_],C]],In5),In6),%trace,
%foldr(put_sub_term_wa_ae_smooth,In6,RS1,RS7),

(RS1=RS7->RS6=RS7;remove_nested_tmps(RS7,RS6)),!.


save_if_same(C,RS11,RS1) :-
	(%true%
	C=RS11
	->
	(rec_join_vars(RJV),
	(member([C,RS11,N],RJV)->
	true;
	(get_rec_join_n(N),
	append(RJV,[[C,RS11,N]],RJV1),
	retractall(rec_join_vars(_)),
	assertz(rec_join_vars(RJV1)))),
	RS1=[[rjv,N]]);
	RS11=RS1),!.
	
sub_into_rjv(List1,List2) :-
	rec_join_vars(RJV),
	sub_term_wa([rjv,_],List1,In1),
	findall([Ad,Item2],(member([Ad,[rjv,N]],In1),
	member([_,Item2,N],RJV)),In2),
	foldr(put_sub_term_wa_ae_smooth,In2,List1,List3),
	((List1=List3)->List2=List1;
	sub_into_rjv(List3,List2)),
	!.

remove_first_outer_bracket_chars(A,B) :-
 sub_term_types_wa([heuristic(outer_bracket_chars(A1),A1)],A,In),In=[[Ad,E]|_],append(["["],L4,E),
 append(E1,["]"],L4),In2=[[Ad,E1]],%[findall([Ad,D],(member([Ad,E],In),E=[D]),In2),
 foldr(put_sub_term_wa_ae,In2,A,B),!.
 %(A=C->C=B;
 %remove_first_outer_bracket_chars(C,B)),!.

outer_bracket_chars(A) :- remove_first_and_last_items("[","]",A,_),!.
	
flatten_join1(A,B) :-
 flatten_join2(A,[],B),!.
 
flatten_join2([],B,B) :- !.
flatten_join2(A,B,C) :-
 (not(is_list(A))->append(B,[A],C);
 ((A=[[Atom,[_]]],atom(Atom))->append(B,A,C);
 ((A=[Atom,[_]],atom(Atom))->append(B,[A],C);
 (A=[D|E],flatten_join2(D,B,F),
 flatten_join2(E,F,C))))),!.

	
rec_join(UV21,RS) :-

get_tmp_join_n(Tmp_join_n),



sub_term_types_wa([heuristic(A=[split1,B],A)],UV21,In11),

%(In1=[]->rec_join(UV2,RS);

findall([Ad,[split1,RS1]],(member([Ad,[split1,C]],In11),try(C,RS11),save_if_same(C,RS11,RS1)),In21),
foldr(put_sub_term_wa_ae,In21,UV21,UV2),



sub_term_types_wa([heuristic((A=[split,B],not(member([split,_],B))),A)],UV2,In1),

%(In1=[]->rec_join(UV2,RS);

findall([Ad,[[tmp,Tmp_join_n],RS1]],(member([Ad,[split,C]],In1),try(C,RS11),save_if_same(C,RS11,RS1)),In2),
foldr(put_sub_term_wa_ae,In2,UV2,UV3),
%trace,
findall([[[tmp,(*)%Tmp_join_n
],RS2]],(member(Y,UV3),(Y=[split,Z]->(rec_join(Z,RS2)%,foldr(append,RS21,RS2)
);%[Y]
[Y]=RS2)),UV4),
%trace,
foldr(append,UV4,UV41),
%trace,
	try(UV41,RS3),
	%UV41=RS3,
	
	RS3=RS6,

	
	(RS6=['&r',['&r',RS4]]->RS=['&r',RS4];RS=RS6).

find_unique_variables(S,UV) :-

	findall([S0,S2],(member([S0,S1],S),
%sub_term_types_wa([string,atom,number],S1,In1),
	sub_term_types_wa([heuristic(var_or_data(A),A)%string,atom,number
	%heuristic((only_item(O),%(string(O)->true;(atom(O)->true;number(O))),
	%not_r_o_nd_types(O)),O)
	],S1,In1),%),C1)

	findall(Q,member([_,Q],In1),Q2),
	%remove_dups(Q1,Q2),
	findall([Add,AN],(member(Q3,Q2),
	member([Add,Q3],In1),%trace,
	
	((Q3=[Type,Data],type_s2a1(Type))->
	(find_unique_variables(Data,AN1),
	AN=[Type,AN1]);
	(
	vars_s2a(Vars),
	(member([Q3,Q4],Vars)->AN=Q4;
	(get_num_s2a(N),vars_base_s2a(Letter),
	atom_concat(Letter,N,AN),
	retractall(vars_s2a(_)),
	append(Vars,[[Q3,AN]],Vars2),
	assertz(vars_s2a(Vars2))
	%change_var_base
	))))
	),In2),
	
	foldr(put_sub_term_wa_ae,In2,S1,S2)
	%change_var_base
	),UV).
		
	%findall([Add,X4],(member([Add,Z1],In2),member([Z1,X2],UV2),Z1=[X1,X3],replace_term([X1,X3],X1,X2,X4)),UV).

/*
not_r_o_nd_types(A) :- not(r_o_nd_types(A)),!.
r_o_nd_types('&r').
r_o_nd_types(o).
r_o_nd_types(nd).
r_o_nd_types(A) :- type_s2a1(A).
*/
	
find_constants(S,RS2,C) :-

	retractall(num_s2a(_)),
	assertz(num_s2a(1)),

	retractall(vars_s2a(_)),
	assertz(vars_s2a([])),

	retractall(vars_base_s2a(_)),
	assertz(vars_base_s2a('B')),
	%* keep same var name
	%change_var_base,
%trace,
	%length(RS1,RS1L),
	% find constants that recur in same place across spec
	findall(%[%C21L,
	%U1,U2,
	C1%C2%C21%C3
	%]
	,%U2,
	%In1],
	(member(RS1,RS2),
	%RS2=[RS1|_],
	findall([U1,%U2,
	In1]
	,(member([U1,U2],RS1),
	

	sub_term_types_wa([heuristic(var_or_data_c(A),A)%string,atom,number
	%heuristic((O=[Type,_],type_s2a1(Type)%only_item(O),
	%not_r_o_nd_types(O)
	%),O)
	],U2,In1)
	%trace,
	%findall([Ad3,P2],(member([Ad2,P1],In11),
	%append(Ad2,[2],Ad3),
	%P1=[_,P2]),In1
	
	%)
	),C1)

	%sub_term_types_wa([heuristic((only_item(O),
	%not_r_o_nd_types(O)),O)],U2,In1)),C1)
	
	%foldr(append,C1,C10),
	%findall([C21,%C22,
	%C23],(member([C21,%C22,
	%C23],C10),
	%findall(C4,(member([Add,C5],C23),
	%trace,
	/*
	findall(L,(member(C12,C1),
	findall(A1%C11
	,(member(A1,C12)%,%=[_,A1]
	%member([C11,_],A1)
	),E),

	%frequency list
	sort(E,K),
	
	findall([G,J],(member(G,K),findall(G,member(G,E),H),length(H,J)),L)),L1),
	*/
	%trace,
	
	%findall(M,(member(M2,L1),
	%C1=[M2|M3],
	%findall(M6,(member(M6,M2),member(M9,M3),member(M6,M9)%=[M6|M8],
	%forall(member(M6,M3),member(M6,M7))
	%),C2)
	),Specs),
	%trace,
	
	% find whether each item number of each variable is constant across specs; if not, give a new var.
	% x 
	% don't need to change to 'Bx'
	
	findall(_,(member(Spec1,Specs),
	length(Spec1,Spec_length),
	(forall(member(Spec2a,Specs),length(Spec2a,Spec_length))->true;(writeln("Error: Specs not same length."),abort))),_),
	
	Specs=[Spec2|_],

	length(Spec2,Spec2_length),
	numbers(Spec2_length,1,[],Var_nums),
%trace,
	findall(Item3d,(member(Var_num,Var_nums),

	%Specs=[[[_Varname0,Items]|_]|_],
	get_item_n(Spec2,Var_num,[Varname,Items]),
	
	length(Items,Items_length),
	numbers(Items_length,1,[],Item_nums),

	findall(Items1,(member(Item_num,Item_nums),

	findall([Varname,Item],(member(Spec2b,Specs),
	%Spec2=[[Var_name,Items]|_],
	%length(Spec2,Spec2_length),
	%*numbers(Spec2_length,1,[],Var_nums),
%trace,
	%*findall([Varname,Item],(member(Var_num,Var_nums),
	%trace,
	%Spec2=[_Var_name,Spec21],
	get_item_n(Spec2b,Var_num,[Varname,Items6]),
	get_item_n(Items6,Item_num,Item)),Items1)
	
	%Items1=[[Varname,_]|_],
	
	),Items21),
	%foldr(append,Items21,Items2),%1)),Items4),

	%trace,
	%Items2=[[Varname,_]|_],
	findall(Item3c,(member(Items2,Items21),
	findall(A,member([_,[_Ad,A]],Items2),A1),
	%trace,
	(maplist(=(_),A1)->Item3c=[];%
	%Item3a=Item3;
	
	%**
	%Item3c=Items2;
	
	
	%trace,
	findall(Item3,(member([Varname3,[Ad,Item3b]],Items2),vars_s2a(Vars),

%Item3=[Varname3,[Ad,Item3b]]
	((member([Item3b,Q4],Vars))->Item3=[Varname3,[Ad,Q4]];
	(get_num_s2a(N),vars_base_s2a(Letter),
	atom_concat(Letter,N,AN),Item3=[Varname3,[Ad,AN
	]],
	retractall(vars_s2a(_)),
	append(Vars,[[Item3b,AN]],Vars2),
	assertz(vars_s2a(Vars2))))
	
	),Item3c))),Item3d)

	
	),Items3),
	foldr(append,Items3,Items42),%1)),Items4),
	foldr(append,Items42,Items4),
	%trace,
	findall([A,B],member([A,[B,C]],Items4),AB),
	remove_dups(AB,AB1),
	


	retractall(num_s2a(_)),
	assertz(num_s2a(1)),

	retractall(vars_s2a(_)),
	assertz(vars_s2a([])),

	retractall(vars_base_s2a(_)),
	assertz(vars_base_s2a('C')),



	%trace,
	findall([A,[B,Item3]],(member([A,B],AB1),findall(C,(member([A,[B,C]],Items4)),C1),
	sort(C1,C2),
	(
	
	%findall(Item3c,(member(Items2,C2),
	%findall(A,member([_Ad,A],Items2),A1),
	%trace,
	%(%maplist(=(_),A1)->Item3c=[];%Item3a=Item3;
	
	
	%trace,
	%findall(Item3,(member([Varname3,[Ad,Item3b]],Items2),
	vars_s2a(Vars1),

%Item3=[Varname3,[Ad,Item3b]]
	((%trace,
	member([C2,Q4],Vars1))->Item3=Q4;
	(get_num_s2a(N),vars_base_s2a(Letter),
	atom_concat(Letter,N,AN),Item3=AN,
	retractall(vars_s2a(_)),
	append(Vars1,[[C2,AN]],Vars21),
	assertz(vars_s2a(Vars21))))
	
	%,writeln1(Item3)
	%),Item3c))),Item3d)	
	
	)),Items43),

	findall(A,member([A,_],Items43),A11),
	remove_dups(A11,A1),

	findall([Var_name1,Items5],(member(Var_name1,A1),findall(A4,(member([Var_name1,A4],Items43)),Items5)),C2),
	%sort(C20,C2),
	RS2=[RS3|_],
	%writeln(U2),
	
	findall(U31,member([U31,U32],RS3),RS4),
	remove_dups(RS4,RS5),

	%S=[[[U12,U21]|_]|_],
	S=[S3|_],
	%findall([Y1,In31],(member([Y1,Y2],U21),
	
%U21=Y2,%[_Y1,Y2],

findall([U31,In3],(member([U31,U32],S3),


	sub_term_types_wa([heuristic(var_or_data_c(A),A)%string,atom,number
	%heuristic((only_item(O),%(string(O)->true;(atom(O)->true;number(O))),
	%not_r_o_nd_types(O)),O)
	%heuristic((O=[Type,_],type_s2a1(Type))%only_item(O),


%sub_term_types_wa([heuristic((only_item(O),%(string(O)->true;(atom(O)->true;number(O))),
	%not_r_o_nd_types(O))
	%,O)
	],U32,In3)),In31),%),In3),

%trace,

findall(XX2,(choose_vars(RS5,C2,Var,Ad1,_U5,In31,XX2)%([Ad2,XX21]=XX2)%*(member([Ad1,XX2],U5)->true;(member([Var,U4],In31),member([Ad1,XX2],U4)))
),C211),%length(C21,C21L)
	%,
	%*),C31),
	foldr(append,C211,C21),
%trace,
	findall([Var,C4],(member(Var,RS5),
	findall([Ad1,XX2],member([Var,[Ad1,XX2]],C21),C23),
	member([Var,XX3],RS3),
	%sort(C31,[[_,U1,U2,C33]|_]),
	%trace,
	foldr(put_sub_term_wa_ae,%C33,%
	C23,%C21,
	XX3,C4)%U2,C3),
	/*
	length(RS5,RS5L),
	numbers(RS5L,1,[],Ns),

	findall([RS51,C31],(member(P2,Ns),get_item_n(RS5,P2,RS51),
	get_item_n(C3,P2,C31)),C4)
	*/
	),C42),
	%foldr(append,C41,C42),
	%C4=[U1,C3],
	%),C4),
	%sort(C4,C41),
	%findall([C42,C43],member([_,C42,C43],C41),C44),
	%C4=UV2,
	%findall(UV,(member(S1,C4),
	%find_unique_variables(S1,UV)),UV2),
	(true%maplist(=(_),UV2)
	->sort(C42,C);%C4=[C|_];
	(writeln("Error: Specs are incompatible."),abort)),!.


choose_vars(RS5,C2,Var,Ad1,U5,In31,XX24) :-
	%findall([Ad1,XX21],(
	findall([Var,XX2],(member([Var,U5],C2),member([Ad1,XX21],U5),XX2=[Ad1,XX21]),XX22),%not(XX2=[])
	%.
	
%choose_vars(C2,Var,Ad1,U5,In31,XX2) :-
	%findall([Ad1,XX21],(
	findall([Var,XX2],(member(Var,RS5),%member([Var,U5],C2),%trace,%
	
	member([Var,U4],In31),member([Ad1,XX21],U4),XX2=[Ad1,XX21],
	not(member([Var,[Ad1,_]],XX22))),XX23),%XX2),not(XX2=[]),
	append(XX22,XX23,XX24).
	

/*
test_formats(Vs,O,F1) :-

	open_file_s("s2a_formats.txt",T),
	member([Vsi,Vso,F1],T),
	%findall(Vsi1,(member(Vsi2,Vsi),atom_string(Vsi1,Vsi2)),Vsi3),
		
	findall([Vsi1,","],member(Vsi1,Vsi),Vsi3),
	append(Vsi4,[_],Vsi3),
	%append(Vsi3,["O"],Vsi4),
	findall([Vs1,","],member(Vs1,Vs),Vs3),
	append(Vs4,[_],Vs3),
	%findall([Vso1,Vso2],(member(Vso1,Vso),%string_concat(Vso1,"_o1",Vso2)),Vso3),
	%loop_replace_s2a(Vso3,F1,F2),
	findall([Vso1,","],member(Vso1,Vso),Vso3),
	append(Vso4,[_],Vso3),
	flatten(["[",Vsi4,"]=[",Vs4,"],",F1,",[",Vso4,"]=",O],L),
	foldr(string_concat,L,S),
	term_to_atom(T1,S),
	catch(T1,_,fail).
	*/

	
%loop_replace_s2a([],F,F) :- !.
%loop_replace_s2a([[Vso1,Vso2]|Vso3],F1,F2) :-
%	replace2(F1,Vso1,Vso2,F3),
%	loop_replace_s2a(Vso3,F3,F2),!.

	
	
remove_first_and_last_brackets(L1,L5) :-
 (remove_first_outer_bracket_chars(L1,L5)->true;
 L1=[L5]),!.
