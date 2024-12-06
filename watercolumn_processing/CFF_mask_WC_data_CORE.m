function [data,params] = CFF_mask_WC_data_CORE(data, fData, iPings, varargin)
%CFF_MASK_WC_DATA_CORE  Mask unwanted water-column data
%
%	Mask unwanted parts of the water-column data, e.g. data in outer beams,
%	within a range from the sonar, bottom echo, distance from bottom echo,
%	within an Easting-Northing polygon, exceeding a threshold of faulty
%	bottom detects, ranges beyong the Minimum Slant Range, etc.
%
%   DATA = CFF_MASK_WC_DATA_CORE(DATA,FDATA,IPINGS) takes input DATA (SBP
%   tensor) and masks unwanted data in it, using the necessary information
%   in FDATA for the relevant ping indices IPINGS. It returns the corrected
%   DATA. 
%
%   CFF_MASK_WC_DATA_CORE(DATA,FDATA,IPINGS,PARAMS) uses
%   processing parameters defined as the fields in the PARAMS structure.
%   Possible parameters are:
%   - 'maxAngle': angle (in degrees) from broadside beyond which data are
%   to be discarded. Typically 50 to 60. Default is inf to KEEP all data.
%   - 'minRange': range (in m) from sonar within which data are to be
%   discarded. Typically 1 to 5. Default is 0 to KEEP all data. 
%   - 'maxRangeBelowBottomEcho': range (in m) from the top of the bottom
%   echo beyond which data are to be discarded. Typically 0 to remove just
%   the echo, or -1 to -10 to be more conservative. Default is inf to KEEP
%   all data. 
%   - 'withinPolygon': vertices (in Easting and Northing) of the polygon
%   outside of which data are to be discarded. Default is [] to KEEP all
%   data. 
%   - 'maxPercentFaultyDetects': proportion (in %) of faulty detects in a
%   ping beyond which the entire ping is to be discarded. Typically ~7 to
%   remove all but perfect pings, ~ 10 to 20 to allow pings with a few
%   faulty detects, or >20 to remove only the most severly affected pings.
%   Default is 100 to KEEP all data. 
%   - 'maxRangeBelowMSR': range (in m) from the Minimum Slant Range (MSR)
%   beyond which data are to be discarded. Typically 0 to remove all data
%   past the MSR, or -1 to -10 to be more conservative. Default is inf to
%   KEEP all data. 
%
%   CFF_MASK_WC_DATA_CORE(...,'comms',COMMS) specifies if and how this
%   function communicates on its internal state (progress, info, errors).
%   COMMS can be either a CFF_COMMS object, or a text string to initiate a
%   new CFF_COMMS object. Options are 'disp', 'textprogressbar', 'waitbar',
%   'oneline', 'multilines'. By default, using an empty CFF_COMMS object
%   (i.e. no communication). See CFF_COMMS for more information.
%
%   [FDATA,PARAMS] = CFF_MASK_WC_DATA_CORE(...) also outputs
%   the parameters used in processing.
%
%   Note: estimation of bottom echo to be improved
%
%   See also CFF_MASK_WC_DATA, CFF_PROCESS_WC,
%   CFF_WC_RADIOMETRIC_CORRECTIONS_CORE,
%   CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


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
comms.start('Masking unwanted data');

% data size
[nSamples,nBeams,nPings] = size(data);

% source datagram
datagramSource = CFF_get_datagramSource(fData);

