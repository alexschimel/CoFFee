% This is a tutorial on how to use _CoFFee_ to georeference bathymetry and backscatter data. Replace the paths appropriately.

% Start from a clean slate:
clear all
close all
restoredefaultpath();
clc

% Set location of _CoFFee_ code root folder and add to path:
coffeeFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee';
addpath(genpath(coffeeFolder));

% Select a raw data file:
dataFolder = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz';
rawFile = CFF_list_raw_files_in_dir(dataFolder, 'filesType', '.all', 'nFilesWanted', 1);
rawFileName = CFF_file_name(char(rawFile));
CFF_print_raw_files_list(rawFile);

% Convert raw data file:
fData = CFF_convert_raw_files(rawFile,'conversionType','seafloor',...
'forceReconvert',1);

% Process navigation data with `CFF_compute_ping_navigation_v2`:
fData = CFF_compute_ping_navigation_v2(fData);

% Using `CFF_compute_ping_navigation_v2` without input parameters selected a default ellipsoid and projection for all future georeferencing:
ellipsoid = fData.MET_ellips;
projection = fData.MET_tmproj;

% Georeference all seafloor data with `CFF_georeference_bottom_detect`:
fData = CFF_georeference_bottom_detect(fData);

% Access bathymetry, backscatter, and the coordinates of the soundings:
bathymetry = -fData.X8_BP_DepthZ; % in m
backscatter = fData.X8_BP_ReflectivityBS; % in dB
easting = fData.X_BP_bottomEasting; % in m
northing = fData.X_BP_bottomNorthing; % in m

% Display:
figure; 

ax(1) = subplot(121);
scatter(easting(:), northing(:), 10, bathymetry(:),'filled'); 
grid on; axis equal; colorbar; colormap(ax(1),'jet');
xlabel('easting (m)'); ylabel('northing (m)'); title('bathymetry (m)');
CFF_nice_easting_northing(); % pretify the axes labels

ax(2) = subplot(122);
scatter(easting(:), northing(:), 10, backscatter(:),'filled'); 
caxis([prctile(backscatter(:),10) prctile(backscatter(:),90)]);
grid on; axis equal; colorbar; colormap(ax(2),'gray');
xlabel('easting (m)'); ylabel('northing (m)'); title('backscatter (dB)')
CFF_nice_easting_northing(); % pretify the axes labels

sgtitle(sprintf('%s\n(%s-%s)',rawFileName,ellipsoid,projection) ,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/6e24be6f-0b78-45b5-b1aa-cefbdac4b0da" alt="projected bathy and BS" width="800">
