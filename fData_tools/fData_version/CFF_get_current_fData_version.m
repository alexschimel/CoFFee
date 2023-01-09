function ver = CFF_get_current_fData_version()
%CFF_GET_CURRENT_FDATA_VERSION  Current version of fData.
%
%   The fData format sometimes requires updating to implement novel
%   features. Such changes imply that data that have been previously
%   converted may not be compatible with newer versions of processing code.
%   As a result, it is necessary to version the fData format. This function 
%   returns the current version of the fData format in order for code to
%   test whether a converted data is up-to-date or if re-converting is
%   advised.
%
%   IMPORTANT NOTE FOR DEVELOPERS: Whenever you change the fData format,
%   please update this function appropriately. Keep the existing version
%   number as a comment and add the new one as a new line above. Add the
%   date, and ideally a quick summary of changes.
%
%   See also CFF_GET_FDATA_VERSION, CFF_coffee_version.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2023; Last revision: 09-01-2023

ver = '0.4'; % 09-01-2023. Add more runtime parameters
% ver = '0.3'; % DD-MM-YYYY. Changes?
% ver = '0.2'; % DD-MM-YYYY. Changes?
% ver = '0.1'; % DD-MM-YYYY. Changes?
% ver = '0.0'; % DD-MM-YYYY. Changes?

end