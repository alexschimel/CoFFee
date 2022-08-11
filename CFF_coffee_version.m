function ver = CFF_coffee_version()
%CFF_COFFEE_VERSION  Get version of CoFFee
%
%   Get version of coffee. Using standard semantic versioning rules. 
%   See info on:
%   https://semver.org/
%   https://interrupt.memfault.com/blog/release-versioning
%
%   IMPORTANT NOTE FOR DEVELOPERS: Whenever you develop CoFFee and intend
%   to release a new tag on git, please update this function appropriately
%   before. Keep the existing version as a comment and add the new one as a
%   new line above. Add the date.
%
%   See also CFF_GET_CURRENT_FDATA_VERSION.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2022-2022; Last revision: 11-08-2022

ver = '2.0.0-alpha.1'; % 11/08/2022

end

