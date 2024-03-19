function [M,easting,northing] = CFF_read_asc(asc_file,varargin)
% [M,easting,northing] = CFF_read_asc(asc_file,varargin)
%
% DESCRIPTION
%
% read asc file
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% using Nate wilsons' code
asc = ascgrid(asc_file);
M = asmatrix(asc);
[easting,northing] = coordmesh(asc);
