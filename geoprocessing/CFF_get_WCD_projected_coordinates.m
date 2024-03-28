function [sampleEasting, sampleNorthing, sampleHeight] = CFF_get_WCD_projected_coordinates(fData,iPing,nSamples)
%CFF_GET_WCD_PROJECTED_COORDINATES  Get projected coordinates for fData WCD
%
%   Computes the coordinates in the projected frame (Easting, Northing,
%   Height) of all samples of one ping of water-column data. These
%   coordinates are used for projected display.
%
%   The projected frame is defined as:
%   - origin: the (0,0) Easting/Northing projection/datum reference
%   - Xp: Easting (positive grid East)
%   - Yp: Northing (grid North, positive grid North)
%   - Zp: Elevation/Height (positive up)
%
%   [E,N,H] = CFF_GET_WCD_PROJECTED_COORDINATES(FDATA,IPING,NSAMPLES)
%   returns the easting E, northing N, and height H (all in m) in the
%   projected frame for all WCD samples with index 1 to NSAMPLES in ping
%   of index IPING in FDATA. 
%
%   See also CFF_GET_SAMPLES_ENH, CFF_GET_WCD_SWATHE_COORDINATES

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% extract coordinates of sonar
sonarHeight   = fData.X_1P_pingH(iPing); %m
sonarEasting  = fData.X_1P_pingE(iPing); %m
sonarNorthing = fData.X_1P_pingN(iPing); %m

% calculate sonar heading from vessel heading, sonar head heading offset,
% and grid convergence
gridConvergenceDeg   = fData.X_1P_pingGridConv(iPing); %deg
vesselHeadingDeg     = fData.X_1P_pingHeading(iPing); %deg
sonarHeadingOffsetDeg = fData.IP_ASCIIparameters.S1H; %deg

sonarHeadingDeg = - mod( gridConvergenceDeg + vesselHeadingDeg + sonarHeadingOffsetDeg, 360 );
sonarHeadingRad = deg2rad(sonarHeadingDeg);

% get the cartesian coordinates in the swath frame (i.e. the distances
% across and upwards from the sonar)
[sampleAcrossDistance,sampleUpwardsDistance] = CFF_get_WCD_swathe_coordinates(fData,iPing,nSamples);

% calculate coordinates in the projected frame
[sampleEasting, sampleNorthing, sampleHeight] = CFF_get_samples_ENH(...
    sonarEasting,sonarNorthing,sonarHeight,...
    sonarHeadingRad,...
    sampleAcrossDistance,sampleUpwardsDistance);