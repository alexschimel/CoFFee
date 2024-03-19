function [SBP_sampleAcrossDistance,SBP_sampleUpwardsDistance] = CFF_get_samples_dist(SBP_sampleRange,BP_beamPointingAngle)
%CFF_GET_SAMPLES_DIST  Sample coordinates in swath frame from range & angle
%
%   Computes the cartesian coordinates in the swath frame (i.e. the
%   distances across and upwards from the sonar) of samples using their
%   range and beam pointing angle. 
%
%   The swath frame is defined as:
%   - origin: sonar face
%   - Xs: across distance (positive ~starboard)
%   - Ys: along distance (positive ~forward)
%   - Zs: up distance (positive up)
%
%   [ACD,UPD] = CFF_GET_SAMPLES_DIST(R,THETA) returns the across distance
%   ACD and the upward distance UPD (both in m) in the swath frame of
%   samples, from their range R from the sonar (in m) and the beam pointing
%   angle THETA (in rad). R must be a SBP tensor or compatible (e.g. a SB
%   matrix for 1 ping, or a 1BP matrix for a common sample across all beams
%   and pings, etc.). THETA must be a BP matrix or compatible (e.g. B1 or
%   1P vector) of beam pointing angle in each ping/beam (in radians). The
%   returned ACD and UPD are SBP matrices (or SB for 1 ping).  
%
%   See also CFF_GET_SAMPLES_RANGE, CFF_GET_SAMPLES_ENH,
%   CFF_GEOREFERENCE_SAMPLE 

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% permute dimension of angle input to get SBP matrix-compatible
SBP_beamPointingAngle = permute(BP_beamPointingAngle,[3,1,2]);

% compute outputs
SBP_sampleAcrossDistance  = -SBP_sampleRange.*sin(SBP_beamPointingAngle);
SBP_sampleUpwardsDistance = -SBP_sampleRange.*cos(SBP_beamPointingAngle);

end