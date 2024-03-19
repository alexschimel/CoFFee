function [fData,params] = CFF_filter_bottom_detect_v2(fData,varargin)
%CFF_FILTER_BOTTOM_DETECT_V2  Filter and interpolate the bottom detections
%
%   Bottom detects are the sample number in each beam corresponding to the
%   bottom, according to the bottom detect algorithms. This
%   filtering/interpolating algorithm can be applied to data either in
%   bathymetry, or water-column datagrams. Note this function requires the
%   bottom samples in input data to have been previously geoprocessed using
%   CFF_GEOREFERENCE_BOTTOM_DETECT. 
%
%   FDATA = CFF_FILTER_BOTTOM_DETECT_V2(FDATA) filters the bottom detect in
%   FDATA using default processing parameters, and returns 
%   FDATA with additional fields from the processing.
%
%   CFF_FILTER_BOTTOM_DETECT_V2(FDATA,PARAMS) uses processing parameters
%   defined as the fields in the PARAMS structure. Possible parameters are:
%   'sourceBottom': string for the bottom detects to start from, either
%   'raw' (default) or 'processed'. 'raw' starts from the raw detects as
%   recorded in the raw data. 'processed' starts from the
%   previously-processed detects, in order to allow for extra-processing.
%   'method': string for the filtering method to be applied, either
%   'filter' (default) or 'flag'. With 'filter' the bottom detects are
%   filtered using a 1D or 2D median filter (see other parameters). With
%   'flag' the bottom detects are either conserved or removed, based on
%   whether they fit a criteria (see other parameters).
%   'pingBeamWindowSize': a two-elements vector (first for pings, second
%   for beams) of non-negative integers defining the window size around a
%   detect to consider for the filtering/flagging. By default using [3,3]
%   that is, we consider windows of 7 beams (f3 starboard, 3 port) and 7
%   pings (3 prior, 3 after) around the detect of interest.
%   'maxHorizDist': nonnegative scalar defining the maximum horizontal
%   distance (in m) to keep windows elements. Use maxHorizDist = inf to
%   indicate NOT using a max horizontal distance (default).
%   'flagVariable': string code defining the variable to be calculated for
%   each element of the window, when using the 'flag' method. Can be 'vert'
%   (vertical distance, default), 'eucl' (euclidian distance), or 'slope'
%   (slope in degrees). All are relative to the bottom detect.
%   'flagThreshold': scalar value defining the threshold for the variable
%   above, i.e. distance (in m) or slope (in degrees).
%   'flagType': string code defining the function applied to return a
%   single value from the window, when using the flag method. Can be
%   'median' (i.e. only the median value needs to meet the criteria,
%   default), 'all' (i.e. ALL the values in the window must meet the
%   criteria), or 'any' (i.e. AT LEAST ONE value in the window must meet
%   the criteria).
%   'interpolateFlag': boolean indicating if remaining NaNs after filtering
%   or flagging must be interpolated. Default is 1, indicating
%   interpolating is requested.
%
%   CFF_FILTER_BOTTOM_DETECT_V2(...,'comms',COMMS) specifies if and how
%   this function communicates on its internal state (progress, info,
%   errors). COMMS can be either a CFF_COMMS object, or a text string to
%   initiate a new CFF_COMMS object. Options are 'disp', 'textprogressbar',
%   'waitbar', 'oneline', 'multilines'. By default, using an empty
%   CFF_COMMS object (i.e. no communication). See CFF_COMMS for more
%   information.
%
%   [FDATA,PARAMS] = CFF_FILTER_BOTTOM_DETECT_V2(...) also outputs the
%   parameters used in processing.
%
%   See also CFF_GEOREFERENCE_BOTTOM_DETECT, CFF_GROUP_PROCESSING.

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

global DEBUG
% DEBUG = 1;

