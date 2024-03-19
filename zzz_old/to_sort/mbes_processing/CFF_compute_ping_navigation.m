function [fData] = CFF_compute_ping_navigation(fData,varargin)
% CFF_compute_ping_navigation.m
%
% Interpolates navigation data from ancillary sensors to ping time (i.e.
% Easting, Northing, Height, Grid Convergence, Heading, Speed).
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |fData|: Required. Structure for the storage of kongsberg EM series
% multibeam data in a format more convenient for processing. The data is
% recorded as fields coded "a_b_c" where "a" is a code indicating data
% origing, "b" is a code indicating data dimensions, and "c" is the data
% name. See the help of function CFF_convert_ALLdata_to_fData.m for
% description of codes.
% * |datagramSource| (optional): 'De', 'SI', 'WC', etc... as the
% source datagram to use for time/date/pingcounter. If not specified,
% function will look in order for "De", "X8" or "WC". Returns error if
% can't find any of these three.
% * |ellips| (optional): see "CFF_ll2tm.m" for options. If not
% specified, function will use 'wgs84'
% * |tmproj| (optional): see "CFF_ll2tm.m" for options. If not
% specified, function will use the UTM projection for the first position
% fix location.
% * |navLat| (optional): navigation latency to introduce, in
% milliseconds. If not specified, function will use navLat = 0;
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with ping navigation fields
%
% *DEVELOPMENT NOTES*
%
% * new developments needed: this function is to obtain best info on sonar
% location (E,N,H) and orientation (azimuth, depression, heading) at time
% of ping. In the future, maybe develop here to accept SBET.
% * function formerly named CFF_process_ping.m
%
%   Copyright 2014-2018 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% 1. VARARGIN CHECKS

% varargin{1}, source datagram for ping info:
if nargin>1
    
    datagramSource = varargin{1};
    
