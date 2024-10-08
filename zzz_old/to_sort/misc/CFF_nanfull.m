function F = CFF_nanfull(S)
%
% Same as function "full" to turn a sparse matrix into a full one, but
% using NaN instead of 0 for empty elements
%
% NEW FEATURES
%
% 2014-10-02: first version.
%
% EXAMPLE
%
% i=[1 2 3 3];
% j=[1 3 1 3];
% s=[11 13 17 18];
% S = sparse(i,j,s)
% F1 = full(S)
% F2 = CFF_nanfull(S)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

[i,j,s] = find(S);
Smask = sparse(i,j,ones(size(i)));
Fmask = full(Smask);
Fmask(Fmask==0)=NaN;
F = full(S);
F = F.*Fmask;