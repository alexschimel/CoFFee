function B = CFF_offset_array(A, offsets, varargin)
%CFF_OFFSET_ARRAY  Offset matrix or 3D tensor by specified index offset
%
%   B = CFF_OFFSET_ARRAY(A,OFFSETS), where A is a matrix and OFFSETS a
%   vector pf size matching one of the two dimensions of A, creates a new
%   matrix B where values are taken from A but with index offsets as
%   specified in OFFSETS. The output array is padded with NaNs. For
%   example, if A = [1 1; 1 1] and OFFSETS = [0 1], 
%   then B = [1 NaN; 1 1; NaN 1], aka the columns of A are shifted
%   downwards by offsets 0 and 1, respectively.
%
%   B = CFF_OFFSET_ARRAY(A,OFFSETS), where A is a 3D tensor and OFFSETS a
%   matrix with size matching two of the three dimensions of A, creates a
%   new matrix B where values are taken from A but with index offsets as
%   specified in OFFSETS. The output array is padded with NaNs.
%
%   CFF_OFFSET_ARRAY(...,'padValue',P), pads the output B with numeric
%   value P instead of NaN.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


% input parsing
p = inputParser;
addRequired(p,'A',@(x) ismatrix(x) || ndims(A)==3);
addRequired(p,'offsets',@(x) ismatrix(squeeze(x)));
addOptional(p,'padValue',NaN, @(x) isnumeric(x));
parse(p,A,offsets,varargin{:});
padValue = p.Results.padValue;
clear p;

% should not have any NaNs in the offsets input.. but just in case of:
offsets(isnan(offsets)) = 0;

% first, let's get rid of the trivial case where there are no offsets. Just
% return input array
uniqueOffsets = unique(offsets);
if numel(uniqueOffsets)==1 && uniqueOffsets==0
    B = A;
    return
end

% next we need to find and conserve the class of A
useGpuArray = isgpuarray(A);
if useGpuArray
    useClass = class(gather(A(1)));
else
    useClass = class(A(1));
end

if ismatrix(A)
    assert(isvector(offsets),'if A is a matrix, offsets must be a vector');
    % get values from input arrays
    [n1,n2] = size(A);
    m = max(offsets);
    if isrow(offsets)
        % offset in height
        assert(numel(offsets)==n2,'dimensions of A and offsets do not match');
        % init output
        if isnan(padValue)
            B = nan(n1+m,n2);
        else
            B = padValue.*ones(n1+m,n2);
        end
        B = cast(B,useClass);
        if useGpuArray
            B = gpuArray(B);
        end
        % fill output
        if numel(uniqueOffsets) == 1
            % unique offset, bulk shift
            B((1:n1)+uniqueOffsets,:) = A;
        else
            % fill column by column
            for ii = 1:numel(offsets)
                B((1:n1)+offsets(ii),ii) = A(:,ii);
            end
        end
    elseif iscolumn(offsets)
        % offset in width
        assert(numel(offsets)==n1,'dimensions of A and offsets do not match');
        % init output
        if isnan(padValue)
            B = nan(n1,n2+m);
        else
            B = padValue.*ones(n1,n2+m);
        end
        B = cast(B,useClass);
        if useGpuArray
            B = gpuArray(B);
        end
        % fill output
        if numel(uniqueOffsets) == 1
            % unique offset, bulk shift
            B(:,(1:n2)+uniqueOffsets) = A;
        else
            % fill row by row
            for ii = 1:numel(offsets)
                B(ii,(1:n2)+offsets(ii)) = A(ii,:);
            end
        end
    end