else
    
    % datagramSource was not specified, check fData for it
    if isfield(fData,'MET_datagramSource')
        datagramSource = fData.MET_datagramSource;
    else
        % not in fData eiter, check for possible sources
        fDataFields = fields(fData);
        if sum(strcmp(fDataFields, 'De_1P_Date'))
            datagramSource = 'De';
            fprintf(['...datagramSource not specified for ping processing. Using ''' datagramSource '''...\n']);
        elseif sum(strcmp(fDataFields, 'X8_1P_Date'))
            datagramSource = 'X8';
            fprintf(['...datagramSource not specified for ping processing. Using ''' datagramSource '''...\n']);
        elseif sum(strcmp(fDataFields, 'WC_1P_Date'))
            datagramSource = 'WC';
            fprintf(['...datagramSource not specified for ping processing. Using ''' datagramSource '''...\n']);
        elseif sum(strcmp(fDataFields, 'AP_1P_Date'))
            datagramSource = 'AP';
            fprintf(['...datagramSource not specified for ping processing. Using ''' datagramSource '''...\n']);
        else
            error('can''t find a suitable datagramSource')
        end
    end
end

% get ping time
pingTSMIM    = fData.([datagramSource '_1P_TimeSinceMidnightInMilliseconds']);
date         = fData.([datagramSource '_1P_Date']);
pingCounter  = fData.([datagramSource '_1P_PingCounter']);


pingDate = datenum(cellfun(@num2str,num2cell(date),'un',0),'yyyymmdd');

% varargin{2}: ellipsoid for CFF_ll2tm conversion
if nargin>2
    ellips = varargin{2};
else
    ellips = 'wgs84';
    %fprintf('ellips not specified. Using ''wgs84''...\n');
end

% varargin{3}: TM projection for CFF_ll2tm conversion
if nargin>3
    tmproj = varargin{3};
else
    firstPosLat = fData.Po_1D_Latitude(1)./20000000;
    firstPosLon = fData.Po_1D_Longitude(1)./10000000;
    [~,~,~,~,tmproj] = CFF_ll2tm(firstPosLon,firstPosLat,ellips,'utm');
    tmproj = ['utm' tmproj];
    %fprintf(['tmproj not specified. Using ''' tmproj '''...\n']);
end

% varargin{?}: datum conversion?
...
    
% varargin{4}: navigation latency
if nargin == 5
    navLat = varargin{4};
else
    navLat = 0;
    %fprintf('navLat not specified. Using 0...\n');
end


%% 2. EXTRACT DATA FROM POSITION AND HEIGHT DATAGRAMS
% in the future, offer possibility to import position/orientation from
% other files, say SBET

posLatitude  = fData.Po_1D_Latitude./20000000; % now in decimal degrees
posLongitude = fData.Po_1D_Longitude./10000000; % now in decimal degrees
posHeading   = fData.Po_1D_HeadingOfVessel./100; % now in degrees relative to north
posSpeed     = fData.Po_1D_SpeedOfVesselOverGround./100; % now in m/s
posTSMIM     = fData.Po_1D_TimeSinceMidnightInMilliseconds; % in ms

posDate      = datenum(cellfun(@num2str,num2cell(fData.Po_1D_Date),'un',0),'yyyymmdd');
posSDN       = posDate(:)'+ posTSMIM/(24*60*60*1000);



%% 3. PROCESS PING TIME
% create ping time vectors in serial date number (SDN, Matlab, the whole
% and fractional number of days from January 0, 0000) and Time Since
% Midnight In Milliseconds (TSMIM, Kongsberg).

pingSDN = pingDate(:)'+ pingTSMIM/(24*60*60*1000) + navLat./(1000.*60.*60.*24);

if isfield(fData,'He_1D_Height')
    heiHeight = fData.He_1D_Height./100; % now m
    heiDate   = datenum(cellfun(@num2str,num2cell(fData.He_1D_Date),'un',0),'yyyymmdd');
    heiSDN    = heiDate(:)' + fData.He_1D_TimeSinceMidnightInMilliseconds/(24*60*60*1000);
else
    heiHeight=zeros(size(pingTSMIM));
    heiSDN =pingSDN;
end

%% 4. PROCESS NAVIGATION AND HEADING:
% Position and heading were recorded at the sensor's time so we need to
% interpolate them at the same time to match ping time.

% convert posLatitude/posLongitude to easting/northing/grid convergence:
[posE, posN, posGridConv] = CFF_ll2tm(posLongitude, posLatitude, ellips, tmproj);

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

% initialize new vectors
pingE        = nan(size(pingTSMIM));
pingN        = nan(size(pingTSMIM));
pingGridConv = nan(size(pingTSMIM));
pingHeading  = nan(size(pingTSMIM));
pingSpeed    = nan(size(pingTSMIM));

% interpolate Easting, Northing, Grid Convergence and Heading at ping times
for jj = 1:length(pingTSMIM)
    A = posSDN-pingSDN(jj);
    iA = find (A == 0);
    if A > 0
        % the ping time is older than any navigation time, extrapolate from the first items in navigation array.
        pingE(jj) = posE(2) + (posE(2)-posE(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingN(jj) = posN(2) + (posN(2)-posN(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingGridConv(jj) = posGridConv(2) + (posGridConv(2)-posGridConv(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingHeading(jj) = posHeading(2) + (posHeading(2)-posHeading(1)).*(pingSDN(jj)-posSDN(2))./(posSDN(2)-posSDN(1));
        pingSpeed(jj) = posSpeed(2) + (posSpeed(2)-posSpeed(1)).*(pingTSMIM(jj)-posTSMIM(2))./(posTSMIM(2)-posTSMIM(1));
    elseif A < 0
        % the ping time is more recent than any navigation time, extrapolate from the last items in navigation array.
        pingE(jj) = posE(end) + (posE(end)-posE(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingN(jj) = posN(end) + (posN(end)-posN(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingGridConv(jj) = posGridConv(end) + (posGridConv(end)-posGridConv(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingHeading(jj) = posHeading(end) + (posHeading(end)-posHeading(end-1)).*(pingSDN(jj)-posSDN(end))./(posSDN(end)-posSDN(end-1));
        pingSpeed(jj) = posSpeed(end) + (posSpeed(end)-posSpeed(end-1)).*(pingTSMIM(jj)-posTSMIM(end))./(posTSMIM(end)-posTSMIM(end-1));
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
        pingSpeed(jj) = posSpeed(iA(2)) + (posSpeed(iA(2))-posSpeed(iA(1))).*(pingTSMIM(jj)-posTSMIM(iA(2)))./(posTSMIM(iA(2))-posTSMIM(iA(1)));
    end
end

% bring heading back into the interval [0 360]
posHeading  = posHeading - jumps.*360;
pingHeading = mod(pingHeading,360);


%% 5. PROCESS HEIGHT
% Height were recorded at the sensor's time so we need to
% interpolate them at the same time to match ping time.

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


%% 6. SAVE RESULTS

fData.MET_datagramSource                  = datagramSource;
fData.MET_navigationLatencyInMilliseconds = navLat;
fData.MET_ellips                          = ellips;
fData.MET_tmproj                          = tmproj;

fData.X_1P_pingCounter  = pingCounter;
fData.X_1P_pingTSMIM    = pingTSMIM;
fData.X_1P_pingSDN      = pingSDN;
fData.X_1P_pingE        = pingE;
fData.X_1P_pingN        = pingN;
fData.X_1P_pingH        = pingH;
fData.X_1P_pingGridConv = pingGridConv;
fData.X_1P_pingHeading  = pingHeading;
fData.X_1P_pingSpeed    = pingSpeed;

% fData.X_1P_pingAzimuth?
% fData.X_1P_pingDepression?
