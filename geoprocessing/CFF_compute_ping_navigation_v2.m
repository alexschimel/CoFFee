function [fData,params] = CFF_compute_ping_navigation_v2(fData,varargin)
%CFF_COMPUTE_PING_NAVIGATION_V2  Computes navigation for each ping
%
%   Computes navigation data for each ping (easting, northing, height, grid
%   convergence, heading, speed) by matching/interpolating navigation data
%   from ancillary sensors to ping time.
%
%   FDATA = CFF_COMPUTE_PING_NAVIGATION_V2(FDATA) computes ping navigation
%   for each ping in FDATA using default processing parameters, and returns
%   FDATA with additional fields from the processing.
%
%   CFF_COMPUTE_PING_NAVIGATION_V2(FDATA,PARAMS) uses processing parameters
%   defined as the fields in the PARAMS structure. Possible parameters are:
%   'datagramSource': two-letters code string for the datagram type to use
%   as a source for the date, time, and counter of pings: 'WC', 'AP', 'X8',
%   etc. By default, a datagramSource is defined automatically from the
%   datagrams available in FDATA. 
%   'navLat': navigation latency in milliseconds. By default, using 0.
%   'ellips': code string for the coordinates' ellipsoid used for
%   projection. See possible codes in CFF_LL2TM: e.g. 'wgs84', 'grs80',
%   etc. By default, using 'wgs84'.
%   'tmproj': code string for the Transverse Mercator projection. See
%   possible codes in CFF_LL2TM: e.g. 'utm54s', 'nztm2000', etc. By
%   default, using the UTM projection corresponding to the location of the 
%   first ping.
%
%   CFF_COMPUTE_PING_NAVIGATION_V2(...,'comms',COMMS) specifies if and how
%   this function communicates on its internal state (progress, info,
%   errors). COMMS can be either a CFF_COMMS object, or a text string to
%   initiate a new CFF_COMMS object. Options are 'disp', 'textprogressbar',
%   'waitbar', 'oneline', 'multilines'. By default, using an empty
%   CFF_COMMS object (i.e. no communication). See CFF_COMMS for more
%   information.  
%
%   [FDATA,PARAMS] = CFF_COMPUTE_PING_NAVIGATION_V2(...) also outputs the
%   parameters used in processing. Useful if parameters not set in input
%   but determined from the data are to be reused for another file. 
%
%   NOTES: improvements to code in the future:
%   * obtain best info on sonar location (E,N,H) and orientation (azimuth,
%   depression, heading) at time of ping. 
%   * accept improved/modified/processed navigation (e.g. SBET). 
%   * add input parameter "skipIfAlreadyDone" that compare the params to
%   the fData.MET fields and skip all the processing if they match.
%
%   See also CFF_LL2TM, CFF_LOAD_CONVERTED_FILES,
%   CFF_GEOREFERENCE_BOTTOM_DETECT, CFF_GROUP_PROCESSING.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 27-07-2022


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
comms.start('Processing navigation and heading');

% start progress
comms.progress(0,6);


%% EXTRACT PING DATA
% create ping time vectors in serial date number (SDN, Matlab, the whole
% and fractional number of days from January 0, 0000) and Time Since
% Midnight In Milliseconds (TSMIM, Kongsberg).

comms.step('Extract ping data');

% get datagramSource parameter
if ~isfield(params,'datagramSource'), params.datagramSource = CFF_get_datagramSource(fData); end % default
mustBeMember(params.datagramSource,{'AP','WC','X8','De'}); % validate
datagramSource = params.datagramSource;

% get navLat parameter
if ~isfield(params,'navLat'), params.navLat = 0; end % default
mustBeNumeric(params.navLat); % validate
navLat = params.navLat;

% get data
pingTSMIM    = fData.([datagramSource '_1P_TimeSinceMidnightInMilliseconds']);
pingDate     = fData.([datagramSource '_1P_Date']);
pingCounter  = fData.([datagramSource '_1P_PingCounter']);
pingDate     = datenum(cellfun(@num2str,num2cell(pingDate),'un',0),'yyyymmdd');
pingSDN      = pingDate(:)'+ pingTSMIM/(24*60*60*1000) + navLat./(1000.*60.*60.*24); % apply navigation latency here

comms.progress(1,6);


%% EXTRACT NAVIGATION DATA
% same for navigation. In the future, offer possibility to import
% position/orientation from other files, say SBET

comms.step('Extract navigation data');

