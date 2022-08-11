function [M,easting,northing] = CFF_read_asc(asc_file,varargin)
% [M,easting,northing] = CFF_read_asc(asc_file,varargin)
%
% DESCRIPTION
%
% read asc file
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
% - asc_file: filename
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
% YYYY-MM-DD: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

% using Nate wilsons' code
asc = ascgrid(asc_file);
M = asmatrix(asc);
[easting,northing] = coordmesh(asc);
