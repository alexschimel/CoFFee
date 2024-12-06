function [L, L_lead, L_trail] = CFF_exact_beam_footprint(R,phi,beta)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% The common approximate for the across-track footprint (in m) of a beam of
% beamwidth phi (rad), on a seafloor intercepted with angle of incidence
% beta (depression from seafloor normal, in rad), considering a range from
% sonar R (m) is:
%
% L = R.*phi./cos(beta);
%
% but this is an approximation considering that we are far away enough from
% the source to have parallel beam edges, aka valid for large R and small
% phi.
%
% Another way to express it, valid in all cases, would be:
% proof in Alex's NIWA notebook 1

L = R.*cos(beta).*( tan(beta+phi./2) - tan(beta-phi./2) );

% actually we can do better and measure the length of the leading print and
% the trailing print:
L_lead  = R.*cos(beta).*tan(beta+phi./2) - R.*sin(beta);
L_trail = R.*sin(beta) - R.*cos(beta).*tan(beta-phi./2);

% and L = L_lead + L_trail;