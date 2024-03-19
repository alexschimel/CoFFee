function out = CFF_all_time_to_datetime(date,TimeSinceMidnightInMilliseconds)
%CFF_ALL_TIME_TO_DATETIME  Convert time from Kongsberg all to datetime
%
%   Convert time format from Kongsberg *.all format to MATLAB datetime
%
%   See also CFF_ALL_TIME_TO_DATETIME.

%   Copyright 2022-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

dateStr = arrayfun(@num2str,date,'UniformOutput',false);

out = datetime(...
    cellfun(@(x) str2double(x(1:4)),dateStr),... % year
    cellfun(@(x) str2double(x(5:6)),dateStr),... % month
    cellfun(@(x) str2double(x(7:8)),dateStr),... % day
    0,... % hour
    0,... % minute
    0,... % second
    TimeSinceMidnightInMilliseconds... % milliseconds
    );