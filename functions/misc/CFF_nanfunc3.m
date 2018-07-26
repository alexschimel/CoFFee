function out = CFF_nanfunc3(func,M,dim)
% out = CFF_nanfunc3(func,M,dim)
%
% DESCRIPTION
%
% Applies function func to array M in chosen dimension dim,
% discounting the NaN values. Works with matrices M with up to 3
% dimensions.
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
% - func
% - M
% - dim
%
% OUTPUT VARIABLES
%
% - out
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% 2015-02-11: dim now optional. to test
% 2014-10-13: first version.
%
% EXAMPLE
%
% M = rand(5,6,4); % create a 5x6x4 matrix full of random values
% M(1,[1,4,5],[1:3]) = NaN; % add some nans
% nanmean = CFF_nanfunc3('mean',M,3); % compute mean depsite the NaNs.
% nanstd = CFF_nanfunc3('std',M,3); % compute std depsite the NaNs.
% nanmedian = CFF_nanfunc3('median',M,3); % compute median depsite the NaNs.
%
%%%
% Alex Schimel, Deakin University
%%%

% get size of M
[m,n,p] = size(M);

% if dim is not provided:
if nargin<3
    % operate along the first non-singleton dimension
    if m>1
        dim=1;
    elseif n>1
        dim=2;
    elseif p>1
        dim=3;
    else
        % input is a single element, apply function to it directly
        tmp = M;
        out = feval(func,tmp(~isnan(tmp)));
        return
    end
end

% operate function along the dimension specified
switch dim
    case 1
        out = nan(1,n,p);
        for jj=1:n
            for kk=1:p
                tmp = M(:,jj,kk);
                out(1,jj,kk) = feval(func,tmp(~isnan(tmp)));
            end
        end
    case 2
        out = nan(m,1,p);
        for ii=1:m
            for kk=1:p
                tmp = M(ii,:,kk);
                out(ii,1,kk) = feval(func,tmp(~isnan(tmp)));
            end
        end
    case 3
        out = nan(m,n,1);
        for ii=1:m
            for jj=1:n
                tmp = M(ii,jj,:);
                out(ii,jj,1) = feval(func,tmp(~isnan(tmp)));
            end
        end
    otherwise
        error('');
end
