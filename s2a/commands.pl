% Commands in s2a

% commands, predicate calls, dup_spec (ds) command to create vars and constants

% if there is a reference to another pred from a spec, run it through s2a, if it is not there, don't run it (give error) x it should be a separate alg - have prolog by then

% use s2a to convert s2a algs to pl
% prolog should contain code with calls, code


% Collect vars from body, calls, code
% Put together header, body of predicate, make a new predicate if &r contains a variable (not necessarily so x), new clause with &nd or (->true;) if no new data in anteced (x see below)
% new preds/clauses if code/call with own header

% should take s2a alg and try to find unknown vals from any known vals using types library preds, mnn (expert pred generators, like pred term processors, which come from previously generated MNNs) or ChatGPT. (This process generates not just converts or optimises MNNs.)

% chicken and egg-first generate library preds from Philosophy, etc. folder, optimising them and finding maths similarities or common formulas - which it does by

% dep 
% 1. s2a to prolog
% 2. maths ind
% 3. spec (x pred) compilation
% 4. commands
% 5. spec compil for new specs
