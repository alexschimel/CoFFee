function FPBS = CFF_project_nav(FPBS,ellips,tmproj)
% FPBS = CFF_project_nav(FPBS,ellips,tmproj)
%
% DESCRIPTION
%
% Project Ping lat/long to desired projection. Also corrects heading for
% grid convergence.
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
% - FPBS: Ping must have fields Lat and Long
%
% - ellips: code string for the input coordinates' ellipsoid.
%              supported codes: 'wgs84', 'grs80'
%
% - tmproj: code string for the ouptut transverse mercator projection.
%              supported codes:
%
%       'utm' -> Universal Transvere Mercator projection without zone
%       specified. The function computes the longitudinal zone for input
%       coordinates and returns the result in variable utmzone. Note: UTM
%       projection is based on WGS84 ellipsoid.
%
%       'utmXXY' -> Universal Transvere Mercator projection with sone
%       specified, where XX is the zone and Y the hemisphere (ex: UTM60S).
%       Note: UTM projection is based on WGS84 ellipsoid.
%
%       More options are available. See help for CFF_ll2tm.m
%
% OUTPUT VARIABLES
%
% - FPBS: Updated FPBS with fields Easting and Northing
%
% RESEARCH NOTES
%
% This function uses CFF_ll2tm
%
% NEW FEATURES
%
% 2014-09-30: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

% convert posLatitude/posLongitude to easting/northing/grid convergence:
[Easting, Northing, GridConvergence] = CFF_ll2tm(FPBS.Ping.Longitude, FPBS.Ping.Latitude, ellips, tmproj);

% Update FPBS
FPBS.Ping.Easting         = Easting;
FPBS.Ping.Northing        = Northing;
FPBS.Ping.GridConvergence = GridConvergence;

