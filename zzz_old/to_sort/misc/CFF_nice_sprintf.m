function str = CFF_nice_sprintf(num)
%
% the sprintf people really wants. The one that turns 0.57 in '0.57', and
% not '0.5700' or '5.7E-1' etc.
%
% NEW FEATURES
%
% 2015-05-21: first version.
%
% EXAMPLE

%   Copyright 2015-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


% output as a floating point with way more accuracy than needed
str = sprintf('%.300f',num);

% remove trailing zeros the dirty looping way:
while strcmp(str(end),'0')
    str(end)=[];
end

