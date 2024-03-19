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

%   Copyright 2017-2023 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


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


% We are reusing mostly here the reasoning and equations of Urban et al.
% (2017) (DOI: 10.1002/lom3.10138), which match a previous
% paper Gurshin et al. (2009) (DOI: 10.1093/icesjms/fsp052). The equation
% of Urban et al. (2017) was reused in Nau et al. (2022) (DOI:
% 10.3389/frsen.2022.839417)
%
% The received echo level for volume backscattering is:
%       EL = SL - TL + Sv + 10*log(V)                                   (1)
% , where TL is the transmission loss: 
%       TL = 40*log(R) + 2*alpha*R                                      (2)
% , V is the sampling volume typically approximated as:
%       V ~ 0.5*c*tau*psi*(R^2)                                         (3)
% (SL is the Source Level, Sv is the volume backscattering strength, R is
% the range from the sounder, alpha is the attenuation coefficient, c is
% the sound speed, tau is the pulse length. NOTE: Urban et al (2017)
% uses "the sampling time (t)" instead of the pulse length (tau), which is
% not correct.
%
% Putting equations (1) to (3) together, we get:
%       EL = SL + Sv - 20*log(R) -2*alpha*R + 10*log(0.5*c*tau*psi)     (4)
%
% The log dependence in "-20*log(R)" is typical of getting to Sv. For
% surface backscattering (Sa/BS), it is in "-30*log(R)", and for target
% strength (TS), it is in "-40*log(R)".
%
% Continuing with the reasoning of Urban et al. (2017), the issue is that
% the level recorded in the raw data files is not EL, but rather:
%       A_WCI = EL + TVG + CF                                           (5)
% , where TVG is the system's TVG function, specified in the Kongsberg
% documentation as:
%       TVG = X*log(R) + 2*alpha*R + OFS + C                            (6)
% , CF is some assumed constant factor representing aspects out of the
% control of the system (i.e. an offset due to component aging, biofouling,
% etc.)
% As specified in the Kongsberg documentation, X is the "TVG function
% applied" (in fact a recorded parameter that can be set to 10, 20, 30 or
% 40 - I think), C is the "TVG offset in dB" (another recorded parameter),
% and OFS is a "gain offset to compensate for TX Source Level, Received
% sensitivity, etc." but that is not recorded.
%
% Note that Konsberg data also includes in Runtime Parameters a "Transmit
% Power Re. Maximum" parameter which is a "mammal protection setting" and
% that is reported in the data, but not in equation (6) above. So instead
% of using equation (6), we would rather use:
%       TVG = X*log(R) + 2*alpha*R + OFS + C + TPRM                     (7)
%
% Putting equations (4), (5) and (7) together, we get:
%   Sv = A_WCI - (X-20)*log(R) - 10*log(0.5*c*tau) - 10*log(psi) - TPRM ...
%        - OFS - C - CF - SL                                            (8)
%
% So this is the full equation to obtain Sv from the recorded level A_WCI.
% Problem is that a lot of those terms are unknown. Let's look at them in
% turn: 
%   (X-20)*log(R) is known and must be corrected otherwise the level is not
% consistent down the range.
%   10*log(0.5*c*tau) is known (sort-of.. we should use effective pulse
% length instead of pulse length). Not sure if it needs correcting since
% those terms are constant. Well, sound speed c might vary along the line.
% All papers cited above chose to correct for this term. But what if this
% term is already a part of the unknown OFS? At least the magnitude of this
% term should be somehow reduced. Considering a sound speed of 1500 m/s and
% typical pulse lengths (0.0001-0.001 m), this term should be around -11 to
% -1 dB.
%   10*log(psi) can also be approximated since we know the beamwidths in Tx
% and Rx. Yet none of the papers cited above chose to correct it. That's
% probably because its magnitude is large. Considering a cone with apex
% angle theta (i.e. approx the beamwidth, say theta=0.5deg), the equation
% for the solid angle psi is psi = 2*pi*(1-cos(0.5*theta)), aka 10*log(psi)
% here would be -42 dB!!!!
%   TPRM is recorded in the files, but ignored in the previous papers. It
% should probably be corrected though, since this parameter can be changed
% while recording the data!
%   OFS is not recorded. We can assume it is a constant value throughout a
% file, but we have no evidence. 
%   C is recorded... but ignored in the papers cited.
%   CF is unknown by definition, but considered constant.
%   SL is unknown, but supposedly corrected by OFS, along with other
%   constant terms ignored in this entire reasoning (i.e. transducer
%   sensitivity, etc.)
%
% So what do we do?
%   Gurshin et al. (2009) and Urban et al. (2017) corrected the recorded
%   level as:
%       A_WCI - (X-20)*log(R) - 10*log(0.5*c*tau)
%   Nau et al. (2022) corrected the recorded level as:
%       A_WCI - (X-20)*log(R) - 10*log(0.5*c*tau) - C
%   What I had been doing so far is correcting the recorded level as:
%       A_WCI + (20-X)*log(R) + TPRM 
%   (notice I add TPRM here while in the equations above, it was
%   subtracted. That's because I don't even know how Kongsberg applies it,
%   or whether it compensates for it in OFS) 



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
