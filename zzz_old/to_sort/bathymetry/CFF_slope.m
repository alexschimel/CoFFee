function [gridSlope, slopeCoef] = CFF_slope(X,Y,Z)
% INCOMPLETE
% make sure that what is exported is the slope vector coordinates in X and
% Y

% scale parameter
scale = 3;
pixNb = (2.*scale+1).^2;

% meshgrid X and Y if not done yet:
if any(size(X)==1) && any(size(Y)==1)
    [X,Y] = meshgrid(X,Y);
end
        
% input sizes
[nrows,ncols] = size(Z);

% pad input arrays
padel = NaN; 

X2 = padel.*ones(nrows+2*scale,ncols+2*scale);
Y2 = padel.*ones(nrows+2*scale,ncols+2*scale);
Z2 = padel.*ones(nrows+2*scale,ncols+2*scale);

X2(1+scale:end-scale,1+scale:end-scale) = X;
Y2(1+scale:end-scale,1+scale:end-scale) = Y;
Z2(1+scale:end-scale,1+scale:end-scale) = Z;


% intialize array
gridSlope = NaN(size(Z));

% plane vectors
[X,Y] = meshgrid([-scale:scale],[-scale:1:scale]');

% reshape in column vectors
X = reshape(X,pixNb,1);
Y = reshape(Y,pixNb,1);

for ii = scale+1:nrows-scale
    for jj = scale+1:ncols-scale
        
        % bathymetry pixels to consider for slope computation at (ii,jj)
        x = X2(ii-scale:ii+scale,jj-scale:jj+scale); 
        y = Y2(ii-scale:ii+scale,jj-scale:jj+scale); 
        z = Z2(ii-scale:ii+scale,jj-scale:jj+scale); 
        
        x = reshape(x,:,1);
        y = reshape(y,:,1);
        z = reshape(z,:,1);
        
        % compute plane coefficients
        coefs = [ x , y , ones(size(x)) ]\z;
        a = coefs(1);
        b = coefs(2);
        c = -1;
        
        % how to make sure the vector is pointing upwards? the projection of
        % the vector on the vertical?
        ...
        
        % compute maximum slope
        gridSlope_rad = atan( sqrt( coef(2).^2 + coef(3).^2 ) ); % in radians
        gridSlope(ii,jj) = 180/pi * gridSlope_rad;               % in degrees
        
    end
end

slopeCoef = 