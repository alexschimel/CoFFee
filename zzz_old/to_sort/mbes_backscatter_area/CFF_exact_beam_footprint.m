function [L, L_lead, L_trail] = CFF_exact_beam_footprint(R,phi,beta)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% the common equation for the beam footprint is a function of the range R
% (m), the beamwidth phi (rad) and the angle of incidence beta (depression
% from seafloor normal, in rad)
%
% L = R.*phi./cos(beta);
%
% but this way to think considers a situation far away from the source,
% with parallel beam edges, aka valid for large R and small phi.
%
% Another way to express it, valid in all cases, would be:
% proof in Alex's NIWA notebook 1

L = R.*cos(beta).*( tan(beta+phi./2) - tan(beta-phi./2) );

% actually we can do better and measure the length of the leading print and
% the trailing print:
L_lead  = R.*cos(beta).*tan(beta+phi./2) - R.*sin(beta);
L_trail = R.*sin(beta) - R.*cos(beta).*tan(beta-phi./2);

% and L = L_lead + L_trail;