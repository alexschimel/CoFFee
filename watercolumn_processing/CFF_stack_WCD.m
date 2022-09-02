function [stack,stackY,params] = CFF_stack_WCD(fData,varargin)
%CFF_STACK_WCD  Stack WCD in range or depth
%
%   This function stacks water-column data in range of in depth. Note this
%   function requires the bottom samples in input data to have been
%   previously geoprocessed using CFF_GEOREFERENCE_BOTTOM_DETECT.
%
%   [STACK,STACKY] = CFF_STACK_WCD(FDATA) stacks all pings and beams of
%   water-column data from the FDATA field 'WC_SBP_SampleAmplitudes' (i.e.
%   original data) in range, over the range values going from 0 (sonar
%   face) to the deepest bottom detect in the data, by increments of the
%   inter-sample distance. The function returns the stacked data STACK as a
%   range-by-pings matrix, and the vector STACKY of ranges corresponding to
%   the rows of that matrix. 
%
%   CFF_STACK_WCD(FDATA,PARAMS) uses processing parameters defined as the
%   fields in the PARAMS structure to modify the default behaviour. 
%   Possible parameters are: 
%   'dataField': name of the fData field to use as the (memmaped file) WCD
%   data to stack. Default is 'WC_SBP_SampleAmplitudes'.
%   'stackMode': string code for the mode of stacking. Possible values are
%   'range' (default) or 'depth'.
%   'angleDegLims': two-values vector of beam angles (in degrees) to which
%   the stacking is to be limited. Default is [-inf,inf] to conserve all
%   beams.
%   'minStackY': minimum range (or depth, depending on stackMode) value for
%   stacking. Must be zero (default, i.e. stacking starts at sonar face) or
%   positive. 
%   'maxStackY': maximum range (or depth, depending on stackMode) value for
%   stacking. Must be 0 (default) or positive. The value 0 (default) is a
%   special code to indicate stacking is to go as far as the deepest bottom
%   detect in the data. Use the value inf to stack as far as data go. 
%   'resDepthStackY': desired depth resolution when stacking in depth. Must
%   be 0 (default) or positive. The value 0 (default) is a special code to
%   indicate the default depth-stacking resolution of twice the
%   inter-sample distance. Note that this parameter only affects stacking
%   in depth. When stacking in range, it is not possible to modify the
%   range resolution (which is the inter-sample distance).
%   'iPingLims': two-values vector of the indices of pings in FDATA to
%   which the stacking is to be limited. Default is [1,inf] to conserve all
%   pings.
%   'iBeamLims': two-values vector of the indices of beams in FDATA to
%   which the stacking is to be limited. Default is [1,inf] to conserve all
%   beams. This parameter does not over-ride 'angleDegLims'. Both
%   parameters are taken into account to limit beam contributions to the
%   stack.
%   'iSampleLims': two-values vector of the indices of samples in FDATA to
%   which the stacking is to be limited. Default is [1,inf] to conserve all
%   samples. This parameter does not over-ride 'minStackY' and 'maxStackY'.
%   All three parameters are taken into account to limit sample
%   contributions to the stack.
%
%   CFF_STACK_WCD(...,'comms',COMMS) specifies if and how this function
%   communicates on its internal state (progress, info, errors). COMMS can
%   be either a CFF_COMMS object, or a text string to initiate a new
%   CFF_COMMS object. Options are 'disp', 'textprogressbar', 'waitbar',
%   'oneline', 'multilines'. By default, using an empty CFF_COMMS object
%   (i.e. no communication). See CFF_COMMS for more information.
%
%   [STACK,STACKY,PARAMS] = CFF_STACK_WCD(...) also outputs the parameters
%   used in processing.
%
%   See also CFF_GEOREFERENCE_BOTTOM_DETECT.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 02-09-2022


global DEBUG;


%% Input arguments management
p = inputParser;
addRequired(p,'fData',@(x) CFF_is_fData_version_current(x)); % source fData
addOptional(p,'params',struct(),@(x) isstruct(x)); % processing parameters
addParameter(p,'comms',CFF_Comms()); % information communication (none by default)
parse(p,fData,varargin{:});
params = p.Results.params;
comms = p.Results.comms;
clear p
if ischar(comms)
    comms = CFF_Comms(comms);
end


%% Prep

% start message
comms.start('Stacking water-column data');


