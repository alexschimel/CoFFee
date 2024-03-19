function [Z2,X2,Y2] = CFF_clip_raster(Z,X,Y,xv,yv)
%CFF_CLIP_RASTER  Clip raster
%
%   Clip raster Z with coordinates X,Y to the polygon of vertices xv,yv.
%   All grid points outside the polygon are set to NaN and then remove
%   unnecessary rows and columns.
%
%   See also CFF_COREGISTER_RASTERS.

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

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


