function [fData] = CFF_filter_WC_bottom_detect(fData,varargin)
% [fData] = CFF_filter_WC_bottom_detect(fData,varargin)
%
% DESCRIPTION
%
% Filter bottom detection in watercolumn data
%
% INPUT VARIABLES
%
% - varargin{1} "method": method for bottom filtering/processing
%   - noFilter: None
%   - alex: medfilt2 + inpaint_nans (default)
%   - amy: ...
%
% OUTPUT VARIABLES
%
% - fData
%
% NEW FEATURES
%
% - 2016-12-01: Using the new "X_PB_bottomSample" field in fData rather
% than "b1"
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m

%   Copyright 2016-2016 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% INPUT PARSER

% initialize input parser
p = inputParser;

% 'fData': The multibeam data structure.
% Required.
validate_fData = @isstruct;
addRequired(p,'fData',validate_fData);

% 'method': apply median filter to all bottom detects (filter), or find &
% delete bad bottom detects (flag).
% Optional -> Default: 'filter'.
validate_method = @(x) ismember(x,{'filter','flag'});
default_method = 'filter';
addOptional(p,'method',default_method,validate_method);

% 'pingBeamWindowSize': the number of pings and beams to define neighbours
% to each bottom detect. 1x2 int array, valid entries zero or positive.
% Use inf to indicate use of all pings or beams.
% set 0 to use just current ping, inf for all pings (long computing time)
% set 0 to use just current beam, inf for all beams (long computing time)

% Optional -> Default: [5,5].
validate_pingBeamWindowSize = @(x) validateattributes(x,{'numeric'},{'size',[1,2],'integer','nonnegative'});
default_pingBeamWindowSize = [5,5];
addOptional(p,'pingBeamWindowSize',default_pingBeamWindowSize,validate_pingBeamWindowSize);

% 'maxHorizDist': maximum horizontal distance to consider neighbours. num,
% valid entries non-zero positive. Use inf to indicate not using a maz
% horizontal distance.
% set inf to not filter by horizontal distance

% Optional - Default: inf
validate_maxHorizDist = @(x) validateattributes(x,{'numeric'},{'scalar','positive'});
default_maxHorizDist = inf;
addOptional(p,'maxHorizDist',default_maxHorizDist,validate_maxHorizDist);

% 'interpolate': interpolate missing values or not. char, valid entries 'yes or 'no'.
% Optional -> Default 'yes'
validate_interpolate = @(x) ismember(x,{'yes','no'});
default_interpolate = 'yes';
addOptional(p,'interpolate',default_interpolate,validate_interpolate);

% optional 'flagParams', struct with fields:
%   type, char, valid entries 'all' or 'median'
%   variable, char, valid entries 'slope', 'eucliDist' or 'vertDist'
%   threshold, num
validate_flagParams = @(x) isstruct(x);
default_flagParams = struct('type','all','variable','vertDist','threshold',1);
addOptional(p,'flagParams',default_flagParams,validate_flagParams);

% parsing actual inputs
parse(p,fData,varargin{:});



%% PRE-PROCESSING

% extract needed data
b0 = fData.X_PB_bottomSample;
bE = fData.X_PB_bottomEasting;
bN = fData.X_PB_bottomNorthing;
bH = fData.X_PB_bottomHeight;
b0(b0==0) = NaN; % repace no detects by NaNs
nPings = size(b0,1);
nBeams = size(b0,2);

% initialize results
b1 = b0;



