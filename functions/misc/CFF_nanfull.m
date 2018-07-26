function F = CFF_nanfull(S)
% function F = CFF_nanfull(S)
%
% DESCRIPTION
%
% Same as function "full" to turn a sparse matrix into a full one, but
% using NaN instead of 0 for empty elements
%
% USE
%
% ...
%
% PROCESSING SUMMARY
% 
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - varagin
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% ...
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
%
%%%
% Alex Schimel, Deakin University
%%%

[i,j,s] = find(S);
Smask = sparse(i,j,ones(size(i)));
Fmask = full(Smask);
Fmask(Fmask==0)=NaN;
F = full(S);
F = F.*Fmask;