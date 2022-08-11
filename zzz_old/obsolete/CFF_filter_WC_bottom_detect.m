function [fData] = CFF_filter_WC_bottom_detect(fData,varargin)
%CFF_FILTER_WC_BOTTOM_DETECT  Filter the bottom detect in watercolumn data
%
%   fData = CFF_filter_WC_bottom_detect(fData,varargin) gets the bottom
%   sample in fData (fData.X_BP_bottomSample) and filter it according to
%   parameters in varargin. The end result is an updated X_BP_bottomSample
%   field.
%
%   OBSOLETE FUNCTION. USE CFF_FILTER_BOTTOM_DETECT_V2 instead

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

warning('OBSOLETE FUNCTION. USE CFF_FILTER_BOTTOM_DETECT_V2 instead.');

%% INPUT PARSER

% initialize input parser
p = inputParser;


% Required.
validate_fData = @isstruct;
addRequired(p,'fData',validate_fData);

% 'method':
validate_method = @(x) ismember(x,{'filter','flag'});
default_method = 'filter';
addOptional(p,'method',default_method,validate_method);

% 'pingBeamWindowSize':
validate_pingBeamWindowSize = @(x) validateattributes(x,{'numeric'},{'size',[1,2],'integer','nonnegative'});
default_pingBeamWindowSize = [5,5];
addOptional(p,'pingBeamWindowSize',default_pingBeamWindowSize,validate_pingBeamWindowSize);

% 'maxHorizDist':
validate_maxHorizDist = @(x) validateattributes(x,{'numeric'},{'scalar','positive'});
default_maxHorizDist = inf;
addOptional(p,'maxHorizDist',default_maxHorizDist,validate_maxHorizDist);

% 'flagParams':
validate_flagParams = @(x) isstruct(x);
default_flagParams = struct('type','all','variable','vertDist','threshold',1);
addOptional(p,'flagParams',default_flagParams,validate_flagParams);

% 'interpolate':
validate_interpolate = @(x) ismember(x,{'yes','no'});
default_interpolate = 'yes';
addOptional(p,'interpolate',default_interpolate,validate_interpolate);

% parsing actual inputs
parse(p,fData,varargin{:});

% saving results individually
method             = p.Results.method;
pingBeamWindowSize = p.Results.pingBeamWindowSize;
maxHorizDist       = p.Results.maxHorizDist;
flagParams         = p.Results.flagParams;
interpolateFlag    = p.Results.interpolate;
clear p


%% PRE-PROCESSING

% extract needed data
b0 = CFF_get_bottom_sample(fData,'which','raw'); % taking raw sample so that we don't refilter something that's been filtered already
%b0 = CFF_get_bottom_sample(fData,'which','processed'); % taking processed sample that is overwritten every time we filter, to allow extra filtering.
bE = fData.X_BP_bottomEasting;
bN = fData.X_BP_bottomNorthing;
bH = fData.X_BP_bottomHeight;

b0(b0==0) = NaN; % replace no detects by NaNs

% dimensions
nBeams = size(b0,1);
nPings = size(b0,2);

% initialize results
b1 = b0;


%% PROCESSSING
switch method
    
    case 'filter'
        
        if isinf(maxHorizDist)
            
            % filter method, no limit on horiz distance
            for pp = 1:nPings
                for bb = 1:nBeams
                    % find the subset of all bottom detects within set interval in pings and beams
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
                    % find the subset of all bottom detects within set interval in pings and beams
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
        
        % get flagging type first
        switch flagParams.type
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
                if isnan(b0(bb,pp))
                    % keep b1(bb,pp) as Nan.
                    continue
                end
                % find the subset of all bottom detects within set interval in pings and beams
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
                switch flagParams.variable
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
                if f(abs(v) > flagParams.threshold)
                    b1(bb,pp) = NaN;
                end
            end
        end
        
    otherwise
        
        error('method not recognized');
end



%% INTERPOLATE
switch interpolateFlag
    
    case 'yes'
        
        b1 = round(inpaint_nans(b1));
        
        % safeguard against inpaint_nans occasionally yielding numbers
        % below zeros in areas where there are a lot of nans:
        b1(b1<1)=2;
        
end



%% TEST DISPLAY
% figure;
% minb = min([b0(:);b1(:)]); maxb= max([b0(:);b1(:)]);
% subplot(221); imagesc(b0); colorbar; Fdata_ID('range of raw bottom'); caxis([minb maxb])
% subplot(222); imagesc(b1); colorbar; Fdata_ID('range of filtered bottom'); caxis([minb maxb])
% subplot(223); imagesc(b1-b0); colorbar; Fdata_ID('filtered minus raw')

%% SAVING RESULTS

fData = CFF_set_bottom_sample(fData,b1);

% and parameters
fData.X_1_bottomFilterParameters.method             = method;
fData.X_1_bottomFilterParameters.pingBeamWindowSize = pingBeamWindowSize;
fData.X_1_bottomFilterParameters.maxHorizDist       = maxHorizDist;
fData.X_1_bottomFilterParameters.flagParams         = flagParams;
fData.X_1_bottomFilterParameters.interpolateFlag    = interpolateFlag;

%% RE-PROCESSING BOTTOM FROM RESULTS
fData = CFF_georeference_WC_bottom_detect(fData);



%% obsolete code

% % OLD method for filtering bottom
% % apply a median filter (medfilt1 should do about the same)
% % fS = ceil((p.Results.beamFilterLength-1)./2);
% fS = pingBeamWindowSize(2);
% for ii = 1+fS:nBeams-fS
%   for jj=1:nPings
%         tmp = b0(ii,jj-fS:jj+fS);
%         tmp = tmp(~isnan(tmp(:)));
%         if ~isempty(tmp)
%             b2(ii,jj) = median(tmp);
%         end
%     end
% end

