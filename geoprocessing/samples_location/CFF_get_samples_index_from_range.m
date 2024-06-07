function SBP_idxSamples = CFF_get_samples_index_from_range(SBP_sampleRange,BP_startSampleNumber,interSamplesDistance)
%CFF_GET_SAMPLES_NUMBER_FROM_RANGE  Index of samples from range
%
%   Computes the index of samples in a beam, based on their range (in m
%   from the sonar head) and the distance between two samples (in m). For 
%   water column data, the sample index must be corrected by a fixed index
%   offset (startSampleNumber). 
%
%   INDSAMP = CFF_GET_SAMPLES_RANGE(SAMPR,STARTSAMPNUM,INTERSAMPDIST)
%   returns the index INDSAMP of samples based on their range SAMPR (in m),
%   the corresponding beams' start index offset STARTSAMPNUM and the
%   corresponding pings' inter-sample distance INTERSAMPDIST. This is the
%   reverse operation of the one operated by CFF_GET_SAMPLES_RANGE. The
%   range of samples SAMPR must be a SBP tensor or compatible (e.g. a 1BP
%   matrix of one sample per ping and beam, or a S1 column vector of
%   indices). The index offset STARTSAMPNUM must be a BP matrix or
%   compatible (e.g. a B1 or 1P vector). The inter-sample distance
%   INTERSAMPDIST must be a scalar or a ping vector (1P or P1) and is in m,
%   as obtained from CFF_INTER_SAMPLE_DISTANCE. 
%
%   See also CFF_GET_SAMPLES_RANGE, CFF_INTER_SAMPLE_DISTANCE,
%   CFF_GET_SAMPLES_DIST, CFF_GET_SAMPLES_ENH, CFF_GEOREFERENCE_SAMPLE 

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% permute dimensions of input to get everything as SBP matrix-compatible
SBP_startSampleNumber = permute(BP_startSampleNumber,[3,1,2]); % 1BP matrix
interSamplesDistance = reshape(interSamplesDistance,[1,numel(interSamplesDistance)]); % ensure 1P vector
SBP_interSamplesDistance = permute(interSamplesDistance,[3,1,2]); % 11P vector

% get sample number from range
SBP_idxSamples = (SBP_sampleRange./SBP_interSamplesDistance)-SBP_startSampleNumber;