%% Input arguments management
p = inputParser;
addRequired(p,'fData',@(x) CFF_is_fData_version_current(x)); % line fData to process
addOptional(p,'params',struct(),@(x) isstruct(x)); % processing parameters
addParameter(p,'comms',CFF_Comms()); % information communication (none by default)
parse(p,fData,varargin{:});
params = p.Results.params;
comms = p.Results.comms;
clear p
if ischar(comms)
    comms = CFF_Comms(comms);
end


%% Prep

% start message
comms.start('Filtering the bottom detections');

% get sourceBottom parameter
if ~isfield(params,'sourceBottom'), params.sourceBottom = 'raw'; end % default
mustBeMember(params.sourceBottom,{'raw','processed'}); % validate
sourceBottom = params.sourceBottom;

% get bottom data to process
b0 = CFF_get_bottom_sample(fData,'which',sourceBottom);
b0(b0==0) = NaN; % replace no detects by NaNs

% get bottom easting, northing and height
bE = fData.X_BP_bottomEasting;
bN = fData.X_BP_bottomNorthing;
bH = fData.X_BP_bottomHeight;

% dimensions
[nBeams, nPings] = size(b0);

% initialize results
b1 = b0;

comms.progress(0,4);


%% Processing parameters common to all methods

% get method
if ~isfield(params,'method'), params.method = 'filter'; end % default
mustBeMember(params.method,{'filter','flag'}); % validate
method = params.method;

% get maxHorizDist
if ~isfield(params,'maxHorizDist'), params.maxHorizDist = inf; end % default
mustBePositive(params.maxHorizDist); % validate
maxHorizDist = params.maxHorizDist;

% get pingBeamWindowSize
if ~isfield(params,'pingBeamWindowSize'), params.pingBeamWindowSize = [3,3]; end % default
CFF_mustBeTwoNonnegativeIntegers(params.pingBeamWindowSize); % validate
pingBeamWindowSize = params.pingBeamWindowSize;


