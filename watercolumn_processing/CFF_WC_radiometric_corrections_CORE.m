function [data,params] = CFF_WC_radiometric_corrections_CORE(data, fData, iPings, varargin)
%CFF_WC_RADIOMETRIC_CORRECTIONS_CORE  Apply radiometric correction to WCD
%
%   Apply physical (aka, not aestethic ones) corrections to the dB level in
%   water-column data: TVG, dB offset, etc.
%
%   DATA = CFF_WC_RADIOMETRIC_CORRECTIONS_CORE(DATA,FDATA,IPINGS) takes
%   input DATA (SBP tensor) and radiometrically corrects it to the acoustic
%   quantity Sv, using the necessary information in FDATA for the relevant
%   ping indices IPINGS. It returns the corrected DATA.
%
%   CFF_WC_RADIOMETRIC_CORRECTIONS_CORE(DATA,FDATA,IPINGS,PARAMS) uses
%   processing parameters defined as the fields in the PARAMS structure.
%   Possible parameters are: 
%   - 'outVal': string for the acoustic quantity desired in output.
%   Possible values are:  
%     - 'Sv' (default): Volume backscattering strength, in dB re 1 m-1.
%     - 'Sa': Area backscattering strength, in dB re 1(m2 m-2)
%     - 'TS': Target strength, in dB re 1 m2
%   For more information see, MacLennan et al. (2002)
%   (DOI: 10.1006/jmsc.2001.1158). 
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
%   Note: development notes at the bottom
%
%   See also CFF_WC_RADIOMETRIC_CORRECTIONS, CFF_PROCESS_WC,
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE, CFF_MASK_WC_DATA_CORE.

%   Copyright 2017-2024 Alexandre Schimel
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


%% Transmit Power level reduction
% Originally, this fData field was made for the "Transmit power re maximum
% in dB" field in Kongsberg data, which is an attenuation of power
% transmitted for "mammal protection". It is recorded in Runtime Parameters
% datagrams in the .all format, and in the #MRZ datagrams in the .kmall
% format. In converted s7k data, we use it to store the "Power Selection"
% (maybe minus the "Gain selection") from "R7000 Sonar Settings" records.
TPRM = fData.Ru_1D_TransmitPowerReMaximum;

% Now, we need a value per ping, and that's a problem.
% In Kongsberg .all format, there are not as many Runtime Parameters
% datagrams as pings. In Kongsberg .kmall format and in .s7k, there is one
% value per ping... of seabed data not WCD. So here we just take the first
% value available and hope it applies to all data. If the value changes, we
% raise a warning that we'll fix this eventually... XXX
if numel(unique(TPRM)) > 1
    comms.info('Transmit Power level reduction not constant within the file. Radiometric correction inappropriate');
end

% Take first value for all pings
TPRM = TPRM(1).*ones(size(iPings));
TPRM = permute(TPRM,[3,1,2]);


%% TVG applied in reception
%
% From Kongsberg datagrams manual:
% "The TVG function applied to the data is X logR + 2 Alpha R + OFS + C.
% The parameters X and C is documented in this datagram. OFS is gain offset
% to compensate for TX Source Level, Receiver sensitivity etc."
% X and C are known but not OFS.
%
% For s7k there is no information on TVG but we encoded X = 30 and C = 0
% in CFF_convert_s7k_to_fdata. To modify if we ever get more information
% XXX
datagramSource = CFF_get_datagramSource(fData);
X = fData.(sprintf('%s_1P_TVGFunctionApplied',datagramSource))(iPings);
C = fData.(sprintf('%s_1P_TVGOffset',datagramSource))(iPings);

X = permute(X,[3,1,2]);
C = permute(C,[3,1,2]); 

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
        Xcorr = X-20;
    case 'Sa'
        Xcorr = X-30;
    case 'TS'
        Xcorr = X-40;
end


