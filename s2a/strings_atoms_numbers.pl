strings_atoms_numbers(T1,T2,rs=RS) :-
%trace,

(character_breakdown_mode(off)->T1=T2;%((RS=on)->(
	%split_string_if_split(T1,A3,split=RS),
	%T1=A3,
	%find_lists3b(A3,T2));A2=T2);

	(sub_term_types_wa([string,atom,number,compound],T1,In1),
	%(length(In1,1)->T1=T2;
	(findall([Ad,[Type,A21]],(member([Ad,A1],In1),
	not(type_s2a1(A1)),
	%not(is_var_s2a(A1)),
	(is_var_s2a(A1)->(Type=var,fail%A2=A1
	);
	(get_type(A1,Type),
	%try(A1,A2)
	characterise(A1,Type,A2),%,A2=[A21]
	((%san_no_rs(false),
	RS=on)->(
	split_string_if_split(A2,A3,split=RS),
	find_lists3b(A3,A21));A2=A21)
	%(length(A2,1)->fail;true)
	))
	),In2),
	foldr(put_sub_term_wa_ae,In2,T1,T2)))).

get_type(A1,string) :- string(A1).
get_type(A1,atom)   :- atom(A1).
get_type(A1,number) :- number(A1).
get_type(A1,compound) :- compound(A1).
%get_type(A1,var) :- is_var_s2a(A1).

type_s2a1(string).
type_s2a1(atom).
type_s2a1(number).
type_s2a1(compound).
%type_s2a1(var).

characterise(A1,compound,A2) :- term_to_atom(A1,A3),string_strings(A3,A2),!.

characterise(A1,_,A2) :- string_strings(A1,A2),!.
%characterise(A1,atom,A2) :- string_chars(A1,A2),!.
%characterise(A1,number,A2) :- number_string(A1,A3),string_strings(A3,A21),findall(A4,(member(A5,A21),number_string(A4,A5)),A2),!.

characterise1(A,A) :-!.
% if convert term to strings destroys vars 
% can't deal with strings, just lists until checked
%trace,get_type(A,C), ((type_s2a1(C),not(C=compound)
%)->(%term_to_atom(A,A1),
%characterise(A,_,B));A=B),!.

join_san(A,string,B) :- foldr(string_concat,A,B),!.
join_san(A,atom,B) :- foldr(string_concat,A,B1),atom_string(B,B1),!.
join_san(A,number,B) :- foldr(string_concat,A,B1),number_string(B,B1),!.
join_san(A,compound,B) :- foldr(string_concat,A,B1),term_to_atom(B,B1),!.

var_or_data(A) :- 
%trace,
(character_breakdown_mode(on)->
var_or_data1(A);
var_or_data2(A)),!.

%var_or_data1(A) :- is_var_s2a(A).
%var_or_data1() :- not(type_s2a1(A)).

% 'A1', 1,a not [num,_] etc
var_or_data1(A) :- only_item(A),(A=[A1,_]->not(type_s2a1(A1));true).

%var_or_data2(A) :- is_var_s2a(A).
var_or_data2(A) :- only_item(A).

var_or_data_c(A) :- %var_or_data(A).
%trace,
(character_breakdown_mode(on)->
var_or_data(A);%
%var_or_data1_c(A);
var_or_data2_c(A)),!.

%var_or_data1(A) :- is_var_s2a(A).
%var_or_data1() :- not(type_s2a1(A)).

% 'A1', [num,_] etc, not num etc
var_or_data1_c(A) :- %trace,
(is_var_s2a(A)->true;(A=[A1,_],type_s2a1(A1))),not(type_s2a1(A)).

%var_or_data2(A) :- is_var_s2a(A).
var_or_data2_c(A) :- only_item(A).

