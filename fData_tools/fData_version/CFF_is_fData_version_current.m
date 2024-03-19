function bool = CFF_is_fData_version_current(fdata_input)
%CFF_IS_FDATA_VERSION_CURRENT  Check if fData version of input is current
%
%   Input can be either the filepath to a fData.mat file, OR a fData
%   structure. 
%

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% version if the fData file
fdata_ver = CFF_get_fData_version(fdata_input);

% current version for the conversion code
curr_ver = CFF_get_current_fData_version();

% match?
bool = strcmpi(fdata_ver,curr_ver);