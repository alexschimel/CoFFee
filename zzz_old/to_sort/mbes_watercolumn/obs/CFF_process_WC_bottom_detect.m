function [fData] = CFF_process_WC_bottom_detect(fData)
% [fData] = CFF_process_WC_bottom_detect(fData)
%
% DESCRIPTION
%
% Calculates the XY position in the swathe frame of each bottom detection,
% as well as their XYZ position in the projected frame. Exact same
% calculations as in CFF_process_watercolumn.m
%
% Important Note: this code executes the same calculations on the bottom
% detect sample as CFF_process_watercolumn.m executes on all WC samples. If
% an improvement is made to one of these two functions, do it on the other
% as well.
%
% INPUT VARIABLES
%
% - 
%
% OUTPUT VARIABLES
%
% - 
% RESEARCH NOTES
%
% - This code uses way too much memory and time to build arrays that may
% not be necessary (PBS). Change this at some point.
%
% NEW FEATURES
%
% - 2016-12-01: First version. Code taken from CFF_process_watercolumn.m

%   Copyright 2014-2016 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% Extract needed data

% dimensions:
nBeams = size(fData.WC_PB_BeamPointingAngle,2);

% grab ping info
P_soundSpeed = fData.WC_P1_SoundSpeed.*0.1; %m/s
P_samplingFrequency = fData.WC_P1_SamplingFrequency.*0.01; %Hz
P_sonarHeight = fData.X_P1_pingH; %m
P_sonarEasting = fData.X_P1_pingE; %m
P_sonarNorthing = fData.X_P1_pingN; %m
P_gridConvergence = fData.X_P1_pingGridConv; %deg
P_vesselHeading = fData.X_P1_pingHeading; %deg
P_sonarHeadingOffset = fData.IP_ASCIIparameters.S1H; %deg

% grab beam info
PB_beamPointingAngleDeg = fData.WC_PB_BeamPointingAngle.*0.01; %deg

% turn P vectors into needed PB arrays

% formerly, using repmat
% PB_sonarEasting = repmat(P_sonarEasting ,[1 nBeams]);
% PB_sonarNorthing = repmat(P_sonarNorthing ,[1 nBeams]);
% PB_sonarHeight = repmat(P_sonarHeight ,[1 nBeams]);

% now using multiplication by one arrays
PB_sonarEasting = P_sonarEasting .* ones(1,nBeams);
PB_sonarNorthing = P_sonarNorthing .* ones(1,nBeams);
PB_sonarHeight = P_sonarHeight .* ones(1,nBeams);


%% Necessary computations

% Compute OWTT distance traveled in one sample
P_oneSampleDistance = P_soundSpeed./(P_samplingFrequency.*2);
% PB_oneSampleDistance = repmat(P_oneSampleDistance ,[1 nBeams]);
PB_oneSampleDistance = P_oneSampleDistance .* ones(1,nBeams);

% Compute beam pointing angles in radians
PB_beamPointingAngleRad = PB_beamPointingAngleDeg.*pi./180; % in radians

% In THEORY, real-time compensation of roll and pitch means the Z for the
% swath frame is exactly the same as Z for elevation, so that we only need
% to rotate in the horizontal frame. In effect, we may want to recompute
% the true up pointing angle for the swath. For now, we'll make it simple:

% Compute the horizontal rotation angle between the swath frame (Ys forward
% and Yp northing)
P_theta = - mod(P_gridConvergence+P_vesselHeading+P_sonarHeadingOffset,360);
P_thetaRad = P_theta.*pi./180;
% PB_thetaRad = repmat(P_thetaRad,[1 nBeams]);
PB_thetaRad = P_thetaRad .* ones(1,nBeams);

%% Bottom detection computations

% Grab sample corresponding to bottom:
% - if fData contains a 'X_PB_bottomSample' field already, it means we are
% requesting all other bottom values to be recalculated from this (probably
% filtered) value. If the field doesn't exist, then this is the first
% calculation requested on the original bottom detect.
if isfield(fData, 'X_PB_bottomSample')
    PB_bottomSample = fData.X_PB_bottomSample; %in sample number
else
    PB_bottomSample = fData.WC_PB_DetectedRangeInSamples; %in sample number
    PB_bottomSample(PB_bottomSample==0) = NaN;
end

% Compute range
PB_bottomRange = PB_bottomSample .* PB_oneSampleDistance;

% Compute Cartesian coordinates in the swath frame:
% - origin: sonar face
% - Xs: across distance (positive ~starboard)
% - Ys: always zero (positive ~forward)
% - Zs: up distance (positive up)
PB_bottomUpDist     = -PB_bottomRange .* cos(PB_beamPointingAngleRad);
PB_bottomAcrossDist = -PB_bottomRange .* sin(PB_beamPointingAngleRad);

% Compute projected coordinates:
% - origin: the (0,0) Easting/Northing projection reference and datum reference
% - Xp: Easting (positive East)
% - Yp: Northing (grid North, positive North)
% - Zp: Elevation/Height (positive up)
PB_bottomEasting  = PB_sonarEasting  + PB_bottomAcrossDist.*cos(PB_thetaRad);
PB_bottomNorthing = PB_sonarNorthing + PB_bottomAcrossDist.*sin(PB_thetaRad);
PB_bottomHeight   = PB_sonarHeight   + PB_bottomUpDist;


%% Save back in fData
fData.X_PB_bottomSample = PB_bottomSample;
fData.X_PB_bottomRange = PB_bottomRange;
fData.X_PB_beamPointingAngleRad = PB_beamPointingAngleRad;
fData.X_PB_bottomUpDist = PB_bottomUpDist;
fData.X_PB_bottomAcrossDist = PB_bottomAcrossDist;
fData.X_PB_bottomEasting = PB_bottomEasting;
fData.X_PB_bottomNorthing = PB_bottomNorthing;
fData.X_PB_bottomHeight = PB_bottomHeight;

