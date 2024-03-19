function [fData] = CFF_filter_WC_sidelobe_artifact(fData,varargin)
% [fData] = CFF_filter_WC_sidelobe_artifact(fData,varargin)
%
% DESCRIPTION
%
% Filter water column artifact 
%
% INPUT VARIABLES
%
% - varargin{1} "method_spec": method for removal of specular reflection
%   - 0: None. Keep original
%   - 1: in devpt
%   - 2: (default)
%   - 3: de Moustier's 75th percentile
%
% OUTPUT VARIABLES
%
% - fData
%
% RESEARCH NOTES
%
% dataset have three dimensions: ping #, beam # and sample #.
%
% calculating the average backcatter level across samples, would allow
% us to spot the beams that have constantly higher or lower energy in a
% given ping. Doing this only for samples in the watercolumn would allow us
% to normalize the energy in the watercolumn of a ping
%
% calculating the average backcatter across all beams would allow
% us to spot the samples that have constantly higher or lower energy in a
% given ping.
%
% MORE PROCESSING ideas:
%
% the circular artifact on the bottom is due to specular reflection
% affecting all beams.
% -> remove in each ping by averaging the level at a given range across
% all beams.
% -> working on several pings at a time would work if the responsible
% reflectors are present on successive pings. They also need to stay at the
% same range so that would need some form of heave compensation. For heave
% compensation, maybe use the mean calculated on each ping and line up the
% highest return (specular).
%
% now when the specular artefacts are gone, what of the level being uneven
% across the swath in the water column? A higher level on outer beams that
% seems constant through pings? A higher level on closer ranges?
% -> Maybe calculate an average level across all pings for each beam and
% sample?
% -> Maybe such artefact is due to the difference in volume insonified that
% is not properly compensated....
% -> Since the system is roll-compensated, a given beam correspond to
% different steering angles, hence different beamwidths.
% -> Average not for each beam, but for each steering angle. Sample should
% be fine.
% 
%
% NEW FEATURES
%
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m

%   Copyright 2016-2016 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% random comment

%% Extract needed data
L0 = fData.WC_PBS_SampleAmplitudes./2; % original level divided by 2 (see kongsberg datagrams document)
bottomSample = fData.X_PB_bottomSample; % original bottom detect
nPings = size(L0,1);
nBeams = size(L0,2);
nSamples = size(L0,3);

%% Set methods
method_spec = 2; % default
if nargin==1
    % fData only. keep default
elseif nargin==2
    method_spec = varargin{1};
else
    error('wrong number of input variables')
end


%% MAIN PROCESSING SWITCH
switch method_spec
    
    case 0
        
        % No filtering. Keep original
        L1 = L0;
        
    case 1
        
        % for each ping, and each sample range, calculate the average level
        % over all beams and remove it
        
        % Compute mean level and std
        [meanAcrossPings,stdAcrossPings] = CFF_nanstat3(L0,1);
        [meanAcrossBeams,stdAcrossBeams] = CFF_nanstat3(L0,2);
        [meanAcrossSamples,stdAcrossSamples] = CFF_nanstat3(L0,3);
        
        % display the mean
        figure; imagesc(squeeze(meanAcrossPings)); xlabel('samples'); ylabel('beams')
        figure; imagesc(squeeze(meanAcrossBeams)); xlabel('samples'); ylabel('pings')
        figure; imagesc(squeeze(meanAcrossSamples)); xlabel('beams'); ylabel('pings')
        
        % repmat for removal
        meanAcrossPings3   = repmat(meanAcrossPings,[nPings,1,1]);
        stdAcrossPings3    = repmat(stdAcrossPings,[nPings,1,1]);
        meanAcrossBeams3   = repmat(meanAcrossBeams,[1,nBeams,1]);
        stdAcrossBeams3    = repmat(stdAcrossBeams,[1,nBeams,1]);
        meanAcrossSamples3 = repmat(meanAcrossSamples,[1,1,nSamples]);
        stdAcrossSamples3  = repmat(stdAcrossSamples,[1,1,nSamples]);
        
        % remove this mean:
        Corr1a = L0 - meanAcrossPings3;
        Corr1b = L0 - meanAcrossBeams3;
        Corr1c = L0 - meanAcrossSamples3;
        Corr1d = L0 - meanAcrossBeams3 - meanAcrossSamples3;
        
        % display
        CFF_watercolumn_display(fData,L0,'wedge')
        CFF_watercolumn_display(fData,Corr1a,'flat')
        CFF_watercolumn_display(fData,Corr1b,'flat')
        CFF_watercolumn_display(fData,Corr1c,'flat')
        CFF_watercolumn_display(fData,Corr1d,'flat')
        
        % keep as L1
        L1 = Corr1b;
        
    case 2
        
        % same but a little bit more complex
        
        % Corr2a = nan(size(L0));
        Corr2b = nan(size(L0));
        % Corr2c = nan(size(L0));
        % Corr2d = nan(size(L0));
        
        for ip=1:nPings
            
            thisPing = L0(ip,:,:);
            thisBottom = bottomSample(ip,:);
            
            % mean level across all beams for each range (and each ping)
            [meanAcrossBeams,stdAcrossBeams] = CFF_nanstat3(thisPing,2);
            
            % repmat for removal
            meanAcrossBeams3 = repmat(meanAcrossBeams,[1,nBeams,1]);
            %stdAcrossBeams3  = repmat(stdAcrossBeams ,[1,nBeams,1]);
            
            % find the reference level as the median level of all samples
            % above the median bottom sample in nadir beams:
            nadirBeams = [floor((nBeams./2)-5):ceil((nBeams./2)+5)]; % middle beams
            nadirBottom = median(thisBottom(nadirBeams),2); % median value -> bottom
            nadirSamples = thisPing(1,nadirBeams,[1:nadirBottom]); % all samples in middle beam, above bottom
            nadirSamples = nadirSamples(:);
            nadirSamples = nadirSamples(~isnan(nadirSamples));
            meanRefLevel = mean(nadirSamples);
            %stdRefLevel = std(nadirSamples);
            
            % statistical compensation:
            % Corr2a(ip,:,:) =  thisPing - meanAcrossBeams3; % simple mean removal, like my first paper
            Corr2b(ip,:,:) =  thisPing - meanAcrossBeams3 + meanRefLevel; % adding mean reference, like everyone does (a in Parnum)
            % Corr2c(ip,:,:) = (thisPing - meanAcrossBeams3)./stdAcrossBeams3 + meanRefLevel; % including normalization for std (b in Parnum)
            % Corr2d(ip,:,:) = ((thisPing - meanAcrossBeams3)./stdAcrossBeams3).*stdRefLevel + meanRefLevel; % going further: re-introducing a reference std   

        end
        
        % test display
        % CFF_watercolumn_display(fData,'otherData',Corr2a,'displayType','flat')
        % CFF_watercolumn_display(fData,'otherData',Corr2b,'displayType','flat')
        % CFF_watercolumn_display(fData,'otherData',Corr2c,'displayType','flat')
        % CFF_watercolumn_display(fData,'otherData',Corr2d,'displayType','flat')
        
        % keep as L1
        % L1 = Corr2a;
        L1 = Corr2b;
        
    case 3
        
        % DEMOUSTIER'S CORRECTION USING PERCENTILES:

        Corr3 = nan(size(L0));

        for ip=1:nPings
            
            thisPing = L0(ip,:,:);
            thisBottom = bottomSample(ip,:);
            
            % calculate 75th percentile 
            clear sevenfiveperc
            for ismp = 1:nSamples
                X = thisPing(:,:,ismp);
            	sevenfiveperc(1,1,ismp) = CFF_invpercentile(X,75);
            end
                
            % repmat for removal
            sevenfiveperc3 = repmat(sevenfiveperc,[1,nBeams,1]);

            % no reference level in his paper
            
            % statistical compensation:
            Corr3(ip,:,:) =  thisPing - sevenfiveperc3;

        end
        
        % test display
        % CFF_watercolumn_display(fData,Corr3,'flat')
        
        % keep as L1
        L1 = Corr3;
            
    otherwise
        
        error('method_spec not recognised')
        
