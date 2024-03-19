function [sampleAcrossDistance,sampleUpwardsDistance] = CFF_get_samples_dist(sampleRange,beamPointingAngle)
% CFF_get_samples_dist.m
%
% Compute samples' coordinates in the swath frame (Distances across and
% upwards from sonar) from the samples' range and beam pointing angle.
%
% Calculate sample(s) cartesian coordinates in the swath frame:
% - origin: sonar face
% - Xs: across distance (positive ~starboard) = -range*sin(pointingAngle)
% - Ys: along distance (positive ~forward) = 0
% - Zs: up distance (positive up) = -range*cos(pointingAngle)
%
% *INPUT VARIABLES*
%
% * |sampleRange|: Required. A SBP matrix (or SB for 1 ping, or 1BP for a
% common sample across all beams and pings, etc.) of each sample's range
% (in m) from the sonar  
% * |beamPointingAngle|: Required. A BP matrix (or B1 for 1 ping) of beam
% pointing angle in each ping/beam 
%
% *OUTPUT VARIABLES*
%
% * |sampleAcrossDistance|: A SBP matrix (or SB for 1 ping) of each
% sample's distance across (in m) from the sonar.
% * |sampleUpwardsDistance|: A SBP matrix (or SB for 1 ping) of each
% sample's distance upwards (in m) from the sonar.
%
%   Copyright 2017-2018 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% permute dimensions of input to get everything as SBP matrices
beamPointingAngle = permute(beamPointingAngle,[3,1,2]);

% compute outputs
sampleAcrossDistance  = bsxfun(@times,-sampleRange,sin(beamPointingAngle));
sampleUpwardsDistance = bsxfun(@times,-sampleRange,cos(beamPointingAngle));

end