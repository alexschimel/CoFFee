function fData = CFF_grid_WC_data(fData,varargin)
%CFF_GRID_WC_DATA  One-line description
%
%   *INPUT VARIABLES*
%   * |fData|: Required. Structure for the storage of kongsberg EM series
%   multibeam data in a format more convenient for processing. The data is
%   recorded as fields coded "a_b_c" where "a" is a code indicating data
%   origing, "b" is a code indicating data dimensions, and "c" is the data
%   name. See the help of function CFF_convert_ALLdata_to_fData.m for
%   description of codes.
%   * |grid_horz_res|: Description (Information). Default: 1 
%   * |grid_vert_res|: Description (Information). Default: 1
%   * |grid_type|: Description (Information). '2D' or '3D' (default) 
%   * |dr_sub|: Description (Information). Default: 4
%   * |db_sub|: Description (Information). Default: 2
%   * |e_lim|: Description (Information). Default: [] 
%   * |n_lim|: Description (Information). Default: []
%
%   *OUTPUT VARIABLES*
%   * |fData|: fData structure updated with fields for gridded data

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% input parsing

% init
p = inputParser;

% grid mode (2D map or 3D) and resolution (horizontal and vertical)
addParameter(p,'grid_type','3D',@(x) ismember(x,{'2D' '3D'}));
addParameter(p,'grid_horz_res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'grid_vert_res',1,@(x) isnumeric(x)&&x>0);

% decimation factors
addParameter(p,'dr_sub',4,@(x) isnumeric(x)&&x>0);
addParameter(p,'db_sub',2,@(x) isnumeric(x)&&x>0);

% grid limitation parameters
addParameter(p,'grdlim_mode','between',@(x) ismember(x,{'between', 'outside of'}));
addParameter(p,'grdlim_var','Sonar',@(x) ismember(x,{'Sonar', 'Bottom'}));
addParameter(p,'data_type','Processed',@(x) ismember(x,{'Processed', 'Original'}));
addParameter(p,'grdlim_mindist',0,@isnumeric);
addParameter(p,'grdlim_maxdist',inf,@isnumeric);
addParameter(p,'grdlim_east',[],@isnumeric);
addParameter(p,'grdlim_north',[],@isnumeric);

% parse
parse(p,varargin{:})

% get results
grid_type     = p.Results.grid_type;
grid_horz_res = p.Results.grid_horz_res;
grid_vert_res = p.Results.grid_vert_res;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
grdlim_mode    = p.Results.grdlim_mode;
grdlim_var     = p.Results.grdlim_var;
grdlim_mindist = p.Results.grdlim_mindist;
grdlim_maxdist = p.Results.grdlim_maxdist;
grdlim_east    = p.Results.grdlim_east;
grdlim_north   = p.Results.grdlim_north;
data_type   = p.Results.data_type;


%% Extract info about WCD
switch data_type
    case 'Original'
        if isfield(fData,'WC_SBP_SampleAmplitudes')
            field_to_grid = 'WC_SBP_SampleAmplitudes';
        else
            field_to_grid = 'AP_SBP_SampleAmplitudes';
        end
    otherwise
        if isfield(fData,'X_SBP_WaterColumnProcessed')
            field_to_grid = 'X_SBP_WaterColumnProcessed';
        elseif isfield(fData,'WC_SBP_SampleAmplitudes')
            field_to_grid = 'WC_SBP_SampleAmplitudes';
        else
            field_to_grid = 'AP_SBP_SampleAmplitudes';
        end
end
% size
[nSamples, nBeams, nPings] = CFF_get_WC_size(fData);

%% Prepare needed 1xP data for computations

% Source datagram
datagramSource = CFF_get_datagramSource(fData);

% inter-sample distance
interSamplesDistance = CFF_inter_sample_distance(fData); % m

% sonar location
sonarEasting  = fData.X_1P_pingE; % m
sonarNorthing = fData.X_1P_pingN; % m
sonarHeight   = fData.X_1P_pingH; % m

% sonar heading
gridConvergence    = fData.X_1P_pingGridConv; % deg
vesselHeading      = fData.X_1P_pingHeading; % deg
sonarHeadingOffset = fData.IP_ASCIIparameters.S1H; % deg
sonarHeading       = deg2rad(-mod(gridConvergence + vesselHeading + sonarHeadingOffset,360)); % rad

% prep specific to reference type
switch grdlim_var
    case 'Sonar'
        % For some files, the sonar height is an actually-measured height
        % referenced to a datum. For others, it's just dummy zero values.
        % Depends on the raw datagrams these values were taken from. Here,
        % the "Sonar-referenced" grids must ignore the sonar height above a
        % datum to ensure the grids are indeed referenced to the sonar. So
        % we enforce dummy zero values for height. If in the future we want
        % to create grids in reference to a datum, will need to adjust this
        % code. 
        sonarHeight = zeros(size(sonarHeight));
    case 'Bottom'
        % For bottom-reference gridding, we will need to calculate the
        % height above bottom for all samples. To do this, we prepare an
        % interpolant: a function that will give the height of the bottom
        % (above datum) for any easting/northing location.
        iValidBottom = false(size(fData.X_BP_bottomHeight));
        iValidBottom(1:db_sub:end,:) = true;
        iValidBottom = iValidBottom & (~isnan(fData.X_BP_bottomHeight) & ~isinf(fData.X_BP_bottomHeight));
        heightInterpolant = scatteredInterpolant(fData.X_BP_bottomNorthing(iValidBottom),fData.X_BP_bottomEasting(iValidBottom),fData.X_BP_bottomHeight(iValidBottom),'linear','none');
end


%% GPU setup
if CFF_is_parallel_computing_available()
    useGpu = 1;
    processingUnit = 'GPU';
else
    useGpu = 0;
    processingUnit = 'CPU';
end

%% Block processing setup
[blocks,info] = CFF_setup_optimized_block_processing(...
    nPings,nSamples*nBeams*4,...
    processingUnit,...
    'desiredMaxMemFracToUse',0.2);
nBlocks = size(blocks,1);
%disp(info);

%% find grid limits

% initialize vectors
minBlockE = nan(1,nBlocks);
minBlockN = nan(1,nBlocks);
minBlockH = nan(1,nBlocks);
maxBlockE = nan(1,nBlocks);
maxBlockN = nan(1,nBlocks);
maxBlockH = nan(1,nBlocks);

% find grid limits for each block
for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings = blocks(iB,1):blocks(iB,2);
    
    % to define the limits of the grid for each block, we'll only consider
    % the easting and northing of the first and last sample for the central
    % beam and two outer beams, for all pings.
    idxSamples = [1 nSamples]';
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))([1 round(nBeams./2) nBeams],blockPings);
    beamPointingAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))([1 round(nBeams./2) nBeams],blockPings));
    
    % Get easting, northing and height
    [blockE, blockN, blockH] = CFF_georeference_sample(idxSamples, startSampleNumber, interSamplesDistance(blockPings), beamPointingAngle, ...
        sonarEasting(blockPings), sonarNorthing(blockPings), sonarHeight(blockPings), sonarHeading(blockPings));
    
    % these subset of all samples should be enough to find the bounds for
    % the entire block
    minBlockE(iB) = min(blockE(:));
    maxBlockE(iB) = max(blockE(:));
    minBlockN(iB) = min(blockN(:));
    maxBlockN(iB) = max(blockN(:));
    minBlockH(iB) = min(blockH(:));
    maxBlockH(iB) = max(blockH(:));
    