end


%% SAVING RESULT IN FDATA
fData.X_PBS_L1 = L1;



%%
% old code to adapt:
%
%
%
% % computing correcting coefficients
% for ii=1:nPings
%
%     M = fData.WC_PBS_SampleAmplitudes(ii,:,:);
%     imagesc(M)
%
%     % Compute mean and std across all beams (except Nans)
%     meanAcrossBeams = nan(1,nSamples);
%     stdAcrossBeams = nan(1,nSamples);
%     for kk=1:nSamples
%         meanAcrossBeams(1,kk) = mean(M(~isnan(M(:,kk)),kk));
%         stdAcrossBeams(1,kk)  = std(M(~isnan(M(:,kk)),kk));
%     end
%
%     % remove one f them, check the quality in result
%     MCorr1 = M - ones(nBeams,1)*meanAcrossBeams;
%
%     % reference sample, use halfway to seafloor at nadir:
%     BeamPointingAngle = fData.WC_PB_BeamPointingAngle(ii,:);
%     [a,indnadir]=min(abs(BeamPointingAngle));
%     DetectedRange = fData.WC_PB_DetectedRangeInSamples(ii,indnadir);
%     StartRangeSampleNumber = fData.WC_PB_StartRangeSampleNumber(ii,indnadir);
%     refsample = round(0.5.*(DetectedRange+StartRangeSampleNumber));
%     refmean = meanAcrossBeams(refsample);
%     refstd = stdAcrossBeams(refsample);
%
%
%     %     bottom = fData.WC_PB_DetectedRangeInSamples(ii,:);
%     %     bottom(bottom==0)=NaN;
%     %     minBottom= min(bottom);
%     %     M2 = M(:,1:minBottom-1);
%     %
%     %     % mean and std across all samples (from 0 to just before shortest bottom range)
%     %     meanAcrossSamples = nan(nBeams,1);
%     %     stdAcrossSamples = nan(nBeams,1);
%     %     for jj=1:nBeams
%     %         meanAcrossSamples(jj,1) = mean(M2(jj,~isnan(M2(jj,:))));
%     %         stdAcrossSamples(jj,1)  = std(M2(jj,~isnan(M2(jj,:))));
%     %     end
%     %
%     %     % mean and std across a number of pings?
%     %     MCorr2 = M - meanAcrossSamples*ones(1,nSamples);
%     %     MCorr3 = M - ones(nBeams,1)*meanAcrossBeams - meanAcrossSamples*ones(1,nSamples);
%     %     % then remove both, try the two orders. check the differences
%
% end
%
%
% fDataCorr2 = (((fData - MeanAcrossAllBeams*ones(1,NumberOfBeams))./(StdAcrossAllBeams*ones(1,NumberOfBeams))) .* refstd) + refmean  ;
%
% fDataCorr = fDataCorr2;