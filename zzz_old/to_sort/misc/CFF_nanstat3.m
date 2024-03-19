function [nanmean,nanstd] = CFF_nanstat3(M,dim)
%
% computes mean and standard deviation of M in the chosen dimension dim,
% discounting the NaN values. Works with matrices M with up to 3
% dimensions.
%
% NEW FEATURES
%
% 2014-09-25: first version.
%
% EXAMPLE
%
% M = rand(5,6,4); % create a 5x6x4 matrix full of random values
% M(1,[1,4,5],[1:3]) = NaN; % add some nans
% [nanmean,nanstd] = CFF_nanstat3(M,3); % compute mean and std depsite the NaNs.

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

[m,n,p] = size(M);

switch dim
    case 1
        nanmean = nan(1,n,p);
        nanstd = nan(1,n,p);
        for jj=1:n
            for kk=1:p
                tmp = M(:,jj,kk);
                nanmean(1,jj,kk) = mean(tmp(~isnan(tmp)));
                nanstd(1,jj,kk)  =  std(tmp(~isnan(tmp)));
            end
        end
    case 2
        nanmean = nan(m,1,p);
        nanstd = nan(m,1,p);
        for ii=1:m
            for kk=1:p
                tmp = M(ii,:,kk);
                nanmean(ii,1,kk) = mean(tmp(~isnan(tmp)));
                nanstd(ii,1,kk)  =  std(tmp(~isnan(tmp)));
            end
        end
    case 3
        nanmean = nan(m,n,1);
        nanstd = nan(m,n,1);
        for ii=1:m
            for jj=1:n
                tmp = M(ii,jj,:);
                nanmean(ii,jj,1) = mean(tmp(~isnan(tmp)));
                nanstd(ii,jj,1)  =  std(tmp(~isnan(tmp)));
            end
        end
    otherwise
        error('');
end
