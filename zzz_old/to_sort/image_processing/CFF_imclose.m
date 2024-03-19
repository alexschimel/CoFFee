function B = CFF_imclose(A,H,varargin)
% B = CFF_imclose(A,H,varargin)
%
% DESCRIPTION
%
% Image morphological closing (ie dilates the erodes)
%
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

B = CFF_imdilate(A,H);
B = CFF_imerode(B,H);


