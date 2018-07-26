function DODstats = CFF_DOD_analysis(DEM1,DEM2,polygon,stats_flag,display_flag)
% DODstats = CFF_DOD_analysis(DEM1,DEM2,polygon,stats_flag,display_flag)
%
% DESCRIPTION
%
% Read DEMs 1 and 2, clip them to polygon, compute DOD, calculate stats (if
% flagged), display DOD (if flagged).
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
% 2015-08-10: first time tag.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

% load DEM1 and DEM2
[Z1,Z1_easting,Z1_northing] = CFF_load_raster(DEM1);
[Z2,Z2_easting,Z2_northing] = CFF_load_raster(DEM2);

% load polygon and clip DEMs to polygon
if ~isempty(polygon)
    
    xv = polygon(:,1);
    yv = polygon(:,2);
    
    % clip grids to polygon
    [Z1,Z1_easting,Z1_northing] = CFF_clip_raster(Z1,Z1_easting,Z1_northing,xv,yv);
    [Z2,Z2_easting,Z2_northing] = CFF_clip_raster(Z2,Z2_easting,Z2_northing,xv,yv);
    
end

% coregister grids
[Z1,Z2,X,Y] = CFF_coregister_rasters(Z1,Z1_easting,Z1_northing,Z2,Z2_easting,Z2_northing);

% create dod from grids 
DOD = CFF_calculate_DOD(Z1,Z2);

% statistics
if stats_flag
    
    % get mean and standard deviation
    [DODstats.mean,DODstats.std] = CFF_nanstat3(DOD(:),1);
    
    % std is a good estimate of deviation around the mean, corresponding to
    % 68.2% of the population being between -1 sigma and +1sigma. But if the
    % population is heavily skewed, the standard deviation is much larger than
    % that. Use the invpercentile function to get a better estimate of
    % deviation. In our DOD, 68.2% of the population is contains within +- of:
    DODstats.perc68 = CFF_invpercentile(abs(DOD(:)),68);
    DODstats.perc99 = CFF_invpercentile(abs(DOD(:)),99);
    DODstats.perc999 = CFF_invpercentile(abs(DOD(:)),99.9);
    
    % get min and max and their location
    [DODstats.min,ind] = min(DOD(:));
    DODstats.minX = X(ind);
    DODstats.minY = Y(ind);
    
    [DODstats.max,ind] = max(DOD(:));
    DODstats.maxX = X(ind);
    DODstats.maxY = Y(ind);
    
    % range
    DODstats.range = DODstats.max - DODstats.min;
    
    % room for more
    ...
        
end

% display and print
if display_flag>0
    
    figure
    imagesc(X(1,:),Y(:,1),DOD);
    colormap jet
    colorbar
    set(gca,'YDir','default')
    alpha(double(~isnan(DOD)));
    grid on; axis equal
    hold on
    plot(DODstats.minX,DODstats.minY,'ko')
    plot(DODstats.maxX,DODstats.maxY,'k*')
    if display_flag>1
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf, 'PaperPosition', [0.25 0.25 12 8]);
        print('-dpng','-r1000','hist.png')
    end
    
    figure
    hist(DOD(:),500)
    set(gca,'YTick',[]);
    grid on
    if display_flag>1
        set(gcf, 'PaperPositionMode', 'manual');
        set(gcf, 'PaperUnits', 'centimeters');
        set(gcf, 'PaperPosition', [0.25 0.25 12 8]);
        print('-dpng','-r1000','hist.png')
    end
end