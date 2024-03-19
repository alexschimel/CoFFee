function [KM_date, TSMIM] = CFF_datetime_to_all_time(dt)
%CFF_DATETIME_TO_ALL_TIME  Convert time from datetime to Kongsberg all
%
%   Convert time from MATLAB datetime format to Kongsberg *.all format
%
%   See also CFF_ALL_TIME_TO_DATETIME.

%   Copyright 2022-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

KM_date = convertTo(dt,'yyyymmdd');
TSMIM = milliseconds(timeofday(dt));
