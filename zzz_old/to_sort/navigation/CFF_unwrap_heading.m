function heading = CFF_unwrap_heading(heading,varargin)
%
% This function unwraps heading values superior to allow them going over
% 360 or inferior to 0 (because every time the vessel crossed the NS
% line, the heading jumps from 0 to 360 (or from 360 to 0) and this
% causes a problem for following interpolation)
%
% INPUT VARIABLES
%
% - heading (in degrees)
% - cutoff (optional): default: 300. Any jump over 300 degrees is used to
% detect the wraps.
%
% OUTPUT VARIABLES
%
% - heading: unwrapped. in degrees
%
% RESEARCH NOTES
%
% To rewrap the data (i.e. bringing heading back in the [0:360] interval,
% do: heading = mod(heading,360);
% 
% NEW FEATURES
%
% 2014-09-29: first version.

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if nargin<3
    cutoff = varargin{1};
else
    cutoff = 300;
end


posJump = find(diff(heading)>cutoff);
negJump = find(diff(heading)<-cutoff);
jumps   = zeros(length(heading),1);

if ~isempty(posJump)
    for jj=1:length(posJump)
        jumps(posJump(jj)+1:end) = jumps(posJump(jj)+1:end) - 1;
    end
end

if ~isempty(negJump)
    for jj=1:length(negJump)
        jumps(negJump(jj)+1:end) = jumps(negJump(jj)+1:end) + 1;
    end
end

% unwrap:
heading = heading + jumps.*360;