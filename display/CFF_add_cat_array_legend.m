function CFF_add_cat_array_legend(varargin)
%CFF_ADD_CAT_ARRAY_LEGEND  Format image of a categorical array
%
%   Adds a suitable colormap and legend to the image of a categorical
%   array.
%
%   CFF_ADD_CAT_ARRAY_LEGEND(A) adds to the current axes a legend for
%   categorical array A.
%
%   CFF_ADD_CAT_ARRAY_LEGEND(H,A) adds to the axes with handle H (or to the
%   parent axes of an image with handle H) a legend for categorical array
%   A.
%
%   Examples:
%
%   A = categorical({'','cat','dog';'dog','cat','turle'});
%   figure;
%   tiledlayout(1,3);
%   nexttile; imagesc(double(A)); colorbar
%   nexttile; image(double(A)); colorbar
%   nexttile; image(double(A)); CFF_add_cat_array_legend(A);

%   Copyright 2022-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% input parsing
A = varargin{end};
if nargin>1
    % target provided in input
    h = varargin{1};
    if isa(h,'matlab.graphics.primitive.Image')
        % if input handle was the image, get the parent axes
        hIm = h;
        hAx = hIm.parent;
    else
        % if input handle was the axes, get the child image
        hAx = h;
        hIm = findobj(hAx,'Type','image');
    end
else
    hAx = gca;
    hIm = findobj(hAx,'Type','image');
end

% set transparency in case some elements are undefined
if any(isundefined(A(:)))
    set(hIm,'AlphaData',~isnan(double(A)));
end

% define colormap
cats = categories(A);
numCat = numel(cats);
if numCat<3
    % if only 2, use Parula for highest contrast
    cmap = parula(2);
elseif numCat<13
    % if 3-12, use a nice colormap from https://colorbrewer2.org
    twelveCol = [...
        166,206,227;... % pale blue
        251,154,153;... % pale red
        178,223,138;... % pale green
        202,178,214;... % pale purple
        253,191,111;... % pale orange
        255,255,153;... % yellow
        31,120,180;... % blue
        227,26,28;... %red
        51,160,44;... % green
        106,61,154;... % purple
        255,127,0;... % orange
        177,89,40]; % brown
    cmap = twelveCol(1:numCat,:)./255;
else
    % if 13 or more, just use jet
    cmap = jet(numCat);
end

% add colormap to axis
colormap(hAx,cmap);

% add colorbar to axis
colorbar(hAx,...
    'Direction','reverse',...
    'Ticks',(1:numCat)+0.5,...
    'TickLabels',cats);

end