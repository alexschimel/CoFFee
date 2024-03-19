function B = CFF_stack_offsets(A,H,varargin)
% B = CFF_stack_offsets(A,H,varargin)
%
% DESCRIPTION
%
% Create copies of A, offseted using the structural element H and stack
% them in 3rd dimension in order to apply 2D filters, typically median.
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
% using NaNs by default, these extras borders don't get used in the
% calculation 
padel = NaN; % 0 or 1 or NaN or inf or min(A(:)) or max(A(:))
A2 = padel.*ones(nrA+nrH-1,ncA+ncH-1);
A2( 1+(nrH-1)/2:end-(nrH-1)/2 , 1+(ncH-1)/2:end-(ncH-1)/2 ) = A;

% as another option, pad with replicate of first/last row/column
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

