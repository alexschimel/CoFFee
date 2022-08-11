function [Z2,X2,Y2] = CFF_clip_raster(Z,X,Y,xv,yv)
% [Z2,X2,Y2] = CFF_clip_raster(Z,X,Y,xv,yv)
%
% DESCRIPTION
%
% clip raster Z with coordinates X,Y to the polygon of vertices xv,yv. All
% grid points outside the polygon are set to NaN and then remove
% unnecessary rows and columns.
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

% build mask
mask = nan(size(Z));
temp = inpolygon(X,Y,xv,yv);
mask(temp) = 1;

% apply mask
newZ = Z.*mask;

% find limits of data:
dataZ = ~isnan(newZ);

rows = double(any(dataZ,2));
irow_beg = find(rows,1,'first'); 
irow_end = find(rows,1,'last'); 

cols = double(any(dataZ,1));
icol_beg = find(cols,1,'first'); 
icol_end = find(cols,1,'last'); 

% output
Z2 = newZ(irow_beg:irow_end,icol_beg:icol_end);
X2 = X(irow_beg:irow_end,icol_beg:icol_end);
Y2 = Y(irow_beg:irow_end,icol_beg:icol_end);


