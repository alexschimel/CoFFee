function ver = CFF_coffee_version()
%CFF_COFFEE_VERSION  Get version of CoFFee
%
%   Get version of coffee.
%
%   IMPORTANT NOTES FOR DEVELOPERS: 
%
%   1. It is crucial that this function STAYS at the root of the CoFFee
%   folder. DO NOT MOVE IT. 
%
%   2. Whenever you develop/modify CoFFee and intend to tag that new commit
%   on git, please update this function appropriately before. Keep the
%   existing version as a comment and add the new one as a new line above.
%   Add the date. Using standard semantic versioning rules aka
%   MAJOR.MINOR.PATCH. If pre-release, follow with dash, alpha/beta/rc, dot
%   and a single version number. See info on: 
%   https://semver.org/
%   https://interrupt.memfault.com/blog/release-versioning
%
%   See also CFF_GET_CURRENT_FDATA_VERSION.

%   Copyright 2022-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

ver = '2.0.0-alpha.15'; % 01/03/2024
% ver = '2.0.0-alpha.14'; % 13/02/2024
% ver = '2.0.0-alpha.13'; % 23/10/2023
% ver = '2.0.0-alpha.12'; % 19/10/2023
% ver = '2.0.0-alpha.11'; % 27/07/2023
% ver = '2.0.0-alpha.10'; % 26/07/2023
% ver = '2.0.0-alpha.9'; % 14/07/2023
% ver = '2.0.0-alpha.8'; % 07/07/2023
% ver = '2.0.0-alpha.7'; % 17/03/2023
% ver = '2.0.0-alpha.6'; % 09/01/2023
% ver = '2.0.0-alpha.5'; % 08/09/2022
% ver = '2.0.0-alpha.4'; % 02/09/2022
% ver = '2.0.0-alpha.3'; % 12/08/2022
% ver = '2.0.0-alpha.2'; % 12/08/2022
% ver = '2.0.0-alpha.1'; % 11/08/2022

end

