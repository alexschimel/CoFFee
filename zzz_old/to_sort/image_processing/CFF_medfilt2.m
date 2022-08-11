function B = CFF_medfilt2(A,H,varargin)
% B = CFF_medfilt2(A,H,varargin)
%
% DESCRIPTION
%
% Filters image A with filter H, computing median (medfilt2)
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
% 2014-10-13: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

%% stackoffset the image
A_stack = CFF_stack_offsets(A,H);

%% computing median (discounting nan elements)
B = CFF_nanfunc3('median',A_stack,3);

