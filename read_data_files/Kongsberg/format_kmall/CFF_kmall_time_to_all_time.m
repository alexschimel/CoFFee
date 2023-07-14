function [KM_date, TSMIM] = CFF_kmall_time_to_all_time(time_sec,time_nanosec)
% convert time format from Kongsberg *.kmall format to *.all format

% convert kmall time to datetime
dt = CFF_kmall_time_to_datetime(time_sec,time_nanosec);

% convert datetime to date and TSMIM
[KM_date, TSMIM] = CFF_datetime_to_all_time(dt);

end