end

% Get grid boundaries from the min and max of those blocks
minGridE = floor(min(minBlockE));
maxGridE = ceil(max(maxBlockE));
numElemGridE = ceil((maxGridE-minGridE)./grid_horz_res)+1;
minGridN = floor(min(minBlockN));
maxGridN = ceil(max(maxBlockN));
numElemGridN = ceil((maxGridN-minGridN)./grid_horz_res)+1;
minGridH = floor(min(minBlockH));
maxGridH = ceil(max(maxBlockH));
numElemGridH = ceil((maxGridH-minGridH)./grid_vert_res)+1;

% the grid defined above in height is referenced to sonar height. It needs
% modified if we request heights reference to seafloor
switch grdlim_var
    case 'Bottom'
        lowestHeight = nanmin(fData.X_BP_bottomHeight(:));
        % by default, defining grid as extending from 0 (the bottom) to the
        % largest height, adding a buffer of a tenth of that largest height
        % on each side
        minGridH = floor( 0 - abs(lowestHeight./10) );
        maxGridH = ceil( abs(lowestHeight) + abs(lowestHeight./10) );
        numElemGridH = ceil((maxGridH-minGridH)./grid_vert_res)+1;
end


%% initalize the grids:
% * weighted sum and total sum of weights. In absence of weights, the total
% sum of weights is simply the count of points, and the weighted sum is
% simply the sum
% * Now also doing a grid containing the maximum horizontal distance to
% nadir, to be used when mosaicking using the "stitching" method.
switch grid_type
    case '2D'
        gridWeightedSum  = zeros(numElemGridN,numElemGridE,'single');
        gridTotalWeight  = zeros(numElemGridN,numElemGridE,'single');
        gridMaxHorizDist =   nan(numElemGridN,numElemGridE,'single');
    case '3D'
        gridWeightedSum  = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
        gridTotalWeight  = zeros(numElemGridN,numElemGridE,numElemGridH,'single');
        gridMaxHorizDist =   nan(numElemGridN,numElemGridE,numElemGridH,'single');
