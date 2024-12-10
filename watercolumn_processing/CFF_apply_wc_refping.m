% CFF_APPLY_WC_REFPING Apply a WC reference ping to remove WC artefact
%
%  Apply the function that creates a set of 'simualted' and 'corrected'
%  pings based on a reference ping correction
%   
%  [X_SBP_WCnorm, X_SBP_WCcorr,X_SBP_WCsim, X_RMSE]= CFF_apply_wc_refping(fData,params)
%  Creates simulated and corrected pings based on FDATA and specified input parameters from the reference ping.
%  This function requires the output variables from CFF_CREATE_REFPING
% 
%  Input parameters (params) in the form of a structure are required as:
%  rp_pct_amp = Relative reference amplitudes (rp_pct_amp)created by CFF_CREATE_WC_REFPING
%  rp_pct_range = Relative range (beyond MSR) (rp_pct_range)created by CFF_CREATE_WC_REFPING % rp_pct_range_msra = Relative range (above MSR) (rp_pct_range_msra)created by CFF_CREATE_WC_REFPING
%  mindB= Minimum WC amplitude value (used for normalisation); Kongsberg default = 63
%  maxdB= Maximum WC amplitude value (used for normalisation); Kongsberg default = 63

% Outputs include:
%  X_SBP_WCnorm: Normalised amplitude values for the original WC data
%  X_SBP_WCcorr: Corrected pings
%  X_SBP_WCsim: Simulated pings
%  X_RMSE: Root mean squared error of the difference between X_SBP_WCsim
%  and X_SBP_WCnorm

%  Copyright 2024 Amy Nau
%  Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


function [X_SBP_WCnorm, X_SBP_WCcorr,X_SBP_WCsim, X_RMSE]= CFF_apply_wc_refping(fData,params)

% Get input parameters
rp_pct_amp=params.rp_pct_amp;
rp_pct_range = params.rp_pct_range;
rp_pct_range_msra = params.rp_pct_range_msra;
mindB=params.mindB;
maxdB=params.maxdB;
% block processing setup
% reduce the fraction if you experience out-of-memory errors
[nSamples,nBeams,nPings] = CFF_get_WC_size(fData,'WC');
[blocks,info] = CFF_setup_optimized_block_processing(...
    nPings,nSamples*nBeams*32,...
    'desiredMaxMemFracToUse',0.05);
nBlocks = size(blocks,1);

% init output
data = [];
X_SBP_WCnorm=[];
X_SBP_WCcorr=[];
X_SBP_WCsim=[];


% work per block of pings
for iB = 1:nBlocks

    fprintf('Working on block %i/%i...\n',iB,nBlocks);

    % list of pings in this block
    blockPings = blocks(iB,1):blocks(iB,2);

    % get WC data
    datagramSource = CFF_get_datagramSource(fData);
    fieldN = sprintf('%s_SBP_SampleAmplitudes',datagramSource);
    blockWCD = CFF_get_WC_data(fData,fieldN,'iPing',blockPings);

   

    % data size for this block
    [nS,nB,nP] = size(blockWCD);

    % Set up bottom samples
    X_BP_bottomRange=fData.X_BP_bottomRange(:,blockPings);
    X_BP_bottomRange=CFF_inpaint_nans(X_BP_bottomRange,4);
    X_BP_bottomSample_WC=fData.X_BP_bottomSample_WC(:,blockPings);
    X_BP_bottomSample_WC=CFF_inpaint_nans(X_BP_bottomSample_WC,4);


    % Init WCD

    blockWCD= double(blockWCD);
    blockWCD(isnan(blockWCD)) = -64;
    % Normalise and smooth pings
    procWCD=(blockWCD-mindB)./(maxdB-mindB);
    

    % Smooth data (Step 1)
    procWCD=smooth3(procWCD,'box',3);


    newbotsamp=[];
    bp_botrange=[];
    test_sample_lookup=[];
    SBP_bottomRange= repmat(shiftdim(X_BP_bottomRange,-1),[nS 1 1]);
    testping_bottomamp= nan(nB, nP);
    newbotsamp= nan(nB, nP);
    bp_botrange= nan(nB, nP);
    % get the range from sonar (in m) for each sample index
    idxSamples = (1:nS)';
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,blockPings);
    interSamplesDistance = CFF_inter_sample_distance(fData,blockPings);
    X_SBP_sampleRange = CFF_get_samples_range(idxSamples,startSampleNumber,interSamplesDistance);

    % Loop through each ping (pp) in the set of uncorrected pings 
    for pp=1:nP
        % Select a single ping (Step 2)
        testping=procWCD(:,:,pp);
        sb_pctrange_testping=nan(nS,nB);
