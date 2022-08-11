function [data,params] = CFF_WC_radiometric_corrections_CORE(data, fData, iPings, varargin)
%CFF_WC_RADIOMETRIC_CORRECTIONS_CORE  Apply radiometric correction to WCD
%
%   This function radiometrically corrects specific pings of water-column
%   data.
%
%   DATA = CFF_WC_RADIOMETRIC_CORRECTIONS_CORE(DATA,FDATA,IPINGS) takes
%   input DATA (SBP tensor) and radiometrically corrects it to the acoustic
%   quantity Sv, using the necessary information in FDATA for the relevant
%   ping indices IPINGS. It returns the corrected DATA.
%
%   CFF_WC_RADIOMETRIC_CORRECTIONS_CORE(DATA,FDATA,IPINGS,PARAMS) uses
%   processing parameters defined as the fields in the PARAMS structure.
%   Possible parameters are: 
%   'outVal': string for the acoustic quantity desired in output. Possible
%   values are 'Sv' (Volume backscattering strength, in dB re 1 m-1,
%   default), 'Sa' (Area backscattering strength, in dB re 1(m2 m-2)), and
%   'TS' (Target strength, in dB re 1 m2). For more information see,
%   MacLennan et al. (2002) (DOI: 10.1006/jmsc.2001.1158). 
%
%   CFF_WC_RADIOMETRIC_CORRECTIONS_CORE(...,'comms',COMMS) specifies if and
%   how this function communicates on its internal state (progress, info,
%   errors). COMMS can be either a CFF_COMMS object, or a text string to
%   initiate a new CFF_COMMS object. Options are 'disp', 'textprogressbar',
%   'waitbar', 'oneline', 'multilines'. By default, using an empty
%   CFF_COMMS object (i.e. no communication). See CFF_COMMS for more
%   information.
%
%   [FDATA,PARAMS] = CFF_WC_RADIOMETRIC_CORRECTIONS_CORE(...) also outputs
%   the parameters used in processing.
%
%   Note: corrections incomplete XXX.
%
%   See also CFF_WC_RADIOMETRIC_CORRECTIONS,
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE, CFF_MASK_WC_DATA_CORE.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 27-07-2022


%% Input arguments management
p = inputParser;
addRequired(p,'data',@(x) isnumeric(x)); % data to process
addRequired(p,'fData',@(x) CFF_is_fData_version_current(x)); % source fData
addRequired(p,'iPings',@(x) isnumeric(x)); % indices of pings to process
addOptional(p,'params',struct(),@(x) isstruct(x)); % processing parameters
addParameter(p,'comms',CFF_Comms()); % information communication (none by default)
parse(p,data,fData,iPings,varargin{:});
params = p.Results.params;
comms = p.Results.comms;
clear p
if ischar(comms)
    comms = CFF_Comms(comms);
end


%% Prep

% start message
comms.start('Applying radiometric corrections');


%% Transmit Power level reduction
% This is the "mammal protection" setting, which is recorded in Runtime
% Parameters datagram
TPRM = fData.Ru_1D_TransmitPowerReMaximum;
if numel(unique(TPRM)) == 1
    % This value does not change in the file
    TPRM = TPRM(1).*ones(size(data));
else
    % dB offset changed within the file. 
    % Would need to check when runtime parameters are being issued. Whether
    % they are triggered with any change for example. Will likely need to
    % extract and compare the time of Ru and WC datagrams to find which db
    % offset applies to which pings.
    % ... TO DO XXX1
    % for now we will just take the first value and apply to everything
    % so that processing can continue...
    comms.info('Transmit Power level reduction not constant within the file. Radiometric correction inappropriate');
    TPRM = TPRM(1).*ones(size(data));
end


%% TVG applied in reception
%
% From Kongsberg datagrams manual:
% "The TVG function applied to the data is X logR + 2 Alpha R + OFS + C.
% The parameters X and C is documented in this datagram. OFS is gain offset
% to compensate for TX Source Level, Receiver sensitivity etc."
datagramSource = CFF_get_datagramSource(fData);

X = fData.(sprintf('%s_1P_TVGFunctionApplied',datagramSource))(iPings);
C = fData.(sprintf('%s_1P_TVGOffset',datagramSource))(iPings);

% Assuming 30log R if nothing has been specified
X(isnan(X)) = 30;
C(isnan(C)) = 0;

% X is a parameter in TVG because it defines the output quantity (not
% taking into account constant factors) as follow: 
% * For backscatter per unit volume (Sv): 20*log(R)
% * For backscatter per unit surface (Sa/BS): 30*log(R)
% * For target strength (TS): 40*log(R)
%
% Here we allow changing that output quantity by applying + Xcorr*log(R) to
% the data. For example if we want Sv, then the output has to be
% 30*log(R) = X*logR + Xcorr*logR, aka we use Xcorr = 30-X

% get outVal parameter
if ~isfield(params,'outVal'), params.outVal = 'Sv'; end % default
mustBeMember(params.outVal,{'Sv','Sa','TS'}); % validate
outVal = params.outVal;

% get Xcorr
switch outVal
    case 'Sv'
        Xcorr = 20-X;
    case 'Sa'
        Xcorr = 30-X;
    case 'TS'
        Xcorr = 40-X;
end
Xcorr = permute(Xcorr,[3,1,2]);


%% Full correction
%
% get sample range
nSamples = size(data,1);
interSamplesDistance = CFF_inter_sample_distance(fData,iPings);
datagramSource = fData.MET_datagramSource;
ranges = CFF_get_samples_range( (1:nSamples)', fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,iPings), interSamplesDistance);

% apply to data
data = data + Xcorr.*log10(ranges) + TPRM;

% Still need to correct for C, but probably need to do all constant terms
% then. XXX1


%% end message
comms.finish('Done');
