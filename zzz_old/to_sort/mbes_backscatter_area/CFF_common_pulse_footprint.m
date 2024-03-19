function L = CFF_common_pulse_footprint(c,tau,beta)
% the common equation for the pulse footprint is a function of sound
% celerity (c), the pulse duration (tau) and the angle of incidence beta
% (depression from seafloor normal, in rad)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

L = (c.*tau./2)./sin(beta);