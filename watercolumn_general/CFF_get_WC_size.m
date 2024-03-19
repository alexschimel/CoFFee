function [nSamples, nBeams, nPings] = CFF_get_WC_size(fData,varargin)
%CFF_GET_WC_SIZE  One-line description
%

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% get source datagram
if ~isempty(varargin) && ~isempty(varargin{1})
    datagramSource = varargin{1};
else
    datagramSource = CFF_get_datagramSource(fData);
end

% get data size
switch datagramSource
    case {'WC' 'AP'}
        fieldN = sprintf('%s_SBP_SampleAmplitudes',datagramSource);        
        [nSamples, nBeams, nPings] = cellfun(@(x) size(x.Data.val),fData.(fieldN));
    case 'X8'
        nSamples = 1;
        [nBeams, nPings] = size(fData.X8_BP_ReflectivityBS);
end

nSamples = nanmax(nSamples);
nBeams = nanmax(nBeams);
nPings = nansum(nPings);