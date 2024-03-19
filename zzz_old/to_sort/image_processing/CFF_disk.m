function out = CFF_disk(radius)
% out = CFF_disk(radius)
%
% DESCRIPTION
%
% create an array of 0-1s where 1s form a disk (use as a structural element
% strel)
%
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

X = [-radius:1:radius];
Y = flipud(X');
[XX,YY] = meshgrid(X,Y);
out = sqrt(XX.^2+YY.^2)<=radius;
