function CFF_nice_easting_northing(varargin)
% CFF_nice_easting_northing(varargin)
%
% DESCRIPTION
%
% turn easting/northing tick labels into proper format
%
% USE
%
% PROCESSING SUMMARY
% 
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - varargin{1} (optional): maximum number of digits for the string representation
% (typically 10 or more)
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% NEW FEATURES
%
% 2014-07-22: first version. taken from /2008-11-01 - Tapuae MBES new
% processing code/script_ProcessData_3_map_processing1_!!!.m
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%

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


