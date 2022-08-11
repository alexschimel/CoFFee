function [sampleEasting, sampleNorthing, sampleHeight, sampleAcrossDistance, sampleUpwardsDistance, sampleRange] = CFF_georeference_sample(idxSamples, startRangeSampleNumber, interSamplesDistance, beamPointingAngle, sonarEasting, sonarNorthing, sonarHeight, sonarHeading)
%CFF_GEOREFERENCE_SAMPLE  Georeference samples
%
%   Get range, swathe coordinates (across and upwards distance from sonar),
%   and projected coordinates (easting, northing, height) of any sample
%   based on the sample index, sample start index offset, inter-samples
%   distance, beam pointing angle and the sonar's projected coordinates
%   and orientation (heading).
%
%   See also CFF_GET_SAMPLES_RANGE, CFF_GET_SAMPLES_DIST,
%   CFF_GET_SAMPLES_ENH

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 19-07-2022

% Calculate range
sampleRange = CFF_get_samples_range(idxSamples,startRangeSampleNumber,interSamplesDistance);

% Calculate cartesian coordinates in the swath frame
[sampleAcrossDistance,sampleUpwardsDistance] = CFF_get_samples_dist(sampleRange,beamPointingAngle);

% Calculate projected coordinates in the geographical frame
[sampleEasting, sampleNorthing, sampleHeight] = CFF_get_samples_ENH(sonarEasting,sonarNorthing,sonarHeight,sonarHeading,sampleAcrossDistance,sampleUpwardsDistance);



