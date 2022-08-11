function fData = CFF_grid_watercolumn(fData,varargin)
% fData = CFF_grid_watercolumn(fData,varargin)
%
% DESCRIPTION
%
% This function grids water column data per slice
%
% INPUT VARIABLES
%
% varargin{1}: data to grid: 'original' or 'L1' or a field of fData of PBS
% size
% varargin{2}: grid resolution in m
%
% OUTPUT VARIABLES
%
% RESEARCH NOTES
%
% EXAMPLES
%
% [gridEasting,gridNorthing,gridHeight,gridLevel,gridDensity] = CFF_grid_watercolumn(fData,'original',0.1)
%
% NEW FEATURES
%
% - 2016-12-01: Also gridding bottom detect
% - 2014-04-30: First version
%
%%%
% Alex Schimel, Deakin University
%%%


%% get field to grid
switch varargin{1}
    case 'original'
        L = fData.WC_PBS_SampleAmplitudes./2;
    case 'L1'
        L = fData.X_PBS_L1;
    case 'masked L1'
        L = fData.X_PBS_L1 .* fData.X_PBS_Mask;
    otherwise
        if isfield(fData,varargin{1})
            Lfield = varargin{1};
            expression = ['L = fData.' Lfield ';'];
            eval(expression);
        else
            error('field not recognized')
        end
end


%% get samples coordinates and remove useless nans
E = reshape(fData.X_PBS_sampleEasting,1,[]);
N = reshape(fData.X_PBS_sampleNorthing,1,[]);
H = reshape(fData.X_PBS_sampleHeight,1,[]);
L = reshape(L,1,[]);

% remove useless nans
indLnan = isnan(L);
L(indLnan) = [];
E(indLnan) = [];
N(indLnan) = [];
H(indLnan) = [];


%% build the easting, northing and height grids

% get grid resolution
res = varargin{2};

% Use the min easting, northing and height (floored) in all non-NaN
% samples as the first value for grids.
minE = floor(min(E));
minN = floor(min(N));
minH = floor(min(H));

% Idem for the last value to cover:
maxE = ceil(max(E));
maxN = ceil(max(N));
maxH = ceil(max(H));

% define number of elements needed to cover max easting, northing and
% height
numE = ceil((maxE-minE)./res)+1;
numN = ceil((maxN-minN)./res)+1;
numH = ceil((maxH-minH)./res)+1;


%% grid Level in natural and bring back to dB
L = 10.^(L./10);
[gridLevel,gridDensity,gridEasting,gridNorthing,gridHeight] = CFF_weightgrid3(E,N,H,L,[minE,res,numE],[minN,res,numN],[minH,res,numH],1);
gridLevel = 10.*log10(gridLevel);

%% saving results
fData.X_1E_gridEasting = gridEasting;
fData.X_N1_gridNorthing = gridNorthing;
fData.X_H_gridHeight = gridHeight;
fData.X_NEH_gridLevel = gridLevel;
fData.X_NEH_gridDensity = gridDensity;

