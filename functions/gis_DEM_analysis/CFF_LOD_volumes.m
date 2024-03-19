function out = CFF_LOD_volumes(DOD,X,Y,LOD,UNC)
%CFF_LOD_VOLUMES  LOD volumes
%
%   Calculate volumes eroded and deposited from the difference between two
%   DEMS (DOD), using a threhsold or Limit Of Detection (LOD). Also use
%   uncertainty (UNC) to output intervals of confidence.
%
%   See also CFF_CALCULATE_DOD.

%   Copyright 2015-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% cell resolutions in X and Y and area
Xres = X(1,2)-X(1,1);
Yres = Y(1,1)-Y(2,1);
cellArea = Xres.*Yres;

%% erosion
DOD_ero_mask = DOD<-LOD;

% volume
volumeEroded  = CFF_nansum3(CFF_nansum3(DOD .* DOD_ero_mask .* cellArea));

% area
areaEroded  = sum(sum(double(DOD_ero_mask))).*cellArea;

% The volume uncertainty of each cell is given by the product of the cell
% area by the cell uncertainty.
eroVolUnc = UNC .* DOD_ero_mask .* cellArea;

% uncertainty in natural sum:
uncertaintyVolumeEroded_sum = CFF_nansum3(CFF_nansum3(eroVolUnc)); 

% propagated uncertainty:
uncertaintyVolumeEroded_propagated = sqrt(CFF_nansum3(CFF_nansum3(eroVolUnc.^2)));

%% deposition
DOD_dep_mask = DOD>LOD;

% volume
volumeDeposited  = CFF_nansum3(CFF_nansum3(DOD .* DOD_dep_mask .* cellArea));

% area
areaDeposited   = sum(sum(double(DOD_dep_mask))).*cellArea;

% The volume uncertainty of a cell is given by the product of the cell area
% by the cell DPU.
depVolUnc = UNC .* DOD_dep_mask .* cellArea;

% uncertainty in natural sum:
uncertaintyVolumeDeposited_sum = CFF_nansum3(CFF_nansum3(depVolUnc)); 

% propagated uncertainty:
uncertaintyVolumeDeposited_propagated = sqrt(CFF_nansum3(CFF_nansum3(depVolUnc.^2)));

%% budget

volumeNetChange = volumeDeposited + volumeEroded;

% total area experiencing change above threshold
areaTotalChange = areaEroded + areaDeposited;

% total area in DOD
areaTotal = sum(sum(double(~isnan(DOD)))).*cellArea;



%% output
out.volumeNetChange = volumeNetChange;
out.volumeEroded = volumeEroded;
out.volumeDeposited = volumeDeposited;
out.uncertaintyVolumeEroded_sum = uncertaintyVolumeEroded_sum;
out.uncertaintyVolumeDeposited_sum = uncertaintyVolumeDeposited_sum;
out.uncertaintyVolumeEroded_propagated = uncertaintyVolumeEroded_propagated;
out.uncertaintyVolumeDeposited_propagated = uncertaintyVolumeDeposited_propagated;
out.areaEroded = areaEroded;
out.areaDeposited = areaDeposited;
out.areaTotalChange = areaTotalChange;
out.areaTotal = areaTotal;
