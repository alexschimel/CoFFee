%% CFF_initialize_WC_processing.m
%
% Initialize (or re-initialize) a fData structure for water-column data
% processing. 
%
%% Help
%
% *USE*
%
% fData = CFF_initialize_WC_processing(fData,'fast') copies the original
% data binary file ('WC_SBP_SamplesAmplitude.dat') as a processed data
% binary file ('X_SBP_WaterColumnProcessed.dat') and memmap this file as
% field fData.X_SBP_WaterColumnProcessed. If X_SBP_WaterColumnProcessed.dat
% exists and is compatible, it is simply repurposed.
%
% Now the issue is that the original data may be in a low-resolution format
% (e.g. watercolumn data at 0.5dB resolution, recorded as int8) while the
% result of processing might be higher resolution and need recording on 4
% bits. So the process above will quantize the result. For a more precise
% output that conserves the full resolution of processed data, use
% fData = CFF_initialize_WC_processing(fData,'precise') but be aware it
% will take more disk space and be slower to use.
%
% *INPUT VARIABLES*
%
% * |fData|: Required. Structure for the storage of kongsberg EM series
% multibeam data in a format more convenient for processing. The data is
% recorded as fields coded "a_b_c" where "a" is a code indicating data
% origing, "b" is a code indicating data dimensions, and "c" is the data
% name. See the help of function CFF_convert_ALLdata_to_fData.m for
% description of codes. 
% * |method|: 'fast' (default) or 'precise'
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed"
% field that memmaps the processed data binary file.
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._ 
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * 2018-10-11: updated header before adding to Coffee v3
% * 2018-10-08: first version inspired from Yoann's Espresso code.
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._ 
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Yoann Ladroit, NIWA.


%% Function
function [fData] = CFF_initialize_WC_processing(fData,varargin)



%% input parsing

% init
p = inputParser;

% required
addRequired(p,'fData',@isstruct);

% optional
% if method = fast, processed data will be recorded at input resolution,
% that is with the same degree of quantification (0.5dB precision). If
% method = precise, processed data will be recorded in single, allowing for
% full resolution of the data processing.
addOptional(p,'method','fast',@(x) ischar(x) && ismember(x,{'fast' 'precise'}));

% parse
parse(p,fData,varargin{:})

% get results
method = p.Results.method;
clear p


%% Source datagram and WC data format
datagramSource = fData.MET_datagramSource;

%% processed data folder
wc_dir = CFF_converted_data_folder(fData.ALLfilename{1});

%% Info about original data
wcdata_class = fData.(sprintf('%s_1_SampleAmplitudes_Class',datagramSource)); % int8 or int16
wcdata_factor = fData.(sprintf('%s_1_SampleAmplitudes_Factor',datagramSource));
wcdata_nanval = fData.(sprintf('%s_1_SampleAmplitudes_Nanval',datagramSource));
[nSamples, nBeams, nPings] = size(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val);
file_X_SBP_WaterColumnRaw  = fullfile(wc_dir,sprintf('%s_SBP_SampleAmplitudes.dat',datagramSource));

%% Info about processed data
file_X_SBP_WaterColumnProcessed  = fullfile(wc_dir,'X_SBP_WaterColumnProcessed.dat');


switch method
    
    case 'fast'
        % initialization is simpler - just copy original data
        
        % Do the job differently if processed data already exist and in the right format
        if exist(file_X_SBP_WaterColumnProcessed,'file') && ...
                isfield(fData,'X_SBP_WaterColumnProcessed') && ...
                all(size(fData.X_SBP_WaterColumnProcessed.Data.val)==[nSamples,nBeams,nPings]) && ...
                strcmp(fData.X_1_WaterColumnProcessed_Class,wcdata_class)
            
            % Processed data file exists and is reuseable. Re-initialize
            
            % Re-initialize the array as the original data
            fData.X_SBP_WaterColumnProcessed.Data.val  = fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val;
            
        else
            
            % Processed data file doesn't exist yet or incorrectly mapped
            % or wrong size, then redo from scratch, aka copying the
            % original data file
            if isfield(fData,'X_SBP_WaterColumnProcessed')
                fData = rmfield(fData,'X_SBP_WaterColumnProcessed');
            end
            if exist(file_X_SBP_WaterColumnProcessed,'file')
                delete(file_X_SBP_WaterColumnProcessed);
            end
            
            % copy original data file as processed data file
            copyfile(file_X_SBP_WaterColumnRaw,file_X_SBP_WaterColumnProcessed);
            
            % add to fData as memmapfile
            fData.X_SBP_WaterColumnProcessed = memmapfile(file_X_SBP_WaterColumnProcessed, 'Format',{wcdata_class [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
        end
        
        % and record same info as original
        fData.X_1_WaterColumnProcessed_Class  = wcdata_class;
        fData.X_1_WaterColumnProcessed_Factor = wcdata_factor;
        fData.X_1_WaterColumnProcessed_Nanval = wcdata_nanval;
        
    case 'precise'
        % initialization is more difficult as we can't just copy original data
        
        wcdataproc_class   = 'single';
        wcdataproc_factor  = 1;
        wcdataproc_nanval  = NaN;
        
        % Still, do the job differently if processed data already exist and in the right format
        if exist(file_X_SBP_WaterColumnProcessed,'file') && ...
                isfield(fData,'X_SBP_WaterColumnProcessed') && ...
                all(size(fData.X_SBP_WaterColumnProcessed.Data.val)==[nSamples,nBeams,nPings]) && ...
                strcmp(fData.X_1_WaterColumnProcessed_Class,wcdataproc_class)
            
            % Processed data file exists and is reuseable. Re-initialize
            
            %% Block processing
            
            % main computation section will be done in blocks
            blockLength = 50;
            nBlocks = ceil(nPings./blockLength);
            blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
            blocks(end) = nPings;
            
            for iB = 1:nBlocks
                
                % list of pings in this block
                blockPings  = (blocks(iB,1):blocks(iB,2));
                
                % get original data in true values
                data = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),blockPings,1,1,'true');
                
                % Add to processed
                fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = data;
                
            end
            
            
        else
            
            % heavy duty one: create the binary file from scratch
            if exist(file_X_SBP_WaterColumnProcessed,'file')
                if isfield(fData,'X_SBP_WaterColumnProcessed')
                    fData = rmfield(fData,'X_SBP_WaterColumnProcessed');
                end
                delete(file_X_SBP_WaterColumnProcessed);
            end
            
            % open
            fid = fopen(file_X_SBP_WaterColumnProcessed,'w+');
            
            %% Block processing
            
            % main computation section will be done in blocks
            blockLength = 50;
            nBlocks = ceil(nPings./blockLength);
            blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
            blocks(end) = nPings;
            
            for iB = 1:nBlocks
                
                % list of pings in this block
                blockPings  = (blocks(iB,1):blocks(iB,2));
                
                % get original data in true values
                data = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),blockPings,1,1,'true');
                
                % write
                fwrite(fid,data,wcdataproc_class);
                
            end
            
            % close
            fclose(fid);
            
            % add to fData as memmapfile
            fData.X_SBP_WaterColumnProcessed = memmapfile(file_X_SBP_WaterColumnProcessed, 'Format',{wcdataproc_class [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
        end
        
        % and record info
        fData.X_1_WaterColumnProcessed_Class  = wcdataproc_class;
        fData.X_1_WaterColumnProcessed_Factor = wcdataproc_factor;
        fData.X_1_WaterColumnProcessed_Nanval = wcdataproc_nanval;
        
end