% Set buffer to search 10 samples on either side of bottom detection. Select
% highest amplitude for bottom amplitude and range (Step 3)
        bd_buff=10;
        for bb=1:nB
            %For each beam, find the sample
            bottomsample=X_BP_bottomSample_WC(bb,pp);
            if bottomsample>nS
                bottomsample=nS;
            end
            %find max amp within 10 samples of bottom sample
            if bottomsample+bd_buff<nS
                [maxbotamp,maxidx]=max(testping(bottomsample-bd_buff:bottomsample+bd_buff,bb));
                newbotsamp(bb,pp)=bottomsample-bd_buff+maxidx-1;
                bp_botrange(bb,pp)=X_SBP_sampleRange((bottomsample-bd_buff+maxidx-1),bb,pp);
            else
                buffer_num=nS-bottomsample;
                [maxbotamp,maxidx]=max(testping(bottomsample-buffer_num:bottomsample+buffer_num,bb));
                newbotsamp(bb,pp)=bottomsample-buffer_num+maxidx-1;
                X_BP_bottomSample_WC(bb,pp)=newbotsamp(bb,pp);
                bp_botrange(bb,pp)=X_SBP_sampleRange((bottomsample-buffer_num+maxidx-1),bb,pp);
                X_BP_bottomRange(bb,pp)=bp_botrange(bb,pp);
            end
            
            testping_bottomamp(bb,pp)=maxbotamp;
        end
    


    test_sample_lookup(:,1)=newbotsamp(:,pp); 
    test_sample_lookup(:,2)=testping_bottomamp(:,pp);

    [MSS, idx]=min(newbotsamp(:,pp));

  % Find minimum slant range (RMSR) within specified number of beams (Step 4)
     MSR=X_SBP_sampleRange(MSS,nB/2,pp);
    MSS=round(MSS);
   
    % Calcualte "relative range" for each sample between bottom detection and
% MSR (Step 5)
    sb_pctrange_testping_msra=nan(MSS-1,nB);
    for bb=1:nB
        % Calculate for samples above MSR (msra)
        for ii=1:MSS-1

            sb_pctrange_testping_msra(ii,bb)=((X_SBP_sampleRange(ii,bb,pp))/MSR);%(fData.X_BP_bottomRange(bb,pp));%
        end
    end
    sb_pctrange_testping_msra(MSS-1,nB)=nan;%(nSamples,nBeams)=nan;
    sb_pctrange_testping_msra(sb_pctrange_testping_msra==0)=nan;
    %Calcualte relative range for below MSR 
    for bb=1:nB
        for ii=MSS:nS


            sb_pctrange_testping(ii,bb)=((X_SBP_sampleRange(ii,bb,pp)-MSR)/(bp_botrange(bb,pp)-MSR));
        end
    end
