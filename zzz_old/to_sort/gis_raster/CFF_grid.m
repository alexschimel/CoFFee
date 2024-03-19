function [XX,YY,ZZ] = CFF_grid(x,y,z,res,w)
% [XX,YY,ZZ] = CFF_grid(x,y,z,res,w)
%
% DESCRIPTION
%
% Grid data points (x,y,z) with weights w, at resolution res.
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
%   Copyright 2013-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

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

% initialize the running count, the running weighted sum, and the running
% sum of weights: 
% N = zeros(length(YY),length(XX));
WS = zeros(length(YY),length(XX));
WW = zeros(length(YY),length(XX));

% weight gridding
for ii = 1:length(x(:))
    
    if ~isnan(x(ii))
        
        % get grid cell index to which this data point will contribute
        iR = round(((y(ii)-YY(1))./res)+1);
        iC = round(((x(ii)-XX(1))./res)+1);
        
        % calculate new values with added point
        % N(iR,iC) = N(iR,iC) + 1;
        WS(iR,iC) = WS(iR,iC) + w(ii).*z(ii);
        WW(iR,iC) = WW(iR,iC) + w(ii);
        
    end
end

% at the end, divide the weighted sum by the sum of weights to get the
% weighted average values
ZZ = WS./WW;


