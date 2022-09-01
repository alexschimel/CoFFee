function [stack,stackY,params] = CFF_stack_WCD(fData,varargin)
%FUNCTION_NAME  One-line description of what the function performs
%
%   Optional multiple lines of information giving more details about the
%   function. The first line above (so-called H1 line) has no space before
%   the function name and two spaces after. FUNCTION_NAME is written in
%   upper-case throughout this docstring. One or multiple examples syntaxes
%   follow. The docstring is completed by a "See also" section that allows
%   help functions such as "help" or "doc" to automatically create
%   hyperlinks. Separated from the docstring by a single empty line are the
%   author(s) and information on last versions.
%
%   [X,Y] = FUNCTION_NAME(A,B,C) returns the sum of A+B as X, and C as Y.
%   Note the input and output variables are also written in upper case.
%   This first syntax should show the basic use.
%
%   X = FUNCTION_NAME(A,B) returns the sum of A+B as X, since the
%   additional input and outputs in this example are unecessary. This other
%   syntax shows alterative functioning.
%
%   FUNCTION_NAME(...,'parameter',VAL) is another syntax to introduce
%   optional or paramter inputs. Since the basic inputs and outputs have
%   already been discussed, they can be ommitted, so the text focuses
%   exclusively on what the option does compared to the basic syntax.
%
%   See also OTHER_FUNCTION_NAME_1, OTHER_FUNCTION_NAME_2, ESPRESSO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   XXXX-XXXX; Last revision: XX-XX-XXXX

global DEBUG;


%% input arguments management
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


% % params wanted, with default values
% % basics
% dataType = original % original or processed (or phase)
% stackMode = range % range or depth
% 
% % min and max indices for WCD to extract
% iPingLims = [1 inf]
% iBeamLims = [1 inf]
% iSampleLims = [1 inf]
% 
% % aditional control
% angleDegLims = [-inf inf]; % keep beams in terms of their angles in degrees
% minStackY = 0 % min value for depth/range
% maxStackY = 0 % max value for depth/range. 0 means limit data to bottom
% resStackY = 0 % depth/range resolution for stack. = means default, ie. = ISD for range, and = 2x ISD for depth.



%% prep

% start message
comms.start('Stacking water-column data');


%% data type to work with

% get dataField parameter
if ~isfield(params,'dataField'), params.dataField = 'WC_SBP_SampleAmplitudes'; end % default
CFF_mustBeField(fData,params.dataField); % validate
dataField = params.dataField;

% we will also need the datagramSource when grabbing ancillary data
datagramSource = CFF_get_datagramSource(fData);


%% indices of pings to extract from memmapped files

% get iPingsLims parameter
if ~isfield(params,'iPingLims'), params.iPingLims = [1 inf]; end % default
CFF_mustBeTwoPositiveIncreasingIntegers(params.iPingLims); % validate
iPingLims = params.iPingLims;

% limit inf to actual max number of pings in file
if isinf(iPingLims(2))
    iPingLims(2) = numel(fData.X_1P_pingCounter);
end

% XXX perhaps add an error/return if iPingLims is outside existing pings

% build vector of indices of pings to extract
iPings = iPingLims(1):iPingLims(2); 

% number of pings to extract
nPings = numel(iPings);


%% indices of beams to extract from memmapped files

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

% XXX perhaps add an error/return if iBeamLims is outside existing beams

% then we restrict the BP matrix based on the iBeamLims
subBeamKeep(1:(iBeamLims(1)-1),:) = false;
subBeamKeep((iBeamLims(2)+1):end,:) = false;

% calcultate the indices of beams to extract from the memmaped files
[indBeamKeep,~] = find(subBeamKeep);

% build vector of indices of beams (per ping) to extract
iBeams = nanmin(indBeamKeep):nanmax(indBeamKeep);

% number of beams (per ping) to extract
nBeams = numel(iBeams); 


%% indices of samples to extract from memmapped files

% at first we ignore the iSampleLims input

% whether we stack in range or depth, the first sample to extract is the
% sample corresponding to minStackY

% get intersample distance to turn ranges into sample numbers
interSamplesDistance = CFF_inter_sample_distance(fData,iPings);

% XXX perhaps add an error/warning if interSamplesDistance is not constant

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
% NOTE: maxStackY==0 (default) is used as special code to indicate we want
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
            % corresponding furthest range
            furthestRange = maxStackY./cos(widestAngleRad);
            % corresponding sample
            lastSample = ceil(furthestRange./interSamplesDistance(1));
        end
        
end

% then we restrict the first and last samples based on input iSampleLims 

% get iSampleLims parameter
if ~isfield(params,'iSampleLims'), params.iSampleLims = [1 inf]; end % default
CFF_mustBeTwoPositiveIncreasingIntegers(params.iSampleLims); % validate
iSampleLims = params.iSampleLims;

% indices of samples to extract
iSamples = max(iSampleLims(1),firstSample):min(iSampleLims(2),lastSample);

% number of samples to extract
nSamples = numel(iSamples);


%% initialize the stack, which is a Range (or Depth) by Pings array
switch stackMode
    case 'range'
        % for stacking in range, we stack all samples that will be
        % extracted. The rows are thus defined by iSamples, or in m: 
        stackY = iSamples.*interSamplesDistance(1);
        % note that any input resStackY parameter is ignored here. It's
        % because we want to keep stacking in range efficient and so we
        % don't re-grid the data

    case 'depth'
        % for stacking in depth, since we will grid the data anyway, we can
        % specify the desired resolution
        
        % get resStackY parameter
        if ~isfield(params,'resStackY'), params.resStackY = 0; end % default
        mustBeNonnegative(params.resStackY); % validate
        resStackY = params.resStackY;
        % NOTE: resStackY==0 (default) is used as special code to indicate
        % we want to use a default stack Y resolution.
        
        if resStackY == 0
            % by default, we use a resolution equal to twice the
            % intersample distance
            fact = 2;
            resStackY = fact*interSamplesDistance(1);
        end
        
        % build stack Y vector
        stackY = minStackY:resStackY:maxStackY;
end
% initialize stack
stack = nan(numel(stackY),nPings,'single');


%% processing setup

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


%% block processing
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
            
            % add to final array
            stack(:,blockPings) = blockStack;
            
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
            blockIndRow = round((-blockSampleUpDist-stackY(1))/resStackY+1);
            clear blockSampleUpDist % clear up memory
            
            % NaN those samples that fall outside of the desired stack
            blockIndRow(blockIndRow<1) = NaN;
            blockIndRow(blockIndRow>numel(stackY)) = NaN;
            
            % index of each sample in the ping (column) vector
            blockIndCol = single(blockPings - blockPings(1) + 1);
            blockIndCol = shiftdim(blockIndCol,-1); % 11P
            blockIndCol = repmat(blockIndCol,nSamples,nBeams); %SBP
            
            % next: vectorize and remove any sample where we have NaNs
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
            
            % save in stacked array
            stack(1:size(blockStackAvg,1),blockPings) = blockStackAvg;
            
    end
end

% debug display
DEBUG = 1;
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

%% end message
comms.finish('Done');
