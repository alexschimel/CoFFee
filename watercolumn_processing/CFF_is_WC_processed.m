function bool = CFF_is_WC_processed(fData)
%CFF_IS_WC_PROCESSED  Check if fData has processed WCD
%
%   BOOL = CFF_PROCESS_WC(FDATA) returns True if FDATA has processed WCD.
%
%   See also CFF_IS_FDATA_VERSION_CURRENT

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% Input arguments management
p = inputParser;
addRequired(p,'fData',@(x) CFF_is_fData_version_current(x)); % source fData
parse(p,fData);
fData = p.Results.fData;
clear p

% condition
bool = isfield(fData,'X_SBP_WaterColumnProcessed');