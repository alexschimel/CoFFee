function B = CFF_imdilate(A,H,varargin)
% B = CFF_imdilate(A,H,varargin)
%
% DESCRIPTION
%
% Image dilation
%
% In dilation, the output pixel value is the maximum value of all pixels
% covered by the strel. For a binary image, if a single pixel covered is
% 1, the result is 1. If all pixels covered are 0, the result is 0.
% For a greyscale image, we simply take the maximum value. For a raster
% image, values could be negative so it's still good to remove 0s from the
% strel so that they don't get taken into account in the computations.
%
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

H=double(H);
H(H==0)=NaN;

% input sizes
[nrA,ncA] = size(A);
[nrH,ncH] = size(H);

% pad input array
% We could use 0 or 1 or NaN or inf or min(A(:)) or max(A(:))
% Here we use NaNs so that borders never get used in computations 
padel = NaN; 
A2 = padel.*ones(nrA+nrH-1,ncA+ncH-1);
A2( 1+(nrH-1)/2:end-(nrH-1)/2 , 1+(ncH-1)/2:end-(ncH-1)/2 ) = A;

% intialize output
B = zeros(nrA,ncA,nrH*ncH);

% vectorize strel and its row/col indices
[CC,RR] = meshgrid([1:ncH],[1:nrH]');
RR = reshape(RR,[],1);
CC = reshape(CC,[],1);
HH = reshape(H,[],1);

% compute the output value for each element of the filter
for ii = 1:nrH*ncH
    B(:,:,ii) = HH(ii) .* A2( [1:nrA]'+RR(ii)-1 , [1:ncA]+CC(ii)-1 );    
end

% dilation
B = max(B,[],3);
