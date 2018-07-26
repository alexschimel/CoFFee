function transect = CFF_DEM_transect(DEMs,lines,resolution,display_flag)
% transect = CFF_DEM_transect(DEMs,lines,resolution,display_flag)
%
% DESCRIPTION
%
% use as template for a new function
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
% YYYY-MM-DD: second version.
% YYYY-MM-DD: first version.
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%

% number of rasters in input
nDEMs = CFF_num_rasters(DEMs);

% number of lines in input
if ~iscell(lines)
    nLines = 1;
else
    nLines = length(lines);
end

clear transect
for ii = 1:nDEMs
    
    % load DEM
    if nDEMs==1
        [Z,X,Y] = CFF_load_raster(DEMs);
    else
        [Z,X,Y] = CFF_load_raster(DEMs{ii});
    end
    
    for jj = 1:nLines
        
        % load line
        if nLines==1
            pline = lines;
        else
            pline = lines{jj};
        end
        
        % distance of each line vertex along line
        lineprev = [pline(1,:); pline(1:end-1,:)];
        dist = cumsum(sqrt(sum((pline-lineprev).^2,2)));
        
        % distance along line of the center of future polygons
        offset = 0;
        interval = 0.1;
        distwanted = [offset:interval:dist(end)];
        
        % XY desired
        xq = interp1(dist,pline(:,1),distwanted);
        yq = interp1(dist,pline(:,2),distwanted);
        
        % extract the DEM values from the line points
        zq = interp2(X,Y,Z,xq,yq);
        
        % get min and max distance where there actually is data (for
        % possible zoom-in)
        mindist = min(distwanted(~(isnan(zq))));
        maxdist = max(distwanted(~(isnan(zq))));
        
        % save per line and per DEM:
        transect(ii,jj).xq = xq;
        transect(ii,jj).yq = yq;
        transect(ii,jj).zq = zq;
        transect(ii,jj).distwanted = distwanted;
        transect(ii,jj).mindist = mindist;
        transect(ii,jj).maxdist = maxdist;
        
    end
    
end

if display_flag>0
    
    % make a figure for each line:
    for jj = 1:nLines
        
        figure
        
        % draw on that figure for each DEM
        for ii = 1:nDEMs
            p{ii} = plot( transect(ii,jj).distwanted - transect(ii,jj).mindist , transect(ii,jj).zq );
            hold on
        end
        
        % line settings for four time series, in grey scale
        if nDEMs==4
            p{1}.Color = [0.8 0.8 0.8];
            p{2}.Color = [0.59 0.59 0.59];
            p{3}.Color = [0.32 0.32 0.32];
            p{4}.Color = [0 0 0];
            p{1}.LineWidth = 1.5;
            p{2}.LineWidth = 1.5;
            p{3}.LineWidth = 1.5;
            p{4}.LineWidth = 1.5;
            p{1}.LineStyle = '-';
            p{2}.LineStyle = '--';
            p{3}.LineStyle = '-';
            p{4}.LineStyle = '--';
        end
 
        grid on
        xlabel('distance from western edge of transect (m)')
        ylabel('Height (m)')
        axis tight
        legend('show')
        
        if display_flag>1
            set(gcf, 'PaperPositionMode', 'manual');
            set(gcf, 'PaperUnits', 'centimeters');
            set(gcf, 'PaperPosition', [0.25 0.25 40 10]);
            CFF_nice_easting_northing(5)
            print('-dpng','-r600','transect.png')
        end
        
    end
    
end
