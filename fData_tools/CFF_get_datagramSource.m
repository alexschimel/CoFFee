function datagramSource = CFF_get_datagramSource(fData,varargin)
%CFF_GET_DATAGRAMSOURCE  Get or set a datagramSource for a fData
%
%   fData may have multiple datagram types that can be used for further
%   processing (typically, seabed data and water-column data) but we can
%   only process one at a time. datagramSource is the two-letter code
%   defining which datagram type are being (or, to be) processed. This
%   function allows deciding an appropriate datagramSource for unprocessed
%   data, or returns the datagramSource for processed data.
% 
%   DS = CFF_GET_DATAGRAMSOURCE(FDATA) checks if FDATA is processed. If
%   yes, it returns its datagramSource as DS. If not, it returns a
%   suitable datagramSource DS for processing.
%
%   CFF_GET_DATAGRAMSOURCE(FDATA, DS) checks if DS is a suitable
%   datagramSource for (presumably unprocessed) FDATA. If yes, it returns
%   DS. If not, it returns another datagramSource that is suitable. 

%   See also CFF_COMPUTE_PING_NAVIGATION_V2.

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% init output
datagramSource = [];

if ~isempty(varargin) && ~isempty(varargin{1})
    % datagramSource requested in input
    datagramSource = varargin{1};
elseif isfield(fData,'MET_datagramSource')
    % datagramSource not requested in input, but fData appears processed
    % with a set datagramSource already
    datagramSource = fData.MET_datagramSource;
end

if ~isempty(datagramSource)
    % check that there are indeed fields for that datagramSource
    if ~isfield(fData,sprintf('%s_1P_Date',datagramSource))
        % if not, that datagramSource is unsuitable so reset it to empty
        datagramSource = [];
    end
end

if isempty(datagramSource)
    % if datagramSource still empty at this point, it means we need to find
    % a suitable one based on fields available in fData. Test all suitable
    % fields, by order of priority
    if isfield(fData, 'AP_1P_Date')
        datagramSource = 'AP';
    elseif isfield(fData, 'WC_1P_Date')
        datagramSource = 'WC';
    elseif isfield(fData, 'X8_1P_Date')
        datagramSource = 'X8';
    elseif isfield(fData, 'De_1P_Date')
        datagramSource = 'De';
    else
        error('can''t find a suitable datagramSource')
    end
end