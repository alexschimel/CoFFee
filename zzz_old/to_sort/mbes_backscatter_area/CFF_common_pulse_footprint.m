function L = CFF_common_pulse_footprint(c,tau,beta)
% The common approximate for the across-track footprint (aka in m) of a
% pulse of length tau (s), on a seafloor intercepted with angle of
% incidence beta (depression from seafloor normal, in rad), considering
% sound celerity c (m.s^-1). 

%   Copyright 2014-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

L = (c.*tau./2)./sin(beta);