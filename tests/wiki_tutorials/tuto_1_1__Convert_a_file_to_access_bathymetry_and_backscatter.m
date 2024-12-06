% This is a tutorial on how to use _CoFFee_ to convert a file to access bathymetry and backscatter data. Replace the paths appropriately.

% Start from a clean slate:
clear all
close all
restoredefaultpath();
clc

% Set location of _CoFFee_ code root folder and add to path:
coffeeFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee';
addpath(genpath(coffeeFolder));

% Set folder of raw data files:
dataFolder = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz';

% Get the first '.all' file in folder:
rawFile = CFF_list_raw_files_in_dir(dataFolder, 'filesType', '.all', 'nFilesWanted', 1);
rawFileName = CFF_file_name(char(rawFile));
CFF_print_raw_files_list(rawFile);

% Convert file:
fData = CFF_convert_raw_files(rawFile,'conversionType','seafloor',...
'forceReconvert',1);

% Access bathymetry and backscatter:
bathymetry = -fData.X8_BP_DepthZ; % in m
backscatter = fData.X8_BP_ReflectivityBS; % in dB

% Display:
figure; 

ax(1) = subplot(211);
imagesc(bathymetry); 
grid on; colorbar; colormap(ax(1),'jet');
xlabel('ping number'); ylabel('beam number'); title('bathymetry (m)');

ax(2) = subplot(212);
imagesc(backscatter); 
caxis([prctile(backscatter(:),10) prctile(backscatter(:),90)]);
grid on; colorbar; colormap(ax(2),'gray');
xlabel('ping number'); ylabel('beam number'); title('backscatter (dB)')

sgtitle(rawFileName ,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/8b3bf40d-0c12-488d-b7ff-294ff15073be" alt="tut1_fig1" width="800">
