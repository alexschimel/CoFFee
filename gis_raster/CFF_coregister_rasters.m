function [Z1out,Z2out,Xout,Yout] = CFF_coregister_rasters(Z1,X1,Y1,Z2,X2,Y2,varargin)
%CFF_COREGISTER_RASTERS  Coregister two rasters
%
%   This function is to register two grids (X1,Y1,Z1) and (X1,Y1,Z1) on the
%   same X,Y by extending the X,Y grids and/or interpolating.
%
%   See also CFF_CLIP_RASTER.

%   Copyright 2015-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% first thing first, if datasets are already coregistered, get out of here:
if all(size(X1)==size(X2)) && all(all(X1==X2)) && all(all(Y1==Y2))
    Z1out = Z1;
    Z2out = Z2;
    Xout = X1;
    Yout = Y1;
    return
end
    
% get datasets resolutions:
X1_res = CFF_get_vector_stepsize(X1(1,:));
X2_res = CFF_get_vector_stepsize(X2(1,:));
Y1_res = abs(CFF_get_vector_stepsize(Y1(:,1)));
Y2_res = abs(CFF_get_vector_stepsize(Y2(:,1)));

% output X Y resolution
if nargin==6
    % unspecified, use X1,Y1
    Xout_res = X1_res;
    Yout_res = Y1_res;
elseif nargin==7
    % one value specified, use for both Xout,Yout
    Xout_res = varargin{1};
    Yout_res = varargin{1};
elseif nargin==8
    % two values specified, use first for Xout, second for Yout
    Xout_res = varargin{1};
    Yout_res = varargin{2};
end

% in case the two grids are already co-registered but one file has proper
% easting/northing and not the other.
if all(size(Z1)==size(Z2))
    if X1(1)==1 && Y1(1)==1 && X2(1)~=1 && Y2(1)~=1
        % Z1 has no georeference but is the same size as Z2, assume Z1 has
        % same georeference as Z2.
        X1 = X2;
        Y1 = Y2;
        X1_res = X2_res;
        Y1_res = Y2_res;
    end
    if X2(1)==1 && Y2(1)==1 && X1(1)~=1 && Y1(1)~=1
        % Z2 has no georeference but is the same size as Z1, assume Z2 has
        % same georeference as Z1.
        X2 = X1;
        Y2 = Y1;
        X2_res = X1_res;
        Y2_res = Y1_res;
    end
end

% get coordinates for the max extent
minX = min([X1(1,1);X2(1,1)]);
maxX = max([X1(1,end);X2(1,end)]);
minY = min([Y1(end,1);Y2(end,1)]);
maxY = max([Y1(1,1);Y2(1,1)]);
[Xout,Yout] = meshgrid([minX:Xout_res:maxX],[maxY:-Yout_res:minY]);

% if original X&Y fit in output X&Y, just fit grids
if all(ismember(X1(1,:),Xout(1,:))) && all(ismember(X2(1,:),Xout(1,:))) && all(ismember(Y1(:,1),Yout(:,1))) && all(ismember(Y2(:,1),Yout(:,1)))
    
    firstcol = find(Xout(1,:)==X1(1));
    firstrow = find(Yout(:,1)==Y1(1));
    Z1out = nan(size(Xout));
    Z1out( firstrow:firstrow+size(Z1,1)-1 , firstcol:firstcol+size(Z1,2)-1 ) = Z1;
    
    firstcol = find(Xout(1,:)==X2(1));
    firstrow = find(Yout(:,1)==Y2(1));
    Z2out = nan(size(Xout));
    Z2out( firstrow:firstrow+size(Z2,1)-1 , firstcol:firstcol+size(Z2,2)-1 ) = Z2;
    
else
    % if not, need some interpolation
    
    Z1out = interp2(X1,Y1,Z1,Xout,Yout);
    Z2out = interp2(X2,Y2,Z2,Xout,Yout);

end
