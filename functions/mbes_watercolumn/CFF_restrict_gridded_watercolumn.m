function [fData,T] = CFF_restrict_gridded_watercolumn(fData, patch_poly)
% [fData,T] = CFF_restrict_gridded_watercolumn(fData, patch_poly)
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

% grab data
gridEasting = fData.X_1E_gridEasting;
gridNorthing = fData.X_N1_gridNorthing;
gridHeight = fData.X_H_gridHeight;
gridLevel = fData.X_NEH_gridLevel;
gridDensity = fData.X_NEH_gridDensity;

% bounds
minE = min(patch_poly(:,1));
maxE = max(patch_poly(:,1));
minN = min(patch_poly(:,2));
maxN = max(patch_poly(:,2));

indE = gridEasting(1,:)>=minE & gridEasting(1,:)<=maxE;
indN = gridNorthing(:,1)>=minN & gridNorthing(:,1)<=maxN;

% measure median bottom in that area
ind = fData.X_PB_bottomEasting>=minE & fData.X_PB_bottomEasting<=maxE & fData.X_PB_bottomNorthing>=minN & fData.X_PB_bottomNorthing<=maxN;
HH = fData.X_PB_bottomHeight(ind);
%hist(HH(:),500)
patch_height = median(HH(:));
indH = gridHeight>patch_height;

% cut easting and northing beyond the patch area and cut to above
% the bottom
gridEasting  = gridEasting(indE);
gridHeight = gridHeight(indH);
gridNorthing = gridNorthing(indN);
gridLevel = gridLevel(indN,indE,indH);
gridDensity  = gridDensity(indN,indE,indH);

% NaN everything that is not in the target area
[xq,yq] = meshgrid(gridEasting(1,:),gridNorthing(:,1));
in = inpolygon(xq,yq,patch_poly(:,1),patch_poly(:,2));
T = sum(in(:)).*length(gridHeight); % total number of cells in patch
for kk = 1:length(gridHeight)
    temp = gridLevel(:,:,kk);
    temp(~in) = NaN;
    gridLevel(:,:,kk) = temp;
end

%% saving results
fData.X_1E_gridEasting = gridEasting;
fData.X_N1_gridNorthing = gridNorthing;
fData.X_H_gridHeight = gridHeight;
fData.X_NEH_gridLevel = gridLevel;
fData.X_NEH_gridDensity = gridDensity;

