function SBP_sampleRange = CFF_get_samples_range(SBP_idxSamples,BP_startSampleNumber,interSamplesDistance)
%CFF_GET_SAMPLES_RANGE  Range of samples from indices
%
%   Computes the range (in m from the sonar head) of samples, based on
%   their index in a beam and the distance between two samples (in m). For
%   water column data, you might need to add a fixed index offset
%   (startSampleNumber).
% 
%   SAMPR = CFF_GET_SAMPLES_RANGE(INDSAMP,STARTSAMPNUM,INTERSAMPDIST)
%   returns the range SAMPR (in m) of samples based on their index INDSAMP,
%   the corresponding beams' start index offset STARTSAMPNUM and the
%   corresponding pings' inter-sample distance INTERSAMPDIST. The index of
%   samples INDSAMP must be a SBP tensor or compatible (e.g. a 1BP matrix
%   of one sample per ping and beam, or a S1 column vector of indices). The
%   index offset STARTSAMPNUM must be a BP matrix or compatible (e.g. a B1
%   or 1P vector). The inter-sample distance INTERSAMPDIST must be a scalar
%   or a ping vector (1P or P1) and is in m, as obtained from
%   CFF_INTER_SAMPLE_DISTANCE. 
%
%   See also CFF_INTER_SAMPLE_DISTANCE, CFF_GET_SAMPLES_DIST,
%   CFF_GET_SAMPLES_ENH, CFF_GEOREFERENCE_SAMPLE,
%   CFF_GET_SAMPLES_INDEX_FROM_RANGE

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% permute dimensions of input to get everything as SBP matrix-compatible
SBP_startSampleNumber = permute(BP_startSampleNumber,[3,1,2]); % 1BP matrix
interSamplesDistance = reshape(interSamplesDistance,[1,numel(interSamplesDistance)]); % ensure 1P vector
SBP_interSamplesDistance = permute(interSamplesDistance,[3,1,2]); % 11P vector

% compute sample range
SBP_sampleRange = (SBP_idxSamples+SBP_startSampleNumber).*SBP_interSamplesDistance;

end





