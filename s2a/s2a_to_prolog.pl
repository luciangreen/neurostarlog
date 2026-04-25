% s2a_to_prolog.pl

% use s2a to convert s2a algs to pl

% do preds, grammars and those within each other

% character_breakdown_mode=off for preds
% character_breakdown_mode=on for grammars

test_s2a_in_s2g :-

s2a_tests(Tests),

findall(_,(%member([N,L,G2],

member([N,Predicate_name,L1,
character_breakdown_mode=CBM,G2],
Tests),

findall(L3,(member(L4,L1),
term_to_atom(L4,L2),
atom_string(L2,L3)),L),
catch(

 strings_to_grammar(L,G1)->(writeln1(G1),
 ((G1=G2)->R=success;R=fail
 )
 ,
 writeln([R,N,strings_to_grammar,test]),
 
 (check_grammar(L,G1)->R1=success;R1=fail)
 ),
  writeln([R1,N,strings_to_grammar,check_grammar,test]),
   (writeln([abort,R1,N,strings_to_grammar,check_grammar,test]),

  nl)))
 ,_),!.
 
 
/*

x: s2g in s2a, (turn off s2g mode)

s2g x use s2a with modified s2g code generator
- use preds for each nd, r, code/call
- simplify later?
- grammars when dealing with files 

put mi in s2a stwa x mi in prolog x mi instead of r, mi compression instead of rr
- keep spec, alg, mi, mic
- correl - find patterns such as 2 4 6 with gaussian elim
- commands
- unfolding predicate call data for new cfgs in case simpler and as accurate
 - may need other additions not just 1+1=2 if there is input in the alg

finds if regression is relevant by examining the data integrity
cut seahorse emoji type bad data

cut incorrect, keep unusual single points


multivariate systems 
align complex data with a straight line instead
vars can coexist-we've found the relation
I can visualise a 3D maze of llm data simply

* run s2a, then s2g on results for grammars (more accurate results using results of s2a)
for character_breakdown_mode=off
- for character_breakdown_mode=on remove labels
- can use grammars for files, preds otherwise

with ds that converts 1->C1 need n() that keeps 1

label that eg n(n+1)/2 = sum of 1+..+n, same with mi c
units/types/eg music notes for 1 2 3, n(n+1)/2

* use gaussian elim for finding next in 123

determine max n in x^n = 3

*/
