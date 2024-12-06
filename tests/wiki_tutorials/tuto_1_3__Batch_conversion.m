% This is a tutorial on how to use _CoFFee_ to batch-convert several files. Replace the paths appropriately.

% Start from a clean slate:
clear all
close all
restoredefaultpath();
clc

% Set location of _CoFFee_ code root folder and add to path:
coffeeFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee';
addpath(genpath(coffeeFolder));

% Use `CFF_list_raw_files_in_dir` to create a list of raw data files for conversion. It is a versatile function with a few useful parameters. Previous tutorials already covered how to:
% * Choose the file formats to search for (e.g. `'.all'`, `'.wcd'`, `'.kmall'`, `'.kmwcd'`, `'.s7k'`). To list pairs of files in the Kongsberg formats, use `'.all/.wcd'` or `'.kmall/.kmwcd'`. By default, the function searches for all of those, and pair all pairable files (if they are in the same folder).
% * Specify the number of files to get from the folder (e.g. `'nFilesWanted', 1`).

% Another useful option is to search recursively in subfolders. By default, `CFF_list_raw_files_in_dir` is NOT recursive, i.e. it does not look into subfolders. Set the `recursiveSearch` parameter to `true` to search `dataFolder` recursively:
dataFolder = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study';
rawFilesList = CFF_list_raw_files_in_dir(dataFolder,'recursiveSearch',true,'filesType','.all/.wcd');
CFF_print_raw_files_list(rawFilesList);

% ![image](https://github.com/alexschimel/CoFFee/assets/8197102/b05fba2c-1b5b-42e2-a8fa-f8b6d8f5f2ad)

% For this tutorial, we will use a larger set of larger set of .all files:
dataFolder = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM710\KV-FOSAE-2015_EM710_BH03_extracts';
rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.all');
CFF_print_raw_files_list(rawFilesList);

% ![image](https://github.com/alexschimel/CoFFee/assets/8197102/abc796ea-faf9-4ee8-aa16-99669c81ad91)

% Batch-convert the first three files. Use the `comms` parameters to follow progress:
fDataGroup = CFF_convert_raw_files(rawFilesList(1:3),'conversionType','seafloor',...
'comms','multilines');

% ![image](https://github.com/alexschimel/CoFFee/assets/8197102/bbf0452f-261c-45a2-a999-e969e525d4a1)

% This command converted data from the first three files and returned the converted data as output. This is not a great solution for large datasets because conversion can take a while and loading all converted data can overfill the memory available. For a large dataset, you may find it preferable to first "batch-convert-and-save" the data (clearing the memory after each conversion), and later load the converted data you need. 

% You can modify the parameters of `CFF_convert_raw_files` to do the batch-convert-and-save step:
CFF_convert_raw_files(rawFilesList,'conversionType','seafloor',...
'saveFDataToDrive', 1, ...
'outputFData', 0, ... 
'comms','multilines');

% ![image](https://github.com/alexschimel/CoFFee/assets/8197102/70eb353f-6dcd-4836-9b3f-3efd360f9a03)

% And then use `CFF_load_converted_files` to load a smaller subset of converted data:
fDataGroup = CFF_load_converted_files(rawFilesList(1:3), ...
'comms','multilines');

% ![image](https://github.com/alexschimel/CoFFee/assets/8197102/fc554b51-c6c1-4457-8b60-0bcf4f947b61)
