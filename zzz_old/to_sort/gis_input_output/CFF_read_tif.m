function [M,easting,northing] = CFF_read_tif(tif_file,varargin)
% [M,easting,northing] = CFF_read_tif(tif_file,varargin)
%
% DESCRIPTION
%
% read tif and tfw file. If tfw file unavailable, returns row and col
% number.
%
% INPUT VARIABLES
%
% - tif_file
% - varagin{1}: tfw file name
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% read tif file
M = imread(tif_file);
M = double(M);

% set no data value in tif to NaN
ims = imfinfo(tif_file);
if isfield(ims,'GDAL_NODATA')
    % test 1: maybe tiff file has a GDAL_NODATA value
    % code other possibilities of "no data" settings
    GDAL_NODATA = str2num(ims.GDAL_NODATA);
    % the following is dirty but I have no choice: My NODATA value in MBES
    % tiff files is -3.402823e+38 but in the data, it is
    % -3.4028230607371e+38 so they don't match. So I test for the presence
    % of the exact GDAL_NODATA value for now
    if any(M(:) == GDAL_NODATA)
        M( M == GDAL_NODATA ) = NaN;
    else
        M( M == min(M(:)) ) = NaN;
    end
else
    % last change, use minimum value in array for NaN
    M( M == min(M(:)) ) = NaN;
end

% indices grid
row = [1:size(M,1)]';
col = 1:size(M,2);
[col,row] = meshgrid(col,row);

% now find the tfw file
if nargin>1
    % check extension
    [pathstr,name,ext] = fileparts(varargin{1});
    if strcmp(ext,'.tfw')
        % input is a tfw file
        tfw_file = varargin{1};
    else
        % input is not a tfw file. Could be a tif file, which associated
        % tfw we want. Change extension
        tfw_file = [pathstr filesep name '.tfw'];
    end
else
    % try find a tfw associated with input tif
    [pathstr,name,ext] = fileparts(tif_file);
    tfw_file = [pathstr filesep name '.tfw'];
end

% now check existence of tfw file and read it
if exist(tfw_file,'file')
    
    % read
    tfw = CFF_read_tfw(tfw_file);
     
    % turn tfw to easting/northing grid
    easting = tfw(1).*col + tfw(3).*row + tfw(5);
    northing = tfw(2).*col + tfw(4).*row + tfw(6);
    
else
    
    % if tfw is not available, we'll use row and col for easting and
    % northing by default
    warning('Could not find a .tfw file. Exporting grid indices as easting/northing')
    easting = col;
    northing = flipud(row);
    
end

