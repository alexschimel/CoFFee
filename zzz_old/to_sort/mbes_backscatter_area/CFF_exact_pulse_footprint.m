function [L, L_lead, L_trail] = CFF_exact_pulse_footprint(R,c,tau,beta)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% the common equation for the pulse footprint is a function of sound
% celerity (c), the pulse duration (tau) and the angle of incidence beta
% (depression from seafloor normal, in rad)
%
% L = (c.*tau./2)./sin(beta);
%
% but this is considered far away from the source in such way that
% waves fronts are straight, aka valid for large range
%
% a way to express it, valid in all cases, is a bit complex, it involves
% two regimes: at high incident angles (grazing), it's a chord of an
% annulus. While at low incident angles, it's a chord of a circle.

% the radii of the inner and outer circles are:
r1 = R;
r2 = R-c.*tau./2;

% the intercept angle at the origin of the circles (theta) is twice the
% incident angle (beta). Proof in alex NIWA notebook #1
theta = 2.*beta;

L = CFF_annulus_chord_length(r1,r2,theta);

% To be consistent with the function for beam footprint, also allows
% outputing the lead distance and trail distance, however, it's bit simple
% with the pulse footprint because L_lead is always 0 while L_trail is
% always L.
%
% Here's why:
%
% 1. Time t=0 in the signal record is the beggining of the emission of the
% pulse of duration tau.
%
% 2. Time t=tau in the signal record is the end of the emission of the
% pulse.
%
% 3. At time t, we receive the reflection of the leading edge of the pulse
% after it was reflected at a range Rl such that:
% c = distance/time = (2.*Rl)./t, therefore Rl = c.*t/2
%
% 4. At time t, we also receive the reflection of the trailing edge of the
% pulse after it was reflected at range Rt such that:
% c = distance/time = (2.*Rt)./(t-tau), therefore 
% Rt = c.*(t-tau)./2 = Rl - c.*tau./2.
%
% 5. In conclusion, when we calculate a range R from the signal t using the
% formula R = c.*t./2 (or cumulated transmission over variable c), the
% range we obtain is that of the leading edge of the pulse footprint, while
% the trailing edge is behind at a distance of c.*tau./2. In other words,
% L_lead = 0 while L_trail = pulse footprint.

L_lead  = zeros(size(L));
L_trail = L;

% and obviously L = L_lead + L_trail;