% get some variables needed in several masks
interSamplesDistance = CFF_inter_sample_distance(fData,iPings);
beamPointingAngleDeg = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,iPings);
startRangeSampleNumber = fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,iPings);
sampleRange = CFF_get_samples_range((1:nSamples)', startRangeSampleNumber, interSamplesDistance);

%% Mask 1: Removing beams beyond an angle from broadside
%   'maxAngle': angle (in degrees) from broadside beyond which data are to
%   be discarded. Typically 50 to 60. Default is inf to KEEP all data.

% get maxAngle parameter
if ~isfield(params,'maxAngle'), params.maxAngle = inf; end % default
mustBeNumeric(params.maxAngle); % validate
maxAngle = params.maxAngle;

if ~isinf(maxAngle)
    % build mask: 1: to conserve, 0: to remove
    X_BP_OuterBeamsMask = beamPointingAngleDeg>=-abs(maxAngle) & beamPointingAngleDeg<=abs(maxAngle);
    X_1BP_OuterBeamsMask = permute(X_BP_OuterBeamsMask ,[3,1,2]);
else
    % conserve all data
    X_1BP_OuterBeamsMask = true(1,nBeams,nPings);
end


%% Mask 2: Removing samples within a range from sonar
%   'minRange': range (in m) from sonar within which data are to be
%   discarded. Typically 1 to 5. Default is 0 to KEEP all data. 

% get minRange parameter
if ~isfield(params,'minRange'), params.minRange = 0; end % default
mustBeNumeric(params.minRange); % validate
minRange = params.minRange;

if minRange>0
    % build mask: 1: to conserve, 0: to remove
    X_SBP_CloseRangeMask = sampleRange>=minRange;
else
    % conserve all data
    X_SBP_CloseRangeMask = true(nSamples,nBeams,nPings);
end


%% Mask 3: Removing samples beyond a range below the top of the seabed echo
%   'maxRangeBelowBottomEcho': range (in m) from the top of the bottom echo
%   beyond which data are to be discarded. Typically 0 to remove just the
%   echo, or -1 to -10 to be more conservative. Default is inf to KEEP all
%   data.

% get maxRangeBelowBottomEcho parameter
if ~isfield(params,'maxRangeBelowBottomEcho'), params.maxRangeBelowBottomEcho = inf; end % default
mustBeNumeric(params.maxRangeBelowBottomEcho); % validate
maxRangeBelowBottomEcho = params.maxRangeBelowBottomEcho;

if ~isinf(maxRangeBelowBottomEcho)
    
    % some data needed to find the top of the bottom echo
    theta = deg2rad(beamPointingAngleDeg); % beam pointing angle in radians
    if isfield(fData,'Ru_1D_ReceiveBeamwidth')
        beamwidth = deg2rad(fData.Ru_1D_ReceiveBeamwidth(1)); % beamwidth
    else
        comms.info('Beamwidth (Ru_1D_ReceiveBeamwidth) level not stored in the file. We will use 1 degree...');
        beamwidth = 1;
    end
    
    % the first part is to find the top of the bottom echo, i.e. the range
    % in each beam where the echo starts. Some development is still needed
    % so for now we're doing a method switch.
    % Best method so far is 3. Debug display after the switch. Don't turn
    % this into a parameter - the point is to find and retain the best
    % method after development, but we keep the old ones just for reference
    % for now. 
    method = 3;
    switch method
        
        case 1
            % first developped version, from Yoann
            
            % beamwidth including increase with beam steering
            psi = beamwidth./cos(abs(theta)).^2/2;
            
            % transition between normal and grazing incidence
            theta_lim = psi/2;
            idx_normal = abs(theta) < theta_lim;
            idx_grazing = ~idx_normal;
            
            % prep
            R = fData.X_BP_bottomRange(:,iPings); % range of bottom detect
            R1 = zeros(size(theta),'single');   % range of echo start
            
            % compute range for each regime
            R1(idx_normal)  = ( 1./cos(theta(idx_normal)+psi(idx_normal)/2)   - 1./cos(theta(idx_normal)) ) .* R(idx_normal);
            R1(idx_grazing) = 2*( sin(theta(idx_grazing)+psi(idx_grazing)/2) - sin(theta(idx_grazing)-psi(idx_grazing)/2) ) .* R(idx_grazing);
            
            % Alex comments: First, the equation for beamwidth increase
            % with beam steering is bizarre. I think it should be
            % psi/cos(theta)... Next, I don't get the equation for the
            % normal regime, but I can see the equation for the second
            % regime is meant to be the horizontal  distance of the
            % intercept of the beam on a flat seafloor... except I think
            % it's missing the abs() function to deal with negative
            % steering angles, and it's multiplied by two for some
            % reason...
            %
            % The main issue is: why the horizontal distance? We want the
            % RANGE at which the beam FIRST intercepts the seafloor.
            %
            % So let's not use that one, but keeping it because I don't
            % fully understand this and I want to keep it until I'm 100%
            % sure it is not correct
            
        case 2
            % second version, from Alex
            
            % first, what I think is the actual beamwidth including beam
            % steering:
            psi = beamwidth./cos(abs(theta));
            
            % recalculating the normal/grazing incidence regimes
            theta_lim = psi/2;
            idx_normal = abs(theta) < theta_lim;
            idx_grazing = ~idx_normal;
            
            % prep
            R = fData.X_BP_bottomRange(:,iPings); % range of bottom detect
            R1 = zeros(size(theta),'single');   % range of echo start
            
            % in the grazing regime, assuming a depth D, the range at which
            % the echo starts is R1 obtained from:
            % cos(theta) = D/R and cos(theta-0.5*psi) = D/R1
            % Aka: R1 = R*(cos(theta)/cos(theta-0.5*psi))
            % Since we here want R-R1, then:
            % R1 = R( 1 - (cos(theta)/cos(theta-0.5*psi)) )
            R1(idx_grazing) = R(idx_grazing) .* ( 1 - (cos(abs(theta(idx_grazing)))./cos(abs(theta(idx_grazing))-0.5.*psi(idx_grazing))) );
            
            % in the normal regime, we just apply the value at the
            % regime-transition aka: R1 = R( 1 - cos(theta) )
            R1(idx_normal) = R(idx_normal) .* ( 1 - cos(abs(theta(idx_normal))) );
            
            % Alex comments: it's closer to the bottom echo, but on our
            % test data, it looks like the bottom detection is not always
            % at the same place in the bottom echo... did we forget some
            % angular correction for the placement of the bottom??
            
        case 3
            % third version, empirical
            
            % Since none of the two first versions work too well on our
            % test data, we try an empirical approach: We try to
            % approximate the range at which the beam footprint starts as
            % the minimum range within +-X beams around beam of interest
            X = 5;
            nbeams = size(theta,1);
            R1 = zeros(size(theta),'single');
            for ip = 1:length(iPings)
                bottomranges = fData.X_BP_bottomRange(:,iPings(ip));
                minrangefunc = @(ibeam) nanmin(bottomranges(max(1,ibeam-X):min(nbeams,ibeam+X)));
                R1(:,ip) = bottomranges - arrayfun(minrangefunc,[1:nbeams]');
            end
            
            % Alex comment: works better overall, but still not perfect.
            
    end
    
    % DEBUG display
    if DEBUG
    	WCD = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),iPings(1));
        [sampleAcrossDist,sampleUpDist] = CFF_get_WCD_swathe_coordinates(fData,iPings(1),size(WCD,1));
        figure;
        pa = pcolor(sampleAcrossDist,sampleUpDist,WCD);
        set(pa,'LineStyle','none');
        colormap('jet'); grid on; hold on
        angleDeg = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource));
        angleRad = deg2rad(angleDeg);
        [botAcDist,botUpDist] = CFF_get_samples_dist(fData.X_BP_bottomRange(:,1)',angleRad(:,1));
        plot(botAcDist,botUpDist,'k.-');
        [echoTopAcDist,echoTopUpDist] = CFF_get_samples_dist(fData.X_BP_bottomRange(:,1)'-R1(:,1)',angleRad(:,1));
        plot(echoTopAcDist,echoTopUpDist,'wo-');
    end
    
    % when we have that range, the rest is easy...
    
    % max range beyond which samples are to be masked
    X_BP_maxRange  = fData.X_BP_bottomRange(:,iPings) - R1 + maxRangeBelowBottomEcho;
    
    % BUG FIX: masking based on range, not sample number, as sampleRange
    % incorporates the start sample number. New code done Aug 15 2024.
    % Remove old code if you are far from this date and have not noticed
    % any significant issue in the bottom echo masking 
    % NEW
    X_SBP_BottomRangeMask = sampleRange < permute(repmat(double(X_BP_maxRange),1,1,nSamples),[3,1,2]);
    
    % OLD
%     % calculate max sample beyond which mask is to be applied
%     X_BP_maxSample = bsxfun(@rdivide,X_BP_maxRange,interSamplesDistance);
%     X_BP_maxSample = round(X_BP_maxSample);
%     X_BP_maxSample(X_BP_maxSample>nSamples|isnan(X_BP_maxSample)) = nSamples;
%     % build list of indices for each beam & ping
%     [PP,BB] = meshgrid((1:nPings),(1:nBeams));
%     maxSubs = [X_BP_maxSample(:),BB(:),PP(:)];    
%     % build mask: 1: to conserve, 0: to remove
%     X_SBP_BottomRangeMask = false(nSamples,nBeams,nPings);
%     for ii = 1:size(maxSubs,1)
%         X_SBP_BottomRangeMask(1:maxSubs(ii,1),maxSubs(ii,2),maxSubs(ii,3)) = true;
%     end
%     
else
    
    % conserve all data
    X_SBP_BottomRangeMask = true(nSamples,nBeams,nPings);
    
end


%% Mask 4: Removing data outside an Easting & Northing polygon
%   'withinPolygon': vertices (in Easting and Northing) of the polygon
%   outside of which data are to be discarded. Default is [] to KEEP all
%   data. 

% get withinPolygon parameter
if ~isfield(params,'withinPolygon'), params.withinPolygon = []; end % default
mustBeNumeric(params.withinPolygon); % validate (can improve this)
withinPolygon = params.withinPolygon;

if ~isempty(withinPolygon)
    % get easting and northing for all samples
    idxSamples = (1:nSamples)';
    sonarEasting = fData.X_1P_pingE(iPings);
    sonarNorthing = fData.X_1P_pingN(iPings);
    sonarHeight = fData.X_1P_pingH(iPings);
    sonarHeading = fData.X_1P_pingHeading(iPings);
    [E,N] = CFF_georeference_sample(idxSamples, startRangeSampleNumber, interSamplesDistance, deg2rad(beamPointingAngleDeg), ...
        sonarEasting, sonarNorthing, sonarHeight, sonarHeading);
    % build mask: 1: to conserve, 0: to remove
    X_SBP_PolygonMask = inpolygon(E,N,...
        withinPolygon(:,1), ...
        withinPolygon(:,2));
else
    % conserve all data
    X_SBP_PolygonMask = true(nSamples,nBeams,nPings);
end


%% Mask 5: Removing pings that have bad quality
% for now we will use the percentage of faulty bottom detects as a
% threshold to identify bad-quality pings. Aka, if mask_ping=10, then we 
% will mask the ping if 10% or more of its bottom detects are faulty.
% Quick data look-up shows that good pings can still have up to 6% faulty
% bottom detects, usually on the outer beams. A ping with some missing
% bottom detects in the data is around 8-15%, so good rule of thumb would be
% to use:
%   'maxPercentFaultyDetects': proportion (in %) of faulty detects in a
%   ping beyond which the entire ping is to be discarded. Typically ~7 to
%   remove all but perfect pings, ~ 10 to 20 to allow pings with a few
%   faulty detects, or >20 to remove only the most severly affected pings.
%   Default is 100 to KEEP all data. 
    
% get maxPercentFaultyDetects parameter
if ~isfield(params,'maxPercentFaultyDetects'), params.maxPercentFaultyDetects = []; end % default
mustBeNumeric(params.maxPercentFaultyDetects); % validate (can improve this)
maxPercentFaultyDetects = params.maxPercentFaultyDetects;

if maxPercentFaultyDetects<100
    % extract needed data
    faultyDetects = fData.(sprintf('%s_BP_DetectedRangeInSamples',datagramSource))(:,iPings)==0; % raw bottom detect
    proportionFaultyDetects = 100.*sum(faultyDetects)./nBeams;
    % build mask: 1: to conserve, 0: to remove
    X_1P_PingMask = proportionFaultyDetects<maxPercentFaultyDetects;
    X_11P_PingMask = permute(X_1P_PingMask ,[3,1,2]);
else
    % conserve all data
    X_11P_PingMask = true(1,1,nPings);
end


%% Mask 6: Removing samples beyond a range below the Minimum Slant Range (MSR)
%   'maxRangeBelowMSR': range (in m) from the Minimum Slant Range (MSR)
%   beyond which data are to be discarded. Typically 0 to remove all data
%   past the MSR, or -1 to -10 to be more conservative. Default is inf to
%   KEEP all data. 

% get maxRangeBelowBottomEcho parameter
if ~isfield(params,'maxRangeBelowMSR'), params.maxRangeBelowMSR = inf; end % default
mustBeNumeric(params.maxRangeBelowMSR); % validate
maxRangeBelowMSR = params.maxRangeBelowMSR;

if ~isinf(maxRangeBelowMSR)
    % get processed bottom range (in m)
    bottomRange = fData.X_BP_bottomRange(:,iPings);
    % min slant range per ping
    bottomRange(bottomRange==0) = NaN;
    P1_minSlantRange = nanmin(bottomRange)';
    SBP_minSlantRange = repmat( permute(P1_minSlantRange,[3,2,1]),nSamples,nBeams);
    % build mask: 1: to conserve, 0: to remove
    X_SBP_MinSlantRangeMask = sampleRange < SBP_minSlantRange + maxRangeBelowMSR;
else 
    % conserve all data
    X_SBP_MinSlantRangeMask = true(nSamples,nBeams,nPings);
end


%% Calculate total mask
mask = X_1BP_OuterBeamsMask & X_SBP_CloseRangeMask & X_SBP_BottomRangeMask & X_SBP_PolygonMask & X_11P_PingMask & X_SBP_MinSlantRangeMask;

% display results
if DEBUG
    ip = 1;
    figure; tiledlayout(1,2);
    ax1=nexttile();imagesc(data(:,:,ip));
    grid on;colormap(jet);colorbar;title('before masking');c=caxis;
    dataOutTemp = data(:,:,ip);
    dataOutTemp(~mask(:,:,ip)) = NaN;
    ax2=nexttile();imagesc(dataOutTemp);
    grid on;colormap(jet);colorbar;title('masked');caxis(c)
    linkaxes([ax1,ax2]);
end


%% apply total mask
data(~mask) = NaN;


%% end message
comms.finish('Done');
