function [fData] = CFF_process_ping(fData,varargin)
% function [fData] = CFF_process_ping(fData,varargin)
%
% DESCRIPTION
%
% Interpolates navigation data from ancillary sensors to ping time (i.e.
% Easting, Northing, Height, Grid Convergence, Heading).
%
% INPUT VARIABLES
%
% - fData: FABCdata structure for the storage of EM series multibeam data,
% as created by convmat2fabc
%
% - varargin{1}: datagramSource (optional): 'De', 'SI', 'WC', etc... as the
% source datagram to use for time/date/pingcounter. If not specified,
% function will look in order for "De", "X8" or "WC". Returns error if
% can't find any of these three.
%
% - varargin{2}: ellips (optional): see "CFF_ll2tm.m" for options. If not
% specified, function will use 'wgs84'
%
% - varargin{3}: tmproj (optional): see "CFF_ll2tm.m" for options. If not
% specified, function will use the UTM projection for the first position
% fix location.
%
% - varargin{4}: navLat (optional): navigation latency to introduce, in
% milliseconds. If not specified, function will use navLat = 0;
%
% OUTPUT VARIABLES
%
% - fData: updated FABCdata structure
%
% RESEARCH NOTES
%
% new developments needed:
% this function is to obtain best info on sonar location (E,N,H) and
% orientation (azimuth, depression, heading) at time of ping. In the
% future, maybe develop here to accept SBET.
%
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% 1. VARARGIN CHECKS

% varargin{1}, source datagram for ping info:
if nargin>1
    % datagramSource was specified, get ping time 
    datagramSource = varargin{1};
    expression = ['pingTSMIM = fData.' datagramSource '_P1_TimeSinceMidnightInMilliseconds;'];
    eval(expression);
    expression = ['date = num2str(fData.' datagramSource '_P1_Date);'];
    eval(expression);
    expression = ['pingCounter  = fData.' datagramSource '_P1_PingCounter;'];
    eval(expression);