%% Data type to work with

% get dataField parameter
if ~isfield(params,'dataField'), params.dataField = 'WC_SBP_SampleAmplitudes'; end % default
CFF_mustBeField(fData,params.dataField); % validate
dataField = params.dataField;

% we will also need the datagramSource when grabbing ancillary data
datagramSource = CFF_get_datagramSource(fData);


%% Indices of pings to extract from memmapped files

% total number of pings in file
nTotPings = numel(fData.X_1P_pingCounter);

% get iPingsLims parameter
if ~isfield(params,'iPingLims'), params.iPingLims = [1 inf]; end % default
CFF_mustBeTwoPositiveIncreasingIntegers(params.iPingLims); % validate
iPingLims = params.iPingLims;

% limit inf to actual max number of pings in file
if isinf(iPingLims(2))
    iPingLims(2) = nTotPings;
end

% error if iPingLims(1) is outside range of existing pings
if iPingLims(1)>nTotPings
    error('iPingLims(1) is outside range of existing pings.');
end

% if iPingLims(1) exceed total number of pings, restrict to total number
if iPingLims(2)>nTotPings
    iPingLims(2) = nTotPings;
end

% build vector of indices of pings to extract
iPings = iPingLims(1):iPingLims(2);

% number of pings to extract
nPings = numel(iPings);


%% Indices of beams to extract from memmapped files

% at first, we ignore the iBeamLims input

% get angleDegLims parameter
if ~isfield(params,'angleDegLims'), params.angleDegLims = [-inf inf]; end % default
CFF_mustBeTwoIncreasingNumerics(params.angleDegLims); % validate
angleDegLims = params.angleDegLims;

% create the logical BP matrix of beams to keep, based on their angles
subBeamKeep = fData.X_BP_beamPointingAngleRad(:,iPings)>= deg2rad(angleDegLims(1)) & ...
    fData.X_BP_beamPointingAngleRad(:,iPings) <= deg2rad(angleDegLims(2));

% then we possibly further restrict the beams based on the input iBeamLims

% get iBeamLims parameter
if ~isfield(params,'iBeamLims'), params.iBeamLims = [1 inf]; end % default
CFF_mustBeTwoPositiveIncreasingIntegers(params.iBeamLims); % validate
iBeamLims = params.iBeamLims;

% limit inf to actual max number of beams in file
if isinf(iBeamLims(2))
    iBeamLims(2) = size(subBeamKeep,1);
end

% XXX perhaps add an error/return if iBeamLims is outside the range of
% existing beams

% then we restrict the BP matrix of beams to keep, based on the iBeamLims
subBeamKeep(1:(iBeamLims(1)-1),:) = false;
subBeamKeep((iBeamLims(2)+1):end,:) = false;

% calcultate the indices of beams to extract from the memmaped files
[indBeamKeep,~] = find(subBeamKeep);

% build vector of indices of beams (per ping) to extract
iBeams = nanmin(indBeamKeep):nanmax(indBeamKeep);

% number of beams (per ping) to extract
nBeams = numel(iBeams); 


%% Indices of samples to extract from memmapped files

% at first we ignore the iSampleLims input

% whether we stack in range or depth, the first sample to extract is the
% sample corresponding to minStackY

% get intersample distance to turn ranges into sample numbers
interSamplesDistance = CFF_inter_sample_distance(fData,iPings);

% XXX all this code works on the assumption that interSamplesDistance is
% constant (and it should be) and then we just use
% interSamplesDistance(1). But perhaps add an error/warning if
% interSamplesDistance is not constant.

% get minStackY parameter
if ~isfield(params,'minStackY'), params.minStackY = 0; end % default
mustBeNonnegative(params.minStackY); % validate
minStackY = params.minStackY;

% first sample to extract
firstSample = max(1,floor(minStackY./interSamplesDistance(1)));

% for the last sample to extract, it depends on maxStackY and also on the
% type of stacking  

% get maxStackY parameter
if ~isfield(params,'maxStackY'), params.maxStackY = 0; end % default
mustBeNonnegative(params.maxStackY); % validate
maxStackY = params.maxStackY;
% NOTE: maxStackY=0 (default) is used as special code to indicate we want
% our stack to only go to the bottom, so we extract all samples that
% contribute data down to the deepest bottom, but no more than that.