%% Processing
switch method
 
    case 'filter'
        
        comms.step('Filtering');
        
        if isinf(maxHorizDist)
            
            % filter method, with no limit on horiz distance
            for pp = 1:nPings
                for bb = 1:nBeams
                    % find the subset of all bottom detects within set
                    % interval in pings and beams 
                    pmin = max(1,pp-pingBeamWindowSize(1));
                    pmax = min(nPings,pp+pingBeamWindowSize(1));
                    bmin = max(1,bb-pingBeamWindowSize(2));
                    bmax = min(nBeams,bb+pingBeamWindowSize(2));
                    % get bottom for subset
                    subBottom = b0(bmin:bmax,pmin:pmax);
                    % compute median value
                    b1(bb,pp) = median(subBottom(:),'omitnan');
                end
            end
            
        else
            
            % filter method, with limit on horiz distance
            for pp = 1:nPings
                for bb = 1:nBeams
                    % find the subset of all bottom detects within set
                    % interval in pings and beams 
                    pmin = max(1,pp-pingBeamWindowSize(1));
                    pmax = min(nPings,pp+pingBeamWindowSize(1));
                    bmin = max(1,bb-pingBeamWindowSize(2));
                    bmax = min(nBeams,bb+pingBeamWindowSize(2));
                    % get bottom for subset
                    subBottom = b0(bmin:bmax,pmin:pmax);
                    % get easting and northing
                    subEasting = bE(bmin:bmax,pmin:pmax);
                    subNorthing = bN(bmin:bmax,pmin:pmax);
                    % compute horizontal distance in m
                    subHzDist = sqrt( (bE(bb,pp)-subEasting).^2 + (bN(bb,pp)-subNorthing).^2 );
                    % keep only subset within desired horizontal distance
                    subBottom(subHzDist>maxHorizDist) = NaN;
                    % compute median value
                    b1(bb,pp) = median(subBottom(:),'omitnan');
                end
            end
            
        end
        
    case 'flag'
        
        comms.step('Flagging');
        
        % flag method additional parameters
        
        % get flagType
        if ~isfield(params,'flagType'), params.flagType = 'median'; end % default
        mustBeMember(params.flagType,{'median','all','any'}); % validate
        flagType = params.flagType;
        
        % get flagVariable
        if ~isfield(params,'flagVariable'), params.flagVariable = 'vert'; end % default
        mustBeMember(params.flagVariable,{'vert','eucl','slope'}); % validate
        flagVariable = params.flagVariable;
        
        % get flagThreshold
        if ~isfield(params,'flagThreshold'), params.flagThreshold = 1; end % default
        mustBeNumeric(params.flagThreshold); % validate
        flagThreshold = params.flagThreshold;
        
        % get/set flagging type first
        switch flagType
            case 'median'
                f = @(x)median(x);
            case 'all'
                f = @(x)all(x);
            case 'any'
                f = @(x)any(x);
        end
        
        % next, processing for each bottom detect (BT)
        for pp = 1:nPings
            for bb = 1:nBeams
                % first off, flag method is inapplicable if BT doesn't
                % exist
                if isnan(b0(bb,pp))
                    % keep b1(bb,pp) as Nan.
                    continue
                end
                % find the subset of all bottom detects within set interval
                % in pings and beams 
                pmin = max(1,pp-pingBeamWindowSize(1));
                pmax = min(nPings,pp+pingBeamWindowSize(1));
                bmin = max(1,bb-pingBeamWindowSize(2));
                bmax = min(nBeams,bb+pingBeamWindowSize(2));
                
                subHzDist = sqrt( (bE(bb,pp)-bE(bmin:bmax,pmin:pmax)).^2 + (bN(bb,pp)-bN(bmin:bmax,pmin:pmax)).^2 );
                subHzDist(subHzDist>maxHorizDist) = NaN;
                
                % if there are no subset left, flag that bottom anyway
                if all(isnan(subHzDist(:)))
                    b1(bb,pp) = NaN;
                    continue
                end
                % compute vertical distance in m
                subVertDist = bH(bmin:bmax,pmin:pmax)-bH(bb,pp);
                % now switch on the flagging variable
                switch flagVariable
                    case 'vert'
                        v = subVertDist(:);
                    case 'eucl'
                        % compute euclidian distance in m
                        subEucliDist = sqrt( subHzDist.^2 + subVertDist.^2);
                        v = subEucliDist(:);
                    case 'slope'
                        % compute slope in degrees
                        subSlope = abs(atan2d(subVertDist,subHzDist));
                        v = subSlope(:);
                end
                % finally, apply flagging decision
                if f(abs(v) > flagThreshold)
                    b1(bb,pp) = NaN;
                end
            end
        end

end

comms.progress(1,4);


%% Interpolate

% get interpolateFlag
if ~isfield(params,'interpolateFlag'), params.interpolateFlag = 1; end % default
mustBeNumericOrLogical(params.interpolateFlag); % validate
interpolateFlag = params.interpolateFlag;

if interpolateFlag
    comms.step('Interpolating');
    b1 = round(inpaint_nans(b1));
    % safeguard against inpaint_nans occasionally yielding numbers below
    % zeros in areas where there are a lot of NaNs
    b1(b1<1)=2;
end

comms.progress(2,4);


%% Test display
if DEBUG
    figure; tiledlayout(3,1);
    minb = min([b0(:);b1(:)]); maxb=max([b0(:);b1(:)]);
    ax1 = nexttile; imagesc(b0); colormap(jet); colorbar; title('range of raw bottom'); grid on; caxis([minb maxb])
    ax2 = nexttile; imagesc(b1); colormap(jet); colorbar; title('range of filtered bottom'); grid on; caxis([minb maxb])
    ax3 = nexttile; imagesc(b1-b0); colormap(jet); colorbar; title('filtered minus raw');
    linkaxes([ax1 ax2 ax3],'xy')
end


%% Saving results

comms.step('Saving');

fData = CFF_set_bottom_sample(fData,b1);
fData.X_MET_bottomFilterParams = params;

comms.progress(3,4);


%% Re-georeference bottom after filtering

comms.step('Re-georeferencing');

fData = CFF_georeference_bottom_detect(fData);

comms.progress(4,4);


%% End message
comms.finish('Done');