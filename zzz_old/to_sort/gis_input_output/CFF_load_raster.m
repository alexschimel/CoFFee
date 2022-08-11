function [Z,X,Y] = CFF_load_raster(IN)
% [Z,X,Y] = CFF_load_raster(IN)
%
% DESCRIPTION
%
% load raster "IN" allowing for a range of formats
%
% USE
%
% "IN" can be:
% - a filename to be loaded (as a string of characters) 
% or data as:
% - a structure with fields X, Y and Z, or 
% - a 3D array with 3rd dimension being of length 3 and containing X,Y and
% Z.
% - a cell array of length 3 with each cell containing, in order, X, Y Z.
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