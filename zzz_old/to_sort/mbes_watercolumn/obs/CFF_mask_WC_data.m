function [fData] = CFF_mask_WC_data(fData,varargin)
% [fData] = CFF_mask_WC_data(fData,varargin)
%
% DESCRIPTION
%
% Create a mask (PBS format) to remove parts of the data
%
% INPUT VARIABLES
%
% - varargin{1} "remove_angle": steering angle beyond which outer beams are
% removed (in deg ref nadir)
%   - eg: 55 -> angles>55 and <-55 are removed
%   - inf (default) -> all angles are conserved
%
% - varargin{2} "remove_closerange": range from sonar (in m) within which
% samples are removed
%   - eg: 4 -> all samples within 4m range from sonar are removed
%   - 0 (default) -> all samples are conserved
%
% -varargin{3} "remove_bottomrange": range from bottom (in m) beyond which
% samples are removed. Range after bottom if positive, before bottom if
% negative
%   - eg: 2 -> all samples 2m after bottom detect and beyond are removed
%   - eg: -3 -> all samples 3m BEFORE bottom detect and beyond are removed
%   (therefore including bottom detect)
%   - inf (default) -> all samples are conserved.
%
% - varargin{4} "mypolygon": horizontal polygon (in Easting, Northing
% coordinates) outside of which samples are removed. 
%   - [] (default) -> all samples are conserved.
%
% OUTPUT VARIABLES
%
% - fData
%
% RESEARCH NOTES
%
% NEW FEATURES
%
% - 2016-12-01: Updating bottom range removal after change of bottom
% processing
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m
%
%   Copyright 2014-2016 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% Extract needed data
nPings   = size(fData.WC_PBS_SampleAmplitudes,1);
nBeams   = size(fData.WC_PBS_SampleAmplitudes,2);
nSamples = size(fData.WC_PBS_SampleAmplitudes,3);


%% Set methods
remove_angle       = inf; % default
remove_closerange  = 0; % default
remove_bottomrange = inf; % default
mypolygon          = []; % default
if nargin==1
    % fData only. keep defaults
elseif nargin==2
    remove_angle = varargin{1};
elseif nargin==3
    remove_angle = varargin{1};
    remove_closerange = varargin{2};
elseif nargin==4
    remove_angle = varargin{1};
    remove_closerange = varargin{2};
    remove_bottomrange =varargin{3};
elseif nargin==5
    remove_angle = varargin{1};
    remove_closerange = varargin{2};
    remove_bottomrange =varargin{3};
    mypolygon = varargin{4};
else
    error('wrong number of input variables')
end


%% INITIALIZE MASK
Final_PBS_Mask = ones(nPings,nBeams,nSamples);


%% OUTER BEAMS REMOVAL

if ~isinf(remove_angle)
    
    % extract needed data
    angles = fData.WC_PB_BeamPointingAngle;
    
    % build mask: 1: to conserve, 0: to remove
    PB_Mask = double( angles >= -abs(remove_angle)*100  ...
                    & angles <=  abs(remove_angle)*100      );
    PBS_Mask = repmat(PB_Mask,[1 1 nSamples]);
    PBS_Mask(PBS_Mask==0) = NaN; % turn 0s to nan
    
    % apply mask
    Final_PBS_Mask = Final_PBS_Mask .* PBS_Mask;
    
end



%% CLOSE RANGE REMOVAL

if remove_closerange>0
    
    % extract needed data
    ranges = fData.X_PBS_sampleRange;
    
    % build mask: 1: to conserve, 0: to remove
    PBS_Mask = double(ranges >= remove_closerange);
    PBS_Mask(PBS_Mask==0) = NaN; % turn 0s to nan
    
    % apply mask
    Final_PBS_Mask = Final_PBS_Mask .* PBS_Mask;
    
end



%% BOTTOM RANGE REMOVAL

if ~isinf(remove_bottomrange)
    
    % extract needed data
    P_oneSampleDistance = fData.X_P_oneSampleDistance;
    PB_bottomRange = fData.X_PB_bottomRange;
    
    % calculate max sample beyond which mask is to be applied
    PB_maxRange = PB_bottomRange + remove_bottomrange;
    PB_oneSampleDistance = repmat(P_oneSampleDistance ,[1 nBeams]);
    PB_maxSample = round(PB_maxRange ./ PB_oneSampleDistance);
    PB_maxSample(PB_maxSample>nSamples)=nSamples;
    
    % build list of indices for each beam & ping
    [X,Y] = meshgrid([1:nBeams],[1:nPings]');
    maxSubs = [Y(:),X(:),PB_maxSample(:)];
    
    % build mask: 1: to conserve, 0: to remove
    PBS_Mask = zeros(nPings,nBeams,nSamples);
    for ii = 1:size(maxSubs,1)
        PBS_Mask(maxSubs(ii,1),maxSubs(ii,2),1:maxSubs(ii,3)) = 1;
    end
    PBS_Mask(PBS_Mask==0) = NaN; % turn 0s to nan
    
    % apply mask
    Final_PBS_Mask = Final_PBS_Mask .* PBS_Mask;
    
end


%% OUTSIDE POLYGON REMOVAL

if ~isempty(mypolygon)
    
    % extract needed data
    E = fData.X_PBS_sampleEasting;
    N = fData.X_PBS_sampleNorthing;
    
    % build mask: 1: to conserve, 0: to remove
    PBS_Mask = inpolygon(E,N,mypolygon(:,1),mypolygon(:,2));
    PBS_Mask = double(PBS_Mask);
    PBS_Mask(PBS_Mask==0) = NaN; % turn 0s to nan

    % apply mask
    Final_PBS_Mask = Final_PBS_Mask .* PBS_Mask;
    
end


%% SAVING RESULT IN FDATA
fData.X_PBS_Mask = Final_PBS_Mask;

