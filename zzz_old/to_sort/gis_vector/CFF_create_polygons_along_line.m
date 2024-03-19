function [polygons,vq] = CFF_create_polygons_along_line(pline,interval,offset,p_length, p_width,display_flag)
% [polygons,vq] = CFF_create_polygons_along_line(pline,interval,offset,p_length, p_width,display_flag)
%
% DESCRIPTION
%
% Create a series of rectangular polygons defined along "pline", centered
% on "pline" at intervals "interval", starting at "offset" distance from
% the first vertex, and having "p_length" length along the line and
% "p_width" width across the line. "display_flag" set to 1 forces display.
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


% distance of each line vertex along line
lineprev = [pline(1,:); pline(1:end-1,:)];
dist = cumsum(sqrt(sum((pline-lineprev).^2,2)));

% distance along line of the center of future polygons
distwanted = [offset:interval:dist(end)];

% XY of center of future polygons 
vq(:,1) = interp1(dist,pline(:,1),distwanted);
vq(:,2) = interp1(dist,pline(:,2),distwanted);

% direction of future polygon as angle from the vertical
%   first:
[alpha(1),rho] = cart2pol(vq(2,1)-vq(1,1),vq(2,2)-vq(1,2));
%   intermediate:
for ii = 2:size(vq,1)-1
    [alpha(ii),rho] = cart2pol(vq(ii+1,1)-vq(ii-1,1),vq(ii+1,2)-vq(ii-1,2));
end
%   last:
[alpha(size(vq,1)),rho] = cart2pol(vq(end,1)-vq(end-1,1),vq(end,2)-vq(end-1,2));

% polygon centered on zero and unrotated
basepoly = [  0.5.*p_length ,  0.5.*p_width ; ...
             -0.5.*p_length ,  0.5.*p_width ; ...
             -0.5.*p_length , -0.5.*p_width ; ...
              0.5.*p_length , -0.5.*p_width ; ...
              0.5.*p_length ,  0.5.*p_width ];

% rotate poly along direction and add center coordinates
for ii = 1:size(vq,1)
    
    % rotate poly along wanted direction
    [THETA,RHO] = cart2pol(basepoly(:,1),basepoly(:,2));
    [X,Y] = pol2cart(THETA + alpha(ii),RHO);
   
    % add center coordinates
    polygons{ii} = ones(5,1)*vq(ii,:) + [X,Y];
    
end

% display test
if display_flag   
    figure
    plot(pline(:,1),pline(:,2),'k.-')
    hold on
    plot(vq(:,1),vq(:,2),'ro')
    axis equal
    grid on
    for ii= 1:length(polygons)
        plot(polygons{ii}(:,1),polygons{ii}(:,2),'r.-')
    end
end