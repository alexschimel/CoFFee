function [M,S] = CFF_compute_watercolumn_energy(fData,method,varargin)
% [fData] = CFF_compute_watercolumn_energy(fData,method,varargin)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

switch method
    
    case 0
        
        % Extract needed data
        D = fData.WC_PBS_SampleAmplitudes;
        nPings = size(D,1);
        nBeams = size(D,2);
        nSamples = size(D,3);
        bot = fData.WC_PB_DetectedRangeInSamples;
        
        % for each ping and each beam, nan all samples below bottom. Note that if
        % no bottom was detected, bot is equal to zero so it works as well.
        for ip = 1:nPings
            for ib = 1:nBeams
                D(ip,ib,bot(ip,ib)+1:end) = NaN;
            end
        end
        
        % also nan everything 2m below sonar
        ind = find(fData.X_PBS_sampleUpDist>-2);
        D(ind) = NaN;
        
        % display tests:
        %ht1 = CFF_watercolumn_display(fData,D,'flat');
        %ht2 = CFF_watercolumn_display(fData,D,'wedge');
        
        % for each ping, calculate mean and std
        M = nan(nPings,1);
        S = nan(nPings,1);
        
        for ip = 1:nPings
            tmp = squeeze(D(ip,:,:));
            tmp = tmp(:);
            tmp = tmp(~isnan(tmp));
            M(ip) = mean(tmp);
            S(ip) = std(tmp);
        end
        
        %
        % clear M1 M2
        % for ii=1:100
        %
        %     siz = 4;
        %     A = round(rand(siz)*10)
        %     B = A - repmat(mean(A),siz,1)
        %
        %     mean(A(:))
        %     mean(B(:))
        %
        %     M1(ii) = mean(A(:));
        %     M2(ii) = mean(B(:));
        % end
        %
        
    case 1
        
        kelp = varargin{1};
        
        M = mean(10.^(kelp(:,7)./20));
        S = sum(10.^(kelp(:,7)./20));
        
        
    otherwise
        
        error
        
end