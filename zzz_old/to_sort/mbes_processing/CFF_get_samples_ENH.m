function [sampleEasting, sampleNorthing, sampleHeight] = CFF_get_samples_ENH(sonarEasting,sonarNorthing,sonarHeight,sonarHeading,sampleAcrossDistance,sampleUpwardsDistance)
% CFF_get_samples_ENH.m
%
% Compute samples' coordinates in the geographical frame (Easting,
% Northing, Height) from their coordinates in the swath frame (Distances
% across and upwards). This requires the geographical coordinates of the
% swath frame origin (sonar), and the orientation of the swath frame in the
% geographical frame (vessel's heading).   
%
% *USE*
%
% Calculate sample(s) projected coordinates:
% - origin: the (0,0) Easting/Northing projection reference and datum
% reference 
% - Xp: Easting (positive East) = sonarEasting + sampleAcrossDist*cos(heading)
% - Yp: Northing (grid North, positive North) = sonarNorthing + sampleAcrossDist*sin(heading)
% - Zp: Elevation/Height (positive up) = sonarHeight + sampleUpDist
%
% *INPUT VARIABLES*
%
% * |sonarEasting|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% sonar's Easting coordinate in the geographical frame.
% * |sonarNorthing|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% sonar's Northing coordinate in the geographical frame.
% * |sonarHeight|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% sonar's Height coordinate in the geographical frame.
% * |sonarHeading|: Required. A 1P matrix (or 1 scalar for 1 ping) of the
% swathe's heading.
% * |sampleAcrossDistance|: Required. A SBP matrix (or SB for 1 ping) of
% each sample's distance across (in m) from the sonar.
% * |sampleUpwardsDistance|: Required. A SBP matrix (or SB for 1 ping) of
% each sample's distance upwards (in m) from the sonar.
%
% *OUTPUT VARIABLES*
%
% * |sampleEasting|: A SBP matrix (or SB for 1 ping) of each sample's
% Easting coordinate in the geographical frame.
% * |sampleNorthing|: A SBP matrix (or SB for 1 ping) of each sample's
% Northing coordinate in the geographical frame. 
% * |sampleHeight|: A SBP matrix (or SB for 1 ping) of each sample's Height
% coordinate in the geographical frame.

%   Copyright 2017-2018 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% permute dimensions of input to get everything as SBP matrices
sonarEasting  = permute(sonarEasting,[3,1,2]); 
sonarNorthing = permute(sonarNorthing,[3,1,2]); 
sonarHeight   = permute(sonarHeight,[3,1,2]);
sonarHeading  = permute(sonarHeading,[3,1,2]);

% compute outputs
sampleEasting  = bsxfun(@plus,sonarEasting,bsxfun(@times,sampleAcrossDistance,cos(sonarHeading)));
sampleNorthing = bsxfun(@plus,sonarNorthing,bsxfun(@times,sampleAcrossDistance,sin(sonarHeading)));
sampleHeight   = bsxfun(@plus,sonarHeight,sampleUpwardsDistance);

end
