function [X,Y] = CFF_read_arcmap_table_XY(filename)
% [X,Y] = CFF_read_arcmap_table_XY(filename)
%
% DESCRIPTION
%
% quick dirty function to read XY data in arcmap tables exported as text
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

T = CFF_readtable(filename);

X = str2num(cell2mat(T.POINT_X));
Y = str2num(cell2mat(T.POINT_Y));
