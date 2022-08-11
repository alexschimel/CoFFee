function str = CFF_nice_sprintf(num)
% str = CFF_nice_sprintf(num)
%
% DESCRIPTION
%
% the sprintf people really wants. The one that turns 0.57 in '0.57', and
% not '0.5700' or '5.7E-1' etc.
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
% - varagin
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% 2015-05-21: first version.
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%


% output as a floating point with way more accuracy than needed
str = sprintf('%.300f',num);

% remove trailing zeros the dirty looping way:
while strcmp(str(end),'0')
    str(end)=[];
end