% test if there are several sources of GPS data
if isfield(fData,'Po_1D_PositionSystemDescriptor')
    ID = unique(fData.Po_1D_PositionSystemDescriptor);
    if numel(ID) > 1
        % several sources available, we will need to choose one
        % start by eliminating those that are obviously bad.
        % I have found data where one source had lat/long values that were
        % both constant and outside of normal values. You may want to
        % devise more tests if you ever come across different examples of
        % bad position data
        isSingleEntry = arrayfun(@(x) sum(fData.Po_1D_PositionSystemDescriptor==x)==1, ID); % check if single entry (then they will be constant)
        isLatAllConst = arrayfun(@(x) all(diff(fData.Po_1D_Latitude(fData.Po_1D_PositionSystemDescriptor==x))==0), ID); % check if all constant values
        isLonAllConst = arrayfun(@(x) all(diff(fData.Po_1D_Longitude(fData.Po_1D_PositionSystemDescriptor==x))==0), ID); % check if all constant values
        isLatAllBad = arrayfun(@(x) all(abs(fData.Po_1D_Latitude(fData.Po_1D_PositionSystemDescriptor==x))>90), ID); % check if all outside [-90:90]
        isLonAllBad = arrayfun(@(x) all(abs(fData.Po_1D_Longitude(fData.Po_1D_PositionSystemDescriptor==x))>180), ID); % check if all outside [-180:180]
        idxBadPos = (~isSingleEntry & (isLatAllConst|isLonAllConst)) | isLatAllBad | isLonAllBad;
        % removing those bad sources
        ID = ID(~idxBadPos);
        if numel(ID)==1
            % only one good source left, just use that one
            pos_idx = fData.Po_1D_PositionSystemDescriptor==ID;
        else
            % still several sources available
            % find the one with the best fix quality
            meanFixQuality = arrayfun(@(x) nanmean(fData.Po_1D_MeasureOfPositionFixQuality(fData.Po_1D_PositionSystemDescriptor==x)), ID);
            [~,idx_keep] = min(meanFixQuality);
            pos_idx = fData.Po_1D_PositionSystemDescriptor==ID(idx_keep);
            comms.info(sprintf('Several sources of GPS data available. Using source with ID: %d',ID(idx_keep)));
        end
    else
        % single source. Use all datagrams.
        pos_idx = 1:numel(fData.Po_1D_Latitude);
    end
else
    % using older version of converted data, throw warning and continue
    comms.info('Navigation information in your converted data indicates it is not up to date with fData version. Consider reconverting this file, particularly if you see strange patterns in the navigation, or if two GPS sources have been logged in the file.');
    pos_idx = 1:numel(fData.Po_1D_Latitude);
end

% get data
posLatitude  = fData.Po_1D_Latitude(pos_idx); 
posLongitude = fData.Po_1D_Longitude(pos_idx);
posHeading   = fData.Po_1D_HeadingOfVessel(pos_idx);
posSpeed     = fData.Po_1D_SpeedOfVesselOverGround(pos_idx);
posTSMIM     = fData.Po_1D_TimeSinceMidnightInMilliseconds(pos_idx); % time since midnight in milliseconds
posDate      = datenum(cellfun(@num2str,num2cell(fData.Po_1D_Date(pos_idx)),'un',0),'yyyymmdd');
posSDN       = posDate(:)'+ posTSMIM/(24*60*60*1000); % serial date number

comms.progress(2,6);

% debug display
dbug = 0;
if dbug
    figure;
    clear ax
    dt = datetime(posSDN,'ConvertFrom','datenum');
    tiledlayout(4,1);
    ax(1) = nexttile; plot(dt, posLatitude, '.-'); ylabel('latitude'); grid on
    ax(2) = nexttile; plot(dt, posLongitude, '.-'); ylabel('longitude'); grid on
    ax(3) = nexttile; plot(dt, posHeading, '.-'); ylabel('heading'); grid on
    ax(4) = nexttile; plot(dt, posSpeed, '.-'); ylabel('speed'); grid on
    linkaxes(ax,'x') 
    figure;
    plot(posLongitude,posLatitude, '.-'); 
    xlabel('longitude');
    ylabel('latitude');
    grid on
end


%% EXTRACT HEIGHT DATA

comms.step('Extract height data');

if isfield(fData,'He_1D_Height')
    heiHeight = fData.He_1D_Height; % now m
    heiDate   = datenum(cellfun(@num2str,num2cell(fData.He_1D_Date),'un',0),'yyyymmdd');
    heiSDN    = heiDate(:)' + fData.He_1D_TimeSinceMidnightInMilliseconds/(24*60*60*1000);
else
    % no height datagrams, create fake variables
    heiHeight = zeros(size(pingTSMIM));
    heiSDN    = pingSDN;
end

comms.progress(3,6);

% debug display
dbug = 0;
if dbug
    figure;
    dt = datetime(heiSDN,'ConvertFrom','datenum');
    plot(dt, heiHeight, '.-'); ylabel('height'); grid on
end


%% PROCESS NAVIGATION AND HEADING
% Get position and heading for each ping. Position and heading were
% recorded at the sensor's time so we need to interpolate them at the same
% time to match ping time.