%% PROCESSSING
switch p.Results.method
    
    case 'filter'
        
        if isinf(p.Results.maxHorizDist)
            
            % filter method, no limit on horiz distance
            tic
            for pp = 1:nPings
                for bb = 1:nBeams
                    % find the subset of all bottom detects within set interval in pings and beams
                    pmin = max(1,pp-p.Results.pingBeamWindowSize(1));
                    pmax = min(nPings,pp+p.Results.pingBeamWindowSize(1));
                    bmin = max(1,bb-p.Results.pingBeamWindowSize(2));
                    bmax = min(nBeams,bb+p.Results.pingBeamWindowSize(2));
                    % get bottom for subset
                    subBottom = b0(pmin:pmax,bmin:bmax);
                    % compute median value
                    b1(pp,bb) = median(subBottom(:),'omitnan');
                end
            end
            toc
            
        else
            
            % filter method, with limit on horiz distance
            for pp = 1:nPings
                for bb = 1:nBeams
                    % find the subset of all bottom detects within set interval in pings and beams
                    pmin = max(1,pp-p.Results.pingBeamWindowSize(1));
                    pmax = min(nPings,pp+p.Results.pingBeamWindowSize(1));
                    bmin = max(1,bb-p.Results.pingBeamWindowSize(2));
                    bmax = min(nBeams,bb+p.Results.pingBeamWindowSize(2));
                    % get bottom for subset
                    subBottom = b0(pmin:pmax,bmin:bmax);
                    % get easting and northing
                    subEasting = bE(pmin:pmax,bmin:bmax);
                    subNorthing = bN(pmin:pmax,bmin:bmax);
                    % compute horizontal distance in m
                    subHzDist = sqrt( (bE(pp,bb)-subEasting).^2 + (bN(pp,bb)-subNorthing).^2 );
                    % keep only subset within desired horizontal distance
                    subBottom(subHzDist>p.Results.maxHorizDist) = NaN;
                    % compute median value
                    b1(pp,bb) = median(subBottom(:),'omitnan');
                end
            end
            
        end
        
    case 'flag'
        
        % get flagging type first
        switch p.Results.flagParams.type
            case 'all'
                f = @(x)all(x);
            case 'median'
                f = @(x)median(x);
            case 'any'
                f = @(x)any(x);
            otherwise
                error('flagParams.type not recognized')
        end
        
        % next, processing for each bottom detect (BT)
        for pp = 1:nPings
            for bb = 1:nBeams
                % first off, flag method is inapplicable if BT doesn't exist.
                if isnan(b0(pp,bb))
                    % keep b1(pp,bb) as Nan.
                    continue
                end
                % find the subset of all bottom detects within set interval in pings and beams
                pmin = max(1,pp-p.Results.pingBeamWindowSize(1));
                pmax = min(nPings,pp+p.Results.pingBeamWindowSize(1));
                bmin = max(1,bb-p.Results.pingBeamWindowSize(2));
                bmax = min(nBeams,bb+p.Results.pingBeamWindowSize(2));
                % index of BT in the subset
                pid = find(pp==pmin:pmax);
                bid = find(bb==bmin:bmax);
                % get easting, northing and height
                subEasting = bE(pmin:pmax,bmin:bmax);
                subNorthing = bN(pmin:pmax,bmin:bmax);
                subHeight = bH(pmin:pmax,bmin:bmax);
                % remove the BT itself from the subset
                subEasting(pid,bid) = NaN;
                subNorthing(pid,bid) = NaN;
                subHeight(pid,bid) = NaN;
                % compute horizontal distance in m
                subHzDist = sqrt( (bE(pp,bb)-subEasting).^2 + (bN(pp,bb)-subNorthing).^2 );
                % keep only subset within desired horizontal distance
                subEasting(subHzDist>p.Results.maxHorizDist) = NaN;
                subNorthing(subHzDist>p.Results.maxHorizDist) = NaN;
                subHeight(subHzDist>p.Results.maxHorizDist) = NaN;
                subHzDist(subHzDist>p.Results.maxHorizDist) = NaN;
                % if there are no subset left, flag that bottom anyway
                if all(isnan(subHzDist(:)))
                    b1(pp,bb) = NaN;
                    continue
                end
                % compute vertical distance in m
                subVertDist = subHeight-bH(pp,bb);
                % now switch on the flagging variable
                switch p.Results.flagParams.variable
                    case 'vert'
                        v = subVertDist(:);
                    case 'eucl'
                        % compute euclidian distance in m
                        subEucliDist = sqrt( subHzDist.^2 + subVertDist.^2);
                        v = subEucliDist(:);
                    case 'slope'
                        % compute slope in degrees
                        subSlope = atan2(subVertDist,subHzDist) .*pi/180;
                        v = subSlope(:);
                    otherwise
                        error('flagParams.variable not recognized')
                end
                % finally, apply flagging decision
                if f(abs(v)) > p.Results.flagParams.threshold
                    b1(pp,bb) = NaN;
                end
            end
        end
        
    otherwise
        
        error('method not recognized');
end



% NOTE: OLD METHOD:
% % apply a median filter (medfilt1 should do about the same)
% % fS = ceil((p.Results.beamFilterLength-1)./2);
% fS = p.Results.pingBeamWindowSize(2);
% for ii=1:nPings
%     for jj = 1+fS:nBeams-fS
%         tmp = b0(ii,jj-fS:jj+fS);
%         tmp = tmp(~isnan(tmp(:)));
%         if ~isempty(tmp)
%             b2(ii,jj) = median(tmp);
%         end
%     end
% end


%% INTERPOLATE
switch p.Results.interpolate
    
    case 'yes'
        
        b1 = round(CFF_inpaint_nans(b1));
        
        % safeguard against inpaint_nans occasionally yielding numbers
        % below zeros in areas where there are a lot of nans:
        b1(b1<1)=2;
        
end



%% TEST DISPLAY
% figure;
% minb = min([b0(:);b1(:)]); maxb= max([b0(:);b1(:)]);
% subplot(221); imagesc(b0); colorbar; title('range of raw bottom'); caxis([minb maxb])
% subplot(222); imagesc(b1); colorbar; title('range of filtered bottom'); caxis([minb maxb])
% subplot(223); imagesc(b1-b0); colorbar; title('filtered-raw')

%% SAVING RESULTS
fData.X_PB_bottomSample = b1;

%% RE-PROCESSING BOTTOM FROM RESULTS
fData = CFF_process_WC_bottom_detect(fData);






