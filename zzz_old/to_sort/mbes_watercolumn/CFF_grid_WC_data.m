function fData = CFF_grid_WC_data(fData,varargin)
% CFF_grid_WC_data.m

%   Copyright 2017-2018 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% XXX: check that gridding uses processed data if it exists, original data
% if not (instead of using the checkboxes)

%% input parsing

% init
p = inputParser;

% required
addRequired(p,'fData',@isstruct);

% optional
addParameter(p,'res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'vert_res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'dim','3D',@(x) ismember(x,{'2D' '3D'}));
addParameter(p,'dr_sub',4,@(x) isnumeric(x)&&x>0);
addParameter(p,'db_sub',2,@(x) isnumeric(x)&&x>0);
addParameter(p,'e_lim',[],@isnumeric);
addParameter(p,'n_lim',[],@isnumeric);

% parse
parse(p,fData,varargin{:})

% get results
res       = p.Results.res;
vert_res  = p.Results.vert_res;
dim       = p.Results.dim;
dr_sub    = p.Results.dr_sub;
db_sub    = p.Results.db_sub;


%% Extract info about WCD
[nSamples, nBeams, nPings] = size(fData.X_SBP_WaterColumnProcessed.Data.val);


%% Prepare needed 1xP data

% Source datagram
datagramSource = fData.MET_datagramSource;


% inter-sample distance
soundSpeed           = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)).*0.1; %m/s
samplingFrequencyHz  = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
interSamplesDistance = soundSpeed./(samplingFrequencyHz.*2); % in m

% sonar location
sonarEasting  = fData.X_1P_pingE; %m
sonarNorthing = fData.X_1P_pingN; %m
sonarHeight   = fData.X_1P_pingH; %m

% sonar heading
gridConvergence    = fData.X_1P_pingGridConv; %deg
vesselHeading      = fData.X_1P_pingHeading; %deg
sonarHeadingOffset = fData.IP_ASCIIparameters.S1H; %deg
sonarHeading       = deg2rad(-mod(gridConvergence + vesselHeading + sonarHeadingOffset,360));


%% block processing setup
blockLength = 10;
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end,2) = nPings;


%% find grid limits

% initialize vectors
minBlockE = nan(1,nBlocks);
minBlockN = nan(1,nBlocks);
maxBlockE = nan(1,nBlocks);
maxBlockN = nan(1,nBlocks);
switch dim
    case '3D'
        minBlockH = nan(1,nBlocks);
        maxBlockH = nan(1,nBlocks);
end

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings = blocks(iB,1):blocks(iB,2);
    
    % Sx1 vector of samples number (first and last samples only) and BxP
    % arrays of start sample number and beam pointing angle (outer beams
    % and central beam, for ping block, only)
    idxSamples = [1 nSamples]';
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))([1 round(nBeams./2) nBeams],blockPings);
    beamPointingAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))([1 round(nBeams./2) nBeams],blockPings)/100);
    
    % Get easting, northing and height
    [blockE, blockN, blockH] = CFF_georeference_sample(idxSamples, startSampleNumber, interSamplesDistance(blockPings), beamPointingAngle, ...
        sonarEasting(blockPings), sonarNorthing(blockPings), sonarHeight(blockPings), sonarHeading(blockPings));

    % these subset of all samples should be enough to find the bounds for the entire block
    minBlockE(iB) = min(blockE(:));
    maxBlockE(iB) = max(blockE(:));
    minBlockN(iB) = min(blockN(:));
    maxBlockN(iB) = max(blockN(:));
    
    switch dim
        case '3D'
            minBlockH(iB) = min(blockH(:));
            maxBlockH(iB) = max(blockH(:));
    end
    
end


%% Get grid boundaries from the min and max of those blocks

% in easting
minGridE = floor(min(minBlockE));
maxGridE = ceil(max(maxBlockE));
numElemGridE = ceil((maxGridE-minGridE)./res)+1;

% in northing
minGridN = floor(min(minBlockN));
maxGridN = ceil(max(maxBlockN));
numElemGridN = ceil((maxGridN-minGridN)./res)+1;

switch dim
    case '3D'
        % in height
        minGridH = floor(min(minBlockH));
        maxGridH = ceil(max(maxBlockH));
        numElemGridH = ceil((maxGridH-minGridH)./vert_res)+1;
end

%% initalize the grids (sum and points density per cell)
switch dim
    case '2D'
        gridSum   = zeros(numElemGridN,numElemGridE,'single');
        gridCount = zeros(numElemGridN,numElemGridE,'single');
    case '3D'
        gridSum   = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
        gridCount = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
end


