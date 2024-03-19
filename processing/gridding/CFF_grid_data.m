function [vg,wg] = CFF_grid_data(x,y,v,xg,yg,varargin)
%CFF_GRID_DATA  Grid 2D data
%
%   [VG,WG] = CFF_GRID_DATA(X,Y,V,XG,YG) grids data with value V at
%   coordinates X,Y into the grid defined by vectors of coordinates XG,YG.
%   The function returns the gridded value VG and the number of points WG
%   (density) that contributed to each grid cell. XG and YG must have a
%   constant and equal grid size. X,Y,V must be vectors or arrays with 
%   matching dimensions.
%
%   CFF_GRID_DATA(...,W) where W is the weights associated with the data,
%   performs the weighted averaging of data points into the grid. In this
%   case, the output WG becomes the cumulative weight of points that
%   contributed to each grid cell. 
%
%   CFF_GRID_DATA(...,MODE), where MODE can be 'blend' (default) or
%   'stitch', informs the gridding strategy. With 'blend', the strategy is
%   the averaging or weighted-averaging explained above. With 'stitch', the
%   value of a single data point is retained for each grid cell, that which
%   had the maximum weight. This option can only be used with weight in
%   input.
%
%   Note: Use CFF_INIT_GRID to create xg,yg from data
%
%   Note: Strategy of gridding, using the x dimension as example: 
%   1. the function calculates the grid size res from diff(xg)
%   2. x points falling between xg(i)-res/2 (included) and xg(i)+res/2
%   (excluded) will be gridded in that i-th grid cell.
%
%   See also CFF_GRID_LINES, CFF_INIT_GRID

%   Copyright 2021-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% TODOs: 
% 1. check that this function also works with gpuArrays
% 2. the stitch mode does not work. To fix, or remove.
% 3. when necessary changes are done, check the test code at the end

% input parser
p = inputParser;
addRequired(p,'x',           @(u) validateattributes(u,{'numeric'},{'2d'}));
addRequired(p,'y',           @(u) validateattributes(u,{'numeric'},{'2d'}));
addRequired(p,'v',           @(u) validateattributes(u,{'numeric'},{'2d'}));
addRequired(p,'xg',          @(u) validateattributes(u,{'numeric'},{'size',[1,NaN],'increasing'}));
addRequired(p,'yg',          @(u) validateattributes(u,{'numeric'},{'size',[NaN,1],'increasing'}));
addOptional(p,'w',   1,      @(u) isnumeric(u));
addOptional(p,'mode','blend',@(u) ismember(u,{'blend','stitch','min'}));
parse(p,x,y,v,xg,yg,varargin{:});
w = p.Results.w;
mode = p.Results.mode;
clear p;

% input additional checks and data preparation
sx = size(x);
sy = size(y);
sv = size(v);
if ~(all(sx==sy)&&all(sx==sv))
    error("'x', 'y' and 'v' must have same size.");
end
if numel(w) == 1
    w = w.*ones(sv);
end
sw = size(w);
if ~all(sw==sv)
    error("'w' must either be a scalar, or have same size as other inputs.");
end
xg_res = unique(diff(xg));
if numel(xg_res)>1
    if numel(xg_res)==2
        % check for a floating point error
        tol = 10.^-8;
        if xg_res(2)-xg_res(1)<tol
            xg_res = round(mean(xg_res)./tol).*tol;
        end
    else
        error("'xg' must be a grid vector with constant grid size.")
    end
end
yg_res = unique(diff(yg));
if numel(yg_res)>1
    if numel(yg_res)==2
        % check for a floating point error
        tol = 10.^-8;
        if yg_res(2)-yg_res(1)<tol
            yg_res = round(mean(yg_res)./tol).*tol;
        end
    else
        error("'yg' must be a grid vector with constant grid size.")
    end
end
res = unique([xg_res,yg_res]);
if numel(res)>1
    error("'xg' and 'yg' must have the same grid size.")
end

% vectorize everything
if sx(2)>1
    x = x(:);
    y = y(:);
    v = v(:);
    w = w(:);
end

% indices of data in grid
ix = round((x-xg(1))/res+1);
iy = round((y-yg(1))/res+1);