% get stackMode parameter
if ~isfield(params,'stackMode'), params.stackMode = 'range'; end % default
mustBeMember(params.stackMode,{'range','depth'}); % validate
stackMode = params.stackMode;

switch stackMode
    case 'range'
        % stacking in range is simple. We simply extract all samples down
        % to the stack's desired max range
        if maxStackY == 0
            % the stack's desired max range is the furthest bottom detect
            % sample (within the extracted pings and beams)
            bottomSamples = CFF_get_bottom_sample(fData);
            lastSample = max(bottomSamples(iBeams,iPings),[],'all','omitnan');
        elseif isinf(maxStackY)
            % simply use the max number of samples in the entire file so we
            % will extract them all
            lastSample = max(cellfun(@(x) x.Format{2}(1),fData.(dataField)));
        else
            % otherwise, we calculate the sample corresponding to maxStackY
            lastSample = ceil(maxStackY./interSamplesDistance(1));
        end
    case 'depth'
        % stacking in depth is a bit more complicated. The last sample to
        % extract is the one for the beam with the widest angle to
        % contribute data to the stack's desired max depth
        angleRad = fData.X_BP_beamPointingAngleRad(iBeams,iPings);
        widestAngleRad = nanmax(abs(angleRad(:)));
        if maxStackY == 0
            % the stack's desired max depth is the deepest bottom depth
            % (within the extracted pings and beams)
            maxStackY = max(abs(fData.X_BP_bottomUpDist(iBeams,iPings)),[],'all','omitnan');
            % corresponding furthest range
            furthestRange = maxStackY./cos(widestAngleRad);
            % corresponding sample
            lastSample = ceil(furthestRange./interSamplesDistance(1));
        elseif isinf(maxStackY)
            % simply use the max number of samples in the entire file so we
            % will extract them all
            lastSample = max(cellfun(@(x) x.Format{2}(1),fData.(dataField)));
            % we need the equivalent maxStackY to build stackY later, so
            % finding here the furthest range and maxStackY corresponding
            % to that last sample
            furthestRange = lastSample.*interSamplesDistance(1);
            maxStackY = furthestRange.*cos(widestAngleRad);
        else
            % otherwise, calculate the sample corresponding to the furthest
            % range for maxStackY. First, that range
            furthestRange = maxStackY./cos(widestAngleRad);
            % then the corresponding sample
            lastSample = ceil(furthestRange./interSamplesDistance(1));
        end
        
end

% then we restrict the first and last samples to extract based on input
% iSampleLims

% get iSampleLims parameter
if ~isfield(params,'iSampleLims'), params.iSampleLims = [1 inf]; end % default
CFF_mustBeTwoPositiveIncreasingIntegers(params.iSampleLims); % validate
iSampleLims = params.iSampleLims;

% indices of samples to extract
iSamples = max(iSampleLims(1),firstSample):min(iSampleLims(2),lastSample);

% number of samples to extract
nSamples = numel(iSamples);


%% Initialize the stack, which is a Range (or Depth) by Pings array
% Note that there is an input resolution parameter in depth-stacking, but
% not range-stacking. That's because depth-stacking includes re-gridding so
% resolution has to be specified anyway, so we can make it parametrable.
% However, range-stacking can be done fast by simply averaging across
% beams (aka keeping the native resolution) instead of re-gridding the
% data. So the range-stacking resolution is the interSamplesDistance.
switch stackMode
    case 'range'
        % for stacking in range, we stack all samples that will be
        % extracted, that is, iSamples. However, we want the stack to be
        % defined based on input minStackY and maxStackY, in other words
        % firstSample and lastSample.
        stackY = (firstSample:1:lastSample).*interSamplesDistance(1);

    case 'depth'
        % for stacking in depth, since data are re-gridded, we have to
        % specify the resolution
        
        % get resDepthStackY parameter
        if ~isfield(params,'resDepthStackY'), params.resDepthStackY = 0; end % default
        mustBeNonnegative(params.resDepthStackY); % validate
        resDepthStackY = params.resDepthStackY;
        % NOTE: resDepthStackY==0 (default) is used as special code to
        % indicate we want to use a default resolution.
        
        if resDepthStackY == 0
            % by default, we use a resolution equal to twice the
            % intersample distance
            fact = 2;
            resDepthStackY = fact*interSamplesDistance(1);
        end
        
        % build stack Y vector
        stackY = minStackY:resDepthStackY:maxStackY;
