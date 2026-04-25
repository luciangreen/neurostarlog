% rs_and_data_to_term([['&r',['A1','A2']]],[2,3,2,3],[],T).

% T = [['&r', [['A1', 'A2'], [[2, 3]]]]]


% rs_and_data_to_term([['&r',['A1','A2']],['&r',['A3','A4']]],[2,3,2,3,3,5],[],T).

% T = [['&r', [['A1', 'A2'], [[2, 3]]]], ['&r', [['A3', 'A4'], [[3, 5]]]]]


%rs_and_data_to_term([[o,['A1']],1,[o,['A1']]],[2,1,2],[],T).
%T = [[o, [['A1'], [2]]], 1, [o, [['A1'], [2]]]].

%rs_and_data_to_term([[o,['A1']],1,[o,['A1']]],[1],[],T).
%T = [[o, [['A1'], []]], 1, [o, [['A1'], []]]].


% rs_and_data_to_term([[o,['A1']],['&r',['A3','A4']]],[2,3,2,3],[],T).

% use var values from elsewhere

% check that recurring vars don't have conflicting vals

%rs_and_data_to_term(A,B,C,D,E,_) :- rs_and_data_to_term(A,B,C,D,E).
rs_and_data_to_term(RS0,D0,D2,%RSa1,RSa2,
T1,T22,T2_old,First) :-
	trim_brackets(RS0,RS1,N1),trim_brackets(D0,D1,_N2),%((RS0=RS1,D0=D1)->fail;true),
	
rs_and_data_to_term0(RS1,D1,D2,%RSa1,RSa2,
[],T2,T2_old,First),
%trace,
(First=true->
wrap_brackets(T2,T21,N1);
T2=T21),
append(T1,T21,T22).


rs_and_data_to_term0(A,D,D,%RSa,RSa,
T,T,_T2_old,_First) :- %trim_brackets(A,A1),%writeln1(A),
(%A=[output,T2_old]->true;
A=[]),!.
rs_and_data_to_term0(RS,D1,D3,%RSa1,RSa2,
T1,T2,T2_old,First) :-
%writeln1(rs_and_data_to_term(RS,D1,D3,%RSa1,RSa2,
%T1,T2,T2_old)),
	%trim_brackets(RS0,RS),trim_brackets(D0,D1),

	%get_ampersand_var_s2a(N),
	%atom_concat('&',N,AN),
	
	%RS=[RS1|RS2],
	(RS=[output,RS3]->
	(%look ahead to char following '&r' x if undefined, try repeating or going on
	%trace,
	%term_to_list(RS3,T32),
	append(T1,[[output,RS3%[RS3,T3]
	]],T31)


	%append(RSa1,[['&',N,'&r',,T3]]],T31)
	);
	(RS=['&r',RS3]->
	(%look ahead to char following '&r' x if undefined, try repeating or going on
	%(ro(RS3),rs_and_data_to_term(RS3,D1,D2,%RSa1,RSa2,
%[],T3))->true;
	%(D1=['&r',D11]->true;D1=D11),
	try_r(RS3,D1,D2,[],T3,T2_old),%),
	
	append(T1,[['&r',T3%[RS3,T3]
	]],T31)
	%append(RSa1,[['&',N,'&r',,T3]]],T31)
	);
	
	(RS=[nd,RS3]->
	(
	try_nd(RS3,D1,D2,T1,T31,T2_old)
	);
	
	%rs_and_data_to_term(RS1,D1,%RSa1,RSa2,
%T1,T2),
	%append(T1,[['&r',[RS3,T3]]],T31)
	
	(RS=[]->
	append(T1,[[]],T31);
	
	/*(is_list(RS)->
	(%trim_brackets(RS1,RS10),
	rs_and_data_to_term(RS,D1,D2,%RSa1,RSa2,
[],T32,T2_old),T3=T32,
	append(T1,T3%[RS3,T3]
	,T31));
	*/
	
	%/*
	(only_item1(RS)->
	(get_token(RS,D1,D2,[],T3),
	%->true;rs_and_data_to_term([RS1],D1,D2,%RSa1,RSa2,
%[],T3)),
	
	append(T1,T3,T31)%;
	);
	%*/
	%)))))

	%rs_and_data_to_term(RS1,D1,D2,%RSa1,RSa2,
%T1,T31)
	(%trace,
	(RS=[RS1|RS2]->%(is_list(RS11)->(RS11=RS1,RS21=RS2,
	Flag_wrap=true%)
	;(RS=RS1,RS2=[],Flag_wrap=false)),
	(D1=[D111|D121]->(is_list(D111)->(D111=D11,D121=D12);(D1=D11,D12=[]))),
	
	%only_item1(RS1)->
	%(get_token([RS1],D1,D13,T1,T3);
	%(
	rs_and_data_to_term(RS1,D11,D31,[],T3,T2_old,true),
	
	append(D31,D12,D13)),

	rs_and_data_to_term(RS2,D13,D2,T3,T32,T2_old,false),
	
	((First=true,Flag_wrap=true)->T33=[T32];T33=T32),
	%trace,
	append(T1,T33,T31))))))
	,
	D2=D3,T2=T31.


ro(['&r',_]).
ro(['&o',_]).

