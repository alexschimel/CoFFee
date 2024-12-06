% This is a tutorial on how to use _CoFFee_ to stack water-column data in range, depth or fan. Replace the paths appropriately.

% # 1. Introduction

% Water-column data for more than 1 ping has three dimensions (pings, beams, samples), which is difficult to visualize. _Stacking_ is the process of reducing this dimensionality to only 2 dimensions, which induces some ambiguity but is easier to visualize.

% * Stacking in **range** reduces the dimensionality to a **Range-by-Ping** array.
% * Stacking in **depth** reduces the dimensionality to a **Depth-by-Ping** array.
% * Stacking in **fan** reduces the dimensionality to an **Across-distance-by-Depth** array (that is, wedge display).

% In _CoFFee_, you can use `CFF_stack_WCD` to operate these three stacking operations.

% Note that vertical echo-integration is also effectively a stacking process (that is, displaying the data as an Easting-by-Northing array) but is not operated by this function, nor covered in this tutorial.

% # 2. Data preparation

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

% To use `CFF_stack_WCD`, it is necessary to first process the navigation and georeference the bottom detect:
fData = CFF_compute_ping_navigation_v2(fData,'comms','multilines');
fData = CFF_georeference_bottom_detect(fData,'comms','multilines');

% # 3. Stack in range

% To use `CFF_stack_WCD`, first create a structure defining the desired parameters. For example, to stack in range only the pings 20 to 120, create a structure `params` as:
params = struct();
params.stackMode = 'range'; % this is the default mode so this could be omitted
params.iPingLims = [20,120]; % to specify all pings use [1,inf] (or do not specify this parameter at all)

% Other parameters are available, such as specifying the range of beam numbers and sample numbers with `iBeamLims` and `iSampleLims`, respectively.

% Then you can call `CFF_stack_WCD`, specifying `params` as parameters:
[rangeStack,rangeStackX,rangeStackY] = CFF_stack_WCD(fData,params,'comms','multilines');

% The function returned the stack array and the vectors for the axes. With this new information, we can display the stack in range:
figure; 
imagesc(rangeStackX,rangeStackY,rangeStack); 
grid on; colorbar; colormap jet
xlabel('ping #'); ylabel('range from sonar (m)');
titleStr = sprintf('%s water-column (dB)\npings %i-%i (stacked in %s)',rawFileName,params.iPingLims(1),params.iPingLims(2),params.stackMode);
title(titleStr,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/f398b550-82b2-4d03-99b5-7bebe687bb0d" alt="water-column data stacked in range" width="800">

% # 4. Stack in depth

% For stacking in depth, set `stackMode` to `'depth'`. You can also specify a desired depth resolution with `resDepthStackY`:
params = struct();
params.stackMode = 'depth';
params.iPingLims = [20,120];
params.resDepthStackY = 0.01; % in m
[depthStack,depthStackX,depthStackY] = CFF_stack_WCD(fData,params,'comms','multilines');

% With this new information, we can display the stack in depth:
figure; 
imagesc(depthStackX,depthStackY,depthStack,'AlphaData',~isnan(depthStack)); 
grid on; colorbar; colormap jet
xlabel('ping #'); ylabel('depth below sonar (m)');
titleStr = sprintf('%s water-column (dB)\npings %i-%i (stacked in %s)',rawFileName,params.iPingLims(1),params.iPingLims(2),params.stackMode);
title(titleStr,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/83824b3f-e18e-4fa2-b046-c6df5a505980" alt="water-column data stacked in depth" width="800">

% # 5. Stack in fan

% For stacking in fan, set `stackMode` to `'fan'`. You can also specify a desired resolution with `resFanStack`:
params = struct();
params.stackMode = 'fan';
params.iPingLims = [20,120];
params.resFanStack = 0.05; % in m
[fanStack,fanStackX,fanStackY] = CFF_stack_WCD(fData,params,'comms','multilines');

% With this new information, we can display the stack in fan:
figure; 
imagesc(fanStackX,fanStackY,fanStack,'AlphaData',~isnan(fanStack)); 
grid on; colorbar; axis equal; colormap jet
xlabel('across distance (m)'); ylabel('depth below sonar (m)');
titleStr = sprintf('%s water-column (dB)\npings %i-%i (stacked in %s)',rawFileName,params.iPingLims(1),params.iPingLims(2),params.stackMode);
title(titleStr,'Interpreter','none');

% <img src="https://github.com/alexschimel/CoFFee/assets/8197102/32d44664-84c8-47fb-a812-20de18686daa" alt="water-column data stacked in fan" width="800">

% # 6. `CFF_stack_WCD` parameters

% The complete list of parameters available to `CFF_stack_WCD` is as follows:

% | Parameter | Description |
% | ------------- | ------------- |
% | `'stackMode'` | String code for the mode of stacking. Possible values are `'range'` (default), `'depth'`, or `'fan'`. When `stackMode` is set to `'depth'`, the resolution in the Y-dimension (depths) is equal to twice the inter-sample distance (see the param field `resDepthStackY` to modify this default behaviour). When `stackMode` is set to `'fan'`, the resolution in both the X-dimension (across-track distance) and Y-dimension (depth) is equal to the distance between two beams at the max depth (see the param field `resFanStack` to modify this default behaviour). |
% | `'dataField'` | Name of the fData field to use as the (memmaped file) WCD data to stack. Default is `'WC_SBP_SampleAmplitudes'`. |
% | `'angleDegLims'` | Two-values vector of beam angles (in degrees) to which the stacking is to be limited. Default is `[-inf,inf]` to conserve all beam angles. |
% | `'minStackY'` | Starting value for the stack's Y-dimension, aka minimum range (for range-stacking) or minimum depth (for depth-stacking and fan-stacking). Must be `0` (default, i.e. stacking starts at sonar face) or positive. |
% | `'maxStackY'` | End value for the stack's Y-dimension. Must be `0` (default) or positive. The value `0` (default) is a special code to indicate stacking is to go as far as the deepest bottom-detect in the data. Use the value `inf` to stack as far as data goes. |
% | `'resDepthStackY'` | Desired depth resolution when depth-stacking. Must be `0` (default) or positive. The value `0` (default) is a special code to indicate the default resolution (see previously for default value). This parameter is ignored in other stacking modes. |
% | `'resFanStack'` | Desired resolution in depth and across-track distance when fan-stacking. Must be `0` (default) or positive. The value `0` (default) is a special code to indicate the default resolution (see previously for default value). This parameter is ignored in other stacking modes. |
% | `'iPingLims'` | Two-values vector of the indices of pings to which the stacking is to be limited. Default is `[1,inf]` to conserve all pings. If requested values are outside the range available in the data, the function will automatically adjust them. |
% | `'iBeamLims'` | Two-values vector of the indices of beams to which the stacking is to be limited. Default is `[1,inf]` to conserve all beams. Note that this parameter does not over-ride the parameter `angleDegLims`. Instead, both parameters are taken into account to limit beam contributions to the stack. |
% | `'iSampleLims'` | Two-values vector of the indices of samples to which the stacking is to be limited. Default is `[1,inf]` to conserve all samples. Note that this parameter does not over-ride the parameters `minStackY` and `maxStackY`. Instead, all three parameters are taken into account to limit sample contributions to the stack. |
