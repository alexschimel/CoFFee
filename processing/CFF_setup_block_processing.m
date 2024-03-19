function blocks = CFF_setup_block_processing(nUnits,maxNumUnitsPerBlock)
%CFF_SETUP_BLOCK_PROCESSING  Setup block processing manually
%
%   Setup block processing manually
%
%   BLOCKS = CFF_SETUP_BLOCK_PROCESSING(NUNITS,MAXNUMUNITSPERBLOCK) returns
%   an Nx2 array BLOCKS where each row is the start and end indices for
%   a block of units to process at a time (typically, pings), using the
%   total number of units NUNITS, and a maximum number of units per block
%   MAXNUMUNITSPERBLOCK. If MAXNUMUNITSPERBLOCK is superior or equal to
%   NUNITS, then the function returns a single block. If
%   MAXNUMUNITSPERBLOCK is inferior, then the function returns several
%   blocks of the desired size, and a last, smaller one.
%
%   See also CFF_SETUP_OPTIMIZED_BLOCK_PROCESSING.

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% input arguments management
p = inputParser;
addRequired(p,'nUnits',@(x)isscalar(x)&gt(x,0)&(round(x)==x)); % total number of units
addRequired(p,'maxNumUnitsPerBlock',@(x)isscalar(x)&gt(x,0)&(round(x)==x)); % max number of units per block
parse(p,nUnits,maxNumUnitsPerBlock);
clear p

nBlocks = ceil(nUnits/maxNumUnitsPerBlock);
blocks = [ 1+(0:nBlocks-1)'.*maxNumUnitsPerBlock , (1:nBlocks)'.*maxNumUnitsPerBlock ];
blocks(end,2) = nUnits;

end