function B = CFF_imopen(A,H,varargin)
% B = CFF_imopen(A,H,varargin)
%
% DESCRIPTION
%
% Image morphological opening (ie erodes, and then dilates
%
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

B = CFF_imerode(A,H);
B = CFF_imdilate(B,H);


