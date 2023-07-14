function out = CFF_kmall_time_to_datetime(time_sec,time_nanosec)
% convert time from Kongsberg *.kmall format to MATLAB datetime

out = datetime(time_sec + time_nanosec.*10^-9,'ConvertFrom','posixtime');
