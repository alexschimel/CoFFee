function [fData] = CFF_watercolumn_sidelobe_filter(fData,varargin)
% OUT = CFF_new_function(argRequired, varargin)
%
% DESCRIPTION
%
% This is a basic description of the function. DELETE THIS LINE IF UNUSED
%
% USE
%
% This is a bit more detailed description of how to use the function. DELETE THIS LINE IF UNUSED
%
% PROCESSING SUMMARY
%
% This is a summary of the steps in the processing. DELETE THIS LINE IF UNUSED
%
% REQUIRED INPUT ARGUMENTS
%
% - 'argRequired': description of the first required argument. If several, add after this line.
%
% OPTIONAL INPUT ARGUMENTS
%
% - 'XXX': description of the optional arguments with list of valid values and what they do. DELETE THIS LINE IF UNUSED
%
% PARAMETERS INPUT ARGUMENTS
%
% - 'XXX': description of the optional parameter arguments (name-value pair). DELETE THIS LINE IF UNUSED
%
% OUTPUT VARIABLES
%
% - OUT: description of output variables. DELETE THIS LINE IF UNUSED
%
% RESEARCH NOTES
%
% This describes what features are temporary or needed future developments. DELETE THIS LINE IF UNUSED
%
% NEW FEATURES
%
% YYYY-MM-DD: second version. Describes the update. DELETE THIS LINE IF UNUSED
% YYYY-MM-DD: first version.
%
% EXAMPLES
%
% This section contains examples of valid function calls. DELETE THIS LINE IF UNUSED
%
%%%
% Alex Schimel, Deakin University. CHANGE AUTHOR IF NEEDED.
%%%


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
%method_bot = 1; % default
%remove_angle = inf; % default
%remove_closerange = 0; % default
%remove_bottomrange = inf; % default
if nargin==1
    % fData only. keep defaults
elseif nargin==2
    method_spec = varargin{1};
    % elseif nargin==3
    %     method_spec = varargin{1};
    %     method_bot = varargin{2};
    % elseif nargin==4
    %     method_spec = varargin{1};
    %     method_bot = varargin{2};
    %     remove_angle = varargin{3};
    % elseif nargin==5
    %     method_spec = varargin{1};
    %     method_bot = varargin{2};
    %     remove_angle = varargin{3};
    %     remove_closerange = varargin{4};
    % elseif nargin==6
    %     method_spec = varargin{1};
    %     method_bot = varargin{2};
    %     remove_angle = varargin{3};
    %     remove_closerange = varargin{4};
    %     remove_bottomrange = varargin{5};
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
        % d0= fData.X_PB_bottomRange_Filt;
        
        %r0= fData.X_PBS_sampleRange;
        for ip=1:nPings
            
            thisPing = L0(ip,:,:);
            thisBottom = b0(ip,:);
            %thisDepth= d0(ip,:);
            %  thisRanges= r0(ip,:,:);
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
        % CFF_watercolumn_display(fData,'otherData',Corr2d,'displayType','flat')clear
        
        % keep as L1
        % L1 = Corr2a;
        
        % AWN test: Sidelobe data only
        
        
        L1=Corr2b;


%     case 3
%
%         % DEMOUSTIER'S CORRECTION USING PERCENTILES:
%
%         Corr3 = nan(size(L0));
%
%         for ip=1:nPings
%
%             thisPing = L0(ip,:,:);
%             thisBottom = b0(ip,:);
%
%             % calculate 75th percentile
%             clear sevenfiveperc
%             for ismp = 1:nSamples
%                 X = thisPing(:,:,ismp);
%             	sevenfiveperc(1,1,ismp) = CFF_invpercentile(X,75);
%             end
%
%             % repmat for removal
%             sevenfiveperc3 = repmat(sevenfiveperc,[1,nBeams,1]);
%
%             % no reference level in his paper
%
%             % statistical compensation:
%             Corr3(ip,:,:) =  thisPing - sevenfiveperc3;
%
%         end
%
%         % test display
%         % CFF_watercolumn_display(fData,Corr3,'flat')
%
%         % keep as L1
%         L1 = Corr3;

otherwise
    
    error('method_spec not recognised')
end
fData.X_PBS_L1 = L1;

end