elseif ndims(A)==3
    assert(ismatrix(squeeze(offsets)),'if A is a 3D tensor, offsets must be a matrix');
    % get values from input arrays
    [n1,n2,n3] = size(A);
    [o1,o2,o3] = size(offsets);
    m = max(offsets(:));
    if o1 == 1
        % offset in height
        assert(o2==n2&&o3==n3,'dimensions of A and offsets do not match');
        % init output
        if isnan(padValue)
            B = nan(n1+m,n2,n3);
        else
            B = padValue.*ones(n1+m,n2,n3);
        end
        B = cast(B,useClass);
        if useGpuArray
            B = gpuArray(B);
        end
        % fill output
        if numel(uniqueOffsets) == 1
            % unique offset, bulk shift
            B((1:n1)+uniqueOffsets,:,:) = A;
        elseif size(permute(unique(permute(offsets,[2 3 1]),'rows'),[3 1 2]),2)==1
            % offset vertical slice by vertical slice
            sliceOffsets = permute(unique(permute(offsets,[2 3 1]),'rows'),[3 1 2]);
            for kk = 1:o3
                B((1:n1)+sliceOffsets(kk),:,kk) = A(:,:,kk);
            end
        elseif size(permute(unique(permute(offsets,[3 2 1]),'rows'),[3 2 1]),3)==1
            % offset vertical slice by vertical slice
            sliceOffsets = permute(unique(permute(offsets,[3 2 1]),'rows'),[3 2 1]);
            for jj = 1:o2
                B((1:n1)+sliceOffsets(jj),jj,:) = A(:,jj,:);
            end
        else
            % fill element by element (slow)
            for jj = 1:o2
                for kk = 1:o3
                    B((1:n1)+offsets(1,jj,kk),jj,kk) = A(:,jj,kk);
                end
            end
        end
    elseif o2 == 1
        % offset in width
        assert(o1==n1&&o3==n3,'dimensions of A and offsets do not match');
        % init output
        if isnan(padValue)
            B = nan(n1,n2+m,n3);
        else
            B = padValue.*ones(n1,n2+m,n3);
        end
        B = cast(B,useClass);
        if useGpuArray
            B = gpuArray(B);
        end
        % fill output
        if numel(uniqueOffsets) == 1
            % unique offset, bulk shift
            B(:,(1:n2)+uniqueOffsets,:) = A;
        elseif size(permute(unique(permute(offsets,[3 1 2]),'rows'),[2 3 1]),3)==1
            % offset horizontal slice by horizontal slice
            sliceOffsets = permute(unique(permute(offsets,[3 1 2]),'rows'),[2 3 1]);
            for ii = 1:o1
                B(ii,(1:n2)+sliceOffsets(ii),:) = A(ii,:,:);
            end
        elseif size(permute(unique(permute(offsets,[1 3 2]),'rows'),[1 3 2]),1)==1
            % offset vertical slice by vertical slice
            sliceOffsets = permute(unique(permute(offsets,[1 3 2]),'rows'),[1 3 2]);
            for kk = 1:o3
                B(:,(1:n2)+sliceOffsets(kk),kk) = A(:,:,kk);
            end
        else
            % fill element by element (slow)
            for ii = 1:o1
                for kk = 1:o3
                    B(ii,(1:n2)+offsets(ii,1,kk),kk) = A(ii,:,kk);
                end
            end
        end
    else
        % offset in depth
        assert(o1==n1&&o2==n2,'dimensions of A and offsets do not match');
        % init output
        if isnan(padValue)
            B = nan(n1,n2,n3+m);
        else
            B = padValue.*ones(n1,n2,n3+m);
        end
        B = cast(B,useClass);
        if useGpuArray
            B = gpuArray(B);
        end
        % fill output
        if numel(uniqueOffsets) == 1
            % unique offset, bulk shift
            B(:,:,(1:n3)+uniqueOffsets) = A;
        elseif size(unique(offsets,'rows'),1)==1
            % offset vertical slice by vertical slice
            sliceOffsets = unique(offsets,'rows');
            for jj = 1:o2
                B(:,jj,(1:n3)+sliceOffsets(jj)) = A(:,jj,:);
            end
        elseif size(unique(offsets','rows'),1)==1
            % offset horizontal slice by horizontal slice
            sliceOffsets = unique(offsets','rows');
            for ii = 1:o1
                B(ii,:,(1:n3)+sliceOffsets(ii)) = A(ii,:,:);
            end
        else
            % fill element by element (slow)
            for ii = 1:o1
                for jj = 1:o2
                    B(ii,jj,(1:n3)+offsets(ii,jj)) = A(ii,jj,:);
                end
            end
        end
    end
end