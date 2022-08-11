function [gridV, gridX, gridY, interpolant] = CFF_grid_2D_data(x,y,v,res,interpolant)
%CFF_GRID_2D_DATA  Grid 2D data
%
%   Grid 2D data values 'v' at resolution 'res' given the data's
%   coordinates 'x' (columns) and 'y' (rows). Optionally, use in input an
%   existing 'interpolant' (class scatteredInterpolant) already fitted to
%   the data to speed up the gridding process (see below information of
%   this variable). 
%
%   Gridding resolution is the same in x and y dimensions.
%
%   Dimensions of x, y and v must all match. Can be vectors or arrays.
%
%   Gridding creates a scatteredInterpolant from the x,y,v data. This
%   operation is what takes the longest time. The function returns this
%   scatteredInterpolant as 'interpolant', so it can be re-used in input of
%   this function for a subsequent re-gridding of the same data, which will
%   then be significantly faster.
%
%   It is possible to grid multiple datasets v1,v2,... sharing the same
%   coordinates x,y, using a cell array for 'v'. Each element of that cell
%   array mut obey the dimensions rules above, and the optional
%   'interpolant' in input must also match the number of datasets. The
%   outputs 'gridV' and 'interpolant' are then also cell arrays of
%   corresponding size. 
%
%   See also CFF_CREATE_BLANK_GRID.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2021-2021; Last revision: 24-11-2021


%% Input management

% number of datasets to grid
if isnumeric(v)
    nV = 1;
elseif iscell(v) && all(cellfun(@(x) isnumeric(x),v))
    nV = numel(v);
else
    error('v must be numeric or cell array of numeric');
end

% check that x,y,v dimensions match
if ~isnumeric(x) || ~isnumeric(y) 
    error('x and y must be numeric');
end
refDims = size(x);
if ~all(size(y)==refDims)
    error('dimensions of x and y must match');
end
if ( nV==1 && ~all(size(v)==refDims) ) || ...
   ( nV>1 && any(cellfun(@(ii) ~all(size(ii)==refDims),v)) )
    error('dimensions of v numeric array(s) must match that of x and y');
end

% interpolant(s)
if ~exist('interpolant','var') || isempty(interpolant)
    if nV == 1
        interpolant = [];
    else
        interpolant = cell(1,nV);
    end
end
interpolantValFun = @(x) (isnumeric(x)&&isempty(x)) || isa(x,'scatteredInterpolant'); 
if nV==1
    if ~interpolantValFun(interpolant)
        error('interpolant must be empty or of type ''scatteredInterpolant''');
    end
else
    if ~iscell(interpolant) || numel(interpolant)~=nV
        error('interpolant must be cell array of size matching that of v cell array');
    end
    if ~all(cellfun(interpolantValFun,interpolant))
        error('interpolant elements must be either empty or of type ''scatteredInterpolant''');
    end
end


%% Prep

% prepare grid coordinates, and the mask grid
[gridX,gridY,gridNaN] = CFF_create_blank_grid(x,y,res);

% indices of data to keep, based on x and y only
idxXYKeep = ~isnan(x) & ~isinf(x) & ~isnan(y) & ~isinf(y);

% gridding v. Keeping single and multiple cases separate to keep code fast
if nV == 1
    % single v array to grid
    % indices of data to keep
    idxKeep = idxXYKeep & ~isnan(v) & ~isinf(v);
    % prepare interpolant if it was not provided in input
    if isempty(interpolant)
        warning('off'); % disables scatteredInterpolant complaining about duplicate points. 
        interpolant = scatteredInterpolant(y(idxKeep),x(idxKeep),v(idxKeep),'natural','none');
        warning('on');
    end
    % apply interpolant
    gridV = interpolant({gridY,gridX});
    % mask data
    gridV(gridNaN) = NaN;
else
   % multiple v arrays to grid
    gridV = cell(size(v));
    for ii = 1:nV
        v_temp = v{ii};
        interpolant_temp = interpolant{ii};
        % indices of data to keep
        idxKeep = idxXYKeep & ~isnan(v_temp) & ~isinf(v_temp);
        % prepare interpolant if it was not provided in input
        if isempty(interpolant_temp)
            warning('off'); % disables scatteredInterpolant complaining about duplicate points. 
            interpolant_temp = scatteredInterpolant(y(idxKeep),x(idxKeep),v_temp(idxKeep),'natural','none');
            warning('on');
        end
        gridV_temp = interpolant_temp({gridY,gridX});
        % mask data
        gridV_temp(gridNaN) = NaN;
        % save in output cell array
        gridV{ii} = gridV_temp;
        interpolant{ii} = interpolant_temp;
    end
end