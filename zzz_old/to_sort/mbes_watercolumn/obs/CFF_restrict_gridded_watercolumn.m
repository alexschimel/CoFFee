function [fData,T] = CFF_restrict_gridded_watercolumn(fData, patch_poly)
% [fData,T] = CFF_restrict_gridded_watercolumn(fData, patch_poly)

%   Copyright 2014-2016 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

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

