function [sampleAcrossDist,sampleUpDist] = CFF_get_WC_coordinates(fData,iPing,nSamples)
%CFF_GET_WC_COORDINATES  WCD samples coordinates in swath frame from fData
%
%   Computes the cartesian coordinates in the swath frame (i.e. the
%   distances across and upwards from the sonar) of all samples of
%   water-column data in one ping. Use this function along with
%   CFF_GET_WC_DATA to get the coordinates of the data for wedge display. 
%
%   The swath frame is defined as:
%   - origin: sonar face
%   - Xs: across distance (positive ~starboard)
%   - Ys: along distance (positive ~forward) = 0
%   - Zs: up distance (positive up)
%
%   [ACD,UPD] = CFF_GET_WC_COORDINATES(FDATA,IPING,NSAMPLES) returns the
%   across distance ACD and the upward distance UPD (both in m) in the
%   swath frame for all WCD samples with index 1 to NSAMPLES in ping of
%   index IPING in FDATA. 
%
%   See also CFF_GET_WC_DATA, CFF_INTER_SAMPLE_DISTANCE,
%   CFF_GET_SAMPLES_RANGE, CFF_GET_SAMPLES_DIST, CFF_GEOREFERENCE_SAMPLE

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2022-2022; Last revision: 20-07-2022

% get source datagram
datagramSource = CFF_get_datagramSource(fData);

% get the range from sonar (in m) for each sample index
idxSamples = (1:nSamples)';
startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,iPing);
interSamplesDistance = CFF_inter_sample_distance(fData,iPing);
sampleRange = CFF_get_samples_range(idxSamples,startSampleNumber,interSamplesDistance);

% get beam pointing angle (in rad)
sampleAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,iPing));

% calculate and return swath coordinates
[sampleAcrossDist,sampleUpDist] = CFF_get_samples_dist(sampleRange,sampleAngle);

