function volumes = CFF_LOD_analysis(DEM1,DEM2,polygon,uncertainty,factors,volume_uncertainty_method,displayStruct)
% volumes = CFF_LOD_analysis(DEM1,DEM2,polygon,uncertainty,factors,volume_uncertainty_method,displayStruct)
%
% DESCRIPTION
%
% compute DOD volumes using Limit of Detection analysis.
%
% USE
%
% ...
%
% PROCESSING SUMMARY
%
% INPUT VARIABLES
%
% - Z1, Z2: input DSMs. Can be file names to be loaded or data as, cells,
% structures or 3D arrays. See CFF_load_raster for more info.
% - polygon: vertices of the polygon to constrain the analysis to. If empty
% (polygon = []), the whole DSMs are used.
% - uncertainty: single value to be used or a cell of two DEMs as Z1 and Z2
% - factors: the factors of uncertainty to be used as LOD in volume
% calculations. Possible to use 0 to prevent use of LOD and use all data
% instead. Use 1 to use the uncertainty value as LOD. Use vectors (eg
% [0:0.1:3] to produce multi LOD analysis
%
% OUTPUT VARIABLES
%
% - volumes
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% 2017-08-23: accepting shapefiles as polygon (not tested) (Alex Schimel)
% 2015-03-10: first version.
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%

% load DEM1 and DEM2
[Z1,Z1_easting,Z1_northing] = CFF_load_raster(DEM1);
[Z2,Z2_easting,Z2_northing] = CFF_load_raster(DEM2);

% load polygon and clip DEMs to polygon
if ~isempty(polygon)
    
    if isnumeric(polygon)
        % polygon is a numerical array of vertices:
        xv = polygon(:,1);
        yv = polygon(:,2);
        
    elseif ischar(polygon)
        % now accepting shapefiles
        
        P = shaperead(polygon); % needs mapping toolbox
        c = length(P); % number of polygons
        xpoly = cell(c,1); % preallocating
        ypoly = cell(c,1); % preallocating
        for ii= 1:c
            xpoly{ii,1} = P(ii).X;
            ypoly{ii,1} = P(ii).Y;
        end
        
        xv = xpoly{1}';
        xv(isnan(xv)) = [];
        xv(end)=[];
        yv = ypoly{1}';
        yv(isnan(yv)) = [];
        yv(end)=[];
        
    end
    
    % clip grids to polygon
    [Z1,Z1_easting,Z1_northing] = CFF_clip_raster(Z1,Z1_easting,Z1_northing,xv,yv);
    [Z2,Z2_easting,Z2_northing] = CFF_clip_raster(Z2,Z2_easting,Z2_northing,xv,yv);
    
end

% co-register grids
[Z1,Z2,X,Y] = CFF_coregister_rasters(Z1,Z1_easting,Z1_northing,Z2,Z2_easting,Z2_northing);

% create dod
DOD = CFF_calculate_DOD(Z1,Z2);

% load and deal with uncertainty
if isnumeric(uncertainty) && all(size(uncertainty))==1
    % single, constant uncertainty value taken as the DOD uncertainty.
    
    % save as UNC for volume computations
    UNC = uncertainty;
    
elseif iscell(uncertainty) && max(size(uncertainty))==2
    % cell array of two things. To be loaded as rasters and combined as DPU
    
    % load
    [U1,U1_easting,U1_northing] = CFF_load_raster(uncertainty{1});
    [U2,U2_easting,U2_northing] = CFF_load_raster(uncertainty{2});
    
    % clip to polygon
    if ~isempty(polygon)
        
        xv = polygon(:,1);
        yv = polygon(:,2);
        
        % clip grids to polygon
        [U1,U1_easting,U1_northing] = CFF_clip_raster(U1,U1_easting,U1_northing,xv,yv);
        [U2,U2_easting,U2_northing] = CFF_clip_raster(U2,U2_easting,U2_northing,xv,yv);
        
    end
    
    % co-register grids
    [U1,U2,UX,UY] = CFF_coregister_rasters(U1,U1_easting,U1_northing,U2,U2_easting,U2_northing);
    
    % compute DPU
    DPU = CFF_calculate_DPU(U1,U2);
    
    % coregister DOD and DPU
    [DOD,DPU,X,Y] = CFF_coregister_rasters(DOD,X,Y,DPU,UX,UY);
    
    % save as UNC for volume computations
    UNC = DPU;
    
end

% get Limit of Detection from uncertainty and input factor and calculate
% volumes for all LoDs.
clear volumes
for i = 1:length(factors)
    LOD = factors(i).*UNC;
    volumes(i) = CFF_LOD_volumes(DOD,X,Y,LOD,UNC);
end

% display
if displayStruct(1).display
    
    volumeNetChange = [volumes(:).volumeNetChange];
    volumeEroded = [volumes(:).volumeEroded];
    volumeDeposited = [volumes(:).volumeDeposited];
    
    switch volume_uncertainty_method
        case 'sum'
            % choose uncertainty as sum:
            uncertaintyVolumeEroded = [volumes(:).uncertaintyVolumeEroded_sum];
            uncertaintyVolumeDeposited = [volumes(:).uncertaintyVolumeDeposited_sum];
        case 'propagated'
            % or propagated:
            uncertaintyVolumeEroded = [volumes(:).uncertaintyVolumeEroded_propagated];
            uncertaintyVolumeDeposited = [volumes(:).uncertaintyVolumeDeposited_propagated];
    end
    
    areaEroded = [volumes(:).areaEroded];
    areaDeposited = [volumes(:).areaDeposited];
    areaTotalChange = [volumes(:).areaTotalChange];
    areaTotal = [volumes(:).areaTotal];
    
    figure;
    
    plot(factors, volumeDeposited, 'Color',[0.4 0.4 0.4],'LineWidth',1)
    hold on
    %plot(factors, volumeNetChange, 'Color',[0 0 0],'LineWidth',1)
    plot(factors, volumeEroded,    'Color',[0.7 0.7 0.7],'LineWidth',1)
    legend('deposition','erosion')
    %legend('deposition','net','erosion')
    
    % erosion uncertainty
    plot(factors, volumeEroded - uncertaintyVolumeEroded,'--','Color',[0.7 0.7 0.7],'LineWidth',1)
    uncertaintyVolumeEroded(volumeEroded + uncertaintyVolumeEroded > 0) = NaN;
    plot(factors, volumeEroded + uncertaintyVolumeEroded,'--','Color',[0.7 0.7 0.7],'LineWidth',1)
    
    % deposition uncertainty
    plot(factors,volumeDeposited + uncertaintyVolumeDeposited,'--','Color',[0.4 0.4 0.4],'LineWidth',1)
    uncertaintyVolumeDeposited(volumeDeposited - uncertaintyVolumeDeposited < 0) = NaN;
    plot(factors,volumeDeposited - uncertaintyVolumeDeposited,'--','Color',[0.4 0.4 0.4],'LineWidth',1)
    
    % max value + uncertainty
    vmax = max([max(abs(volumeEroded-uncertaintyVolumeEroded)), max(abs(volumeDeposited+uncertaintyVolumeDeposited))]);
    
    % plot the value at k=1?
    % stem([1,1],[-vmax,vmax],'k.','LineWidth',1)
    % stem([1.96,1.96],[-vmax,vmax],'k.','LineWidth',1)

    grid on
    xlabel('threshold factor k')
    ylabel('erosion (m^3)                     deposition (m^3)')
    ylim([-vmax vmax])
    xlim([min(factors) max(factors)])
    
    if displayStruct(1).print
        
         % adjust font size first
        set(gca, 'FontSize',displayStruct(1).fontSize)
        
        % then the window position and size
        set(gcf, 'Units', 'centimeters');
        pos = get(gcf, 'Position');
        set(gcf, 'Position', [pos(1) pos(2) displayStruct(1).size]);
        
        % make the print position and size the same
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf, 'PaperPosition', [0.1 0.1 displayStruct(1).size]);
        
        % get nice tick labels
        CFF_nice_easting_northing(5)
        
        % finally print
        print(['-d' displayStruct(1).format],['-r' displayStruct(1).resolution],[displayStruct(1).filename '.' displayStruct(1).format])

    end

end


