function [fData] = CFF_process_watercolumn(fData)
% [fData] = CFF_process_watercolumn(fData)
%
% DESCRIPTION
%
% Calculates the XY position in the swathe frame of each WC sample, as well
% as their XYZ position in the projected frame. Exact same calculations
% as in CFF_process_WC_bottom_detect.m
%
% Important Note: this code executes the same calculations on the WC
% samples as CFF_process_WC_bottom_detect.m executes on the bottom
% detection samples. If an improvement is made to one of these two
% functions, do it on the other as well.
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
% - 2016-12-01: Removed the bottom detect part and put it in its own
% function (CFF_process_WC_bottom_detect.m)
% - 2014-02-26: First version. Code adapted from old processing scripts

%   Copyright 2014-2016 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% Extract needed data

% dimensions:
nPings = size(fData.WC_PBS_SampleAmplitudes,1);
nBeams = size(fData.WC_PBS_SampleAmplitudes,2);
nSamples = size(fData.WC_PBS_SampleAmplitudes,3);

% grab ping info
P_soundSpeed = fData.WC_P1_SoundSpeed.*0.1; %m/s
P_samplingFrequency = fData.WC_P1_SamplingFrequency.*0.01; %Hz
P_sonarHeight = fData.X_P1_pingH; %m
P_sonarEasting = fData.X_P1_pingE; %m
P_sonarNorthing = fData.X_P1_pingN; %m
P_gridConvergence = fData.X_P1_pingGridConv; %deg
P_vesselHeading = fData.X_P1_pingHeading; %deg
P_sonarHeadingOffset = fData.IP_ASCIIparameters.S1H; %deg

% OWTT distance traveled in one sample
P_oneSampleDistance = P_soundSpeed./(P_samplingFrequency.*2);

% grab beam info
PB_startRangeSampleNumber = fData.WC_PB_StartRangeSampleNumber;
PB_beamPointingAngleDeg = fData.WC_PB_BeamPointingAngle.*0.01; %deg
PB_beamPointingAngleRad = PB_beamPointingAngleDeg.*pi./180; % in radians

% sample index (starting with zero)
S_indices = 0:nSamples-1;

% In THEORY, real-time compensation of roll and pitch means the Z for the
% swath frame is exactly the same as Z for elevation, so that we only need
% to rotate in the horizontal frame. In effect, we may want to recompute
% the true up pointing angle for the swath. For now, we'll make it simple:

% Compute the horizontal rotation angle between the swath frame (Ys forward
% and Yp northing)
P_theta = - mod( P_gridConvergence + P_vesselHeading + P_sonarHeadingOffset, 360 );
P_thetaRad = P_theta.*pi./180;


%% Compute range

% PBS arrays:
PBS_indices(1,1,:) = S_indices;
PBS_indices        = repmat(PBS_indices,[nPings nBeams 1]);
PBS_startRangeSampleNumber = repmat(PB_startRangeSampleNumber,[1 1 nSamples]);
PBS_beamPointingAngleRad   = repmat(PB_beamPointingAngleRad,[1 1 nSamples]);
PBS_oneSampleDistance      = repmat(P_oneSampleDistance,[1 nBeams nSamples]);

% range calculation
PBS_sampleRange = ( PBS_indices + PBS_startRangeSampleNumber ) .* PBS_oneSampleDistance;

% Compute Cartesian coordinates in the swath frame:
% - origin: sonar face
% - Xs: across distance (positive ~starboard)
% - Ys: always zero (positive ~forward)
% - Zs: up distance (positive up)
PBS_sampleUpDist     = -PBS_sampleRange .* cos(PBS_beamPointingAngleRad);
PBS_sampleAcrossDist = -PBS_sampleRange .* sin(PBS_beamPointingAngleRad);

% More PBS arrays:
PBS_sonarEasting  = repmat(P_sonarEasting,[1 nBeams nSamples]);
PBS_sonarNorthing = repmat(P_sonarNorthing,[1 nBeams nSamples]);
PBS_sonarHeight   = repmat(P_sonarHeight,[1 nBeams nSamples]);
PBS_thetaRad      = repmat(P_thetaRad,[1 nBeams nSamples]);

% Compute projected coordinates:
% - origin: the (0,0) Easting/Northing projection reference and datum reference
% - Xp: Easting (positive East)
% - Yp: Northing (grid North, positive North)
% - Zp: Elevation/Height (positive up)
PBS_sampleEasting  = PBS_sonarEasting  + PBS_sampleAcrossDist.*cos(PBS_thetaRad);
PBS_sampleNorthing = PBS_sonarNorthing + PBS_sampleAcrossDist.*sin(PBS_thetaRad);
PBS_sampleHeight   = PBS_sonarHeight   + PBS_sampleUpDist;

%% Save back in fData

fData.X_P_oneSampleDistance = P_oneSampleDistance;
fData.X_PBS_sampleRange = PBS_sampleRange;
fData.X_PBS_beamPointingAngleRad = PBS_beamPointingAngleRad;
fData.X_PBS_sampleUpDist = PBS_sampleUpDist;
fData.X_PBS_sampleAcrossDist = PBS_sampleAcrossDist;
fData.X_PBS_sampleEasting = PBS_sampleEasting;
fData.X_PBS_sampleNorthing = PBS_sampleNorthing;
fData.X_PBS_sampleHeight = PBS_sampleHeight;