end

if useGpu
    % turn grids into gpuArrays
    gridWeightedSum  = gpuArray(gridWeightedSum);
    gridTotalWeight  = gpuArray(gridTotalWeight);
    gridMaxHorizDist = gpuArray(gridMaxHorizDist);
end


%% fill the grids with block processing
for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = blocks(iB,1):blocks(iB,2);
    
    % get data to grid (possibly decimated in beams and samples
    blockL = CFF_get_WC_data(fData,field_to_grid,'iPing',blockPings,'dr_sub',dr_sub,'db_sub',db_sub,'output_format','true');
    
    % retrieve the index of samples given the decimation
    nSamples_temp = size(blockL,1);
    idxSamples = (1:dr_sub:nSamples_temp*dr_sub)';
    
    startSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(1:db_sub:end,blockPings);
    beamPointingAngle = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(1:db_sub:end,blockPings));
    
    % get easting, northing, height and across distance from the samples
    [blockE, blockN, blockH, blockAccD] = CFF_georeference_sample(idxSamples, startSampleNumber, interSamplesDistance(blockPings), beamPointingAngle, ...
        sonarEasting(blockPings), sonarNorthing(blockPings), sonarHeight(blockPings), sonarHeading(blockPings));
    
    % blockE and blockN needs to stay double for the interpolant, but
    % blockAdd needs to be single for the following calculations
    blockAccD = single(blockAccD);
    
    % for bottom-reference gridding, we need to calculate each sample's
    % height above the bottom. We use the interpolant here, which takes a
    % while....
    switch grdlim_var
        case 'Bottom'
            % First, we calculate the height of the bottom for the
            % Easting/Northing location of each sample.
            
            % REFACTOR Alex 16/08/2024
            
            % SUPER OLD
            % block_bottomHeight = HeightInterpolant(blockN,blockE);
            
            % OLD (Yoann)
            % block_bottom_H=permute(fData.X_BP_bottomHeight(1:db_sub:end,blockPings),[3 1 2]);
            % block_bottomHeight = nan(size(blockH));
            % id_interp = (blockH>block_bottom_H);%reducing the amount of data we need to compute heigth above bottom for
            % block_bottomHeight(id_interp) = heightInterpolant(blockN(id_interp),blockE(id_interp));
            
            % NEW
            % No need to calculate the height of the bottom at the
            % horizontal location of samples for which the level is NaN
            block_bottomHeight = nan(size(blockN));
            iValid = ~isnan(blockL);
            block_bottomHeight(iValid) = heightInterpolant(blockN(iValid),blockE(iValid));
            
            % REFACTOR END
            
            % Turn sample's height above datum to height above bottom
            blockH = blockH - block_bottomHeight;
            clear block_bottomHeight
    end
    
    % define weights here
    weighting_mode = 'none'; % 'SIAfilter' or 'none'
    switch weighting_mode
        case 'none'
            % all samples have the same weight (1) in the gridding
            blockW = ones(size(blockL),class(blockL));
        case 'SIAfilter'
            % samples have a weight dependent on how strongly they were
            % affected by the SIA filter. The ranges where specular occured
            % had a strong mean BS to which we will apply a small weight
            % (towards 0), while the ranges that had no speculars had a
            % relatively lower mean BS, and those we will apply a larger
            % weight (towards 1).
            % This correction requires to have saved the sidelobe artifact
            % correction at the processing stage.
            if isfield(fData, 'X_S1P_sidelobeArtifactCorrection')
                
                SIAcorrection = fData.X_S1P_sidelobeArtifactCorrection(1:dr_sub:end,1,blockPings);
                
                % define downramp function, going down linearly from
                % (X1,Y1) to (X2,Y2). Equals Y1 for x<X1, and equals Y2 for
                % x>X2.
                downramp_fun  = @(x,X1,X2,Y1,Y2) min(max(x.*(Y1-Y2)./(X1-X2)+(Y2.*X1-Y1.*X2)./(X1-X2),Y2),Y1);
                
                % use inverse percentiles to figure the start and end of
                % the ramp.
                start_ramp = CFF_invpercentile(SIAcorrection(:),20);
                end_ramp   = CFF_invpercentile(SIAcorrection(:),80);
                
                % apply to SIAcorrection to get the weight scores (between
                % 0 and 1)
                fact   = downramp_fun(SIAcorrection,start_ramp,end_ramp,1,0);
                blockW = single(repmat(fact,1,size(blockL,2),1));
            else
                warning('This weighting mode cannot be used because processed data do not include the needed field. Using no-weighting mode for now.');
                blockW = ones(size(blockL),class(blockL));
            end
    end
    
    % start with removing all data where anything is missing
    indNan = isnan(blockL) | isnan(blockW) | isnan(blockE) | isnan(blockN) | isnan(blockH) | isnan(blockAccD);
    blockL(indNan) = [];
    if isempty(blockL)
        continue;
    end
    blockW(indNan)    = [];
    blockE(indNan)    = [];
    blockN(indNan)    = [];
    blockH(indNan)    = [];
    blockAccD(indNan) = [];
    clear indNan
    
    % next, in case of 2D gridding, removing samples outside of desired
    % layer
    switch grid_type
        case '2D'
            switch grdlim_var
                case 'Sonar'
                    % heights are referenced to sonar and min/max distances
                    % are in depth (below sonar)
                    switch grdlim_mode
                        case 'between'
                            idx_keep = blockH<=-grdlim_mindist & blockH>=-grdlim_maxdist;
                        case 'outside of'
                            idx_keep = blockH>=-grdlim_mindist | blockH<=-grdlim_maxdist;
                    end
                case 'Bottom'
                    % heights are referenced to bottom and min/max distances
                    % are in height (above bottom)
                    switch grdlim_mode
                        case 'between'
                            idx_keep = blockH>=grdlim_mindist & blockH<=grdlim_maxdist;
                        case 'outside of'
                            idx_keep = blockH<=grdlim_mindist | blockH>=grdlim_maxdist;
                    end
            end
        otherwise
            idx_keep = true(size(blockH));
    end
    
    %Only keep samples within the allocated grid (potential issue in bottom reference grids otherwise)
    idx_keep = idx_keep &...
        (blockE-minGridE)>=0 & (blockE-maxGridE)<=0 & (blockN-minGridN)>=0 & (blockN-maxGridN)<=0 & (blockH-minGridH)>=0 & (blockH-maxGridH)<=0;
    
    blockL(~idx_keep) = [];
    if isempty(blockL)
        continue;
    end
    blockW(~idx_keep)    = [];
    blockE(~idx_keep)    = [];
    blockN(~idx_keep)    = [];
    blockH(~idx_keep)    = [];
    blockAccD(~idx_keep) = [];
    clear idx_keep
    
    % at this stage, pass blockL and blockW as GPU arrays if using GPUs
    if isa(gridWeightedSum,'gpuArray')
        blockL    = gpuArray(blockL);
        blockW    = gpuArray(blockW);
        blockAccD = gpuArray(blockAccD);
    end
    
    % pass grid level in natural before gridding
    blockL = 10.^(blockL./10);
    
    % also, turn across distance (signed) to horizontal distance from nadir
    % (unsigned)
    blockD = abs(blockAccD);
    clear blockAccD
    
    % data indices in the full grid
    E_idx = round((blockE-minGridE)/grid_horz_res+1);
    N_idx = round((blockN-minGridN)/grid_horz_res+1);
    clear blockE blockN
    
    % first index
    idx_E_start = min(E_idx);
    idx_N_start = min(N_idx);
    
    % data indices in the small grid built just for this block of pings
    E_idx = E_idx - min(E_idx) + 1;
    N_idx = N_idx - min(N_idx) + 1;
    
    % size of this small grid
    N_E = max(E_idx);
    N_N = max(N_idx);
    
    % now gridding...
    switch grid_type
        
        case '2D'
            
            % no need for blockH any more
            clear blockH
            
            % we use the accumarray function to sum all values in both the
            % total weight grid, and the weighted sum grid. Prepare the
            % common values here
            subs    = single([N_idx' E_idx']); % indices in the temp grid of each data point
            sz      = single([N_N N_E]);       % size of ouptut
            clear N_idx E_idx
            
            % sum of weights per grid cell, and sum of weighted levels per
            % grid cell
            gridTotalWeight_forBlock = accumarray(subs,blockW',sz,@sum,single(0));
            gridWeightedSum_forBlock = accumarray(subs,blockW'.*blockL',sz,@sum,single(0));
            
            clear blockL blockW
            
            % maximum horiz distance from nadir per grid cell
            gridMaxHorizDist_forBlock = accumarray(subs,blockD',sz,@max,single(NaN));
            clear blockD subs
            
            % Add the block's small grid of weights sum to the full one,
            % and the block's small grid of sum of weighted levels to the
            % full one
            gridTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + gridTotalWeight_forBlock;
            gridWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = ...
                gridWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) + gridWeightedSum_forBlock;
            clear gridTotalWeight_forBlock gridWeightedSum_forBlock
            
            % Add the block's small grid of maximum horiz dist to the full
            % one: just keep in the grid whatever the maximum is per cell
            gridMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1) = nanmax( ...
                gridMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1), gridMaxHorizDist_forBlock);
            clear gridMaxHorizDist_forBlock
            
        case '3D'
            
            % prepare indices as we did before in E,N, this time in height
            H_idx = round((blockH-minGridH)/grid_vert_res+1);
            clear blockH
            idx_H_start = min(H_idx);
            H_idx = H_idx - min(H_idx) + 1;
            N_H = max(H_idx);
            
            % we use the accumarray function to sum all values in both the
            % total weight grid, and the weighted sum grid. Prepare the
            % common values here
            subs    = single([N_idx' E_idx' H_idx']); % indices in the temp grid of each data point
            sz      = single([N_N N_E N_H]);          % size of ouptut
            clear N_idx E_idx H_idx
            
            % sum of weights per grid cell, and sum of weighted levels per grid cell
            gridTotalWeight_forBlock = accumarray(subs,blockW',sz,@sum,single(0));
            gridWeightedSum_forBlock = accumarray(subs,blockW'.*blockL',sz,@sum,single(0));
            clear blockL blockW
            
            % maximum horiz distance from nadir per grid cell
            gridMaxHorizDist_forBlock = accumarray(subs,blockD',sz,@max,single(NaN));
            clear blockD subs
            
            % Add the block's small grid of weights sum to the full one,
            % and the block's small grid of sum of weighted levels to the
            % full one
            gridTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridTotalWeight(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) + gridTotalWeight_forBlock;
            
            gridWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = ...
                gridWeightedSum(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) + gridWeightedSum_forBlock;
            clear gridTotalWeight_forBlock gridWeightedSum_forBlock
            
            % Add the block's small grid of maximum horiz dist to the full
            % one: just keep in the grid whatever the maximum is per cell
            gridMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1) = nanmax( ...
                gridMaxHorizDist(idx_N_start:idx_N_start+N_N-1,idx_E_start:idx_E_start+N_E-1,idx_H_start:idx_H_start+N_H-1), gridMaxHorizDist_forBlock);
            clear gridMaxHorizDist_forBlock
            
    end
    
end


%% crop the edges of the grids
% they were built based on the size of the full dataset and so may be much
% bigger than actual data contained
switch grid_type
    
    case '2D'
        
        % dimensional sums
        sumgridTotalWeight_N = sum(gridTotalWeight,2);
        sumgridTotalWeight_E = sum(gridTotalWeight,1);
        
        % min and max indices for cropping
        minNidx = find(sumgridTotalWeight_N,1,'first');
        maxNidx = find(sumgridTotalWeight_N,1,'last');
        minEidx = find(sumgridTotalWeight_E,1,'first');
        maxEidx = find(sumgridTotalWeight_E,1,'last');
        
        % crop the grids
        gridTotalWeight  = gridTotalWeight(minNidx:maxNidx,minEidx:maxEidx);
        gridWeightedSum  = gridWeightedSum(minNidx:maxNidx,minEidx:maxEidx);
        gridMaxHorizDist = gridMaxHorizDist(minNidx:maxNidx,minEidx:maxEidx);
        
        % define and crop dim vectors
        gridNorthing = (0:numElemGridN-1)'.*grid_horz_res + minGridN;
        gridEasting  = (0:numElemGridE-1) .*grid_horz_res + minGridE;
        gridNorthing = gridNorthing(minNidx:maxNidx);
        gridEasting  = gridEasting(:,minEidx:maxEidx);
        
    case '3D'
        
        % dimensional sums
        sumgridTotalWeight_1EH = sum(gridTotalWeight,1);
        sumgridTotalWeight_N1H = sum(gridTotalWeight,2);
        sumgridTotalWeight_N = sum(sumgridTotalWeight_N1H,3);
        sumgridTotalWeight_E = sum(sumgridTotalWeight_1EH,3);
        sumgridTotalWeight_H = sum(sumgridTotalWeight_1EH,2);
        
        % min and max indices for cropping
        minNidx = find(sumgridTotalWeight_N,1,'first');
        maxNidx = find(sumgridTotalWeight_N,1,'last');
        minEidx = find(sumgridTotalWeight_E,1,'first');
        maxEidx = find(sumgridTotalWeight_E,1,'last');
        minHidx = find(sumgridTotalWeight_H,1,'first');
        maxHidx = find(sumgridTotalWeight_H,1,'last');
        
        % crop the grids
        gridTotalWeight  = gridTotalWeight(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        gridWeightedSum  = gridWeightedSum(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        gridMaxHorizDist = gridMaxHorizDist(minNidx:maxNidx,minEidx:maxEidx,minHidx:maxHidx);
        
        % define and crop dim vectors
        gridNorthing = (0:numElemGridN-1)'.*grid_horz_res + minGridN;
        gridEasting  = (0:numElemGridE-1) .*grid_horz_res + minGridE;
        gridHeight   = permute((0:numElemGridH-1).*grid_vert_res + minGridH,[3,1,2]);
        gridNorthing = gridNorthing(minNidx:maxNidx);
        gridEasting  = gridEasting(:,minEidx:maxEidx);
        gridHeight   = gridHeight(:,:,minHidx:maxHidx);
        
end

%% final calculation: average and back in dB
gridLevel = 10.*log10(gridWeightedSum./gridTotalWeight);
clear gridWeightedSum


%% if gridded data were gpuArrays, convert back to regular before storing
% so that data can be used even without the parallel computing toolbox and
% so that loading data don't overload the limited GPU memory. Gather has no
% effect if these were regular arrays
gridLevel        = gather(gridLevel);
gridTotalWeight  = gather(gridTotalWeight);
gridMaxHorizDist = gather(gridMaxHorizDist);


%% saving results:

% metadata
fData.X_1_gridHeightReference = grdlim_var;
fData.X_1_gridHorizontalResolution = grid_horz_res;

switch grid_type
    case '3D'
        fData.X_1_gridVerticalResolution = grid_vert_res;
end

% grid axes
fData.X_1E_gridEasting  = gridEasting;
fData.X_N1_gridNorthing = gridNorthing;

switch grid_type
    case '3D'
        fData.X_11H_gridHeight = gridHeight;
end

% actual grids
fData.X_NEH_gridLevel        = gridLevel;
fData.X_NEH_gridDensity      = gridTotalWeight;
fData.X_NEH_gridMaxHorizDist = gridMaxHorizDist;


