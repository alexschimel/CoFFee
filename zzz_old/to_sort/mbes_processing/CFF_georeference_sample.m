function [sampleEasting, sampleNorthing, sampleHeight,sampleAcrossDistance,sampleUpwardsDistance,sampleRange] = CFF_georeference_sample(idxSamples, startRangeSampleNumber, interSamplesDistance, beamPointingAngle, sonarEasting, sonarNorthing, sonarHeight, sonarHeading)
% CFF_georeference_sample.m
%
% Get range, swathe coordinates (across and upwards distance from sonar),
% and projected coordinates (easting, northing, height) of any sample based
% on the sample number, sample number offset, inter-samples distance, beam
% pointing angle and the sonar's [projected coordinates and orientation
% (heading)
%
% *INPUT VARIABLES*
%
% * |idxSamples|: Required. A SBP array of samples indices. Can be S1 for
% common samples across all beams and pings. (or SB1 or S1P).
% * |startSampleNumber|: Required. A BP matrix (or B1 for 1 ping) of the
% offset number to add to idxSamples in each ping/beam.
% * |interSamplesDistance|: Required. A 1P matrix (or 1 scalar for 1 ping)
% of the distance between two samples in each beam.
% * |beamPointingAngle|: Required. A BP matrix (or B1 for 1 ping) of beam
% pointing angle in each ping/beam 
% * |sonarEasting|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% sonar's Easting coordinate in the projected frame.
% * |sonarNorthing|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% sonar's Northing coordinate in the projected frame.
% * |sonarHeight|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% sonar's Height coordinate in the projected frame.
% * |sonarHeading|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% swathe's heading.
%
% *OUTPUT VARIABLES*
%
% * |sampleEasting|: A SBP matrix (or SB for 1 ping) of each sample's
% Easting coordinate in the projected frame.
% * |sampleNorthing|: A SBP matrix (or SB for 1 ping) of each sample's
% Northing coordinate in the projected frame. 
% * |sampleHeight|: A SBP matrix (or SB for 1 ping) of each sample's Height
% coordinate in the projected frame.
% * |sampleAcrossDistance|: A SBP matrix (or SB for 1 ping) of each
% sample's distance across (in m) from the sonar.
% * |sampleUpwardsDistance|: A SBP matrix (or SB for 1 ping) of each
% sample's distance upwards (in m) from the sonar.
% * |sampleRange|: A SBP matrix (or SB for 1 ping) of each sample's range
% (in m) from the sonar.
%
%   Copyright 2017-2018 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% Calculate range for the sample(s). 
% For water column, you need to take
% into account the startRangeSampleNumber to compute range as:
% range = interSamplesDistance*(idxSamples+startRangeSampleNumber)
%
% For the sample corresponding to bottom detect, there should not be an offset.
sampleRange = CFF_get_samples_range(idxSamples,startRangeSampleNumber,interSamplesDistance);


%% Calculate sample(s) cartesian coordinates in the swath frame:
% - origin: sonar face
% - Xs: across distance (positive ~starboard) = -range*sin(pointingAngle)
% - Ys: along distance (positive ~forward) = 0
% - Zs: up distance (positive up) = -range*cos(pointingAngle)
[sampleAcrossDistance,sampleUpwardsDistance] = CFF_get_samples_dist(sampleRange,beamPointingAngle);


%% Calculate sample(s) projected coordinates:
% - origin: the (0,0) Easting/Northing projection reference and datum reference
% - Xp: Easting (positive East) = sonarEasting + sampleAcrossDist*cos(heading)
% - Yp: Northing (grid North, positive North) = sonarNorthing + sampleAcrossDist*sin(heading)
% - Zp: Elevation/Height (positive up) = sonarHeight + sampleUpDist
[sampleEasting, sampleNorthing, sampleHeight] = CFF_get_samples_ENH(sonarEasting,sonarNorthing,sonarHeight,sonarHeading,sampleAcrossDistance,sampleUpwardsDistance);



