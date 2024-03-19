function B = CFF_medfilt2(A,H,varargin)
% B = CFF_medfilt2(A,H,varargin)
%
% DESCRIPTION
%
% Filters image A with filter H, computing median (medfilt2)
%
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% stackoffset the image
A_stack = CFF_stack_offsets(A,H);

%% computing median (discounting nan elements)
B = CFF_nanfunc3('median',A_stack,3);

