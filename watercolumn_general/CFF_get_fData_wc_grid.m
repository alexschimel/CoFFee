function data = CFF_get_fData_wc_grid(fData, field, d_lim_sonar_ref, d_lim_bottom_ref)
%CFF_GET_FDATA_WC_GRID  Get gridded data from fData.
%
%   If 3D grid, option possible to only take data within specified vertical
%   bounds.
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

if ~iscell(field)
    field = {field};
end

data = cell(1,numel(field));
L = cell(1,numel(field));

for ui = 1:numel(field)
    L{ui} = fData.(['X_NEH_' field{ui}]);
    if CFF_is_parallel_computing_available()
        if ~isa(L{ui},'gpuArray')
            % use GPU processing, turn arrays to gpuArrays
            L{ui} = gpuArray(L{ui});
        end
    else
        if isa(L{ui},'gpuArray')
            % not using GPU processing, turn gpuArrays to arrays
            L{ui} = gather(L{ui});
        end
    end
end

% in case WC data is in 3D, caculate 2D views depending on display controls
if size(L{1},3)>1
    
    switch fData.X_1_gridHeightReference
        
        case {'depth below sonar' 'Sonar'}
            
            d_max = 0;
            d_min = nanmin(fData.X_BP_bottomHeight(:));
            
            d_line_max = nanmin(d_lim_sonar_ref(2),d_max);
            d_line_min = nanmax(d_lim_sonar_ref(1),d_min);
            
            if ~any(~isnan(d_lim_sonar_ref))
                return;
            end
            
            idx_rem = (squeeze(fData.X_11H_gridHeight)+fData.X_1_gridVerticalResolution/2<d_line_min)|(squeeze(fData.X_11H_gridHeight)-fData.X_1_gridVerticalResolution/2>d_line_max);
            
        case {'height above bottom' 'Bottom'}
            
            d_max = nanmax(abs(nanmin(fData.X_BP_bottomHeight(:))));
            d_min = 0;
            
            if ~any(~isnan(d_lim_bottom_ref))
                return;
            end
            
            d_line_max = nanmin(d_lim_bottom_ref(2),d_max);
            d_line_min = nanmax(d_lim_bottom_ref(1),d_min);
            
            idx_rem = (squeeze(fData.X_11H_gridHeight)+fData.X_1_gridVerticalResolution/2<d_line_min)|(squeeze(fData.X_11H_gridHeight)-fData.X_1_gridVerticalResolution/2>d_line_max);
    end
    
    for ui = 1:numel(field)
        if ~all(idx_rem)
            L{ui}(:,:,idx_rem) = NaN;
            switch field{ui}
                case 'gridLevel'
                    data{ui} = 20*log10(nanmean(10.^(L{ui}(:,:,:)/20),3));
                case 'gridDensity'
                    data{ui} = nansum(L{ui}(:,:,:),3);
                case 'gridMaxHorizDist'
                    data{ui} = nanmax(L{ui}(:,:,:),[],3);
            end
        else
            [~,id_keep] = nanmin(abs(squeeze(fData.X_11H_gridHeight)-d_line_min));
            data{ui} = (L{ui}(:,:,id_keep));
        end
    end
    
else
    data = L;
end