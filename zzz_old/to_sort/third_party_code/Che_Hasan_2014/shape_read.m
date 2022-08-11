function results = shape_read(filename)
% PURPOSE: reads an arcview shapfile and returns a structure 
%          that can be used by make_map() function
% -----------------------------------------------------
% USAGE: results = shape_read(filename)
% where: filename = an arcview file name without the extension
% ----------------------------------------------------------------------------------------
% Returns: a structure variable:
%  results.npoly = a scalar with # of polygon regions or data observations on the map
%  results.nvars = # of variables from the dbf file [should = the length(vnames)]
%  results.nobs  = # of observations from the dbf file [should = npoly]
%  results.xmin = an nobs-vector of minimum longitude for each region
%  results.xmax = an nobs-vector of maximum longitude for each region
%  results.ymin = an nobs-vector of minimum lattitude for each region
%  results.ymax = an nobs-vector of maximum lattitude for each region
%  results.nvertices = an nobs-vector of # of vertices for each region
%  results.nparts = an nobs-vector of # of parts for each region
%  results.xc = an nobs-vector with x-centroid for each polygon/ region
%  results.yc = an nobs-vector with y-centroid for each polygon/ region
%  results.data = (an nobs=npoly by nvars) matrix of sample data observations for each polygon/ region
%  results.vnames = variable names for data vectors from dbf file
% ---------------------------------------------------------------------------------------
%  results.x = an (n by nvertices) vector of polygon points, with NaN separators
%  results.y = an (n by nvertices) vector of polygon points, with NaN separators
%              (the same as poly(i).handles(i), but organized a one long vector
%               these can be used as carte argument to the geoxp functions carte = [results.x results.y])
% ----------------------------------------------------------------------------------------
% NOTES:
%
% 1) to load and plot a map involving npoly=nobs sample data observations
% results = shape_read('myarcfile');
% poly = make_map(results);
% to set the facecolor of the map polygons, using the handles in poly structure
% for i=1:results.npoly;
%  for k=1:results.nparts(i);
%  set(poly(i).handles(k),'FaceColor',[0 1 1]);
%  end;
% end;
%
% 2) to use the geoxp functions:
% % [results,poly] = shpfile_read('myarcfile');
% histomap(results.xc,results.yc,variable,nbcl,[results.x results.y], ...)
% ----------------------------------------------------------------------------------------
% see ALSO: arc_histmap(results, ...), arc_moranplot
% ----------------------------------------------------------------------------------------
% uses: a c-mex function shp_read.c, compile with mex shp_read.c shapelib.c
% ----------------------------------------------------------------------------------------

% written by: James P. LeSage 12/2003
% University of Toledo
% Department of Economics
% Toledo, OH 43606
% jlesage@spatial-econometrics.com

if nargin ~= 1
error('shpfile_read: Wrong # of input arguments');
end;

% call to mex file
[cartex,cartey,xmin,xmax,ymin,ymax,nvertices,nparts,xc,yc] = shp_read(filename);
% compile with:
% mex shp_read.c shapelib.c

ind = find(cartex ~= 0);
long = cartex(ind,1);
latt = cartey(ind,1);
npoly = length(xmin);
results.npoly = npoly;
results.xc = xc;
results.yc = yc;
clear xc;
clear yc;

results.x = long(1:end-1,1);
results.y = latt(1:end-1,1);
x = results.x;
y = results.y;

poly(1).fig_handle = figure('Visible','off');
handles = polyplot(long(1:end-1,1),latt(1:end-1,1),'fill',[0 0 0]);

clear long;
clear latt;

 % Process chunks separated by NaN .................
in = [0; find(isnan(x)); length(x)+1];
n = length(in)-1;
cnt = 1;
jj = 1;
while (jj <= n)
  ii = in(jj)+1:in(jj+1)-1;
  ii = [ii ii(1)];
  xx = x(ii); yy = y(ii);
if nparts(cnt,1) == 1
poly(cnt).handles(1,1) = handles(jj);
results.xmin(cnt) = xmin(cnt);
results.xmax(cnt) = xmax(cnt);
results.ymin(cnt) = ymin(cnt);
results.ymax(cnt) = ymax(cnt);
results.nvertices(cnt) = nvertices(cnt);
results.nparts(cnt) = nparts(cnt);
cnt = cnt+1;
jj = jj+1;
else
 for k=1:nparts(cnt,1);
  poly(cnt).handles(1,k) = handles(jj);
  jj = jj+1;
 end;
results.xmin(cnt) = xmin(cnt);
results.xmax(cnt) = xmax(cnt);
results.ymin(cnt) = ymin(cnt);
results.ymax(cnt) = ymax(cnt);
results.nvertices(cnt) = nvertices(cnt);
results.nparts(cnt) = nparts(cnt);
cnt = cnt+1;
end;
end;

