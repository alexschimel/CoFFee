%% CFF_get_samples_dist.m
%
% Compute samples' coordinates in the swath frame (Distances across and
% upwards from sonar) from the samples' range and beam pointing angle.
%
%% Help
%
% *USE*
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
% * 2018-10-11: first version. 
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
% Yoann Ladroit, Alexandre Schimel, NIWA.

%% Function
function [sampleAcrossDistance,sampleUpwardsDistance] = CFF_get_samples_dist(sampleRange,beamPointingAngle)

% permute dimensions of input to get everything as SBP matrices
beamPointingAngle = permute(beamPointingAngle,[3,1,2]);

% compute outputs
sampleAcrossDistance  = bsxfun(@times,-sampleRange,sin(beamPointingAngle));
sampleUpwardsDistance = bsxfun(@times,-sampleRange,cos(beamPointingAngle));

end