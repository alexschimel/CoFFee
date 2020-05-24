function [fData] = CFF_filter_watercolumn(fData,varargin)
% [fData] = CFF_filter_watercolumn(fData,varargin)
%
% DESCRIPTION
%
% General function to filter/remove data based on given parameters
%
% INPUT VARIABLES
%
% - varargin{1} "method_spec": method for removal of specular reflection
%   - 0: None. Keep original
%   - 1: in devpt
%   - 2: (default)
%   - 3: de Moustier's 75th percentile
%
% - varargin{2} "method_bot": method for bottom filtering/processing
%   - 0: None
%   - 1: medfilt2 + inpaint_nans (default)
%   - 2:
%
% - varargin{3} "remove_angle": steering angle beyond which outer beams are
% removed (in deg ref nadir)
%   - eg: 55 -> angles>55 and <-55 are removed
%   - inf (default) -> all angles are conserved
%
% - varargin{4} "remove_closerange": range from sonar (in m) within which
% samples are removed
%   - eg: 4 -> all samples within 4m from sonar are removed
%   - 0 (default) -> all samples are conserved
%
% - varargin{5} "remove_bottomrange": range from bottom (in m) beyond which
% samples are removed. Range after bottom if positive, before bottom if
% negative
%   - eg: 2 -> all samples beyond 2m after bottom detect are removed
%   - eg: -3 -> all samples beyond 3m BEFORE bottom detect are removed
%   (therefore including bottom detect)
%   - inf (default) -> all samples are conserved.
%
% - varargin{6} "mypolygon": horizontal polygon (in Easting,
% northing coordinates) outside of which samples are removed.
% negative
%   - [] (default) -> all samples are conserved.
%
% OUTPUT VARIABLES
%
% fData
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
% - 2016-11-06: adding option to remove data outside of input polygon
% - 2014-02-26: first version. Code adapted from old processing scripts
%
%%%
% Alex Schimel, Deakin University
%%%

% random comment

%% Extract needed data
L0 = fData.WC_PBS_SampleAmplitudes./2;% original level divided by 2 (see kongsberg datagrams document)
b0 = fData.WC_PB_DetectedRangeInSamples; % original bottom detect
nPings = size(L0,1);
nBeams = size(L0,2);
nSamples = size(L0,3);
angles = fData.WC_PB_BeamPointingAngle;
ranges = fData.X_PBS_sampleRange;
P_oneSampleDistance = fData.X_P_oneSampleDistance;


%% Set methods
method_spec = 2; % default
method_bot = 1; % default
remove_angle = inf; % default
remove_closerange = 0; % default
remove_bottomrange = inf; % default
mypolygon = []; % default
if nargin==1
    % fData only. keep defaults
elseif nargin==2
    method_spec = varargin{1};
elseif nargin==3
    method_spec = varargin{1};
    method_bot = varargin{2};
elseif nargin==4
    method_spec = varargin{1};
    method_bot = varargin{2};
    remove_angle = varargin{3};
elseif nargin==5
    method_spec = varargin{1};
    method_bot = varargin{2};
    remove_angle = varargin{3};
    remove_closerange = varargin{4};
elseif nargin==6
    method_spec = varargin{1};
    method_bot = varargin{2};
    remove_angle = varargin{3};
    remove_closerange = varargin{4};
    remove_bottomrange = varargin{5};
elseif nargin==7
    method_spec = varargin{1};
    method_bot = varargin{2};
    remove_angle = varargin{3};
    remove_closerange = varargin{4};
    remove_bottomrange = varargin{5};
    mypolygon = varargin{6};
else
    error('wrong number of input variables')
end


%% SPECULAR REFLECTION FILTERING:
switch method_spec
    
    case 0
        
        % keep as L1
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
            thisBottom = b0(ip,:);
            
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
            thisBottom = b0(ip,:);
            
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



