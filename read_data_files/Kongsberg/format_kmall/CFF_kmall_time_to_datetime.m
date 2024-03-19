function out = CFF_kmall_time_to_datetime(time_sec,time_nanosec)
%CFF_KMALL_TIME_TO_DATETIME  Convert time from Kongsberg kmall to datetime
%
%   Convert time format from Kongsberg *.kmall format to MATLAB datetime.
%
%   See also CFF_ALL_TIME_TO_DATETIME, CFF_KMALL_TIME_TO_ALL_TIME.

%   Copyright 2022-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

out = datetime(time_sec + time_nanosec.*10^-9,'ConvertFrom','posixtime');