try_r(RS3,D1,D2,T1,T2,T2_old) :-

	try_r1(RS3,D1,D3,[],T3,T2_old),
	(T3=[]->
	(D2=D3,T1=T2);
	((T1=[]->(T3=T31,%[T31|_],
	append(T1,T31,T4));T4=T1),
	try_r(RS3,D3,D2,T4,T2,T2_old))).

try_r1([],D,D,T,T,_T2_old) :- !.
try_r1(_,[],[],T,T,_T2_old) :- !.

try_r1(RS3,D1,D3,T1,T2,T2_old) :-

	RS3=[RS4|RS5],
	%D1=[D4|D5],
	ro(RS4),rs_and_data_to_term([RS4],D1,D5,%RSa1,RSa2,
[],T31,T2_old,true),
	append(T1,T31,T3),
	%D5=D3,T3=T2.
	try_r1(RS5,D5,D3,T3,T2,T2_old).


try_r1(RS3,D1,D3,T1,T2,T2_old) :-

	(RS3=[RS4|RS5]->true;(RS3=RS4,RS5=[])),
	(D1=[D4|D5]->true;(D1=D4,D5=[])),
	get_val_s2a(RS4,D4),
	append(T1,[D4],T3),
	%D5=D3,T3=T2.
	try_r1(RS5,D5,D3,T3,T2,T2_old).

try_r1(_,D,D,T,T,_T2_old) :- !.

try_o(RS3,D1,D3,T1,T3) :-
	(try_r1(RS3,D1,D3,T1,T3);
	(D1=D3,T1=T3)).

try_nd(RS3,D1,D2,T1,T3,T2_old) :-
	RS3=[RS4|RS5],
	(rs_and_data_to_term(RS4,D1,D2,%RSa1,RSa2,
T1,T3,T2_old,true)%->true
;
	try_nd(RS5,D1,D2,T1,T3,T2_old)).

get_token([],D,D,T,T) :- !.
get_token(RS1,D1,D3,T1,T3) :-
%writeln1(get_token(RS1,D1,D3,T1,T3)),
%trace,
	((D1=[D4|D2],
	not(only_item1(D1)))->
	(get_val_s2a(RS1,D4),D2=D3,
	append(T1,[D4],T3));

((RS1=[Type1, Var1],type_s2a1(Type1),
D1=[Type2, Val1],type_s2a1(Type2)),%->true;
%[Var,Val]=[Var1,Val1]),
%get_token(Var1,Val1,D3,T1,T3))->true;
%trace,
rs_and_data_to_term(Var1,Val1,D3,%RSa1,RSa2,
[],T31,_T2_old3,true),
append(T1,[[Type2,T31]],T3))->true;

	(append(T1,[D1],T3),
	get_val_s2a(RS1,D1),
	append(T1,[D1],T3),D3=[])).	

/*get_val_s2a(Var,Val) :-
((Var=[Type1, Var1],type_s2a1(Type1),
Val=[Type2, Val1],type_s2a1(Type2))->true;
[Var,Val]=[Var1,Val1]),
get_val_s2a1(Var1,Val1).
*/
get_val_s2a(Var,Val) :-
%trace,
	(is_var_s2a(Var)->
	(vars_table_s2a(Vars),
	(member([Var,Val1],Vars)->
	(Val=Val1->true;fail);
	(append(Vars,[[Var,Val]],Vars2),
	retractall(vars_table_s2a(_)),
	assertz(vars_table_s2a(Vars2)))));
	(Var=Val->true;Val=[string, [Var]])
	).
	%writeln(not(is_var_s2a(Val))),
	%not(is_var_s2a(Val)).
	
is_var_s2a(Item) :-
	atom(Item),atom_concat(It,Em,Item),
	atom_length(It,1),
	is_upper(It),
	atom_string(Em,Em1),
	number_string(_N,Em1).
	
only_item1(A) :- (character_breakdown_mode(on)->
	only_item1_c(A);only_item2_c(A)).
only_item1(A) :- only_item2_c(A).

only_item1_c(A) :- (is_var_s2a(A)->true;(A=[A1,_],type_s2a1(A1))),not(type_s2a1(A)).
only_item2_c(A):-only_item(A).
only_item2_c([]).


%/*
%*/

ro(['&r',_]).
ro(['&o',_]).

rnd(A):-ro(A).
rnd([nd,_]).

double_to_single_brackets(A,B) :-
 sub_term_types_wa([heuristic(double_brackets(A1),A1)],A,In),findall([Ad,D],(member([Ad,E],In),E=[D]),In2),foldr(put_sub_term_wa_ae,In2,A,C),
 (A=C->C=B;
 double_to_single_brackets(C,B)),!.
 
double_brackets([[_|_]]).
double_brackets([[]]).

trim_brackets(A,B,N):-(is_list(A)->(trim_brackets1(A,C,0,N),B=C);A=B),!.%(rnd(C)->B=[C];(not(is_list(C))%rnd(C)

trim_brackets1(A,B,N1,N3):-A=[C],N2 is N1+1,trim_brackets1(C,B,N2,N3),!.
trim_brackets1(A,A,N,N) :-!.

wrap_brackets(A,A,0) :-!.
wrap_brackets(A,B,N) :-
[A]=C,N2 is N-1,wrap_brackets(C,B,N2),!.
