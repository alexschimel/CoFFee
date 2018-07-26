function L = CFF_common_beam_footprint(R,phi,beta)
% the common equation for the beam footprint is a function of the range R
% (m), the beamwidth phi (rad) and the angle of incidence beta (depression
% from seafloor normal, in rad)

L = R.*phi./cos(beta);

