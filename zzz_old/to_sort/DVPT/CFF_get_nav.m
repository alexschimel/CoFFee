function [FPBS] = CFF_get_nav(FPBS,MATfiles,varargin)
%CFF_GET_NAV  One-line description
%
%   Interpolates navigation data from ancillary sensors (i.e. Easting,
%   Northing, Height, Grid Convergence, Heading) in MAT file to ping time
%   in FPBS Data.
%
%   INPUT VARIABLES
%
%   - FPBS: File/Ping/Beam/Sample Data structure for the storage of
%   multibeam data, as created by CFF_convert_mat_to_fpbs
%
%   - MATfiles: List of MAT files containing the ancillary sensors data, as
%   created by CFF_convert_all_to_mat
%
%   - varargin{1}: navLat (optional): navigation latency to introduce, in
%   milliseconds. If not specified, function will use navLat = 0;
%
%   OUTPUT VARIABLES
%
%   - FPBS: File/Ping/Beam/Sample Data structure updated with navigation
%   data (in Ping table)
%
%   RESEARCH NOTES
%
%   new developments needed:
%   this function is to obtain best info on sonar location (E,N,H) and
%   orientation (azimuth, depression, heading) at time of ping. In the
%   future, maybe develop here to accept SBET.
%
%   This function uses CFF_unwrap_heading and CFF_interpolate_nav
%
%   add a possible datum conversion in varargin
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2010-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% 1. VARARGIN CHECKS
% varargin{1}: navigation latency
if nargin>2
    navLat = varargin{1};
else
    navLat=0;
end

% This function is made for a cell array of filenames. If input is a single
% filename string, turn to cell
if ischar(MATfiles)
    MATfiles = {MATfiles};
end

%% 2. EXTRACT DATA FROM POSITION AND HEIGHT DATAGRAMS
% in the future, offer possibility to import position/orientation from
% other files, say SBET

for ff = 1:length(MATfiles)
    
    % load attitude, height and position datagrams for this file
    load(MATfiles{ff},'EM_Position','EM_Height','EM_Attitude');
    
    % read attitude data
    nEntries = EM_Attitude.NumberOfEntries; % number of entries per attitude datagram
    iEntries = [cumsum(nEntries)-nEntries+1;cumsum(nEntries)]; % indices of entries put together
    clear attTime attRoll attPitch attHeave attHeading
    for aa = 1:length(nEntries)
        baseTime = datenum(int2str(EM_Attitude.Date(aa)),'yyyymmdd') + EM_Attitude.TimeSinceMidnightInMilliseconds(aa)./(1000*60*60*24);
        attTime(iEntries(1,aa):iEntries(2,aa),1) = baseTime + EM_Attitude.TimeInMillisecondsSinceRecordStart{aa}./(1000*60*60*24);
        attRoll(iEntries(1,aa):iEntries(2,aa),1) = EM_Attitude.Roll{aa}./100; % now in degrees relative to vertical
        attPitch(iEntries(1,aa):iEntries(2,aa),1) = EM_Attitude.Pitch{aa}./100; % now in degrees relative to vertical
        attHeave(iEntries(1,aa):iEntries(2,aa),1) = EM_Attitude.Heave{aa}./100; % now in m
        attHeading(iEntries(1,aa):iEntries(2,aa),1) = EM_Attitude.Heading{aa}./100; % now in degrees relative to north
    end
    
    % read height data
    heiTime    = datenum(int2str(EM_Height.Date'),'yyyymmdd') + EM_Height.TimeSinceMidnightInMilliseconds'./(1000*60*60*24); % in datenum
    heiHeight  = EM_Height.Height'./100; % now in m
    % height is heave plus altitude, decimated. Not a great estimate. Code
    % to use SBET for height as soon as possible.
    
    % read position data
    posTime                     = datenum(int2str(EM_Position.Date'),'yyyymmdd') + EM_Position.TimeSinceMidnightInMilliseconds'./(1000.*60.*60.*24); % in datenum
    posLatitude                 = EM_Position.Latitude'./20000000; % now in decimal degrees
    posLongitude                = EM_Position.Longitude'./10000000; % now in decimal degrees
    posSpeedOfVesselOverGround  = EM_Position.SpeedOfVesselOverGround'./100; % now in m/s
    %posCourseOfVesselOverGround = EM_Position.CourseOfVesselOverGround'./100; % now in degrees relative to north (use attitude heading)
    %posHeading                  = EM_Position.HeadingOfVessel'./100; % now in degrees relative to north (use attitude heading)
    
    % get indices of pings corresponding to this file
    ind = find( FPBS.Ping.Index == find(cellfun( @(x) isequal(x,MATfiles{ff}), FPBS.File.Name)) );
    
    % get ping time and add latency
    pingTime = FPBS.Ping.Time(ind) + navLat./(1000.*60.*60.*24);
    
    % unwrap heading
    % allow heading values superior to
    % 360 or inferior to 0 (because every time the vessel crossed the NS
    % line, the heading jumps from 0 to 360 (or from 360 to 0) and this
    % causes a problem for following interpolation):  
    attHeading = CFF_unwrap_heading(attHeading,300);
    % posCourseOfVesselOverGround = CFF_unwrap_heading(posCourseOfVesselOverGround,300);
    % posHeading = CFF_unwrap_heading(posHeading,300);

    % interpolate navigation
    pingRoll      = CFF_interpolate_nav(attTime,attRoll,pingTime);
    pingPitch     = CFF_interpolate_nav(attTime,attPitch,pingTime);
    pingHeave     = CFF_interpolate_nav(attTime,attHeave,pingTime);
    pingHeading   = CFF_interpolate_nav(attTime,attHeading,pingTime);
    pingHeight    = CFF_interpolate_nav(heiTime,heiHeight,pingTime);
    pingLatitude  = CFF_interpolate_nav(posTime,posLatitude,pingTime);
    pingLongitude = CFF_interpolate_nav(posTime,posLongitude,pingTime);
    pingSpeed     = CFF_interpolate_nav(posTime,posSpeedOfVesselOverGround,pingTime);

    % rewrap heading
    % attHeading = mod(attHeading,360); % not needed further anyway
    % posCourseOfVesselOverGround = mod(posCourseOfVesselOverGround,360); % not used
    % posHeading = mod(posHeading,360); % not used
    pingHeading = mod(pingHeading,360);

    % save results
    FPBS.Ping.Roll(ind)      = pingRoll;
    FPBS.Ping.Pitch(ind)     = pingPitch;
    FPBS.Ping.Heave(ind)     = pingHeave;
    FPBS.Ping.Heading(ind)   = pingHeading;
    FPBS.Ping.Height(ind)    = pingHeight;
    FPBS.Ping.Latitude(ind)  = pingLatitude;
    FPBS.Ping.Longitude(ind) = pingLongitude;
    FPBS.Ping.Speed(ind)     = pingSpeed;
    
end
