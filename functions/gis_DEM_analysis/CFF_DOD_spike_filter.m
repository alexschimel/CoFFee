function DEM2 = CFF_DEM_spike_filter(DEM, n_pixel_neighborhood, k_std_factor, display_flag)
%CFF_DEM_SPIKE_FILTER  Filtering spikes out of DEM.
%
%   Filtering spikes out of DEM. The larger n and the smaller k, the more
%   filtering.
%
%   See also CFF_CALCULATE_DOD.

%   Copyright 2015-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% params
n = n_pixel_neighborhood; %neighborhood size
k = k_std_factor; %std factor

% size of DEM
[nR,nC] = size(DEM);

% display
if display_flag
    figure
    imagesc(DEM);
    colormap jet
    colorbar
    alpha(double(~isnan(DEM)));
    grid on; axis equal
end

flag = 1;
while flag
    
    for iR = 1:nR
        for iC = 1:nC
            
            % get value
            val = DEM(iR,iC);
            
            % get neighborhood around pixel, except val
            iRvec = max(1,iR-n):min(nR,iR+n);
            iCvec = max(1,iC-n):min(nC,iC+n);
            nhood = DEM(iRvec,iCvec);
            nhood(iR==iRvec,iC==iCvec)=NaN; % removing val 
            nhood = nhood(~isnan(nhood));
            medhood = median(nhood);
            stdhood = std(nhood);
            
            % compare median to standard
            fact = (val - medhood)./std
            
            
            
            
        end
    end
    
    % median of neighborhood around min
    DEMminRbeg = max(1,DEMminR - n);
    DEMminRend = min(nR,DEMminR + n);
    DEMminCbeg = max(1,DEMminC - n);
    DEMminCend = min(nC,DEMminC + n);
    nhood = DEM(DEMminRbeg:DEMminRend,DEMminCbeg:DEMminCend);
    nhood = nhood(~isnan(nhood));
    medhood = median(nhood);
    
    % test and change
    if abs(DEMmin - medhood) > k.*DEMstd
        DEM(DEMminI) = medhood;
        flag = 1;
    else
        flag = 0;
    end
    
    % get indices of neighborhood
    DEMmaxRbeg = max(1,DEMmaxR - n);
    DEMmaxRend = min(nR,DEMmaxR + n);
    DEMmaxCbeg = max(1,DEMmaxC - n);
    DEMmaxCend = min(nC,DEMmaxC + n);
    nhood = DEM(DEMmaxRbeg:DEMmaxRend,DEMmaxCbeg:DEMmaxCend);
    nhood = nhood(~isnan(nhood));
    medhood = median(nhood);
    
    % test and change
    if abs(DEMmax - medhood) > k.*DEMstd
        DEM(DEMmaxI) = medhood;
        flag = 1;
    else
        flag = 0;
    end
    

    
end

DEM2 = DEM;



