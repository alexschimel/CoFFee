function L = CFF_common_beam_footprint(R,phi,beta)
% The common approximate for the across-track footprint (in m) of a beam of
% beamwidth phi (rad), on a seafloor intercepted with angle of incidence
% beta (depression from seafloor normal, in rad), considering a range from
% sonar R (m). 

%   Copyright 2014-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

L = R.*phi./cos(beta);

