% CFF_CREATE_WC_REFPING Create a WC reference ping
%
%  Apply the function that creates a water column 'Reference Ping' (Nau et al., 2024)
%   
%  [reference_ping, rp_pct_amp, rp_pct_range, rp_pct_range_msra]= CFF_create_wc_refping(fData, params) 
%  Creates a reference ping based on FDATA and specified input parameters. 
% 
%  Input parameters (params) in the form of a structure are required as:
%  startPing = starting ping for the Reference Ping
%  endPing = ending ping for the Reference Ping
%  mindB= Minimum WC amplitude value (used for normalisation); Kongsberg default = 63
%  maxdB= Maximum WC amplitude value (used for normalisation); Kongsberg default = 63

% Outputs include:
% reference_ping: Normalised amplitude values for the reference ping
% rp_pct_amp: Relative reference amplitude matrix
% rp_pct_range: Relative range matrix valid for samples beyond the MSR
% rp_pct_range_msra: Relatve range matrix valid for samples above the MSR

%  Copyright 2024 Amy Nau
%  Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

function [reference_ping, rp_pct_amp, rp_pct_range, rp_pct_range_msra]= CFF_create_wc_refping(fData, params)
%clear all


% block processing setup
% reduce the fraction if you experience out-of-memory errors
[nSamples,nBeams,nPings] = CFF_get_WC_size(fData,'WC');

% Get subset of pings based on the user-defined start and end ping

blockPings = params.startPing:params.endPing;
% Subset data to only pings of interest


% get WC data
datagramSource = CFF_get_datagramSource(fData);
fieldN = sprintf('%s_SBP_SampleAmplitudes',datagramSource);
blockWCD = CFF_get_WC_data(fData,fieldN,'iPing',blockPings);
% Convert to double and fill in nan values with minimum value of -64
blockWCD=double(blockWCD);
blockWCD(isnan(blockWCD)) = -64;

% data size for this block
[nS,nB,nP] = size(blockWCD);

% Normalise WC values
procWCD=(blockWCD-params.mindB)./(params.maxdB-params.mindB);

% Smooth values using a 3x3x3 3D box filter (Step 1)
procWCD=smooth3(procWCD,'box',3);

% Average WC amplitudes across pings to create single "beam pattern" from this series of
% pings (Step 2)
reference_ping=CFF_nanstat3(procWCD,3);

% Get corresponding bottom range and sample values for the subset of pings
X_BP_bottomRange=fData.X_BP_bottomRange(:,params.startPing: params.endPing);
X_BP_bottomRange=CFF_inpaint_nans(X_BP_bottomRange,4);
X_BP_bottomSample_WC=fData.X_BP_bottomSample_WC(:,params.startPing: params.endPing);

% Infill bottom values to remove nans
X_BP_bottomSample_WC=CFF_inpaint_nans(X_BP_bottomSample_WC,4);

%Number of samples for bottom detection buffer
bd_buff=10;

% Set up variables
bottomamp_idx=nan(nB,nP);
new_bottom_range= nan(nB,nP);
rp_pct_range=nan(nS,nB);

for pp=1:nP
    for bb=1:nB
        %For each beam, find the highest amplitude sample within specified
        %number of samples (bd_buff)
        bottomsample=round(X_BP_bottomSample_WC(bb,pp));
        wc_amps=procWCD(:,bb,pp);
        % Catch case where buffer number exceeds total number of samples
        if bottomsample+bd_buff>nS
            bd_buff_new=n-bottomsample;
            [maxbotamp, idx]=max(wc_amps(bottomsample-bd_buff_new:bottomsample+bd_buff_new));

            bottomamp_idx(bb,pp)=(bottomsample-bd_buff_new+idx-1);
        else
            [maxbotamp, idx]=max(wc_amps(bottomsample-bd_buff:bottomsample+bd_buff));

            bottomamp_idx(bb,pp)=(bottomsample-bd_buff+idx-1);
        end
    end


    % get the range from sonar (in m) for each sample index
    idxSamples = (1:nS)';
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,blockPings);
    interSamplesDistance = CFF_inter_sample_distance(fData,blockPings);
    X_SBP_sampleRange = CFF_get_samples_range(idxSamples,startSampleNumber,interSamplesDistance);

    for bb=1:nBeams
        new_bottom_range(bb,pp)=X_SBP_sampleRange(bottomamp_idx(bb,pp),bb,pp);

    end

end

X_BP_bottomSample_WC=bottomamp_idx;
X_BP_bottomRange=new_bottom_range;

% Calculate average range for each sample (Step 2)
sbp_range=CFF_nanstat3(X_SBP_sampleRange,3);

% Calculate average bottom detection range and sample (Step  3)
bp_bottomrange=mean(X_BP_bottomRange,2);
bp_bottomsample=mean(X_BP_bottomSample_WC,2);