%% fill the grids with block processing

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = blocks(iB,1):blocks(iB,2);
    
    % Sx1 vector of (decimated) samples number and (beam-decimated) BxP
    % arrays of start sample number and beam pointing angle (for ping
    % block, only)
    idxSamples = (1:dr_sub:nSamples)';
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(1:db_sub:end,blockPings);
    beamPointingAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(1:db_sub:end,blockPings)/100);
    
    % Get easting, northing and height
    [blockE, blockN, blockH] = CFF_georeference_sample(idxSamples, startSampleNumber, interSamplesDistance(blockPings), beamPointingAngle, ...
        sonarEasting(blockPings), sonarNorthing(blockPings), sonarHeight(blockPings), sonarHeading(blockPings));

    % get data to grid
    blockL = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed',blockPings,dr_sub,db_sub,'true');
    
    % remove nans:
    indNan = isnan(blockL);
    blockL(indNan) = [];
    if isempty(blockL)
        continue;
    end
    blockE(indNan) = [];
    blockN(indNan) = [];
    
    switch dim
        case '3D'
            blockH(indNan) = [];
    end
    clear indNan
    
    if isempty(blockL)
        continue;
    end
    
    % pass grid Level in natural before gridding
    blockL = 10.^(blockL./10);
    
    % data indices in full grid
    E_idx = round((blockE-minGridE)/res+1);
    N_idx = round((blockN-minGridN)/res+1);
    
    % first index
    idx_E_start = min(E_idx);
    idx_N_start = min(N_idx);
    
    % data indices in temp grid
    E_idx = E_idx - min(E_idx) + 1;
    N_idx = N_idx - min(N_idx) + 1;
    
    % size of temp grid
    N_E = max(E_idx);
    N_N = max(N_idx);
    
    switch dim
        
        case '2D'
            subs = single([N_idx' E_idx']);
            clear N_idx E_idx
            
            % Number of data points in grid cell (density/weight)
            gridCountTemp = accumarray(subs,ones(size(blockL'),'single'),single([N_N N_E]),@sum,single(0));
            
            % Sum of data points in grid cell
            gridSumTemp = accumarray(subs,blockL',single([N_N N_E]),@sum,single(0));
            
            clear blockE blockN blockH blockL subs
            
            % Summing sums in full grid
            gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)+gridCountTemp;
            
            % Summing density in full grid
            gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1)+gridSumTemp;
            
        case '3D'
            H_idx = round((blockH-minGridH)/vert_res+1);
            idx_H_start = min(H_idx);
            H_idx = H_idx - min(H_idx) + 1;
            N_H = max(H_idx);
            
            subs = single([N_idx' E_idx' H_idx']);
            clear N_idx E_idx H_idx
            
            % Number of data points in grid cell (density/weight)
            gridCountTemp = accumarray(subs,ones(size(blockH'),'single'),single([N_N N_E N_H]),@sum,single(0));
            
            % Sum of data points in grid cell
            gridSumTemp = accumarray(subs,blockL',single([N_N N_E N_H]),@sum,single(0));
            
            clear blockE blockN blockH blockL subs
            
            % Summing sums in full grid
            gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridCount(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1)+gridCountTemp;
            
            % Summing density in full grid
            gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1)+gridSumTemp;
    end
    
    clear gridCountTemp gridSumTemp
    
end


%% crop the results (remove nans on the edges)
switch dim
    
    case '2D'
        
        % dimensional sums
        sumGridCount_N = sum(gridCount,2);
        sumGridCount_E = sum(gridCount,1);
        
        % min and max indices for cropping
        minNidx = find(sumGridCount_N,1,'first');
        maxNidx = find(sumGridCount_N,1,'last');
        minEidx = find(sumGridCount_E,1,'first');
        maxEidx = find(sumGridCount_E,1,'last');
        
        % crop count and sum
        gridCount = gridCount(minNidx:maxNidx,minEidx:maxEidx);
        gridSum   = gridSum(minNidx:maxNidx,minEidx:maxEidx);
        
        % define and crop dim vectors
        gridNorthing = (0:numElemGridN-1)'.*res + minGridN;
        gridEasting  = (0:numElemGridE-1) .*res + minGridE;
        gridNorthing = gridNorthing(minNidx:maxNidx);
        gridEasting  = gridEasting(:,minEidx:maxEidx);
        
    case '3D'
        
        % dimensional sums
        sumGridCount_1EH = sum(gridCount,1);
        sumGridCount_N1H = sum(gridCount,2);
        sumGridCount_N = sum(sumGridCount_N1H,3);
        sumGridCount_E = sum(sumGridCount_1EH,3);
        sumGridCount_H = sum(sumGridCount_1EH,2);
        
        % min and max indices for cropping
        minNidx = find(sumGridCount_N,1,'first');
        maxNidx = find(sumGridCount_N,1,'last');
        minEidx = find(sumGridCount_E,1,'first');
        maxEidx = find(sumGridCount_E,1,'last');
        minHidx = find(sumGridCount_H,1,'first');
        maxHidx = find(sumGridCount_H,1,'last');
        
        % crop count and sum
        gridCount = gridCount(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        gridSum   = gridSum(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        
        % define and crop dim vectors
        gridNorthing = (0:numElemGridN-1)'.*res + minGridN;
        gridEasting  = (0:numElemGridE-1) .*res + minGridE;
        gridHeight   = permute((0:numElemGridH-1).*vert_res + minGridH,[3,1,2]);
        gridNorthing = gridNorthing(minNidx:maxNidx);
        gridEasting  = gridEasting(:,minEidx:maxEidx);
        gridHeight   = gridHeight(:,:,minHidx:maxHidx);
       
end

% final calculation average and back in dB
gridLevel = 10.*log10(gridSum./gridCount);


%% saving results:

fData.X_NEH_gridLevel   = gridLevel;
fData.X_NEH_gridDensity = gridCount;
fData.X_1E_gridEasting  = gridEasting;
fData.X_N1_gridNorthing = gridNorthing;
fData.X_1_gridHorizontalResolution = res;

switch dim
    case '3D'
        fData.X_11H_gridHeight  = gridHeight;
        fData.X_1_gridVerticalResolution = vert_res;
end


