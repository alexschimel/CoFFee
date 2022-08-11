%% CFF_georeference_sample.m
%
% Get range, swathe coordinates (across and upwards distance from sonar),
% and projected coordinates (easting, northing, height) of any sample based
% on the sample number, sample number offset, inter-samples distance, beam
% pointing angle and the sonar's [projected coordinates and orientation
% (heading)
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._  
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX 
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
% sonar's Easting coordinate in the geographical frame.
% * |sonarNorthing|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% sonar's Northing coordinate in the geographical frame.
% * |sonarHeight|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% sonar's Height coordinate in the geographical frame.
% * |sonarHeading|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% swathe's heading.
%
% *OUTPUT VARIABLES*
%
% * |sampleEasting|: A SBP matrix (or SB for 1 ping) of each sample's
% Easting coordinate in the geographical frame.
% * |sampleNorthing|: A SBP matrix (or SB for 1 ping) of each sample's
% Northing coordinate in the geographical frame. 
% * |sampleHeight|: A SBP matrix (or SB for 1 ping) of each sample's Height
% coordinate in the geographical frame.
% * |sampleAcrossDistance|: A SBP matrix (or SB for 1 ping) of each
% sample's distance across (in m) from the sonar.
% * |sampleUpwardsDistance|: A SBP matrix (or SB for 1 ping) of each
% sample's distance upwards (in m) from the sonar.
% * |sampleRange|: A SBP matrix (or SB for 1 ping) of each sample's range
% (in m) from the sonar.
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._ 
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * 2018-10-11: first version. Combining code so that georeferencing of
% bottom sample and WC samples are now using the same code at all times
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._ 
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Yoann Ladroit, NIWA.

%% Function
function [sampleEasting, sampleNorthing, sampleHeight,sampleAcrossDistance,sampleUpwardsDistance,sampleRange] = CFF_georeference_sample(idxSamples, startRangeSampleNumber, interSamplesDistance, beamPointingAngle, sonarEasting, sonarNorthing, sonarHeight, sonarHeading)


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



