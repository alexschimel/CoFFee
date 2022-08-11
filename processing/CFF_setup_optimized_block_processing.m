function [blocks, info] = CFF_setup_optimized_block_processing(nUnits,unitSizeInBytes,varargin)
%CFF_SETUP_OPTIMIZED_BLOCK_PROCESSING  Setup block processing from memory
%
%   Setup block processing based on memory
%
%   BLOCKS = CFF_SETUP_OPTIMIZED_BLOCK_PROCESSING(NUNITS,UNITSIZEINBYTES)
%   returns an Nx2 array BLOCKS where each row is the start and end indices
%   for a block of units to process at a time (typically, pings), using the
%   total number of units NUNITS, and the size of one unit in bytes
%   UNITSIZEINBYTES (typically for SBP processing, equal to the product of
%   the number of samples, the number of beams, and the size of a sample in
%   bytes - 4 bytes for class 'single'). The blocks are defined based on
%   the memory available for CPU processing in order to avoid Out-Of-memory
%   error. 
%
%   CFF_SETUP_OPTIMIZED_BLOCK_PROCESSING(NUNITS,UNITSIZEINBYTES,PU)
%   where PU = 'GPU' does the same but based on the memory available for
%   GPU processing (parallel computing). By default, PU = 'CPU'.
%
%   CFF_SETUP_OPTIMIZED_BLOCK_PROCESSING(...,'minMemFracToKeepFree',VAL)
%   uses VAL as the desired fraction of total device memory to keep free to
%   safeguard against out-of-memory errors. By default, VAL = 0.15. If you
%   experience Out-Of-Memory errors, you can increase this fraction. Tests
%   have found 0.1-0.4 to be reasonable values.
%
%   CFF_SETUP_OPTIMIZED_BLOCK_PROCESSING(...,'desiredMaxMemFracToUse',VAL)
%   uses VAL as the desired fraction of available memory to use for
%   calculations. By default, VAL = 0.1. If you experience Out-Of-Memory
%   errors, you can decrease this fraction. Tests have found 0.01-0.4 to be
%   reasonable values.
%
%   CFF_SETUP_OPTIMIZED_BLOCK_PROCESSING(...,'maxNumBlockVar',VAL) uses VAL
%   as the maximum number of "big" block variables in memory at one time in
%   the upcoming processing, in order to estimate maximum memory usage.
%   Ideally, check your code to find the true number and inform it here in
%   order to get more accurate estimate. If you don't do it, this 
%   function uses a guess VAL = 5 by default. If the true number is lower,
%   you will miss on performance. If the true number is higher, you risk an
%   Out-Of-Memory error. If you are unsure, set a higher number (i.e. 10)
%   to get conservative estimates, at the cost of lower performance. Note:
%   write your code to limit that maximum number, by clearing "big" block
%   variables as soon as they are not necessary anymore.
%
%   [BLOCKS,INFO] = CFF_SETUP_OPTIMIZED_BLOCK_PROCESSING(...) returns the
%   additional INFO structure with metadata on the internal calculations.
%
%   See also CFF_MEMORY_AVAILABLE, CFF_IS_PARALLEL_COMPUTING_AVAILABLE,
%   CFF_SETUP_BLOCK_PROCESSING. 

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2022; Last revision: 05-08-2022


% input arguments management
p = inputParser;
addRequired(p,'nUnits',@(x)isnumeric(x)&isscalar(x)); % total number of units
addRequired(p,'unitSizeInBytes',@(x)isnumeric(x)&isscalar(x)); % size in bytes for one unit of data
addOptional(p,'processingUnit','CPU',@(x)ismember(upper(x),{'CPU','GPU'})); % device
addParameter(p,'minMemFracToKeepFree',0.15,@(x)isscalar(x)&ge(x,0)&lt(1)); % min fraction of device memory to keep free
addParameter(p,'desiredMaxMemFracToUse',0.1,@(x)isscalar(x)&gt(x,0)&le(x,1)); % desired max fraction of memory available to use
addParameter(p,'maxNumBlockVar',5,@(x)isscalar(x)&(x==round(x))&gt(x,0)); % max number of block variables in memory at a time
parse(p,nUnits,unitSizeInBytes,varargin{:});
processingUnit = p.Results.processingUnit;
minMemFracToKeepFree = p.Results.minMemFracToKeepFree;
desiredMaxMemFracToUse = p.Results.desiredMaxMemFracToUse;
maxNumBlockVar = p.Results.maxNumBlockVar;
clear p


%% Calculate desired maximum memory to use
% all sizes in MB for ease of reading/debugging

% total memory available on device
totDeviceMemInMB = CFF_memory_available(processingUnit)./(1024.^2);

% memory available accounting for safety buffer
memAvailInMB = totDeviceMemInMB.*(1-minMemFracToKeepFree);

% desired max amount of memory to use
desiredMaxMemToUseInMB = desiredMaxMemFracToUse.*memAvailInMB;


%% Check against one unit limit

% at minimum, we need to be able to process one unit at a time
memNeededForOneUnitInMB = (unitSizeInBytes./(1024.^2)).*maxNumBlockVar;

% if that amount of memory is higher than the desired max amount we want to
% use, we have no choice but up the max amount to use
maxMemToUseInMB = max(desiredMaxMemToUseInMB,memNeededForOneUnitInMB);

% so the actual fraction of memory to use is:
maxMemFracToUse = maxMemToUseInMB./memAvailInMB;


%% Calculate blocks

% maximum number of such units that can be processed at a time (block)
maxNumUnitsPerBlock = floor(maxMemToUseInMB./memNeededForOneUnitInMB);

% get blocks
blocks = CFF_setup_block_processing(nUnits,maxNumUnitsPerBlock);


%% Extra info

% number of blocks
nBlocks = size(blocks,1);

% number of units per block (except, possibly the last one, smaller)
nUnitsPerBlock = blocks(1,2);

% predicted memory used per block 
predMemUsedPerBlockInMB = nUnitsPerBlock.*memNeededForOneUnitInMB;

% actual memory on device to stay free
freeMemInMB = totDeviceMemInMB - predMemUsedPerBlockInMB;

% saving internal calculations as info for check/debugging
info.processingUnit = processingUnit;
info.totDeviceMemInMB = totDeviceMemInMB;
info.minMemFracToKeepFree = minMemFracToKeepFree;
info.memAvailInMB = memAvailInMB;
info.desiredMaxMemFracToUse = desiredMaxMemFracToUse;
info.desiredMaxMemToUseInMB = desiredMaxMemToUseInMB;
info.memNeededForOneUnitInMB = memNeededForOneUnitInMB;
info.maxMemToUseInMB = maxMemToUseInMB;
info.maxMemFracToUse = maxMemFracToUse;
info.nUnits = nUnits;
info.nBlocks = nBlocks;
info.nUnitsPerBlock = nUnitsPerBlock;
info.predMemUsedPerBlockInMB = predMemUsedPerBlockInMB;
info.freeMemInMB = freeMemInMB;

end