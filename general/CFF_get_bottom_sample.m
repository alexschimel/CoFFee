function BP_bottomSample = CFF_get_bottom_sample(fData,varargin)
%CFF_GET_BOTTOM_SAMPLE  Get the bottom sample (per ping and beam) in fData
%
%   Gets the number of the sample corresponding to the bottom detect for
%   each ping and beam. 
%
%   BS = CFF_GET_BOTTOM_SAMPLE(FDATA) returns the processed (i.e. possibly
%   filtered) bottom sample BS if it exists, otherwise the raw bottom
%   sample, from the datagram source in FDATA. 
%
%   BS = CFF_GET_BOTTOM_SAMPLE(...,'datagramSource',DS) forces the
%   use of the input datagramSource DS, with DS being one of either 'WC',
%   'AP', 'De', or 'X8'. 
%
%   BS = CFF_GET_BOTTOM_SAMPLE(...,'which','raw') forces the return of
%   the raw bottom sample.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% INPUT PARSING
p = inputParser;
addRequired(p,'fData',@isstruct);
addOptional(p,'datagramSource', CFF_get_datagramSource(fData),@(x) ismember(x,{'WC','AP','De','X8'}));
addOptional(p,'which','processed',@(x) ismember(x,{'raw','processed'}));
parse(p,fData,varargin{:});
datagramSource = p.Results.datagramSource;
which          = p.Results.which;
clear p


%% EXTRACT
if strcmp(which,'processed') && isfield(fData,sprintf('X_BP_bottomSample_%s',datagramSource))
    % A processed bottom sample already exists (possibly filtered).
    % Extract that.
    BP_bottomSample = fData.(sprintf('X_BP_bottomSample_%s',datagramSource)); % in sample number
else
    % Extracting raw bottom sample
    BP_bottomSample = fData.(sprintf('%s_BP_DetectedRangeInSamples',datagramSource)); % in sample number
    BP_bottomSample(BP_bottomSample<=0) = NaN;
end