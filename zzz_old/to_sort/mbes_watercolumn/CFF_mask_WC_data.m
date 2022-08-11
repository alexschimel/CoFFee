%% CFF_mask_WC_data.m
%
% Mask water-column data to remove unwanted samples
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._  
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX 
%
% *INPUT VARIABLES*
%
% * |fData|: Required. Structure for the storage of kongsberg EM series
% multibeam data in a format more convenient for processing. The data is
% recorded as fields coded "a_b_c" where "a" is a code indicating data
% origing, "b" is a code indicating data dimensions, and "c" is the data
% name. See the help of function CFF_convert_ALLdata_to_fData.m for
% description of codes. 
% * |remove_angle|: Optional. Steering angle beyond which outer beams are
% removed (in deg ref acoustic axis). Example: 55 -> angles>55 and <-55 are
% removed. Default: inf (all angles are conserved).
% * |remove_range|: Optional. Range from sonar (in m) within which
% samples are removed/conserved. Example: 4 -> all samples within 4m range
% from sonar are removed. -4 -> all samples beyond 4m range from sonar area
% removed. Default: 0 (all samples are conserved). 
% * |remove_bottomrange|: Optional. Range from bottom (in m) beyond which
% samples are removed. Range after bottom if positive, before bottom if
% negative. Example: 2 -> all samples 2m AFTER bottom detect and beyond are
% removed. Example: -3 -> all samples 3m BEFORE bottom detect and beyond
% are removed (therefore including bottom detect). Default: inf (all
% samples are conserved). 
% * |mypolygon|: Optional. Horizontal polygon (in Easting, Northing
% coordinates) outside of which samples are removed. Defualt: [] (all
% samples are conserved). 
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed" now
% masked.
%
% *DEVELOPMENT NOTES*
%
% * check that masking uses filtered bottom if it exists, original bottom
% if not.
%
% *NEW FEATURES*
%
% * 2018-10-11: Updated header before adding to Coffee v3
% * 2017-10-10: new v2 functions because of dimensions swap (Alex Schimel)
% - 2016-12-01: Updating bottom range removal after change of bottom
% processing
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._ 
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Deakin University, NIWA. Yoann Ladroit, NIWA.

%% Function
function [fData] = CFF_mask_WC_data(fData,varargin)


%% INPUT PARSING

remove_angle       = inf; % default
remove_range  = 0;   % default
remove_bottomrange = inf; % default
mypolygon          = [];  % default

if nargin==1
    % fData only. keep defaults
elseif nargin==2
    remove_angle = varargin{1};
elseif nargin==3
    remove_angle      = varargin{1};
    remove_range = varargin{2};
elseif nargin==4
    remove_angle       = varargin{1};
    remove_range  = varargin{2};
    remove_bottomrange = varargin{3};
elseif nargin==5
    remove_angle       = varargin{1};
    remove_range  = varargin{2};
    remove_bottomrange = varargin{3};
    mypolygon          = varargin{4};
else
    error('wrong number of input variables')
end


%% Extract info about WCD
wcdata_class  = fData.X_1_WaterColumnProcessed_Class; % int8 or int16
wcdata_factor = fData.X_1_WaterColumnProcessed_Factor; 
wcdata_nanval = fData.X_1_WaterColumnProcessed_Nanval;
[nSamples, nBeams, nPings] = size(fData.X_SBP_WaterColumnProcessed.Data.val);


%% Prep

% Source datagram
datagramSource = fData.MET_datagramSource;


% inter-sample distance
soundSpeed          = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)).*0.1; %m/s
samplingFrequencyHz = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
dr_samples = soundSpeed./(samplingFrequencyHz.*2);



%% Block processing