else
    % datagramSource was not specified
    fDataFields = fields(fData);
    if sum(strcmp(fDataFields, 'De_P1_Date'))
        datagramSource = 'De';
        pingTSMIM  = fData.De_P1_TimeSinceMidnightInMilliseconds;
        date         = num2str(fData.De_P1_Date);
        pingCounter  = fData.De_P1_PingCounter;
        fprintf(['datagramSource not specified. Using ''' datagramSource '''...\n']);
    elseif sum(strcmp(fDataFields, 'X8_P1_Date'))
        datagramSource = 'X8';
        pingTSMIM  = fData.X8_P1_TimeSinceMidnightInMilliseconds;
        date         = num2str(fData.X8_P1_Date);
        pingCounter  = fData.X8_P1_PingCounter;
        fprintf(['datagramSource not specified. Using ''' datagramSource '''...\n']);
    elseif sum(strcmp(fDataFields, 'WC_P1_Date'))
        datagramSource = 'WC';
        pingTSMIM  = fData.WC_P1_TimeSinceMidnightInMilliseconds;
        date         = num2str(fData.WC_P1_Date);
        pingCounter  = fData.WC_P1_PingCounter;
        fprintf(['datagramSource not specified. Using ''' datagramSource '''...\n']);
    else
        error('can''t find a suitable datagramSource')
    end
end

% varargin{2}: ellipsoid for CFF_ll2tm conversion
if nargin>2
    ellips=varargin{2};
else
    ellips = 'wgs84';
    %fprintf('ellips not specified. Using ''wgs84''...\n');
end

% varargin{3}: TM projection for CFF_ll2tm conversion
if nargin>3
    tmproj=varargin{3};
else
    firstPosLat = fData.Po_D1_Latitude(1)./20000000;
    firstPosLon = fData.Po_D1_Longitude(1)./10000000;
    [dump1, dump2, dump3, dump4, tmproj] = CFF_ll2tm(firstPosLon,firstPosLat,ellips,'utm');
    tmproj = ['utm' tmproj];
    %fprintf(['tmproj not specified. Using ''' tmproj '''...\n']);
end

% varargin{?}: datum conversion?
...

% varargin{4}: navigation latency
if nargin==5
    navLat = varargin{4};
else
    navLat=0;
    %fprintf('navLat not specified. Using 0...\n');
end


%% 2. EXTRACT DATA FROM POSITION AND HEIGHT DATAGRAMS
% in the future, offer possibility to import position/orientation from
% other files, say SBET
posLatitude  = fData.Po_D1_Latitude./20000000; % now in decimal degrees
posLongitude = fData.Po_D1_Longitude./10000000; % now in decimal degrees
posHeading   = fData.Po_D1_HeadingOfVessel./100; % now in degrees relative to north
posSpeed     = fData.Po_D1_SpeedOfVesselOverGround./100; % now in m/s
posTSMIM     = fData.Po_D1_TimeSinceMidnightInMilliseconds; % in ms

heiHeight    = fData.He_D1_Height./100; % now m
heiTSMIM     = fData.He_D1_TimeSinceMidnightInMilliseconds; % in ms


%% 3. PROCESS PING TIME
% create ping time vectors in serial date number (SDN, Matlab, the whole
% and fractional number of days from January 0, 0000) and Time Since
% Midnight In Milliseconds (TSMIM, Kongsberg).
pingYear    = str2num(date(:,1:4));
pingMonth   = str2num(date(:,5:6));
pingDay     = str2num(date(:,7:8));
pingSecond  = pingTSMIM./1000;
pingSDN     = datenum(pingYear, pingMonth, pingDay, 0, 0, pingSecond) + navLat./(1000.*60.*60.*24);
pingTSMIM   = pingTSMIM + navLat;


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
jumps   = zeros(length(posHeading),1);
if ~isempty(posJump)
    for jj=1:length(posJump)
        jumps(posJump(jj)+1:end) = jumps(posJump(jj)+1:end) - 1;
    end
end
if ~isempty(negJump)
    for jj=1:length(negJump)
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
    A = posTSMIM-pingTSMIM(jj);
    iA = find (A == 0);
    if A > 0
        % the ping time is older than any navigation time, extrapolate from the first items in navigation array.
        pingE(jj) = posE(2) + (posE(2)-posE(1)).*(pingTSMIM(jj)-posTSMIM(2))./(posTSMIM(2)-posTSMIM(1));
        pingN(jj) = posN(2) + (posN(2)-posN(1)).*(pingTSMIM(jj)-posTSMIM(2))./(posTSMIM(2)-posTSMIM(1));
        pingGridConv(jj) = posGridConv(2) + (posGridConv(2)-posGridConv(1)).*(pingTSMIM(jj)-posTSMIM(2))./(posTSMIM(2)-posTSMIM(1));
        pingHeading(jj) = posHeading(2) + (posHeading(2)-posHeading(1)).*(pingTSMIM(jj)-posTSMIM(2))./(posTSMIM(2)-posTSMIM(1));
        pingSpeed(jj) = posSpeed(2) + (posSpeed(2)-posSpeed(1)).*(pingTSMIM(jj)-posTSMIM(2))./(posTSMIM(2)-posTSMIM(1));
    elseif A < 0
        % the ping time is more recent than any navigation time, extrapolate from the last items in navigation array.
        pingE(jj) = posE(end) + (posE(end)-posE(end-1)).*(pingTSMIM(jj)-posTSMIM(end))./(posTSMIM(end)-posTSMIM(end-1));
        pingN(jj) = posN(end) + (posN(end)-posN(end-1)).*(pingTSMIM(jj)-posTSMIM(end))./(posTSMIM(end)-posTSMIM(end-1));
        pingGridConv(jj) = posGridConv(end) + (posGridConv(end)-posGridConv(end-1)).*(pingTSMIM(jj)-posTSMIM(end))./(posTSMIM(end)-posTSMIM(end-1));
        pingHeading(jj) = posHeading(end) + (posHeading(end)-posHeading(end-1)).*(pingTSMIM(jj)-posTSMIM(end))./(posTSMIM(end)-posTSMIM(end-1));
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
        [temp,iMax] = max(A(iNegA));
        iA(1) = iNegA(iMax); % index of navigation time just older than ping time
        iPosA = find(A>0);
        [temp,iMin] = min(A(iPosA));
        iA(2) = iPosA(iMin); % index of navigation time just more recent ping time
        % now extrapolate easting, northing, grid convergence and heading
        pingE(jj) = posE(iA(2)) + (posE(iA(2))-posE(iA(1))).*(pingTSMIM(jj)-posTSMIM(iA(2)))./(posTSMIM(iA(2))-posTSMIM(iA(1)));
        pingN(jj) = posN(iA(2)) + (posN(iA(2))-posN(iA(1))).*(pingTSMIM(jj)-posTSMIM(iA(2)))./(posTSMIM(iA(2))-posTSMIM(iA(1)));
        pingGridConv(jj) = posGridConv(iA(2)) + (posGridConv(iA(2))-posGridConv(iA(1))).*(pingTSMIM(jj)-posTSMIM(iA(2)))./(posTSMIM(iA(2))-posTSMIM(iA(1)));
        pingHeading(jj) = posHeading(iA(2)) + (posHeading(iA(2))-posHeading(iA(1))).*(pingTSMIM(jj)-posTSMIM(iA(2)))./(posTSMIM(iA(2))-posTSMIM(iA(1)));
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
pingH = nan(size(pingTSMIM));

% interpolate Height at ping times
for jj = 1:length(pingTSMIM)
    A = heiTSMIM-pingTSMIM(jj);
    iA = find (A == 0);
    if A > 0
        % the ping time is older than any height time, extrapolate from the first items in height array.
        pingH(jj) = heiHeight(2) + (heiHeight(2)-heiHeight(1)).*(pingTSMIM(jj)-heiTSMIM(2))./(heiTSMIM(2)-heiTSMIM(1));
    elseif A < 0
        % the ping time is more recent than any height time, extrapolate from the last items in height array.
        pingH(jj) = heiHeight(end) + (heiHeight(end)-heiHeight(end-1)).*(pingTSMIM(jj)-heiTSMIM(end))./(heiTSMIM(end)-heiTSMIM(end-1));
    elseif ~isempty(iA)
        % the ping time corresponds to an existing height time, get height
        % from it
        pingH(jj) = heiHeight(iA);
    else
        % the ping time is within the limits of the height time array but doesn't correspond to any value in it, interpolate from nearest values
        iNegA = find(A<0);
        [temp,iMax] = max(A(iNegA));
        iA(1) = iNegA(iMax); % index of height time just older than ping time
        iPosA = find(A>0);
        [temp,iMin] = min(A(iPosA));
        iA(2) = iPosA(iMin); % index of height time just more recent ping time
        % now extrapolate height
        pingH(jj) = heiHeight(iA(2)) + (heiHeight(iA(2))-heiHeight(iA(1))).*(pingTSMIM(jj)-heiTSMIM(iA(2)))./(heiTSMIM(iA(2))-heiTSMIM(iA(1)));
    end
end


%% 6. SAVE RESULTS

fData.MET_datagramSource                  = datagramSource;
fData.MET_navigationLatencyInMilliseconds = navLat;
fData.MET_ellips                          = ellips;
fData.MET_tmproj                          = tmproj;

fData.X_P1_pingCounter  = pingCounter;
fData.X_P1_pingTSMIM    = pingTSMIM;
fData.X_P1_pingSDN      = pingSDN;
fData.X_P1_pingE        = pingE;
fData.X_P1_pingN        = pingN;
fData.X_P1_pingH        = pingH;
fData.X_P1_pingGridConv = pingGridConv;
fData.X_P1_pingHeading  = pingHeading;
fData.X_P1_pingSpeed    = pingSpeed;

% fData.X_P1_pingAzimuth?
% fData.X_P1_pingDepression?
