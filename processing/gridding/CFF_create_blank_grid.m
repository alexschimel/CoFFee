function [gridX,gridY,gridNaN] = CFF_create_blank_grid(x,y,res)
%CFF_CREATE_BLANK_GRID  Prepare blank grid for 2D data
%
%   Takes data coordinates (x,y) (vector or matrices of any dimensions) and
%   generate grid coordinate vectors (gridX,gridY) at desired resolution
%   (res), along with a 2D grid indicating cells where there are no data
%   (gridNaN) to use as mask.
%
%   See also CFF_GRID_2D_DATA.

%   Copyright 2021-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% calculate grid coordinates
idxKeep = ~isnan(x(:)) & ~isnan(y(:));
gridX = min(x(idxKeep)):res:max(x(idxKeep));
gridY = (min(y(idxKeep)):res:max(y(idxKeep)))';

% indices of data points in grid
iX = floor((x(idxKeep)-gridX(1))/res)+1;
iY = floor((y(idxKeep)-gridY(1))/res)+1;
subs = single([iY iX]);

% size of output grid
sz = single([numel(gridY) numel(gridX)]);

% use accumarray to generate grid
gridNaN = accumarray(subs,ones(numel(x(idxKeep)),1),sz,@(x) sum(x),0);
gridNaN = gridNaN==0;