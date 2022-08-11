function L = CFF_common_pulse_footprint(c,tau,beta)
% the common equation for the pulse footprint is a function of sound
% celerity (c), the pulse duration (tau) and the angle of incidence beta
% (depression from seafloor normal, in rad)

L = (c.*tau./2)./sin(beta);