function out = CFF_disk(radius)
% out = CFF_disk(radius)
%
% DESCRIPTION
%
% create an array of 0-1s where 1s form a disk (use as a structural element
% strel)
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


X = [-radius:1:radius];
Y = flipud(X');
[XX,YY] = meshgrid(X,Y);
out = sqrt(XX.^2+YY.^2)<=radius;
