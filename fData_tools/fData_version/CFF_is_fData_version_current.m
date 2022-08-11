function bool = CFF_is_fData_version_current(fdata_input)
%CFF_IS_FDATA_VERSION_CURRENT  Check if fData version of input is current
%
%   Input can be either the filepath to a fData.mat file, OR a fData
%   structure. 
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 24-05-2021

% version if the fData file
fdata_ver = CFF_get_fData_version(fdata_input);

% current version for the conversion code
curr_ver = CFF_get_current_fData_version();

% match?
bool = strcmpi(fdata_ver,curr_ver);