function sampleRange = CFF_get_samples_range(idxSamples,startSampleNumber,interSamplesDistance)
% CFF_get_samples_range.m
%
% Compute samples range (in m) from sonar, based on the sample number, the
% origin offset, and the distance between two samples
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

%   Copyright 2017-2018 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% permute dimensions of input to get everything as SBP matrices
startSampleNumber    = permute(startSampleNumber,[3,1,2]);
interSamplesDistance = permute(interSamplesDistance,[3,1,2]); 

% compute outputs
sampleRange = bsxfun(@times,bsxfun(@plus,idxSamples,startSampleNumber),interSamplesDistance);

end





