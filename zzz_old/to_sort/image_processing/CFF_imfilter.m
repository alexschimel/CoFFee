function B = CFF_imfilter(A,H,varargin)
% B = CFF_imfilter(A,H,varargin)
% DESCRIPTION
%
% implementing manual version of imfilter (need a toolbox)
%
% B = imfilter(A,h) filters the array A with the
% filter h. The array A can be logical or a nonsparse
% numeric array of any class and dimension. The result B has the same size
% and class as A.   
%
% imfilter computes each element of the output, B, using double-precision
% floating point. If A is an integer or logical array, imfilter truncates
% output elements that exceed the range of the given type, and rounds
% fractional values.   
%
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% turn zeros to NaN in H
H=double(H);
H(H==0)=NaN;

% input sizes
[nrA,ncA] = size(A);
[nrH,ncH] = size(H);
nel = numel(find(~isnan(H)));

% pad input array with padel
% pad with NaNs for erosion, dilation so that borders never get used in
% computations 
padel = NaN; % 0 or 1 or NaN or inf or min(A(:)) or max(A(:))
A2 = padel.*ones(nrA+nrH-1,ncA+ncH-1);
A2( 1+(nrH-1)/2:end-(nrH-1)/2 , 1+(ncH-1)/2:end-(ncH-1)/2 ) = A;

% or pad with replicate of first/last row/column
% A2 = A;
% for ii = 1:(ncH-1)/2
%     A2 = [A2(:,1) A2 A2(:,end)];
% end
% for jj = 1:(nrH-1)/2
%     A2 = [A2(1,:);A2;A2(end,:)];
% end

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


%% imfilter (correlation or convolution).
% sum? what's conv2?
% summing with the strel having zeros will come back to the same thing as
% using nanfunc with sum
B = CFF_nanfunc3('sum',B,3);










