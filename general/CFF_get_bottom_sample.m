function BP_bottomSample = CFF_get_bottom_sample(fData,varargin)
%CFF_GET_BOTTOM_SAMPLE  Get the bottom sample (per ping and beam) in fData
%
%   Gets the number of the sample corresponding to the bottom detect for
%   each ping and beam. 
%
%   BP_bottomSample = CFF_GET_BOTTOM_SAMPLE(fData) returns the processed
%   bottom sample (i.e. possibly filtered) if it exists, otherwise the raw
%   bottom sample, from the datagram source in fData.
%
%   BP_bottomSample =
%   CFF_GET_BOTTOM_SAMPLE(fData,'datagramSource',datagramSource) forces the
%   use of the input datagramSource, with datagramSource being one of
%   either 'WC', 'AP', 'De', or 'X8'.
%
%   BP_bottomSample =
%   CFF_GET_BOTTOM_SAMPLE(fData,'which','raw') forces the return of the raw
%   bottom sample.


%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021


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
    BP_bottomSample(BP_bottomSample==0) = NaN;
end