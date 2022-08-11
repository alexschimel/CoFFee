%% CFF_georeference_WC_bottom_detect.m
%
% Get range, swathe coordinates (across and upwards distance from sonar),
% and projected coordinates (easting, northing, height) of the bottom
% detect samples
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
% * |fData|: Required. Structure for the storage of kongsberg EM series
% multibeam data in a format more convenient for processing. The data is
% recorded as fields coded "a_b_c" where "a" is a code indicating data
% origing, "b" is a code indicating data dimensions, and "c" is the data
% name. See the help of function CFF_convert_ALLdata_to_fData.m for
% description of codes. 
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with bottom detect georeferencing
% fields
%
% *DEVELOPMENT NOTES*
%
% * Function formerly named CFF_process_WC_bottom_detect.m
%
% *NEW FEATURES*
%
% * 2018-10-12: using default datagramSource. Not in input anymore.
% * 2018-10-11: Moved the georeferencing part into its own subfunction.
% Updated header before adding to Coffee v3 
% * 2018-10-04: updated varargin management to find datagramSource, to
% match CFF_compute_ping_navigation
% * 2017-10-10: removed the saving of beampointinganglerad (Alex Schimel)
% * 2017-10-10: New function recorded as v2 because of the changes in
% dimensions. Also, changed to match the latest changes in
% CFF_process_watercolumn_v2.m including the use of bsxfun to avoid repmat.
% Also updated the header (Alex Schimel).
% * 2016-12-01: First version. Code taken from CFF_process_watercolumn.m
% (Alex Schimel)
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
% Alexandre Schimel, NIWA.

%% Function
function [fData] = CFF_georeference_WC_bottom_detect(fData)

%% info extraction

% Extract needed ping info
datagramSource = fData.MET_datagramSource;
X_1P_soundSpeed           = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)).*0.1; %m/s
X_1P_samplingFrequencyHz  = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
X_1P_sonarHeight          = fData.X_1P_pingH; %m
X_1P_sonarEasting         = fData.X_1P_pingE; %m
X_1P_sonarNorthing        = fData.X_1P_pingN; %m
X_1P_gridConvergenceDeg   = fData.X_1P_pingGridConv; %deg
X_1P_vesselHeadingDeg     = fData.X_1P_pingHeading; %deg
X_1_sonarHeadingOffsetDeg = fData.IP_ASCIIparameters.S1H; %deg

% Extract needed beam info
% X_BP_startRangeSampleNumber = fData.WC_BP_StartRangeSampleNumber; % not needed for bottom detect (I think)
X_BP_beamPointingAngleDeg   = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource)).*0.01; %deg
X_BP_beamPointingAngleRad   = deg2rad(X_BP_beamPointingAngleDeg);

% Grab sample corresponding to bottom:
if isfield(fData, 'X_BP_bottomSample')
    % if fData contains a 'X_BP_bottomSample' field already, it means we
    % are requesting all other bottom values to be recalculated from this
    % (probably filtered) value.  
    X_BP_bottomSample = fData.X_BP_bottomSample;
else
    % If the field doesn't exist, then this is the first calculation
    % requested on the original bottom detect. 
    X_BP_bottomSample = fData.(sprintf('%s_BP_DetectedRangeInSamples',datagramSource)); %in sample number
    X_BP_bottomSample(X_BP_bottomSample==0) = NaN;
end

% in any case, permute dimensions to 1BP format
 X_1BP_bottomSample = permute(X_BP_bottomSample,[3,1,2]);

 
 
%% Computations

% OWTT distance traveled in one sample
X_1P_oneSampleDistance = X_1P_soundSpeed./(X_1P_samplingFrequencyHz.*2);

% Compute the horizontal rotation angle between the swath frame (Ys forward
% and Yp northing)
% In THEORY, real-time compensation of roll and pitch means the Z for the
% swath frame is exactly the same as Z for elevation, so that we only need
% to rotate in the horizontal frame. In effect, we may want to recompute
% the true up pointing angle for the swath. For now, we'll make it simple:
X_1P_thetaDeg = - mod( X_1P_gridConvergenceDeg + X_1P_vesselHeadingDeg + X_1_sonarHeadingOffsetDeg, 360 );
X_1P_thetaRad = deg2rad(X_1P_thetaDeg);

% Now we have all we need to georeference those bottom detect samples
[X_1BP_bottomEasting, X_1BP_bottomNorthing, X_1BP_bottomHeight, X_1BP_bottomAcrossDist, X_1BP_bottomUpDist, X_1BP_bottomRange] = CFF_georeference_sample(X_1BP_bottomSample, 0, X_1P_oneSampleDistance, X_BP_beamPointingAngleRad, X_1P_sonarEasting, X_1P_sonarNorthing, X_1P_sonarHeight, X_1P_thetaRad);


%% saving

fData.X_BP_bottomSample         = X_BP_bottomSample;
fData.X_BP_bottomRange          = permute(X_1BP_bottomRange,[2,3,1]);
fData.X_PB_beamPointingAngleRad = X_BP_beamPointingAngleRad;
fData.X_BP_bottomUpDist         = permute(X_1BP_bottomUpDist,[2,3,1]);
fData.X_BP_bottomAcrossDist     = permute(X_1BP_bottomAcrossDist,[2,3,1]);
fData.X_BP_bottomEasting        = permute(X_1BP_bottomEasting,[2,3,1]);
fData.X_BP_bottomNorthing       = permute(X_1BP_bottomNorthing,[2,3,1]);
fData.X_BP_bottomHeight         = permute(X_1BP_bottomHeight,[2,3,1]);



