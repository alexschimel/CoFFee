function CFF_beach_LOD_analysis(DEM1_file,DEM2_file,ref_polygon_file,main_polygon_file,main_line_file)
% CFF_beach_LOD_analysis(DEM1_file,DEM2_file,ref_polygon_file,main_polygon_file,main_line_file)
%
% DESCRIPTION
%
% DOD analysis of beach in warrnambool
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
% % for UAV Warrnambool paper
% Z1_file = '.\DATA\20140306_warrnambool_harbour_dsm.tif';
% Z2_file = '.\DATA\20140702_warrnambool_harbour_dsm.tif';
% ref_polygon_file = '.\DATA\Carpark_polygon_vertices.txt';
% main_polygon_file = '.\DATA\Beach_polygon_vertices.txt';
% main_line_file  = '.\DATA\Beach_line_vertices.txt';
% CFF_beach_LOD_analysis(Z1_file,Z2_file,ref_polygon_file,main_polygon_file,main_line_file)
%
%%%
% Alex Schimel, Deakin University
%%%


%% get reference polygon
[X,Y] = CFF_read_arcmap_table_XY(ref_polygon_file);
reference_polygon = [X,Y];

%% get main polygon
[X,Y]= CFF_read_arcmap_table_XY(main_polygon_file);
main_polygon = [X,Y];

%% create analysis polygons. set at 1m wide polygons 1m apart, 100m long, 1m offset
[X,Y]= CFF_read_arcmap_table_XY(main_line_file);
[analysis_polygons,vq] = CFF_create_polygons_along_line([X,Y],1,1,1,100,0);

%% load DEM1 and DEM2
[Z1,Z1_easting,Z1_northing] = CFF_load_raster(DEM1_file);
[Z2,Z2_easting,Z2_northing] = CFF_load_raster(DEM2_file);

%% get uncertainty from reference area
display_flag = 2; % 1 for figure, 2 for print
[tempmean,uncertainty,ref_DOD,ref_X,ref_Y] = CFF_reference_DOD_analysis({Z1_easting,Z1_northing,Z1},{Z2_easting,Z2_northing,Z2},reference_polygon,display_flag);

%% clip data to main polygon

% get polygons vertices:
xv = main_polygon(:,1);
yv = main_polygon(:,2);

% clip grids to polygon
[Z1,X1,Y1] = CFF_clip_raster(Z1,Z1_easting,Z1_northing,xv,yv);
[Z2,X2,Y2] = CFF_clip_raster(Z2,Z2_easting,Z2_northing,xv,yv);

% coregister grids
[Z1,Z2,X,Y] = CFF_coregister_rasters(Z1,X1,Y1,Z2,X2,Y2);

%% multiple LOD analysis on main polygon
beachface_sigmafactor = [0:0.1:5];
display_flag = 2;
beachface_volumes = CFF_LOD_analysis({X,Y,Z1},{X,Y,Z2},[],uncertainty,beachface_sigmafactor,'sum',display_flag);
beachface_threshold = beachface_sigmafactor.*uncertainty;

% in particular, beachface volumes for LoD = 0 and loD = uncertainty can be
% retrieved with:
beachface_volumes(1);
beachface_volumes(11);

%% single LOD analysis on multiple polygons
factor = 1; % or 1 or 2?
display_flag = 0;
for ii = 1:length(analysis_polygons)
    analysis_volumes(ii) = CFF_LOD_analysis({X,Y,Z1},{X,Y,Z2},analysis_polygons{ii},uncertainty,factor,'sum',display_flag);
end

%% figure for volume eroded per m of beach
figure;
yaxisvalues = vq(:,2) - min(vq(:,2));
plot(abs([analysis_volumes(:).volumeEroded]),yaxisvalues,'k')
grid on
xlabel('volume eroded (m3) per m of beach')
ylim([0 max(yaxisvalues)])

set(gcf, 'PaperPositionMode', 'manual');
set(gcf, 'PaperUnits', 'centimeters');
set(gcf, 'PaperPosition', [0.25 0.25 5 15]);
print('-dpng','-r600','eroded.png')





