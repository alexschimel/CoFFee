function [fData] = CFF_mask_WC_data(fData,varargin)
%CFF_MASK_WC_DATA  Mask water-column data to remove unwanted samples
%
%   *INPUT VARIABLES*
%   * |fData|: Required. Structure for the storage of kongsberg EM series
%   multibeam data in a format more convenient for processing. The data is
%   recorded as fields coded "a_b_c" where "a" is a code indicating data
%   origing, "b" is a code indicating data dimensions, and "c" is the data
%   name. See the help of function CFF_convert_ALLdata_to_fData.m for
%   description of codes.
%   * |remove_angle|: Optional. Steering angle beyond which outer beams are
%   removed (in deg ref acoustic axis). Example: 55 -> angles>55 and <-55
%   are removed. Default: inf (all angles are conserved).
%   * |remove_closerange|: Optional. Range from sonar (in m) within which
%   samples are removed. Example: 4 -> all samples within 4m range from
%   sonar are removed. Default: 0 (all samples are conserved).
%   * |remove_bottomrange|: Optional. Range from bottom (in m) beyond which
%   samples are removed. Range after bottom if positive, before bottom if
%   negative. Example: 2 -> all samples 2m AFTER bottom detect and beyond
%   are removed. Example: -3 -> all samples 3m BEFORE bottom detect and beyond
%   are removed (therefore including bottom detect). Default: inf (all
%   samples are conserved).
%   * |mypolygon|: Optional. Horizontal polygon (in Easting, Northing
%   coordinates) outside of which samples are removed. Defualt: [] (all
%   samples are conserved).
%
%   *OUTPUT VARIABLES*
%   * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed"
%   now masked.
%
%   *DEVELOPMENT NOTES*
%   * check that masking uses filtered bottom if it exists, original bottom
%   if not.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% extract info about WCD
wcdata_Class  = fData.X_1_WaterColumnProcessed_Class; % int8 or int16
wcdata_Factor = fData.X_1_WaterColumnProcessed_Factor;
wcdata_Nanval = fData.X_1_WaterColumnProcessed_Nanval;

[nSamples, nBeams, nPings] = CFF_get_WC_size(fData);

% block processing setup
[blocks,info] = CFF_setup_optimized_block_processing(...
    nPings,nSamples*nBeams*4,...
    'desiredMaxMemFracToUse',0.1);

% block processing
for iB = 1:size(blocks,1)
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    
    % grab data in dB
    data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',blockPings,'output_format','true');
    
    % core processing
    data = CFF_mask_WC_data_CORE(data, fData, blockPings, varargin{:});
    
    % convert modified data back to raw format and store
    data = data./wcdata_Factor;
    data(isnan(data)) = wcdata_Nanval;
    fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = cast(data,wcdata_Class);
    
end



