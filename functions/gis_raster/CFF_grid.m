function [XX,YY,ZZ] = CFF_grid(x,y,z,res,w)
% [XX,YY,ZZ] = CFF_grid(x,y,z,res,w)
%
% DESCRIPTION
%
% Grid data points (x,y,z) with weights w, at resolution res.
%
% USE
%
% ...
%
% PROCESSING SUMMARY
% 
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - x,y,z: data vectors to be gridded
% - res: grid resolution (in m)
% - w (optional): weight vector for each data point. If not in input, 1 is
% used for each data point (arithmetic mean computation)
%
% OUTPUT VARIABLES
%
% - XX,YY,ZZ: gridded data
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% 2014-10-13: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

if nargin<5
    w = ones(size(x));
end

% find grid boundaries
minY = min(y(:));
maxY = max(y(:));
minX = min(x(:));
maxX = max(x(:));

% set grid vectors
XX = [floor(minX):res:ceil(maxX)];
YY = [floor(minY):res:ceil(maxY)]';

% initialize ZZ and WW arrays
ZZ  = -999.*ones(length(YY),length(XX)); % remove NaNs to allow averaging
WW = zeros(length(YY),length(XX));

% weight gridding
for ii = 1:length(x(:))
    
    if ~isnan(x(ii))
        
        % get grid cell index
        iR = round(((y(ii)-YY(1))./res)+1);
        iC = round(((x(ii)-XX(1))./res)+1);
        
        % add new point to grid, updating based on weight
        ZZ(iR,iC)  = ((ZZ(iR,iC).*WW(iR,iC))+z(ii).*w(ii))./(WW(iR,iC)+w(ii));
        WW(iR,iC) = WW(iR,iC)+w(ii);
        
    end
end

% put NaNs back in ZZ
ZZ(ZZ==-999) = NaN;
