function CFF_circle (x,y,radius,varargin)
% drawing a circle using Matlab's command "rectangle"

%   Copyright 2010-2010 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

rectangle('position',[x-radius, y-radius, 2*radius, 2*radius],'curvature',[1 1],varargin{:});