clear xmin;
clear xmax;
clear ymin;
clear ymax;
clear nvertices;
clear nparts;


% clean up the invisible figure window stuff
hfig = gcf;
close(hfig);
clf reset;
close all;


% now read the dbf file and place the data into a structure
[datamatrix,vnames] = dbf_read(filename);

results.vnames = strvcat(vnames);
results.nvars = size(datamatrix,2);
results.nobs = size(datamatrix,1);
if results.nobs ~= results.npoly
warning('shpfile_read: # of shapefile polygons do not match # of data observations in dbf file');
end;
results.data = datamatrix;
clear datamatrix;

function [handles] = polyplot(x,y,a1,a2)
% POLYPLOT Plotting or filling polygons.
%	L = POLYPLOT(X,Y) plots polygon(s)
%	concatenated into coordinate vectors X, Y.
%	If X, Y consist of coordinates of several
%	polygons they must be separated by NaN:
%	X = [X1 NaN X2 NaN X3 ...]. In this case each
%	polygon is "closed" and plotted separately.
%	L is a vector of handles of lines defining
%	polygon boundaries, one handle per line.
%	L = POLYPLOT(X,Y,C) also specifies line color.
%	C can be a letter such as 'w', 'y', 'c', etc.,
%	a 1 by 3 vector in RGB format or a string of 
%	such letters, like 'rgby' or n by 3 matrix.
%	In the latter case this string or matrix plays the
%	role of color order for succession of polygons.
%	If the number of polygons is more than number of
%	colors, colors are cyclically repeated.
%
%	P = POLYPLOT(X,Y,'fill',C) fills polygons
%	creating a patch rather than a line and returns
%	patch handles P.
%
%	This program can also fill non-simply connected
%	polygons, such as ones with holes. It checks
%	the direction of each polygons separated by
%	NaN in coordinate vectors. If the contour is
%	clock-wise (signed area is negative) then it
%	interprets such a polygon as a "hole" and fills
%	it with the background color.

%  Copyright (c) 1995 by Kirill K. Pankratov,
%       kirill@plume.mit.edu.
%       06/25/95, 09/07/95  

%  May call AREA function.

 % Handle input ....................................
is_patch = 0;
clr = get(gca,'colororder');
if nargin>2
  lm = min(length(a1),4);
  names = ['fill '; 'patch'];
  is_patch = all(a1(1:lm)==names(1,1:lm));
  is_patch = is_patch | all(a1(1:lm)==names(2,1:lm));

  if is_patch
    if nargin>3, clr = a2; end
  else
    clr = a1;
  end
end
if isstr(clr), clr=clr(:); end
nclr = size(clr,1);
x = x(:); y = y(:);

 % Check hold state ............
if ~ishold, newplot, end

 % Setup a call ................
if is_patch
  call = 'patch';
  cpn = 'facecolor';
else
  call = 'line';
  cpn = 'color';
end
% call = ['p(jj)=' call '(''xdata'',xx,''ydata'',yy);'];
% call
 % Get color for "holes" polygons ..................
clrh = get(gca,'color');
if strcmp(clrh,'none'), clrh = get(gcf,'color'); end 

 % Process chunks separated by NaN .................
in = [0; find(isnan(x)); length(x)+1];
n = length(in)-1;
for jj=1:n
  ii = in(jj)+1:in(jj+1)-1;
  ii = [ii ii(1)];
  xx = x(ii); yy = y(ii);

  % Check area
  a(jj) = area(xx,yy);

  % Create the patch or line
  %eval(call)
  handles(jj) = patch(xx,yy,[1 0 0]);
  ic = rem(jj-1,nclr)+1;
  set(handles(jj),cpn,clr(ic,:))
end

 % If non-simply-connected patch, fill "holes" with 
 % background color ...............................
if is_patch & n>1
  % Find which polygons are inside which
  holes = find(a<0);
  % Set color
  set(handles(holes),'FaceColor',clrh)

end


function  a = area(x,y)
% AREA  Area of a planar polygon.
%	AREA(X,Y) Calculates the area of a 2-dimensional
%	polygon formed by vertices with coordinate vectors
%	X and Y. The result is direction-sensitive: the
%	area is positive if the bounding contour is counter-
%	clockwise and negative if it is clockwise.
%
%	See also TRAPZ.

%  Copyright (c) 1995 by Kirill K. Pankratov,
%	kirill@plume.mit.edu.
%	04/20/94, 05/20/95  

 % Make polygon closed .............
x = [x(:); x(1)];
y = [y(:); y(1)];

 % Calculate contour integral Int -y*dx  (same as Int x*dy).
lx = length(x);
a = -(x(2:lx)-x(1:lx-1))'*(y(1:lx-1)+y(2:lx))/2;


