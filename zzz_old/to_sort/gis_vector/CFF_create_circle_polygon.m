function [x,y] = CFF_create_circle_polygon(center,radius,numVert)
% [x,y] = CFF_create_circle_polygon(center,radius)
%
% DESCRIPTION
%
% Create a polygon of numVert number of vertices of coordinates x,y shaped
% as a circle centered on center and with radius radius.
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% preallocate x and y 
x = zeros(numVert,1);
y = zeros(numVert,1);

% angle of the unit circle in radians
circleAng = 2*pi;

% the average angular separation between points in a unit circle
angleSeparation = circleAng/numVert;

% create the matrix of angles for equal separation of points
angleMatrix = 0:angleSeparation:circleAng;

% drop the final angle since 2Pi = 0
angleMatrix(end) = [];

% generate the points x and y
x = center(1) + radius * cos(angleMatrix);
y = center(2) + radius * sin(angleMatrix);
    
% display
%figure;
%plot(x,y,'.-')
%axis equal
%grid on

