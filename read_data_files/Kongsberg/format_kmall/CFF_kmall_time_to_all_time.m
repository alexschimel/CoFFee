function [KM_date, TSMIM] = CFF_kmall_time_to_all_time(time_sec,time_nanosec)
%CFF_KMALL_TIME_TO_ALL_TIME  Convert time from Kongsberg kmall to all
%
%   Convert time format from Kongsberg *.kmall format to Kongsberg *.kmall
%   format.
%
%   See also CFF_KMALL_TIME_TO_DATETIME.

%   Copyright 2022-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% convert kmall time to datetime
dt = CFF_kmall_time_to_datetime(time_sec,time_nanosec);

% convert datetime to date and TSMIM
[KM_date, TSMIM] = CFF_datetime_to_all_time(dt);

end