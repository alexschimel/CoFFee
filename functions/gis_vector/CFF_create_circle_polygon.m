function [x,y] = CFF_create_circle_polygon(center,radius,numVert)
% [x,y] = CFF_create_circle_polygon(center,radius)
%
% DESCRIPTION
%
% Create a polygon of numVert number of vertices of coordinates x,y shaped
% as a circle centered on center and with radius radius.
%
% USE
%
% This is a bit more detailed description of how to use the function. DELETE THIS LINE IF UNUSED
%
% PROCESSING SUMMARY
% 
% This is a summary of the steps in the processing. DELETE THIS LINE IF UNUSED
%
% REQUIRED INPUT ARGUMENTS
%
% - 'argRequired': description of the first required argument. If several, add after this line. 
%
% OPTIONAL INPUT ARGUMENTS
%
% - 'XXX': description of the optional arguments with list of valid values and what they do. DELETE THIS LINE IF UNUSED
%
% PARAMETERS INPUT ARGUMENTS
%
% - 'XXX': description of the optional parameter arguments (name-value pair). DELETE THIS LINE IF UNUSED
%
% OUTPUT VARIABLES
%
% - OUT: description of output variables. DELETE THIS LINE IF UNUSED
%
% RESEARCH NOTES
%
% This describes what features are temporary or needed future developments. DELETE THIS LINE IF UNUSED
%
% NEW FEATURES
%
% YYYY-MM-DD: second version. Describes the update. DELETE THIS LINE IF UNUSED
% YYYY-MM-DD: first version.
%
% EXAMPLES
%
% This section contains examples of valid function calls. DELETE THIS LINE IF UNUSED
%
%%%
% Alex Schimel, Deakin University. CHANGE AUTHOR IF NEEDED.
%%%

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

