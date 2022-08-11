function [data, params] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData, iPings, varargin)
%CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE  Filter WCD sidelobe artefact
%
%   This function filters the sidelobe artefact in specific pings of
%   water-column data.
%
%   DATA = CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE(DATA,FDATA,IPINGS) takes
%   input DATA (SBP tensor) and filters the sidelobe artefact in it, using
%   the necessary information in FDATA for the relevant ping indices
%   IPINGS. It returns the corrected DATA.
%
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE(DATA,FDATA,IPINGS,PARAMS) uses
%   processing parameters defined as the fields in the PARAMS structure.
%   Possible parameters are: 
%   'avgCalc': mode of calculation of the average value across beams. Can
%   be 'mean' (default) or 'median'.
%   'refType': type of calculation for reference level: 'constant'
%   (constant value) or 'fromPingData' (calculated from the data, default).
%   'refCst': (only used if refType is 'constant') set the constant value
%   here (in dB). Default is -70.
%   'refArea': (only used if refType is 'fromPingData') set the reference
%   area for the calculation of the reference level here: 'nadirWC' uses
%   data from the eleven middle beams before minimum slant range, or
%   'cleanWC' uses all data before minimum slant range (default).
%   'refCalc': (only used if refType is 'fromPingData')) set mode of
%   calculation of the reference value from the reference data here.
%   Possible values are 'mean', 'median', 'mode', 'perc5', 'perc10',
%   'perc25' (default).
%
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE(...,'comms',COMMS) specifies if
%   and how this function communicates on its internal state (progress,
%   info, errors). COMMS can be either a CFF_COMMS object, or a text string
%   to initiate a new CFF_COMMS object. Options are 'disp',
%   'textprogressbar', 'waitbar', 'oneline', 'multilines'. By default,
%   using an empty CFF_COMMS object (i.e. no communication). See CFF_COMMS
%   for more information.
%
%   [FDATA,PARAMS] = CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE(...) also outputs
%   the parameters used in processing.
%
%   Note: development notes at the bottom
%
%   See also CFF_FILTER_WC_SIDELOBE_ARTIFACT,
%   CFF_WC_RADIOMETRIC_CORRECTIONS_CORE, CFF_MASK_WC_DATA_CORE.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 28-07-2022


global DEBUG;


%% Input arguments management
p = inputParser;
addRequired(p,'data',@(x) isnumeric(x)); % data to process
addRequired(p,'fData',@(x) CFF_is_fData_version_current(x)); % source fData
addRequired(p,'iPings',@(x) isnumeric(x)); % indices of pings to process
addOptional(p,'params',struct(),@(x) isstruct(x)); % processing parameters
addParameter(p,'comms',CFF_Comms()); % information communication (none by default)
parse(p,data,fData,iPings,varargin{:});
params = p.Results.params;
comms = p.Results.comms;
clear p
if ischar(comms)
    comms = CFF_Comms(comms);
end


%% Prep

% start message
comms.start('Filtering sidelobe artefact');


%% Calculate average value across beams

% get avgCalc parameter
if ~isfield(params,'avgCalc'), params.avgCalc = 'mean'; end % default
mustBeMember(params.avgCalc,{'mean','median'}); % validate
avgCalc = params.avgCalc;

% calculation
switch avgCalc
    case 'mean'
        avgAcrossBeams = mean(data,2,'omitnan');
    case 'median'
        avgAcrossBeams = median(data,2,'omitnan');
end
    

%% Calculate reference level

% get refType parameter
if ~isfield(params,'refType'), params.refType = 'fromPingData'; end % default
mustBeMember(params.refType,{'fromPingData','constant'}); % validate
refType = params.refType;

