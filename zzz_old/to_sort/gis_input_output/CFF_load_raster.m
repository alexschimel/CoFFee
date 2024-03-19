function [Z,X,Y] = CFF_load_raster(IN)
%CFF_LOAD_RASTER  Load raster
%
%   Load raster IN allowing for a range of formats.
%
%   "IN" can be:
%   - a filename to be loaded (as a string of characters) or data as:
%   - a structure with fields X, Y and Z, or 
%   - a 3D array with 3rd dimension being of length 3 and containing X,Y
%   and Z. 
%   - a cell array of length 3 with each cell containing, in order, X, Y Z.
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(IN) && exist(IN,'file')
    % IN is a file
    [pathstr,name,ext] = fileparts(IN);
    if strcmp(ext,'.tif') || strcmp(ext,'.tiff')
        % IN is a tif file to be loaded
        [Z,X,Y] = CFF_read_tif(IN);
    elseif strcmp(ext,'.asc')
        % IN is an asc file to be loaded
        [Z,X,Y] = CFF_read_asc(IN);
    end
elseif isstruct(IN)
    if isfield(IN,'X') && isfield(IN,'Y') && isfield(IN,'Z')
        X = IN.X;
        Y = IN.Y;
        Z = IN.Z;
    end
elseif iscell(IN) && max(size(IN))== 3
    X = IN{1};
    Y = IN{2};
    Z = IN{3};
elseif isnumeric(IN) && size(IN,3) == 3
    X = IN(:,:,1);
    Y = IN(:,:,2);
    Z = IN(:,:,3);
end