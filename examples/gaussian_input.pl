% examples/gaussian_input.pl
% Example Prolog source for PR 6 Gaussian optimisation tests.
%
% Contains:
%   - A linear index recurrence (constant step) for Gaussian optimisation.
%   - A quadratic index recurrence (triangular numbers) for Gaussian optimisation.
%   - A predicate with unsupported maths that must be preserved unchanged.
%
% Expected optimisations:
%   linear/2  → linear(N, Out) :- Out is 2 + 3 * N.
%   tri/2     → tri(N, Out)    :- Out is <polynomial in N>.
%   cube/2    → preserved unchanged (X*X*X is not a recognised recurrence).

% linear/2: computes Out = 2 + 3*N.
% Base:  linear(0, 2).
% Step:  Out is Out_prev + 3  (constant increment 3).
linear(0, 2).
linear(N, Out) :- N > 0, N1 is N-1, linear(N1, Out1), Out is Out1 + 3.

% tri/2: computes triangular numbers, Out = N*(N+1)/2.
% Base:  tri(0, 0).
% Step:  Out is Out_prev + N  (increment grows with index).
tri(0, 0).
tri(N, Out) :- N > 0, N1 is N-1, tri(N1, Out1), Out is Out1 + N.

% cube/2: unsupported maths (cubic, not a polynomial recurrence of
% the recognisable base+step form).  Must be preserved unchanged.
cube(X, Y) :- Y is X * X * X.
