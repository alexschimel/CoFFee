function CFF_write_DOD_asc(DEM1,DEM2,filename)
%CFF_WRITE_DOD_ASC  Compute DOD and export as ESRI asc file
%
%   See also CFF_CALCULATE_DOD.

%   Copyright 2015-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% load DEM1 and DEM2
[Z1,Z1_easting,Z1_northing] = CFF_load_raster(DEM1);
[Z2,Z2_easting,Z2_northing] = CFF_load_raster(DEM2);

% co-register grids
[Z1,Z2,X,Y] = CFF_coregister_rasters(Z1,Z1_easting,Z1_northing,Z2,Z2_easting,Z2_northing);

% create dod
DOD = CFF_calculate_DOD(Z1,Z2);

% write as asc
CFF_write_asc(DOD,X,Y,filename)