% Calcualte maximum bottom amplitude by sample range (Step 6)

    test_sample_lookup_stbd=test_sample_lookup(1:nB/2,:);
    test_sample_lookup_port=test_sample_lookup(nB/2+1:nB,:);


    %Process starboard beam pattern into a percentage
   
    stbd_sort=sortrows(test_sample_lookup_stbd,[1 2]);
    [~,uniqueIndex] = unique(stbd_sort(:,1),'last');
    stbd_sort = stbd_sort(uniqueIndex,:);

    %Create maxtrix and infill values

    a=nan(nS,1);
    for ii=1:length(stbd_sort)
        s=stbd_sort(ii,1);
        amps=stbd_sort(ii,2);
        a(s)=amps;
    end

    a=CFF_inpaint_nans(a,4);

    sb_maxamp_stbd=repmat(a,1,nB/2);

 

    sb_maxamp_stbd(1:MSS-1,:)=1; 
    %Process port beams
    port_sort=sortrows(test_sample_lookup_port,[1 2]);
    [~,uniqueIndex] = unique(port_sort(:,1),'last');
    port_sort = port_sort(uniqueIndex,:);

    %Create maxtrix and infill values

    b=nan(nS,1);
    for ii=1:length(port_sort)
        p=port_sort(ii,1);
        ampp=port_sort(ii,2);
        b(p)=ampp;
    end

    b=CFF_inpaint_nans(b,4);
    sb_maxamp_port=repmat(b,1,nB/2);

   

    sb_maxamp_port(1:MSS-1,:)=1; %((maxdB-mindB)/maxdB);
    sb_maxamp=[sb_maxamp_stbd sb_maxamp_port];
    %%

    %Create table for relative range
    bp_pct_corr=nan(nS, nB);

    % Populate relative range matrix with relative reference amplitudes
    % using match with relative range from reference ping (Step 7)
    for bb=1:nB

        for ss=1:MSS-1%nSamples
            %  if ss<MSS
            beam_pcts=rp_pct_range_msra(:,bb);
            A = repmat(sb_pctrange_testping_msra(ss,bb),[1 length(beam_pcts)]);
            [minValue,closestIndex] = min(abs(A-beam_pcts'));
            closestValue = rp_pct_amp(closestIndex,bb) ;

            bp_pct_corr(ss,bb)=closestValue;
        end


    end
    for bb=1:nB
        for ss=MSS:nS %else

            beam_pcts=rp_pct_range(:,bb);
            A = repmat(sb_pctrange_testping(ss,bb),[1 length(beam_pcts)]);
            [minValue,closestIndex] = min(abs(A-beam_pcts'));
            closestValue = rp_pct_amp(closestIndex,bb) ;
            bp_pct_corr(ss,bb)=closestValue;
            
        end
    end

    % Create "simlated ping" using the max bottom amplitude and the
    % relative amplitude (Step 8)
    ping_sim=[];
    ping_sim=sb_maxamp.*bp_pct_corr;
    nSamplestest=length(testping);
    ping_sim(nSamplestest,nB)=nan;

    % Create a "corrected ping" by subtracting the simulated ping from the
    % uncorrected ping (Step 9)
ping_corr=[];
    % Remove data below bottom detection
    testping((SBP_bottomRange(:,:,pp))<X_SBP_sampleRange(:,:,pp))=nan;
    ping_sim((SBP_bottomRange(:,:,pp))<X_SBP_sampleRange(:,:,pp))=nan;
    ping_corr=testping-ping_sim;

    
   

     X_SBP_WCnorm(:,:, blockPings(pp))=testping;
    X_SBP_WCcorr(:,:, blockPings(pp))=ping_corr;
    X_SBP_WCsim(:,:,blockPings(pp))=ping_sim;
    
    end
   fprintf('End of block \n')
  
   clearvars -except fData  X_SBP_WCnorm X_SBP_WCcorr X_SBP_WCsim nBlocks info blocks rp_pct_amp rp_pct_range rp_pct_range_msra mindB maxdB nSamples 
end
% Calculate root mean square error between simualted ping and uncorrected ping
X_RMSE=squeeze(rmse(X_SBP_WCnorm, X_SBP_WCsim, 'omitnan'));

end