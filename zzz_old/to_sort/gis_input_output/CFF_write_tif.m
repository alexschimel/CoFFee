function CFF_write_tif(MAP,X,Y,filename)
% CFF_write_tif(MAP,X,Y,filename)
%
% DESCRIPTION
%
% Save array as floating point tif. XXX seems to be some issue with it...
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% include a test for consistent diff value in X and Y. maybe a test for
% rotation too?
...

%% write tif

t = Tiff([filename '.tif'], 'w'); 
tagstruct.ImageLength = size(MAP, 1); 
tagstruct.ImageWidth = size(MAP, 2); 
tagstruct.Compression = Tiff.Compression.None; 
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP; 
tagstruct.Photometric = Tiff.Photometric.MinIsBlack; 
tagstruct.BitsPerSample = 64;
tagstruct.SamplesPerPixel = 1;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky; 
t.setTag(tagstruct); 
t.write(MAP); 
t.close();

% NOTE: atfer importing the result in Arc I have some issues... Explore
% this more later

%% write tfw
% assuming no rotation

A = X(1,2)-X(1,1); %Line 1: x-scale. This is the horizontal distance in meters represented by each pixel. So in the above example each pixel is .6 meters wide. 
D = 0;             %Line 2: Rotation about y axis. 
B = 0;             %Line 3: Rotation about x axis. 
E = Y(2,1)-Y(1,1); %Line 4: y-scale This is the vertical distance in meters represented by each pixel. So in the above example each pixel is .6 meters tall. Normally negative, because whilst an image has its origin in the top left corner, for Northings and Eastings the origin is normally considered to be the bottom left corner - hence why the scale is normally negative. 
C = X(1,1);        %Line 5: x-reference point. This is the horizontal coordinate (or Easting) of the center of the top left pixel. 
F = Y(1,1);        %Line 6: y-reference point. This is the vertical coordinate (or Northing) of the center of the top left pixel. 

fid = fopen([filename '.tfw'], 'wt');
fprintf(fid, '%6.8f\n', [A D B E C F]);
fclose(fid);