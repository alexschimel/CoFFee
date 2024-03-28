function [sampleEasting, sampleNorthing, sampleHeight] = CFF_get_samples_ENH(sonarEasting,sonarNorthing,sonarHeight,sonarHeading,sampleAcrossDistance,sampleUpwardsDistance)
%CFF_GET_SAMPLES_ENH  Compute samples coordinates in the projected frame
%
%   Compute coordinates in the projected frame (Easting, Northing,
%   Height) of samples using their coordinates in the swath frame
%   (Distances across and upwards). 
%
%   The projected frame is defined as:
%   - origin: the (0,0) Easting/Northing projection/datum reference
%   - Xp: Easting (positive grid East)
%   - Yp: Northing (grid North, positive grid North)
%   - Zp: Elevation/Height (positive up)

%   The swath frame is defined as:
%   - origin: sonar face
%   - Xs: across distance (positive ~starboard)
%   - Ys: along distance (positive ~forward)
%   - Zs: up distance (positive up)
%
%   [E,N,H] = CFF_GET_SAMPLES_ENH(SE,SN,SH,SHEADING,SAMPACD,SAMPUPD)
%   returns the easting E, northing N, and height H in the projected
%   frame of samples, from the sonar easting SE (in m), sonar northing SN
%   (in m), sonar height SH (in m), sonar heading SHEADING (in radians
%   relative to North?), and the samples' across distance SAMPACD (in m)
%   and upward distance SAMPUPD (in m) in the swath frame. SE, SN, SH, and
%   SHEADING must be matching 1P matrices or compatible (e.g. scalars for
%   one ping). SAMPACD and SAMPUPD must be SBP tensors or compatible (e.g.
%   SB matrices for 1 ping).
%
%   See also CFF_GET_SAMPLES_RANGE, CFF_GET_SAMPLES_DIST,
%   CFF_GEOREFERENCE_SAMPLE 

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% permute dimensions of input to get everything as SBP matrices
sonarEasting  = permute(sonarEasting,[3,1,2]);
sonarNorthing = permute(sonarNorthing,[3,1,2]);
sonarHeight   = permute(sonarHeight,[3,1,2]);
sonarHeading  = permute(sonarHeading,[3,1,2]);

% compute outputs
sampleEasting  = sonarEasting  + sampleAcrossDistance.*cos(sonarHeading);
sampleNorthing = sonarNorthing + sampleAcrossDistance.*sin(sonarHeading);
sampleHeight   = sonarHeight   + sampleUpwardsDistance;

% NOTE: We make the STRONG ASSUMPTION here that the projected and swath
% frames have THE SAME Z axis, so that going from one to the other only
% requires considering the rotation about the Z axis (aka heading/yaw),
% which includes the vessel heading, the sonar head heading offset, and the
% grid convergence (aka angle between true north and grid north). 
% 
% This is only valid if the system was corrected in real time for pitch
% and roll, and the single swath is pointed directly downwards. Aka, this
% is most likely wrong for multi-sectors, and systems using
% yaw-compensation.

end
