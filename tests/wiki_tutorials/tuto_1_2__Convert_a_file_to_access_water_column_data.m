% This is a tutorial on how to use _CoFFee_ to convert a file to access water-column data. Replace the paths appropriately.

% Start from a clean slate:
clear all
close all
restoredefaultpath();
clc

% Set location of _CoFFee_ code root folder and add to path:
coffeeFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee';
addpath(genpath(coffeeFolder));

% Set folder of raw data files.
% For Kongsberg data acquired in file pairs (i.e. *.all and *.wcd, or *.kmall and *.kmwcd), ensure the pair of files are in the same folder.
dataFolder = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz';

% Get the first *.all & *.wcd file pair in folder:
rawFile = CFF_list_raw_files_in_dir(dataFolder, 'filesType', '.all/.wcd', 'nFilesWanted', 1);
rawFileName = CFF_file_name(char(CFF_onerawfileonly(rawFile)));
CFF_print_raw_files_list(rawFile);

% Convert file, including water-column data:
fData = CFF_convert_raw_files(rawFile,'conversionType','WCD',...
'forceReconvert',1);

% Get water-column data:
iPing = 1;
WCD = CFF_get_WC_data(fData,'WC_SBP_SampleAmplitudes','iPing',iPing);

% Display:
figure; 

imagesc(WCD'); 
grid on; colorbar; colormap jet
xlabel('sample number'); ylabel('beam number');

titleStr = sprintf('%s water-column (dB), ping %i',rawFileName,iPing);
title(titleStr,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/c1cc7a4f-71ac-48c3-9c57-256549be73f2" alt="tut1_fig1" width="800">