end
% initialize stack
stack = nan(numel(stackY),nPings,'single');


%% Processing setup

% setup GPU
if CFF_is_parallel_computing_available()
    useGpu = 1;
    processingUnit = 'GPU';
else
    useGpu = 0;
    processingUnit = 'CPU';
end

% number of big block variables in the calculations for each mode
switch stackMode
    case 'range'
        maxNumBlockVar = 1;
    case 'depth'
        maxNumBlockVar = 4;
end

% setup block processing
[blocks,info] = CFF_setup_optimized_block_processing(...
    nPings,nSamples*nBeams*4,...
    processingUnit,...
    'desiredMaxMemFracToUse',0.1,...
    'maxNumBlockVar',maxNumBlockVar);
% disp(info);


%% Block processing
for iB = 1:size(blocks,1)
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    
    % get WC data
    blockWCD = CFF_get_WC_data(fData,dataField,'iPing',iPings(blockPings),'iBeam',iBeams,'iRange',iSamples);
    if isempty(blockWCD)
        continue;
    end
    
    % set to NaN the beams that are not part of the stack
    blockWCD(:,~subBeamKeep(iBeams,blockPings)) = NaN;
    
    if useGpu
        blockWCD = gpuArray(blockWCD);
    end
    
    switch stackMode
        
        case 'range'
            
            % average across beams in natural values, then back to dB
            blockStack = 10*log10(squeeze(mean(10.^(blockWCD/10),2,'omitnan')));
            
            % save in stack array
            idxRows = iSamples-firstSample+1;
            stack(idxRows,blockPings) = blockStack;
            
        case 'depth'
            
            % convert a couple variables here to gpuArrays so all
            % computations downstream use the GPU and all variables become
            % gpuArrays
            if useGpu
                iSamples = gpuArray(iSamples);
                blockPings = gpuArray(blockPings);
            end
            
            % distance upwards from sonar for each sample
            blockStartSampleNumber = single(fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(iBeams,iPings(blockPings)));
            blockSampleRange = CFF_get_samples_range(single(iSamples'),blockStartSampleNumber,single(interSamplesDistance(blockPings)));
            blockAngle = single(angleRad(:,blockPings));
            [~,blockSampleUpDist] = CFF_get_samples_dist(blockSampleRange,blockAngle);
            clear blockSampleRange % clear up memory
            
            % index of each sample in the depth (row) vector
            blockIndRow = round((-blockSampleUpDist-stackY(1))/resDepthStackY+1);
            clear blockSampleUpDist % clear up memory
            
            % NaN those samples that fall outside of the desired stack
            blockIndRow(blockIndRow<1) = NaN;
            blockIndRow(blockIndRow>numel(stackY)) = NaN;
            
            % index of each sample in the ping (column) vector
            blockIndCol = single(blockPings - blockPings(1) + 1);
            blockIndCol = shiftdim(blockIndCol,-1); % 11P
            blockIndCol = repmat(blockIndCol,nSamples,nBeams); %SBP
            
            % vectorize and remove any sample where we have NaNs
            blockIndNaN = isnan(blockIndRow) | isnan(blockWCD);
            blockIndRow(blockIndNaN) = [];
            blockIndCol(blockIndNaN) = [];
            blockWCD(blockIndNaN) = [];
            clear blockIndNaN % clear up memory
            
            % average level in each stack grid cell, in natural values,
            % then turn result back to dB
            blockStackSumVal = accumarray( [blockIndRow(:),blockIndCol(:)],...
                10.^(blockWCD(:)/10),[],@sum,single(0));
            blockStackNumElem = accumarray( [blockIndRow(:),blockIndCol(:)],...
                single(1),[],@sum);
            blockStackAvg = 10*log10(blockStackSumVal./blockStackNumElem);
            clear blockIndRow blockIndCol % clear up memory
            
            % save in stack array
            stack(1:size(blockStackAvg,1),blockPings) = blockStackAvg;
            
    end
end

% display results
if DEBUG
    figure;
    imagesc(iPings,stackY,stack,'AlphaData',~isnan(stack));
    colormap jet
    colorbar
    grid on
    title(sprintf('WCD stack in %s',stackMode));
    xlabel('ping #')
    ylabel('m')
end


%% End message
comms.finish('Done');