% Find minimum slant range (RMSR) within specified number of beams (Step 4)
buffer_beams=25; 
[MSS, idx]=min(bp_bottomsample(nBeams/2-buffer_beams:nBeams/2+buffer_beams));
MSR=bp_bottomrange(nBeams/2-buffer_beams+idx-1); 
% % % NEW CODE:
% % [MSS, idx]=min(bp_bottomsample);
MSS=round(MSS);
% % 
% %  MSR=X_SBP_sampleRange(MSS,nB/2,pp);
% % % ENd new
 rp_pct_range=nan(MSS-1,nBeams);
rp_pct_range_msra=nan(MSS-1,nBeams);


% Calcualte "relative range" for each sample between bottom detection and
%MSR (Step 5)

for ii=MSS:nS
    for bb=1:nB
        rp_pct_range(ii,bb)=(sbp_range(ii,bb)-MSR)/(bp_bottomrange(bb)-MSR);
    end
end
rp_pct_range_msra=nan(nS,nB);
% Calcualte "percent" of range for each sample above MSR ("msra")
for ii=1:MSS-1
    for bb=1:nB
        rp_pct_range_msra(ii,bb)=(sbp_range(ii,bb)/MSR); %bp_bottomrange(bb));
    end
end

% Calcualte maximum bottom amplitude by sample range (Step 6)

% Round averaged bottom sample to get whole number sample
bottomsamples_round=round(bp_bottomsample);
% Get corresponding normalized amplitude for each sample range along each
% beam (this finds the max amplitude within 20 samples for the recorded
% bottom detection, but can be adjusted if needed)

beampattern_bottomamp=nan(1,nB);
for bb=1:nB
    %For each beam, find the sample with max amplitude

    bottomsample=bottomsamples_round(bb);
    if bottomsample+bd_buff>nS
        bd_buff=nS-bottomsample;
    end
    maxbotamp=max(reference_ping(bottomsample-bd_buff:bottomsample+bd_buff,bb));
    beampattern_bottomamp(bb)=maxbotamp;
end
% Create lookup table to relate bottom sample number and amplitude
amp_sample_lookup=[];
amp_sample_lookup(:,1)=bottomsamples_round;
amp_sample_lookup(:,2)=beampattern_bottomamp;

% Split stbd and port sides

amp_sample_lookup_stbd=amp_sample_lookup(1:nB/2,:);
amp_sample_lookup_port=amp_sample_lookup(nB/2+1:nB,:);

% Samples are sorted and unique values taken as the beam pattern is related to
% the amplitude of the highest sample within that sample range, not for each
% beam

stbd_sort=sortrows(amp_sample_lookup_stbd,[1 2]);
[~,uniqueIndex] = unique(stbd_sort(:,1),'last');
stbd_sort = stbd_sort(uniqueIndex,:);

%Create maxtrix and infill values. For each sample range, find the
%corresponding sample from stbd_sort and the related amplitude value, then
%fill in the amplitude value at that sample position in the new matrix (a)
nS=length(reference_ping);
a=nan(nS,1);
for ii=1:length(stbd_sort)
    s=stbd_sort(ii,1);
    amps=stbd_sort(ii,2);
    a(s)=amps;
end

% Interpolate missing values
a=CFF_inpaint_nans(a,4);

% Apply to all stbd beams
sb_maxamp_stbd=repmat(a,1,nBeams/2);
sb_maxamp_stbd(sb_maxamp_stbd<0)=nan;

%Process port beams
port_sort=sortrows(amp_sample_lookup_port,[1 2]);
[~,uniqueIndex] = unique(port_sort(:,1),'last');
port_sort = port_sort(uniqueIndex,:);

%Create maxtrix and infill values
nS=length(reference_ping);
b=nan(nS,1);
for ii=1:length(port_sort)
    p=port_sort(ii,1);
    ampp=port_sort(ii,2);
    b(p)=ampp;
end

% Interpolate missing values
b=CFF_inpaint_nans(b,4);

% Apply to all beams on port side
sb_maxamp_port=repmat(b,1,nBeams/2);
sb_maxamp_port(sb_maxamp_port<0)=nan;

sb_maxamp=[sb_maxamp_stbd sb_maxamp_port];


b=CFF_inpaint_nans(b,4);


sb_maxamp_port=repmat(b,1,nB/2);

sb_maxamp_port(1:MSS-1,:)=1;
sb_maxamp_stbd(1:MSS-1,:)=1;
sb_maxamp=[sb_maxamp_stbd sb_maxamp_port];



% Calculate relative reference amplitude  based on maximum amplitude at each sample
% range (Step 7)
rp_pct_amp=reference_ping./sb_maxamp;

bp_upperwc=reference_ping;%((maxdB-mindB)/maxdB);
rp_pct_amp(1:MSS-1,:)=bp_upperwc(1:MSS-1,:);

end
