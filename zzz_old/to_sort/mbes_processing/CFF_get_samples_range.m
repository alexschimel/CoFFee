%% CFF_get_samples_range.m
%
% Compute samples range (in m) from sonar, based on the sample number, the
% origin offset, and the distance between two samples
%
%% Help
%
% *USE*
%
% Calculate range for the sample(s). For water column, you need to take
% into account the startRangeSampleNumber to compute range as:
% range = interSamplesDistance*(idxSamples+startRangeSampleNumber)
%
% For the sample corresponding to bottom detect, there should not be an
% offset. 
%
% *INPUT VARIABLES*
%
% * |idxSamples|: Required. A SBP array of samples indices. Can be S1 for
% common samples across all beams and pings. (or SB1 or S1P).
% * |startSampleNumber|: Required. A BP matrix (or B1 for 1 ping) of the
% offset number to add to idxSamples in each ping/beam.
% * |interSamplesDistance|: Required. A 1P matrix (or 1 scalar for 1 ping)
% of the distance between two samples in each beam.
%
% *OUTPUT VARIABLES*
%
% * |sampleRange|: A SBP matrix (or SB for 1 ping) of each sample's range
% (in m) from the sonar.
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
function sampleRange = CFF_get_samples_range(idxSamples,startSampleNumber,interSamplesDistance)

% permute dimensions of input to get everything as SBP matrices
startSampleNumber    = permute(startSampleNumber,[3,1,2]);
interSamplesDistance = permute(interSamplesDistance,[3,1,2]); 

% compute outputs
sampleRange = bsxfun(@times,bsxfun(@plus,idxSamples,startSampleNumber),interSamplesDistance);

end





