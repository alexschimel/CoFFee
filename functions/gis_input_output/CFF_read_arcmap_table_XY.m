function [X,Y] = CFF_read_arcmap_table_XY(filename)
% [X,Y] = CFF_read_arcmap_table_XY(filename)
%
% DESCRIPTION
%
% quick dirty function to read XY data in arcmap tables exported as text
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
% YYYY-MM-DD: second version.
% YYYY-MM-DD: first version.
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%

T = CFF_readtable(filename);

X = str2num(cell2mat(T.POINT_X));
Y = str2num(cell2mat(T.POINT_Y));
