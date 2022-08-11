function [xg,yg,zg] = CFF_init_grid(x_lim,y_lim,varargin)
%CFF_INIT_GRID  Define grid vectors from input x,y or x,y,z data
%
%   [XG,YG] = CFF_INIT_GRID(X_LIM,Y_LIM), where X_LIM and Y_LIM are two
%   elements vectors containing the data min and max limits in the x,y
%   dimensions, returns vectors containing the x,y coordinates of the
%   middle of grid cells with grid size equal to 1. 
%
%   CFF_INIT_GRID(...,RES) uses RES for grid size instead of the default
%   value of 1. 
%
%   [XG,YG,ZG] = CFF_INIT_GRID(X_LIM,Y_LIM,RES,Z_LIM) does the same thing
%   but with an added third dimension z. The grid size in z is also RES.
%
%   CFF_INIT_GRID(X_LIM,Y_LIM,RES,Z_LIM,Z_RES) does the same thing but
%   where Z_RES defines the grid size in z, so potentially different than
%   the grid size RES in x,y.
%
%   Note: Strategy of grid definition from input, using the x dimension as
%   example:
%   1. x_lim(1) is the center of the first grid cell
%   2. points falling between x_lim(1)-res/2 (included) and x_lim(1)+res/2
%   (excluded) will be gridded in that first grid cell.
%   3. There are as many grid cells as necessary to include a point at
%   x_lim(2).
%   For example, with x_lim = [2 5] and res = 2, this function will return
%   xg = [2,4,6], as the middle coordinates of the columns with bounds:
%   [1-3[, [3-5[, and [5-7[.
%
%   See also CFF_GRID_LINES, CFF_GRID_DATA

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no)
%   2017-2022; Last revision: 06-04-2022

% input parser
p = inputParser;
addRequired(p,'x_lim',     @(u) validateattributes(u,{'numeric'},{'numel',2,'increasing'}));
addRequired(p,'y_lim',     @(u) validateattributes(u,{'numeric'},{'numel',2,'increasing'}));
addOptional(p,'res',    1, @(u) validateattributes(u,{'numeric'},{'scalar','positive'}));
addOptional(p,'z_lim', [], @(u) validateattributes(u,{'numeric'},{'numel',2,'increasing'}));
addOptional(p,'z_res', [], @(u) validateattributes(u,{'numeric'},{'scalar','positive'}));
parse(p,x_lim,y_lim,varargin{:});
res = p.Results.res;
z_lim = p.Results.z_lim;
z_res = p.Results.z_res;
clear p;

% total number of columns (x) and rows (y)
n_cols = round((x_lim(2)-x_lim(1))./res+1);
n_rows = round((y_lim(2)-y_lim(1))./res+1);

% coordinates of middle of cells
xg = (0:1:n_cols-1).*res + x_lim(1);
yg = (0:1:n_rows-1)'.*res + y_lim(1);

% same thing in z dimension if requested
if ~isempty(z_lim)
    % if no input z_res, use res
    if isempty(z_res)
        z_res = res;
    end
    % total number of layers (z)
    n_lays = round((z_lim(2)-z_lim(1))./z_res+1);
    % middle coordinates
    zg = (0:1:n_lays-1).*z_res + z_lim(1);
end

