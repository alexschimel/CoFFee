function [vi,wi] = CFF_weightgrid(x,y,v,xi,yi,w)
%CFF_WEIGHTGRID  Weight gridding of 2D points
%
%   IMPORTANT NOTE: This function is now obsolete. Use CFF_weightgrid_2D.m
%   instead. 
%   Function for weighted gridding of (x,y,v,w) data (v=value, w=weight) on
%   (xi,yi) grid. Returns vi and total weight wi. xi & yi must be three
%   elements vectors describing (1) the first value,(2) the step
%   (resolution) and (3) the total number of elements.
%   If weight is constant (=1), the calculation is a simple averaging and
%   the returned weight is the density of points that contributed to the
%   cell value.
%
%   To avoid using "find" in gridding (which slows down the code
%   considerably), this function requires the gridded vectors to be
%   linearly spaced (ie have a constant space between each element). But
%   issues in floating-point accuracy makes this complicated. So instead,
%   the code requests not the grid points of xi, yi but simply the defining
%   parameters (first value, step, number of elements).
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2014-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


warning('IMPORTANT NOTE: This function is now obsolete. Use CFF_weightgrid_2D.m instead.');

% prepare interpolation grids
xi_firstval = xi(1);
xi_step = xi(2);
xi_numel = xi(3);

yi_firstval = yi(1);
yi_step = yi(2);
yi_numel = yi(3);

% note: this is unused but just for info, here's how you'd build the grid
% vectors from these parameters:
% xi_grid=[0:xi_numel-1].*xi_step + xi_firstval;
% yi_grid=[0:yi_numel-1].*yi_step + yi_firstval;

% turn (x,y,v,w) variables to vectors
x = reshape(x,1,[]);
y = reshape(y,1,[]);
v = reshape(v,1,[]);
w = reshape(w,1,[]);

% if weight is a single value (1), expand to size of other variables
if length(w)==1
    w=ones(size(x));
end

% find x,y values that are outside the grid & remove them
indout = x<xi_firstval | x>(xi_numel-1).*xi_step+xi_firstval | y<yi_firstval | y>(yi_numel-1).*yi_step+yi_firstval;
x(indout)=[];
y(indout)=[];
v(indout)=[];
w(indout)=[];

% define a default NO_VALUE that allows progressive averaging (can't use
% NaN). This value must be impossible to attain during the averaging. We'll
% replace it with NaN at the end so no worries
NO_VALUE = floor(min(v))-1000;

% initialize arrays
vi = NO_VALUE.*ones(yi_numel,xi_numel);
wi = zeros(yi_numel,xi_numel);

% perform weight gridding
for ii = 1:length(v)
    if ~isnan(v(ii))
        
        % take value one by one
        thisx = x(ii);
        thisy = y(ii);
        thisv = v(ii);
        thisw = w(ii);
        
        % find appropriate cell indices
        i_Yi = round(((thisy-yi_firstval)./yi_step)+1);
        i_Xi = round(((thisx-xi_firstval)./xi_step)+1);
        
        % add new value to cell according to its weight
        vi(i_Yi,i_Xi)  = ((vi(i_Yi,i_Xi).*wi(i_Yi,i_Xi))+thisv.*thisw)./(wi(i_Yi,i_Xi)+thisw);
        
        % update cell weight
        wi(i_Yi,i_Xi) = wi(i_Yi,i_Xi)+thisw;
        
    end
end

% put NaN instead of NO_VALUE in the grid cells that were not filled
vi(vi==NO_VALUE) = NaN;

