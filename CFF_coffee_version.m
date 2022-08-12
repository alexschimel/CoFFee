function ver = CFF_coffee_version()
%CFF_COFFEE_VERSION  Get version of CoFFee
%
%   Get version of coffee.
%
%   IMPORTANT NOTE FOR DEVELOPERS: Whenever you develop/modify CoFFee and
%   intend to tag that new commit on git, please update this function
%   appropriately before. Keep the existing version as a comment and add
%   the new one as a new line above. Add the date. Using standard semantic
%   versioning rules aka MAJOR.MINOR.PATCH. If pre-release, follow with
%   dash, alpha/beta/rc, dot and a single version number. See info on:
%   https://semver.org/
%   https://interrupt.memfault.com/blog/release-versioning
%
%   See also CFF_GET_CURRENT_FDATA_VERSION.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2022-2022; Last revision: 11-08-2022

ver = '2.0.0-alpha.1'; % 11/08/2022

end

