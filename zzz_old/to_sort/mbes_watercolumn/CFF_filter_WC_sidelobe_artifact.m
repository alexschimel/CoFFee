function [fData] = CFF_filter_WC_sidelobe_artifact(fData,varargin)
% CFF_filter_WC_sidelobe_artifact.m
%
% Filter the water column specular/sidelobe artifact
%
% *INPUT VARIABLES*
%
% * |fData|: Required. Structure for the storage of kongsberg EM series
% multibeam data in a format more convenient for processing. The data is
% recorded as fields coded "a_b_c" where "a" is a code indicating data
% origing, "b" is a code indicating data dimensions, and "c" is the data
% name. See the help of function CFF_convert_ALLdata_to_fData.m for
% description of codes. 
% * |method_spec|: Optional/Parameters. Method for removal of specular
% reflection. Default: 2
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed" now
% filtered.
%
% *DEVELOPMENT NOTES*
%
% * IMPORTANT: only method 2 has been updated. All other methods don't
% work. to update XXX.
% * dataset have three dimensions: ping #, beam # and sample #. Calculating
% the average backcatter level across samples, would allow 
% us to spot the beams that have constantly higher or lower energy in a
% given ping. Doing this only for samples in the watercolumn would allow us
% to normalize the energy in the watercolumn of a ping. Calculating the
% average backcatter across all beams would allow 
% us to spot the samples that have constantly higher or lower energy in a
% given ping.
% * the circular artifact on the bottom is due to specular reflection
% affecting all beams.
% -> remove in each ping by averaging the level at a given range across
% all beams.
% -> working on several pings at a time would work if the responsible
% reflectors are present on successive pings. They also need to stay at the
% same range so that would need some form of heave compensation. For heave
% compensation, maybe use the mean calculated on each ping and line up the
% highest return (specular).
%
% now when the specular artefacts are gone, what of the level being uneven
% across the swath in the water column? A higher level on outer beams that
% seems constant through pings? A higher level on closer ranges?
% -> Maybe calculate an average level across all pings for each beam and
% sample?
% -> Maybe such artefact is due to the difference in volume insonified that
% is not properly compensated....
% -> Since the system is roll-compensated, a given beam correspond to
% different steering angles, hence different beamwidths.
% -> Average not for each beam, but for each steering angle. Sample should
% be fine.
%
% *NEW FEATURES*
%
% * 2018-10-11: Updated header before adding to Coffee v3
% * 2018-10-09: in this new version, the filtering is using
% fData.X_SBP_WaterColumnProcessed as source data, whatever it is. By
% running this function just after CFF_initialize_WC_processing that copy
% the original data into fData.X_SBP_WaterColumnProcessed, one can filter
% the original data. If you mask after initialization, the filtering will
% be applied to that masked original data, etc.
% * 2016-10-10: v2 for new datasets recorded as SBP instead of PBS
% * 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m

%   Copyright 2014-2018 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% INPUT PARSING

method_spec = 2; % default
if nargin == 1
    % fData only. keep default
elseif nargin == 2
    method_spec = varargin{1};
else
    error('wrong number of input variables')
end


%% Extract info about WCD
wcdata_class  = fData.X_1_WaterColumnProcessed_Class; % int8 or int16
wcdata_factor = fData.X_1_WaterColumnProcessed_Factor;
wcdata_nanval = fData.X_1_WaterColumnProcessed_Nanval;
[nSamples, nBeams, nPings] = size(fData.X_SBP_WaterColumnProcessed.Data.val);