%% BOTTOM DETECT FILTERING:
switch method_bot
    
    case 0
        
        % keep as b1
        b1 = b0;
        
    case 1
        
        % medfilt1 and inpaint_nan bottom
        filtSize = 7; % filter width in beams
        fS=ceil((filtSize-1)./2);
        b0(b0==0) = NaN; % repace no detects by NaN
        b1 = b0;
        for ii=1:nPings
            % for each ping
            for jj = 1+fS:nBeams-fS
                tmp = b0(ii,jj-fS:jj+fS);
                tmp = tmp(~isnan(tmp(:)));
                if ~isempty(tmp)
                    b1(ii,jj) = median(tmp);
                end
            end
        end
        b1 = round(CFF_inpaint_nans(b1));
        % because inpaint interpolation can yield numbers below zeros in
        % areas where there are a lot of nans:
        b1(b1<1)=2;
        
        %display
%         figure;
%         minb=min([b0(:);b1(:)]);
%         maxb=max([b0(:);b1(:)]);
%         subplot(221); imagesc(b0); colorbar; title('range of raw bottom'); caxis([minb maxb])
%         subplot(222); imagesc(b1); colorbar; title('range of filtered bottom'); caxis([minb maxb])
%         subplot(223); imagesc(b1-b0); colorbar; title('filtered-raw')
        
    case 2
        
    otherwise
        error('method_bot not recognised')
        
end

% saving
fData.X_PB_b1 = b1;



%% OUTER BEAMS REMOVAL

if ~isinf(remove_angle)
    
    % build mask: 1: to conserve, 0: to remove
    PB_Mask = double( angles >= -abs(remove_angle)*100  ...
                    & angles <=  abs(remove_angle)*100      );
    PBS_Mask = repmat(PB_Mask,[1 1 nSamples]);
    PBS_Mask(PBS_Mask==0) = NaN;
    
    % apply mask
    L1 = L1 .* PBS_Mask;
    
end



%% CLOSE RANGE REMOVAL

if remove_closerange>0
    
    % build mask: 1: to conserve, 0: to remove
    PBS_Mask = double(ranges >= remove_closerange);
    PBS_Mask(PBS_Mask==0) = NaN;
    
    % apply mask
    L1 = L1 .* PBS_Mask;
    
end


%% BOTTOM RANGE REMOVAL

if ~isinf(remove_bottomrange)
    
    PB_oneSampleDistance = repmat(P_oneSampleDistance ,[1 nBeams]);
    PB_bottomRange = b1 .* PB_oneSampleDistance;
    PB_maxRange = PB_bottomRange + remove_bottomrange;
    PB_maxSample = round(PB_maxRange ./ PB_oneSampleDistance);
    PB_maxSample(PB_maxSample>nSamples)=nSamples;
    
    [X,Y] = meshgrid([1:nBeams],[1:nPings]');
    maxSubs = [Y(:),X(:),PB_maxSample(:)];
    
    % build mask: 1: to conserve, 0: to remove
    PBS_Mask = zeros(nPings,nBeams,nSamples);
    for ii = 1:size(maxSubs,1)
        PBS_Mask(maxSubs(ii,1),maxSubs(ii,2),1:maxSubs(ii,3)) = 1;
    end
    PBS_Mask(PBS_Mask==0) = NaN;
    
    % apply mask
    L1 = L1 .* PBS_Mask;
    
end


%% OUTSIDE POLYGON REMOVAL

if ~isempty(mypolygon)
    
    % extract needed data
    E = fData.X_PBS_sampleEasting;
    N = fData.X_PBS_sampleNorthing;
    
    % build mask: 1: to conserve, 0: to remove
    PBS_Mask = inpolygon(E,N,mypolygon(:,1),mypolygon(:,2));
    PBS_Mask = double(PBS_Mask);
    PBS_Mask(PBS_Mask==0) = NaN;

    % apply mask
    L1 = L1 .* PBS_Mask;
    
end

%% SAVING L1
fData.X_PBS_L1 = L1;


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