% remove data 1) outside of grid boundaries, 2) with a nan value, 3)
% with zero weight
iKeep = ix>=1 & ix<=numel(xg) ...
    & iy>=1 & iy<=numel(yg) ...
    & ~isnan(x) & ~isnan(y) & ~isnan(v) & ~isnan(w) & w~=0;
if any(iKeep==0)
    ix = ix(iKeep);
    iy = iy(iKeep);
    v  = v(iKeep);
    w  = w(iKeep);
end

% prepare for accumarray
subs = [iy ix];
sz = [numel(yg) numel(xg)];

switch mode
    case 'blend'
        % Here we calculate the weighted average of v,w. 
        % NOTE: I originally wrote a special case when output weights are
        % not requested so a single accumarray using @mean could be used,
        % but it turns out it takes more time than using the weighted
        % average below with unit weights.
        wg  = accumarray(subs,w,sz,@sum,0); % gridded weight
        wvg = accumarray(subs,v.*w,sz,@sum,NaN); % gridded weighted sum
        vg = wvg./wg; % gridded weighted average
    case 'stitch'
        wg  = accumarray(subs,w,sz,@max,NaN); % gridded maximum weight
        [~,iw] = ismember(wg,w); % indices of data point to retain
        iNaN = iw==0; % NaN indices are grid cells with no data
        iw(iNaN) = 1; % temporarily give them a dummy index
        vg = v(iw); % get corresponding values
        vg(iNaN) = NaN; % put the NaNs back in
        wg(iNaN) = 0; % in weight grid, no data should be 0
    case 'min'
        vg  = accumarray(subs,v,sz,@min,NaN); % gridded weight
        wg = [];
end

end

% TEST CODE
% 
% % define grid
% [xg,yg] = CFF_init_grid([0 100], [0 100]);
% 
% % data points
% N = 10000000;
% x = [randn(N,1).*10+33;randn(N,1).*10+66];
% y = [randn(N,1).*10+33;randn(N,1).*10+66];
% v = [2.*ones(N,1);1.*ones(N,1)];
% 
% % weight options
% w1 = [10.*ones(N,1);10.*ones(N,1)];
% w2 = [1.*ones(N,1);100.*ones(N,1)];
% 
% 
% exp = 1;
% tic
% [vg,wg] = CFF_grid_data(x,y,v,xg,yg);
% t= toc;
% figure;
% subplot(121); imagesc(vg,'AlphaData',~isnan(vg)); 
% set(gca,'YDir','default'); axis equal; grid on; colorbar;
% title(sprintf('exp #%i: %f s',exp,t))
% subplot(122); imagesc(wg,'AlphaData',wg~=0); 
% set(gca,'YDir','default'); axis equal; grid on; colorbar;
% title('blend, no weights')
% 
% exp = 2;
% tic
% [vg,wg] = CFF_grid_data(x,y,v,xg,yg,w1);
% t= toc;
% figure;
% subplot(121); imagesc(vg,'AlphaData',~isnan(vg)); 
% set(gca,'YDir','default'); axis equal; grid on; colorbar;
% title(sprintf('exp #%i: %f s',exp,t))
% subplot(122); imagesc(wg,'AlphaData',wg~=0); 
% set(gca,'YDir','default'); axis equal; grid on; colorbar;
% title('blend, same weights of 10')
% 
% exp = 3;
% tic
% [vg,wg] = CFF_grid_data(x,y,v,xg,yg,w2);
% t= toc;
% figure;
% subplot(121); imagesc(vg,'AlphaData',~isnan(vg)); 
% set(gca,'YDir','default'); axis equal; grid on; colorbar;
% title(sprintf('exp #%i: %f s',exp,t))
% subplot(122); imagesc(wg,'AlphaData',wg~=0); 
% set(gca,'YDir','default'); axis equal; grid on; colorbar;
% title('blend, different weights')
% 
% exp = 4;
% tic
% [vg,wg] = CFF_grid_data(x,y,v,xg,yg,w2,'stitch');
% t= toc;
% figure;
% subplot(121); imagesc(vg,'AlphaData',~isnan(vg)); 
% set(gca,'YDir','default'); axis equal; grid on; colorbar;
% title(sprintf('exp #%i: %f s',exp,t))
% subplot(122); imagesc(wg,'AlphaData',wg~=0); 
% set(gca,'YDir','default'); axis equal; grid on; colorbar;
% title('stitch, different weights')
