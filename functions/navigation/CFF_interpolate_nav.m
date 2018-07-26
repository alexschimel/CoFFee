function ping_data = CFF_interpolate_nav(sensor_time,sensor_data,ping_time)
% ping_data = CFF_interpolate_nav(sensor_time,sensor_data,ping_time)
%
% DESCRIPTION
%
% This function interpolates sensor_data recorded at sensor_time for
% ping_time, outputting resulting interpolation ping_data. To be used to
% interpolate navigation data (lat, long, heading, etc.)
%
% USE
%
% ...
%
% PROCESSING SUMMARY
% 
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - sensor_time
% - sensor_data
% - ping_time
%
% OUTPUT VARIABLES
%
% - ping_data
%
% RESEARCH NOTES
%
% modify to allow arrays of sensor_data (several columns of data)
%
% NEW FEATURES
%
% 2014-09-29: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

% initialize new vectors
ping_data = nan(size(ping_time));

% interpolate sensor data at ping time
for jj = 1:length(ping_time)
    A = sensor_time-ping_time(jj);
    iA = find (A == 0);
    if A > 0
        % the ping time is older than any sensor time, extrapolate from the first items in sensor array.
        ping_data(jj) = sensor_data(2) + (sensor_data(2)-sensor_data(1)).*(ping_time(jj)-sensor_time(2))./(sensor_time(2)-sensor_time(1));
    elseif A < 0
        % the ping time is more recent than any sensor time, extrapolate from the last items in sensor array.
        ping_data(jj) = sensor_data(end) + (sensor_data(end)-sensor_data(end-1)).*(ping_time(jj)-sensor_time(end))./(sensor_time(end)-sensor_time(end-1));
    elseif ~isempty(iA)
        % the ping time corresponds to an existing sensor time, get data from it
        ping_data(jj) = sensor_data(iA);
    else
        % the ping time is within the limits of the sensor time array but doesn't correspond to any value in it, interpolate from nearest values
        iNegA = find(A<0);
        [temp,iMax] = max(A(iNegA));
        iA(1) = iNegA(iMax); % index of sensor time just older than ping time
        iPosA = find(A>0);
        [temp,iMin] = min(A(iPosA));
        iA(2) = iPosA(iMin); % index of sensor time just more recent ping time
        % now interpolate linearly
        ping_data(jj) = sensor_data(iA(2)) + (sensor_data(iA(2))-sensor_data(iA(1))).*(ping_time(jj)-sensor_time(iA(2)))./(sensor_time(iA(2))-sensor_time(iA(1)));
    end
end

