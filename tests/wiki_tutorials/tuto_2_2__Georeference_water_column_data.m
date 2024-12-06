% This is a tutorial on how to use _CoFFee_ to georeference water-column data. Replace the paths appropriately.

% Start from a clean slate:
clear all
close all
restoredefaultpath();
clc

% Set location of _CoFFee_ code root folder and add to path:
coffeeFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee';
addpath(genpath(coffeeFolder));

% Select a raw data file with water-column data and convert it.
% For Kongsberg data acquired in file pairs (i.e. *.all and *.wcd, or *.kmall and *.kmwcd), ensure the pair of files are in the same folder.
dataFolder = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz';
rawFile = CFF_list_raw_files_in_dir(dataFolder, 'filesType', '.all/.wcd', 'nFilesWanted', 1);
rawFileName = CFF_file_name(char(CFF_onerawfileonly(rawFile)));
fData = CFF_convert_raw_files(rawFile,'conversionType','WCD',...
'forceReconvert',1);

% Access water-column data:
iPing = 1;
WCD = CFF_get_WC_data(fData,'WC_SBP_SampleAmplitudes','iPing',iPing);

% At this stage, the water-column data is not yet georeferenced. We can only display it in its native format, aka as beam/sample:
figure; 

imagesc(WCD'); 
grid on; colorbar; colormap jet
xlabel('sample number'); ylabel('beam number');

titleStr = sprintf('%s water-column (dB), ping %i',rawFileName,iPing);
title(titleStr,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/57fce05e-1aa3-4abd-8d0c-13c900cd4a49" alt="beam/sample display" width="800">

% To calculate the coordinates of each water-column data sample in the swathe frame (that is, distances across and upwards), use `CFF_get_WCD_swathe_coordinates`:
nSamples = size(WCD,1);
[sampleAcrossDist,sampleUpDist] = CFF_get_WCD_swathe_coordinates(fData,iPing,nSamples);

% With this new information, we can display the water-column data as a wedge (or fan):
figure;

h = pcolor(sampleAcrossDist, sampleUpDist, WCD);
set(h,'AlphaData',~isnan(WCD),'facealpha','flat','LineStyle','none');
grid on; axis equal; colorbar; colormap jet
xlabel('across-track distance (m)'); ylabel('height above sonar (m)');

titleStr = sprintf('%s water-column (dB), ping %i',rawFileName,iPing);
title(titleStr,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/7a46eea9-1bee-4367-8704-93c478784eaf" alt="wedge display" width="800">

% To calculate the coordinates of each water-column data sample in the projected frame (that is, easting, northing, and height), we first need to process navigation data with `CFF_compute_ping_navigation_v2`:
fData = CFF_compute_ping_navigation_v2(fData);

% Using `CFF_compute_ping_navigation_v2` without input parameters selected a default ellipsoid and projection for all future georeferencing:
ellipsoid = fData.MET_ellips;
projection = fData.MET_tmproj;

% Then, the coordinates in the projected frame can be obtained using `CFF_get_WCD_projected_coordinates`:
[sampleEasting, sampleNorthing, sampleHeight] = CFF_get_WCD_projected_coordinates(fData,iPing,nSamples);

% With this new information, we can display the water-column data in "3D":
figure;

idxValidWCD = ~isnan(WCD);
h = scatter3(sampleEasting(idxValidWCD), sampleNorthing(idxValidWCD), sampleHeight(idxValidWCD), 10, WCD(idxValidWCD), 'filled');
grid on; axis equal; colorbar; colormap jet
xlabel('easting (m)'); ylabel('northing (m)'); ylabel('height (m)');
CFF_nice_easting_northing(); % pretify the axes labels

titleStr = sprintf('%s water-column (dB), ping %i\n(%s-%s)',rawFileName,iPing,ellipsoid,projection);
title(titleStr,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/770a9400-3c75-4f25-87cb-a7b69f54238e" alt="projected display" width="800">
