function interSamplesDistance = CFF_inter_sample_distance(fData, varargin)
%CFF_INTER_SAMPLE_DISTANCE  Distance (in m) between two data samples
%
%   Returns the distance in meters between two samples of a beam
%   time-series in fData, based on the sound speed and sample frequency as
%   recorded in the data. Note that sampling frequency may have been
%   modified to account for the decimation in samples when reading the
%   data. 
%
%   INTERSAMPLESDISTANCE = CFF_INTER_SAMPLE_DISTANCE(FDATA) returns the
%   inter-sample distance for all pings in FDATA.
%
%   INTERSAMPLESDISTANCE = CFF_INTER_SAMPLE_DISTANCE(FDATA,IPINGS) returns
%   the inter-sample distance only for specified ping indices IPINGS in
%   FDATA. 
%
%   See also CFF_GET_SAMPLES_RANGE

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2022; Last revision: 28-07-2022

% input parsing
p = inputParser;
addRequired(p,'fData',@(x) CFF_is_fData_version_current(x));
addOptional(p,'iPings',[]);
parse(p,fData,varargin{:});
iPings = p.Results.iPings;
clear p;

% get sound speed and sampling frequency
datagramSource = CFF_get_datagramSource(fData);
switch datagramSource
    case {'WC','AP'}
        sound_speed    = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)); % m/s
        sampling_freq  = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); % Hz
    case 'X8'
        sound_speed    = fData.X8_1P_SoundSpeedAtTransducer; % m/s
        sampling_freq  = fData.X8_1P_SamplingFrequencyInHz; % Hz
end

% calculate
interSamplesDistance = sound_speed./(sampling_freq.*2); % in m

% return only for desired pings
if ~isempty(iPings)
    interSamplesDistance = interSamplesDistance(iPings);
end

