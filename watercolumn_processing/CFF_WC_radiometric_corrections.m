function [fData] = CFF_WC_radiometric_corrections(fData)
%CFF_WC_RADIOMETRIC_CORRECTIONS  One-line description
%
%   Apply physical (aka, not aestethic ones) corrections to the dB level in
%   water-column data: TVG, dB offset, etc.
%
%   *INPUT VARIABLES*
%   * |fData|: Required. Structure for the storage of kongsberg EM series
%   multibeam data in a format more convenient for processing. The data is
%   recorded as fields coded "a_b_c" where "a" is a code indicating data
%   origing, "b" is a code indicating data dimensions, and "c" is the data
%   name. See the help of function CFF_convert_ALLdata_to_fData.m for
%   description of codes.
%
%   *OUTPUT VARIABLES*
%   * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed"
%   now radiometrically corrected
%
%   *DEVELOPMENT NOTES*
%   Just started this function to integrate the "transmit power re maximum"
%   dB offset that is stored in Runtime Parameters (marine mammal
%   protection modes I think). But ideally develop this function for future
%   compensations of TVG, pulse length, etc.

%   Copyright 2017-2019 Alexandre Schimel
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
    data = CFF_WC_radiometric_corrections_CORE(data,fData);
    
    % convert modified data back to raw format and store
    data = data./wcdata_Factor;
    data(isnan(data)) = wcdata_Nanval;
    fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = cast(data,wcdata_Class);
    
end

