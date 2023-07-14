function [KM_date, TSMIM] = CFF_datetime_to_all_time(dt)
% convert time from MATLAB datetime format to Kongsberg *.all format

KM_date = convertTo(dt,'yyyymmdd');
TSMIM = milliseconds(timeofday(dt));