comms.step('Processing navigation and heading');

% get ellips parameter
if ~isfield(params,'ellips'), params.ellips = 'wgs84'; end % default
mustBeMember(params.ellips,{'wgs84','grs80'}); % validate
ellips = params.ellips;

% get tmproj parameter, or use default UTM zone from first ping
if ~isfield(params,'tmproj')
    % default
    [~,~,~,~,params.tmproj] = CFF_ll2tm(posLongitude(1),posLatitude(1),ellips,'utm');
    params.tmproj = ['utm' params.tmproj];
    comms.info(['tmproj not specified in input. Defining it from first position fix: ''' params.tmproj '''']);
end
mustBeA(params.tmproj,'char'); % validate (too many cases to validate better)
tmproj = params.tmproj;

% convert posLatitude/posLongitude to easting/northing/grid convergence:
[posE, posN, posGridConv] = CFF_ll2tm(posLongitude, posLatitude, ellips, tmproj);

% we need at least two position samples to process the navigation. If there
% is only one, make up another one using dead reckoning
if numel(posE)==1
    posE = [posE, posE + posSpeed.*cosd(posHeading)];
    posN = [posN, posN + posSpeed.*sind(posHeading)];
    posGridConv = [posGridConv, posGridConv];
    posHeading = [posHeading, posHeading];
    posSpeed = [posSpeed, posSpeed];
    posTSMIM = [posTSMIM, posTSMIM + 1000]; % + 1 sec
    posSDN = [posSDN, posSDN + 1/(24*60*60)]; % + 1 sec
end

% convert heading to degrees and allow heading values superior to
% 360 or inferior to 0 (because every time the vessel crossed the NS
% line, the heading jumps from 0 to 360 (or from 360 to 0) and this
% causes a problem for following interpolation):

posJump = find(diff(posHeading)>300);
negJump = find(diff(posHeading)<-300);
jumps   = zeros(1,length(posHeading));

if ~isempty(posJump)
    for jj = 1:length(posJump)
        jumps(posJump(jj)+1:end) = jumps(posJump(jj)+1:end) - 1;
    end
end

if ~isempty(negJump)
    for jj = 1:length(negJump)
        jumps(negJump(jj)+1:end) = jumps(negJump(jj)+1:end) + 1;
    end
end

posHeading = posHeading + jumps.*360;

% dirty heading fix if first value is null
if posHeading(1)==0 && abs(posHeading(2))>5
    posLatitude(1) = [];
    posLongitude(1) = [];
    posHeading(1) = [];
    posSpeed(1) = [];
    posTSMIM(1) = [];
    posDate(1) = [];
    posSDN(1) = [];
    jumps(1) = [];
end

% initialize new vectors
pingE        = nan(size(pingSDN));
pingN        = nan(size(pingSDN));
pingGridConv = nan(size(pingSDN));
pingHeading  = nan(size(pingSDN));
pingSpeed    = nan(size(pingSDN));

% interpolate Easting, Northing, Grid Convergence and Heading at ping times
for jj = 1:length(pingSDN)
    A = posSDN-pingSDN(jj);
    iA = find (A == 0);
    if A > 0
        % the ping time is older than any navigation time, extrapolate from the first items in navigation array.
        pingE(jj) = posE(2) + (posE(2)-posE(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingN(jj) = posN(2) + (posN(2)-posN(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingGridConv(jj) = posGridConv(2) + (posGridConv(2)-posGridConv(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingHeading(jj) = posHeading(2) + (posHeading(2)-posHeading(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingSpeed(jj) = posSpeed(2) + (posSpeed(2)-posSpeed(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
    elseif A < 0
        % the ping time is more recent than any navigation time, extrapolate from the last items in navigation array.
        pingE(jj) = posE(end) + (posE(end)-posE(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingN(jj) = posN(end) + (posN(end)-posN(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingGridConv(jj) = posGridConv(end) + (posGridConv(end)-posGridConv(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingHeading(jj) = posHeading(end) + (posHeading(end)-posHeading(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingSpeed(jj) = posSpeed(end) + (posSpeed(end)-posSpeed(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
    elseif ~isempty(iA)
        % the ping time corresponds to an existing navigation time, get easting and northing from it.
        pingE(jj) = posE(iA);
        pingN(jj) = posN(iA);
        pingGridConv(jj) = posGridConv(iA);
        pingHeading(jj) = posHeading(iA);
        pingSpeed(jj) = posSpeed(iA);
    else
        % the ping time is within the limits of the navigation time array but doesn't correspond to any value in it, interpolate from nearest values
        iNegA = find(A<0);
        [~,iMax] = max(A(iNegA));
        iA(1) = iNegA(iMax); % index of navigation time just older than ping time
        iPosA = find(A>0);
        [~,iMin] = min(A(iPosA));
        iA(2) = iPosA(iMin); % index of navigation time just more recent ping time
        % now extrapolate easting, northing, grid convergence and heading
        pingE(jj) = posE(iA(2)) + (posE(iA(2))-posE(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
        pingN(jj) = posN(iA(2)) + (posN(iA(2))-posN(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
        pingGridConv(jj) = posGridConv(iA(2)) + (posGridConv(iA(2))-posGridConv(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
        pingHeading(jj) = posHeading(iA(2)) + (posHeading(iA(2))-posHeading(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
        pingSpeed(jj) = posSpeed(iA(2)) + (posSpeed(iA(2))-posSpeed(iA(1))).*(pingSDN(jj)-posSDN(iA(2)))./(posSDN(iA(2))-posSDN(iA(1)));
    end
end

% bring heading back into the interval [0 360]
posHeading  = posHeading - jumps.*360;
pingHeading = mod(pingHeading,360);

comms.progress(4,6);

% debug display
dbug = 0;
if dbug
    figure;
    clear ax
    dt = datetime(pingSDN,'ConvertFrom','datenum');
    tiledlayout(5,1);
    ax(1) = nexttile; plot(dt, pingN, '.-'); ylabel('northing'); grid on
    ax(2) = nexttile; plot(dt, pingE, '.-'); ylabel('easting'); grid on
    ax(3) = nexttile; plot(dt, pingGridConv, '.-'); ylabel('grid convergence'); grid on
    ax(4) = nexttile; plot(dt, pingHeading, '.-'); ylabel('heading'); grid on
    ax(5) = nexttile; plot(dt, pingSpeed, '.-'); ylabel('speed'); grid on
    linkaxes(ax,'x') 
    figure;
    plot(pingE,pingN, '.-'); 
    xlabel('easting');
    ylabel('northing');
    grid on
end



%% PROCESS HEIGHT
% Get height for each ping. Height were recorded at the sensor's time so we
% need to interpolate them at the same time to match ping time.

comms.step('Processing height');

% initialize new vectors
pingH = nan(size(pingSDN));

% interpolate Height at ping times
for jj = 1:length(pingSDN)
    A = heiSDN-pingSDN(jj);
    iA = find (A == 0,1);
    if A > 0
        % the ping time is older than any height time, extrapolate from the first items in height array.
        pingH(jj) = heiHeight(2) + (heiHeight(2)-heiHeight(1)).*(pingSDN(jj)-heiSDN(2))./(heiSDN(2)-heiSDN(1));
    elseif A < 0
        % the ping time is more recent than any height time, extrapolate from the last items in height array.
        pingH(jj) = heiHeight(end) + (heiHeight(end)-heiHeight(end-1)).*(pingSDN(jj)-heiSDN(end))./(heiSDN(end)-heiSDN(end-1));
    elseif ~isempty(iA)
        % the ping time corresponds to an existing height time, get height
        % from it
        pingH(jj) = heiHeight(iA);
    else
        % the ping time is within the limits of the height time array but doesn't correspond to any value in it, interpolate from nearest values
        iNegA = find(A<0);
        [~,iMax] = max(A(iNegA));
        iA(1) = iNegA(iMax); % index of height time just older than ping time
        iPosA = find(A>0);
        [~,iMin] = min(A(iPosA));
        iA(2) = iPosA(iMin); % index of height time just more recent ping time
        % now extrapolate height
        pingH(jj) = heiHeight(iA(2)) + (heiHeight(iA(2))-heiHeight(iA(1))).*(pingSDN(jj)-heiSDN(iA(2)))./(heiSDN(iA(2))-heiSDN(iA(1)));
    end
end

comms.progress(5,6);


%% SAVE RESULTS

comms.step('Save results');

% save processed results
fData.X_1P_pingCounter  = pingCounter;
fData.X_1P_pingTSMIM    = pingTSMIM;
fData.X_1P_pingSDN      = pingSDN;
fData.X_1P_pingE        = pingE;
fData.X_1P_pingN        = pingN;
fData.X_1P_pingH        = pingH;
fData.X_1P_pingGridConv = pingGridConv;
fData.X_1P_pingHeading  = pingHeading;
fData.X_1P_pingSpeed    = pingSpeed;

% save processing parameters
fData.MET_datagramSource = datagramSource;
fData.MET_navigationLatencyInMilliseconds = navLat;
fData.MET_ellips = ellips;
fData.MET_tmproj = tmproj;

% sort fields by name
fData = orderfields(fData);

% also save parameters back in params, for possible reuse for another file
params.datagramSource = datagramSource;
params.navLat = navLat;
params.ellips = ellips;
params.tmproj = tmproj;

comms.progress(6,6);


%% end message
comms.finish('Done');
