function CFF_circle (x,y,radius,varargin)
% drawing a circle using Matlab's command "rectangle"

rectangle('position',[x-radius, y-radius, 2*radius, 2*radius],'curvature',[1 1],varargin{:});


