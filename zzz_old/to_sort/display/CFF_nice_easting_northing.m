function CFF_nice_easting_northing(varargin)
%CFF_NICE_EASTING_NORTHING  Improve easting/northing tick labels format
%
%   INPUT VARIABLES
%   - varargin{1} (optional): maximum number of digits for the string
%   representation (typically 10 or more).
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2007-2012 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if nargin > 0
    precision = varargin{1};
else
    precision = 10; %default
end

% get current ticks position
ytick=get(gca,'ytick');
xtick=get(gca,'xtick');

% turn to strings
ytickstr=num2str(ytick',precision);
xtickstr=num2str(xtick',precision);

% update strings
set(gca,'yticklabel',ytickstr);
set(gca,'xticklabel',xtickstr);

% and prevent matlab from changing these upon print command
set(gca,'XTickMode','manual')
set(gca,'YTickMode','manual')
set(gca,'XTickLabelMode','manual')
set(gca,'YTickLabelMode','manual')


