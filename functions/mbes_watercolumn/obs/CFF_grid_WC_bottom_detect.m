%% CFF_grid_WC_bottom_detect.m
%
% Grids the bottom detect data in water column data.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-03: new header (ALex Schimel).
% * 2017-10-03: Replaced the old grid function CFF_weightgrid by the new
% one CFF_weightgrid_2D BUT NOT TESTED YET (Alex Schimel).
% * 2017-07-11: First version. Taken from CFF_grid_watercolumn (Alex
% Schimel).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.


%% Function
function fData = CFF_grid_WC_bottom_detect(fData,res)


%% get bottom coordinates
botE = reshape(fData.X_PB_bottomEasting,1,[]);
botN = reshape(fData.X_PB_bottomNorthing,1,[]);
botH = reshape(fData.X_PB_bottomHeight,1,[]);

%% build the easting, northing and height grids

% Use the min easting, northing and height (floored) in all non-NaN
% samples as the first value for grids.
minE = fData.X_1E_gridEasting(1);
minN = fData.X_N1_gridNorthing(1);

% define number of elements needed to cover max easting, northing and
% height
numE = length(fData.X_1E_gridEasting);
numN = length(fData.X_N1_gridNorthing);


%% now grid watercolumn data

% USING THE NEW FUNCTION BUT NOT TESTED YET. 
[gridBottom,gridBottomDensity] = CFF_weightgrid_2D(botE,botN,botH,[],[minE,res,numE],[minN,res,numN]);

% ANY ISSUE, TRY THE OLD FUNCTION BELOW:
% [gridBottom,gridBottomDensity] = CFF_weightgrid(botE,botN,botH,[minE,res,numE],[minN,res,numN],1);


%% saving results
fData.X_NE_gridBottom = gridBottom;
fData.X_NE_gridBottomDensity = gridBottomDensity;


