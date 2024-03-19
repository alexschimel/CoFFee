function L = CFF_common_beam_footprint(R,phi,beta)
% the common equation for the beam footprint is a function of the range R
% (m), the beamwidth phi (rad) and the angle of incidence beta (depression
% from seafloor normal, in rad)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

L = R.*phi./cos(beta);