% main computation section will be done in blocks, and saved as numerical
% arrays or processedDataFile depending on fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).
blockLength = 50;
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end) = nPings;

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    nBlockPings = length(blockPings);

    % MASK 1: OUTER BEAMS REMOVAL
    if ~isinf(remove_angle)
        
        % extract needed data
        angles = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,blockPings)./100;
        
        % build mask: 1: to conserve, 0: to remove
        X_BP_OuterBeamsMask = angles>=-abs(remove_angle) & angles<=abs(remove_angle);
        
        X_1BP_OuterBeamsMask = permute(X_BP_OuterBeamsMask ,[3,1,2]);
        
    else        
        
        % conserve all data
        X_1BP_OuterBeamsMask = true(1,nBeams,nBlockPings);
        
    end
    
    % MASK 2: RANGE REMOVAL
    if remove_range == 0
        
        % conserve all data
        X_SBP_RangeMask = true(nSamples,nBeams,nBlockPings);
        
    else
        
        % extract needed data
        ranges = CFF_get_samples_range( (1:nSamples)', fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,blockPings), dr_samples(blockPings));
        
        if remove_range>0
            % build mask: conserve (1) all ranges beyond desired threshold
            X_SBP_RangeMask = ranges>=remove_range;
        else
            % build mask: conserve (1) all ranges under desired threshold
            X_SBP_RangeMask = ranges<=remove_range;
        end
        
    end
    
    % MASK 3: BOTTOM RANGE REMOVAL
    if ~isinf(remove_bottomrange)
        
        % beam pointing angle
        theta = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,blockPings)/100);
        
        % beamwidth (nominal and with steering)
        psi = deg2rad(fData.Ru_1D_ReceiveBeamwidth(1)./10);
        psi = psi./cos(theta);
        
        % transition between normal and grazing incidence
        theta_lim = psi/2;
        idx_normal = abs(theta) < theta_lim;
        idx_grazing = ~idx_normal;
        
        % length of bottom echo? XXX
        M = zeros(size(theta),'single');
        M(idx_normal)  = ( 1./cos(theta(idx_normal)+psi(idx_normal)/2)   - 1./cos(theta(idx_normal)) ) .* fData.X_BP_bottomRange(idx_normal);
        M(idx_grazing) = ( 1./cos(theta(idx_grazing)+psi(idx_grazing)/2) - 1./cos(theta(idx_grazing)-psi(idx_grazing)/2) ) .* fData.X_BP_bottomRange(idx_grazing);
        
        % calculate max sample beyond which mask is to be applied
        X_BP_maxRange  = fData.X_BP_bottomRange(:,blockPings) + remove_bottomrange - abs(M);
        X_BP_maxSample = bsxfun(@rdivide,X_BP_maxRange,dr_samples(blockPings));
        X_BP_maxSample = round(X_BP_maxSample);
        X_BP_maxSample(X_BP_maxSample>nSamples|isnan(X_BP_maxSample)) = nSamples;
        
        % build list of indices for each beam & ping
        [PP,BB] = meshgrid((1:nBlockPings),(1:nBeams));
        maxSubs = [X_BP_maxSample(:),BB(:),PP(:)];
        
        % build mask: 1: to conserve, 0: to remove
        X_SBP_BottomRangeMask = false(nSamples,nBeams,nBlockPings);
        for ii = 1:size(maxSubs,1)
            X_SBP_BottomRangeMask(1:maxSubs(ii,1),maxSubs(ii,2),maxSubs(ii,3)) = true;
        end

    else
        
        % conserve all data
        X_SBP_BottomRangeMask = true(nSamples,nBeams,nBlockPings);
        
    end
    
    % MASK 4: OUTSIDE POLYGON REMOVAL
    if ~isempty(mypolygon)
        
        % sonar location
        sonarEasting  = fData.X_1P_pingE(1,blockPings); %m
        sonarNorthing = fData.X_1P_pingN(1,blockPings); %m
        sonarHeight   = fData.X_1P_pingH(1,blockPings); %m
        
        % sonar heading
        gridConvergence    = fData.X_1P_pingGridConv(1,blockPings); %deg
        vesselHeading      = fData.X_1P_pingHeading(1,blockPings); %deg
        sonarHeadingOffset = fData.IP_ASCIIparameters.S1H; %deg
        sonarHeading       = deg2rad(-mod(gridConvergence + vesselHeading + sonarHeadingOffset,360));
        
        % inter-sample distance
        soundSpeed           = fData.WC_1P_SoundSpeed(1,blockPings).*0.1; %m/s
        samplingFrequencyHz  = fData.WC_1P_SamplingFrequencyHz(1,blockPings); %Hz
        interSamplesDistance = soundSpeed./(samplingFrequencyHz.*2); % in m
        
        % samples
        nSamples = size(fData.WC_SBP_SampleAmplitudes.Data.val,1);
        idxSamples = [1:nSamples]';
        startRangeSampleNumber = fData.WC_BP_StartRangeSampleNumber(:,blockPings);
        
        % beam pointing angle
        beamPointingAngle = deg2rad(fData.WC_BP_BeamPointingAngle(:,blockPings)/100);
    
        % Get across and upwards distance
        [sampleEasting, sampleNorthing] = CFF_georeference_sample(idxSamples, startRangeSampleNumber, interSamplesDistance, beamPointingAngle, sonarEasting, sonarNorthing, sonarHeight, sonarHeading);

        % build mask: 1: to conserve, 0: to remove
        X_SBP_PolygonMask = inpolygon(sampleEasting,sampleNorthing,mypolygon(:,1),mypolygon(:,2));
        
    else
        
        % conserve all data
        X_SBP_PolygonMask = true(nSamples,nBeams,nBlockPings);
        
    end
    
    % MULTIPLYING ALL MASKS
    mask = bsxfun(@and,X_1BP_OuterBeamsMask,(X_SBP_RangeMask & X_SBP_BottomRangeMask & X_SBP_PolygonMask));
    
    % get raw data and apply mask
    data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed',blockPings,1,1,'raw');
    data(~mask) = fData.X_1_WaterColumnProcessed_Nanval;
    
    % saving
    fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = data;

end





end
