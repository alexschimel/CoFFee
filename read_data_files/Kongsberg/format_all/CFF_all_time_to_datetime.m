function out = CFF_all_time_to_datetime(date,TimeSinceMidnightInMilliseconds)
% convert time format from Kongsberg *.all format to MATLAB datetime

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