%% Full correction
%
% get sample range
nSamples = size(data,1);
interSamplesDistance = CFF_inter_sample_distance(fData,iPings);
datagramSource = fData.MET_datagramSource;
ranges = CFF_get_samples_range( (1:nSamples)', fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,iPings), interSamplesDistance);

% apply to data
data = data - Xcorr.*log10(ranges) - C; % used to also do - TPRM. See notes


%% end message
comms.finish('Done');


%% DVPT NOTES
%
% Making my own reasoning here, from Urick (1983), Lurton (2002), MacLennan
% et al. (2002), Gurshin et al. (2009) (DOI: 10.1093/icesjms/fsp052), Urban
% et al. (2017) (DOI: 10.1002/lom3.10138), and Nau et al. (2022) (DOI:
% 10.3389/frsen.2022.839417) 
%
% The intensity of the received echo (Echo Level) is written as (Urick,
% Lurton): 
%       EL = SL - 2*TL + TS                                             (1)
% , where SL is the Source Level, TL is the (one-way) Transmission Loss,
% and TS is the Target Strength.
%
% The one-way transmission loss TL is (Lurton): 
%       TL = 20*log(R) + alpha*R                                        (2)
% , where R is the range from the sounder (unit?), and alpha is the
% attenuation coefficient (unit?).
%
% For volume backscattering, TS is written as (Urick, Urban, MacLennan):
%       TS = Sv + 10*log(V)                                             (3)
% , where Sv is the volume backscattering strength and V is the scattering
% volume, approximated as (Urick, Lurton):
%       V ~ 0.5*c*tau*psi*(R^2)                                         (4)
% , where c is the sound speed (unit?), tau is the pulse length (unit?),
% and psi is the equivalent aperture of the source/receiver system (solid
% angle, in steradians). NOTE: Urban incorrectly calls V the "sampling
% volume" and uses "the sampling time (t)" instead of the pulse length
% (tau) in this equation.
%
% Putting equations (1) to (4) together, we get:
%       EL = SL + Sv - 20*log(R) - 2*alpha*R + 10*log(0.5*c*tau*psi)    (5)
%
% Now the level recorded in the raw data files is not the Echo Level. The
% Recorded Level (RL) may be written as (my own terminology):
%       RL = EL + RG - UL                                               (6)
% , where RG is the gain introduced by the system in reception (receiver
% Gain), which is usually in the form of one constant term and one
% range-varying term known as Time Varying Gain, and UL is a (assumed
% constant) Unknown Loss due to factors outside the system's control
% (biofouling, aging components, etc.).
%
% Similarly, the Source Level may be controlled by user-set or
% system-controlled parameters, such that: 
%       SL = NSL + TG,                                                  (7)
% , where NSL is the Nominal Source Level and TG (Transmit Gain) is a
% parameterizable, fixed gain (or attenuation) in transmission.
%
% In Kongsberg systems using the .all format:
% - There is a TVG in reception, described in the documentation as: 
%       TVG = X*log(R) + 2*alpha*R + OFS + C                            (8)
% , where X is the "TVG function applied" (in fact a recorded parameter
% that can be set to 10, 20, 30 or 40 - I think), C is the "TVG offset in
% dB" (another recorded parameter), and OFS is a "gain offset to compensate
% for Tx Source Level, Received sensitivity, etc." but that does not appear
% to be recorded. We assume that this is the only gain in reception such
% that, for this data type, the Receive Gain is just this TVG: 
%       RG = TVG = X*log(R) + 2*alpha*R + OFS + C                       (9)
% - There is "mammal protection setting" to reduce power transmitted. It is
% recorded in Runtime Parameters as "Transmit Power Re. Maximum" (TPRM).
% From experience, it is usually 0 or negative and in dB (e.g. TPRM = -20
% dB). We assume that this is the only gain in transmission such that, for
% this data type:
%       TG = TPRM                                                      (10)
%
% Putting equations 5 to 9 together, we get Sv from the recorded level RL
% with the equation:
%       Sv = RL - (X-20)*log(R) - 10*log(0.5*c*tau) - C - TPRM  
%            - NSL - 10*log(psi) - OFS + UL                            (11)
%
% A few comments at this stage: 
%   In practice, we may want to do corrections in steps. For example, in
% equation above, there is no more 2*alpha*R component, because the one in
% the TVG compensates the one from the transmission loss. But in practice,
% you may want to correct them separately, for example if the alpha used in
% TVG was wrong. 
%   (X-20)*log(R) is known and must be corrected otherwise the level is not
% consistent down the range.
%   10*log(0.5*c*tau) is known... sort-of. We would need to make sure to
% use effective pulse length for tau instead of pulse length, and use the
% appropriate sound speed, ideally at the depth where the scattering volume
% was approximated. Considering a sound speed of 1500 m/s and typical pulse
% lengths (0.000014-0.00032 s for the EM 204 Mk II), this term should be
% around -20 to -5 dB. If  we are working with data acquired with a
% constant pulse length, and considering constant sound speed, this term is
% constant and perhaps can be lumped with the other uncompensated constant
% terms. 
%   10*log(psi) can also be approximated since the beamwidths in Tx and Rx
% should be known. Note that its magnitude is quite large. Considering a
% cone with apex angle theta (i.e. approx the beamwidth, say theta=0.5deg),
% the equation for the solid angle psi is psi = 2*pi*(1-cos(0.5*theta)),
% aka 10*log(psi) here would be -42 to -35 dB! Like the previous term, we may
% assume that beamwidths are constant, and so consider this term constant,
% and lump it with the other uncompensated constant terms, but beamwidths
% DO change with steering angle.
%   C and TPRM are known (they are reported in the files) so can be
% corrected, and probably should, in case their values change in a dataset,
% But it is unclear whether the (unknown) TVG term OFS already compensates
% for TPRM. Since OFS and C come from the same TVG equation, it can be
% safely assumed that OFS does not compensate for C. 
%   NSL and OFS are unknown, but supposedly OFS compensates for NSL (and
% maybe also TPRM?) among others.
%   UL is by definition unknown. 
%
% How it's done in the literature:
%   Gurshin and Nau call the recorded level A_WC, while Urban calls it
% A_WCI. Gurshin and Urban get Sv from RL with: 
%       Sv = RL - (X-20)*log(R) - 10*log(0.5*c*tau)                    (12)
%   Nau get Sv from RL with:
%       Sv = RL - (X-20)*log(R) - 10*log(0.5*c*tau) - C                (13)
%
% So:
% 1. All three papers ignore the unknown constant terms NSL, OFS and UL.
% 2. All three papers ignore the known 10*log(psi) and TPRM.
% 3. Against the two others, Nau account for the known C.
%
% So what do we implement? For now, we will ignore 10*log(psi) and the
% unknown terms like the three cited papers, but we will compensate for all
% known terms, including C and TPRM, under the assumption that OFS does not
% already compensates for them. This should be verified with Kongsberg and
% with data where those terms change. We therefore implements the following
% equation to get, not Sv proper, but Sv with an assumed constant offset:
%       ~Sv = RL - (X-20)*log(R) - 10*log(0.5*c*tau) - C - TPRM        (14)
%
% Now for TS and Sa:
%
% For TS, we just reuse equation 1, and come to:
% ...