%% MAIN PROCESSING METHOD SWITCH
switch method_spec
    
    case 0
        
        % No filtering. Keep original
        if memoryMapFlag
            % create binary file
            
            file_X_SBP_L1 = fullfile(wc_dir,'X_SBP_L1.dat');
            % open
            fileID_X_SBP_L1 = fopen(file_X_SBP_L1,'w+');
            % write
            fwrite(fileID_X_SBP_L1, CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),[],1,1),'int8');
            % close
            fclose(fileID_X_SBP_L1);
            % Dimensions
            [nSamples,nBeams,nPings] = size(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val);
            % re-open as memmapfile
            fData.X_SBP_L1 = memmapfile(file_X_SBP_L1, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
        else
            fData.X_SBP_L1.Data.val =  CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),[],1,1);
        end
        
    case 1
        
        % for each ping, and each sample range, calculate the average level
        % over all beams and remove it
        
        % Dimensions
        [nSamples,nBeams,nPings] = size(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val);
        
        % init arrays
        if memoryMapFlag
            % create binary file
            file_X_SBP_L1 = fullfile(wc_dir,'X_SBP_L1.dat');
            fileID_X_SBP_L1 = fopen(file_X_SBP_L1,'w+');
        else
            % initialize numerical arrays
            fData.X_SBP_L1.Data.val = zeros(nSamples,nBeams,nPings,'int8');
        end
        
        % Compute mean level across beams:
        meanAcrossBeams   = nanmean(CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),[],1,1),2);
        
        % remove this mean:
        X_SBP_L1 = bsxfun(@minus,CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),[],1,1),meanAcrossBeams); % removing mean across beams
        
        % note the same technique could maybe be applied in other
        % dimensions? across samples?
        % meanAcrossSamples = nanmean(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val./2,1);
        % X_SBP_L1 = bsxfun(@minus,fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val./2,meanAcrossSamples); % removing mean across samples
        %
        % across pings?
        % meanAcrossPings   = nanmean(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val./2,3);
        % X_SBP_L1 = bsxfun(@minus,fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val./2,meanAcrossPings); % removing mean across pings
        %
        % what about across pings then across samples? (VERY experimental)
        % X_SBP_L1 = bsxfun(@minus,bsxfun(@minus,fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val./2,meanAcrossBeams),meanAcrossSamples); % removing mean across pings THEN mean across samples (experimental)
        %
        % Maybe something could be done with the std across dimensions?
        % stdAcrossSamples  = std(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val./2,[],1,'omitnan');
        % stdAcrossBeams    = std(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val./2,[],2,'omitnan');
        % stdAcrossPings    = std(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val./2,[],3,'omitnan');
        
        % saving result
        if memoryMapFlag
            % write into binary files:
            fwrite(fileID_X_SBP_L1,X_SBP_L1,'single');
        else
            % save in array
            fData.X_SBP_L1.Data.val = X_SBP_L1;
        end
        
        % finalize if memmap files, some finishing up code necessary...
        if memoryMapFlag
            
            % close binary files
            fclose(fileID_X_SBP_L1);
            
            % re-open files as memmapfile
            fData.X_SBP_L1 = memmapfile(file_X_SBP_L1, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
        end
        
    case 2
        
        
        %% prep
        
        % define 11 middle beams for reference level
        nadirBeams = (floor((nBeams./2)-5):ceil((nBeams./2)+5)); % middle beams
        
        %% Block processing
        
        % block processing setup
        blockLength = 10;
        nBlocks = ceil(nPings./blockLength);
        blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
        blocks(end,2) = nPings;
        
        for iB = 1:nBlocks
            
            % list of pings in this block
            blockPings  = (blocks(iB,1):blocks(iB,2));
            nBlockPings = length(blockPings);
            
            % grab data
            data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed',blockPings,1,1,'true');
            
            % grab bottom detect
            bottom = fData.X_BP_bottomSample(:,blockPings);
            
            % mean level across all beams for each range (and each ping)
            meanAcrossBeams = mean(data,2,'omitnan');
            
            % find the reference level as the median level of all samples above the median bottom sample in nadir beams:
            nadirBottom = median(bottom(nadirBeams,:)); % median value -> bottom
            refLevel = nan(1,1,nBlockPings);
            for iP = 1:nBlockPings
                refLevel(1,1,iP) = nanmedian(reshape(data(1:nadirBottom(iP),nadirBeams,:),1,[]));
            end
            
            % statistical compensation. removing mean, then adding
            % reference level, like everyone does (correction "a" in
            % Parnum's thesis)
            data = bsxfun(@plus,bsxfun(@minus,data,meanAcrossBeams),refLevel);
            
            % convert result back into proper format
            data = data./wcdata_factor;
            data(isnan(data)) = wcdata_nanval;
            data = cast(data,wcdata_class);
            
            % save in array
            fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = data;
            
            % note that other compensations of that style are possible (to
            % be tested for performance
            
            % adding the reference level is simple, but begs the question
            % of what reference level to use? In my first paper, I
            % suggested not intriducing a reference level at all, i.e.:
            % X_SBP_L1 = bsxfun(@minus,thisPing,meanAcrossBeams);
            
            % Or we can make the compensation more complicated, for example
            % including normalization for std (correction "b" in Parnum):
            % stdAcrossBeams  = std(thisPing,[],2,'omitnan');
            % X_SBP_L1 = bsxfun(@rdivide,bsxfun(@minus,thisPing,meanAcrossBeams),stdAcrossBeams) + refLevel;
            
            % Or, going even further, re-introducing a reference standard
            % deviation:
            % stdRefLevel = std(reshape(thisPing((1:nadirBottom),nadirBeams),1,[]),'omitnan');
            % X_SBP_L1 = bsxfun(@rdivide,bsxfun(@minus,thisPing,meanAcrossBeams),stdAcrossBeams).*stdRefLevel + refLevel;
            
        end
        
        
    case 3
        
        % DEMOUSTIER'S CORRECTION USING PERCENTILES:
        
        % Dimensions
        [nSamples,nBeams,nPings] = size(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val);
        
        % init arrays
        if memoryMapFlag
            % create binary file
            file_X_SBP_L1 = fullfile(wc_dir,'X_SBP_L1.dat');
            fileID_X_SBP_L1 = fopen(file_X_SBP_L1,'w+');
        else
            % initialize numerical arrays
            fData.X_SBP_L1.Data.val = zeros(nSamples,nBeams,nPings,'int8');
        end
        
        % per-ping processing
        for ip = 1:nPings
            
            % grab data
            thisPing = double(CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),ip,1,1));
            
            % calculate 75th percentile
            sevenfiveperc = nan(nSamples,1);
            for ismp = 1:nSamples
                X = thisPing(ismp,:,:);
                sevenfiveperc(ismp,1) = CFF_invpercentile(X,75);
            end
            
            % statistical compensation:
            X_SBP_L1 =  bsxfun(@minus,thisPing,sevenfiveperc);
            
            % saving result
            if memoryMapFlag
                % write into binary files:
                fwrite(fileID_X_SBP_L1,X_SBP_L1,'int8');
            else
                % save in array
                fData.X_SBP_L1.Data.val(:,:,ip) = X_SBP_L1;
            end
            
            
        end
        
        % finalize if memmap files, some finishing up code necessary...
        if memoryMapFlag
            
            % close binary files
            fclose(fileID_X_SBP_L1);
            
            % re-open files as memmapfile
            fData.X_SBP_L1 = memmapfile(file_X_SBP_L1, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
        end
        
        
    otherwise
        
        error('method_spec not recognised')
        
end
