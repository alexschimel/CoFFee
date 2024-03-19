function nIN = CFF_num_rasters(IN)
% nIN = CFF_num_rasters(IN)
%
% DESCRIPTION
%
% number of rasters in IN
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% get number of rasters. The only way I can think I could have several
% rasters in input is as a cell array of strings, or a cell array of 3D
% arrays. So test for cell.

if ~iscell(IN)
    % IN is not a cell -> single raster
    nIN = 1;
elseif iscell(IN) && min(size(IN))==1 && max(size(IN))==3 && all(size(IN{1})~=1)
    % IN is a 1*3 or 3*1 cell array, the first one of which contains an array that is not a vector -> single raster
    nIN = 1;
else
    % all other cases -> several rasters
    if iscell(IN) && size(IN,1)==1
        nIN=size(IN,2);
    elseif iscell(IN) && size(IN,2)==1
        nIN=size(IN,1);
    else
        % you shouldnt get here unless I forgot a case.. :(
        error;
    end
end