% calculations
switch refType
    
    case 'constant'
        % constant reference level, as per parameter
        
        % get refCst parameter
        if ~isfield(params,'refCst'), params.refCst = -70; end % default
        mustBeNumeric(params.refCst); % validate
        refCst = params.refCst;
        
        % calculate reference level
        refLevel = single(refCst.*ones(1,1,numel(iPings)));
        
    case 'fromPingData'
        % reference level calculated from ping data, as per parameters
        
        % get closest bottom sample (minimum slant range) in each ping
        [num_samples, ~, ~] = size(data);
        bottomSamples = CFF_get_bottom_sample(fData);
        bottomSamples = bottomSamples(:,iPings);
        closestBottomSample = nanmin(bottomSamples);
        closestBottomSample = nanmin(ceil(closestBottomSample),num_samples);
        
        % indices for data extraction (getting rid of surface noise)
        iSampleStart = ceil(nanmin(closestBottomSample)/10);
        iSampleEnd   = ceil(nanmax(closestBottomSample));
        
        % get refArea parameter
        if ~isfield(params,'refArea'), params.refArea = 'cleanWC'; end % default
        mustBeMember(params.refArea,{'nadirWC','cleanWC'}); % validate
        refArea = params.refArea;

        % defining reference data
        switch refArea
            
            case 'nadirWC'
                % using an average noise level from all samples in the
                % water column of this ping, above the bottom, within the
                % 11 beams closest to nadir.
                [~, nBeams, ~] = size(data);
                nadirBeams = (floor((nBeams./2)-5):ceil((nBeams./2)+5));
                refData = data(iSampleStart:iSampleEnd,nadirBeams,:);
                
            case 'cleanWC'
                % using an average noise level from all samples in the
                % water column of this ping, within minimum slant range,
                % aka "clean watercolumn"
                refData = data(iSampleStart:iSampleEnd,:,:);
                              
        end
        
        % nan all samples beyond minimum slant range in the extracted data
        iNan = iSampleStart-1+(1:size(refData,1))' >= closestBottomSample;
        iNan = permute(iNan,[1 3 2]);
        iNan = repmat(iNan,1,size(refData,2),1);
        refData(iNan) = NaN;
        
        % get refCalc parameter
        if ~isfield(params,'refCalc'), params.refCalc = 'perc25'; end % default
        mustBeMember(params.refCalc,{'mean','median','mode','perc5','perc10','perc25'}); % validate
        refCalc = params.refCalc;
        
        % calculate reference level
        switch refCalc
            case 'mean'
                refLevel = nanmean(refData,[1 2]);
            case 'median'
                refLevel = nanmedian(refData,[1 2]);
            case 'mode'
                refLevel = mode(refData,[1 2]);
            case 'perc5'
                refLevel = prctile(refData,5,[1 2]);
            case 'perc10'
                refLevel = prctile(refData,10,[1 2]);
            case 'perc25'
                refLevel = prctile(refData,25,[1 2]);
        end
        
end

% display results
if DEBUG
    ip = 1;
    figure; tiledlayout(1,3);
    ax1=nexttile();imagesc(data(:,:,ip));
    grid on;colormap(jet);colorbar;title('raw');c=caxis;
    ax2=nexttile();imagesc(data(:,:,ip)-avgAcrossBeams(:,:,ip));
    grid on;colormap(jet);colorbar;title('... -avg');
    ax3=nexttile();imagesc(data(:,:,ip)-avgAcrossBeams(:,:,ip)+refLevel(:,:,ip));
    grid on;colormap(jet);colorbar;title('... +ref');caxis(c);
    linkaxes([ax1,ax2,ax3]);
end

%% Remove average and add reference level
data = data - avgAcrossBeams + refLevel;


%% end message
comms.finish('Done');


%% DVPT NOTES
% I originally developed several methods to filter the sidelobe artefact.
% The overall principle is normalization. Just as for seafloor backscatter
% you normalize the level across all angles by removing the average level
% computed across all angles, here with water-column, you normalize the
% level by removing the average level computed across all ranges.
%
% There are several levels of complexity possible.
%
% At the most basic, you really only need to remove the average. The
% resulting data has an average of 0, which is not the normal dB range.
% This is what I did for seafloor backscatter in my first paper. In my
% original code, this was method 1.
%
% So the next level of complexity is to reintroduce a reference level after
% removing the mean. This is the most common procedure, the one retained in
% the code  here (formerly known as method 2), and the one termed
% correction "a" in Parnum's thesis. 
%
% Now, usually a "normalization" implies also the standard deviation: you
% remove the mean, then divide by the standard deviation. If you want to
% add a new mean (reference level), you do it after those two first steps.
% This is correction "b" in Parnum. Tou'd need to calculate the std as
%       stdAcrossBeams = std(data,0,2,'omitnan');
% and in the final calculation do instead:
%       data = (data-avgAcrossBeams)./stdAcrossBeams + refLevel;
%
% Continuing further from Parnum's idea, you could reintroduce a reference
% standard deviation, just as the reference level is actually a reference
% mean. So, in order, you substract the mean, divide by the std, multiply
% by the reference std, and add the reference level.
% The reference std would be calculated in the same loop as that for
% reference level as:
%       refStd = nanstd(refData,[1 2]);
% and reintroduced in the final calculation as:
%       data = (((data-avgAcrossBeams)./stdAcrossBeams)+refLevel).*refStd;
%
% Another note worth thinking about: Why normalizing only across ranges?
% What about the other dimensions? Normalizing across samples would be
% calculated as:
%       avgAcrossSamples = mean(data,1,'omitnan');
% Across pings as:
%       avgAcrossPings = mean(data,3,'omitnan');
% What about across more than one dimension? Is that possible?
%
% Last note: De Moustier came across a similar solution to filter sidelobe
% artefacts except it consisted in calculating the 75% percentiles across
% all ranges, rather than the mean. Also he did not introduce a reference
% level. It would go as something like this:
% [nSamples, ~, ~] = size(fData.X_SBP_WaterColumnProcessed.Data.val);
% for ip = 1:numel(iPings)
%     thisPing = data(:,:,ip);
%     sevenfiveperc = nan(nSamples,1); % calc 75th percentile across ranges
%     for ismp = 1:nSamples
%         X = thisPing(ismp,:,:);
%         sevenfiveperc(ismp,1) = CFF_invpercentile(X,75);
%     end
%     thisPing_corrected =  thisPing - sevenfiveperc;
% end

