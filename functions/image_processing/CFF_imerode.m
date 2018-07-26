function B = CFF_imerode(A,H,varargin)
% B = CFF_imerode(A,H,varargin)
%
% DESCRIPTION
%
% Image erosion
%
% USE
%
% ...
%
% PROCESSING SUMMARY
% 
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - varagin
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% 2014-10-13: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

% In erosion, the output pixel value is the minimum value of all pixels
% covered by the strel. For a binary image, if a single pixel covered is
% zero, the result is zero. If all pixels covered are 1, the result is 1.
% For a greyscale image, we simply take the minimum value.

% The strel are constructed as binary as 0s and 1s with 0s standing for
% pixels "that are not part of the strel". So we need to remove them so
% that these 0 don't influence the "min" computation

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

% erosion
B = min(B,[],3);
