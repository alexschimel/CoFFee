%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% 1. testing my functions for exact footprints compared to equations commonly used
% see CFF_common_beam_footprint, CFF_common_pulse_footprint,
% CFF_exact_beam_footprint and CFF_exact_pulse_footprint


%% 1.1. testing on single values
clear all
c = 1500; % sound velocity (m/s)
tau = 100*10^-6; % pulse duration (s)
R = 100; % range (m)
phid = 1; % receive beamwidth (deg)
betad = 45; % incident angle (deg)

phi = deg2rad(phid);
beta = deg2rad(betad);

% the usual formulas for footprints are:
Lb1 = CFF_common_beam_footprint(R,phi,beta);
Lp1 = CFF_common_pulse_footprint(c,tau,beta);

% my new ones:
Lb2 = CFF_exact_beam_footprint(R,phi,beta);
Lp2 = CFF_exact_pulse_footprint(R,c,tau,beta);

% calculate differences in percentage
Lp_perc_diff = 100.*(1-Lp1./Lp2)
Lb_perc_diff = 100.*(1-Lb1./Lb2)

% conclusion: the differences are less than 0.1%. Very very little
% difference in this case.


%% 1.2 now testing on a range of values
clear all
tau(:,1,1,1,1)   = [25:25:200]*10^-6; % pulse duration (s)
c(1,:,1,1,1)     = [1400:10:1700]; % sound velocity (m/s)
betad(1,1,:,1,1) = 0:1:90; % incident angle (deg)
phid(1,1,1,:,1)  = 0.1:0.1:10; % receive beamwidth (deg)
R(1,1,1,1,:)     = 1:10:10000; % range (m)

phi = deg2rad(phid);
beta = deg2rad(betad);

% the usual formulas for footprints are:
Lb1 = CFF_common_beam_footprint(R,phi,beta);
Lp1 = CFF_common_pulse_footprint(c,tau,beta);

% my new ones:
Lb2 = CFF_exact_beam_footprint(R,phi,beta);
Lp2 = CFF_exact_pulse_footprint(R,c,tau,beta);

% calculate differences in percentage
Lp_perc_diff = 100.*(1-Lp1./Lp2);
Lb_perc_diff = 100.*(1-Lb1./Lb2);

% find the maximum differences and the parameters values for that max
% difference

% first in the case of pulse footprint
[Lp_perc_diff_max,ind] = max(Lp_perc_diff(:));
[tau_ind,c_ind,beta_ind,phi_ind,R_ind] = ind2sub(size(Lp_perc_diff),ind);

% verify
tau0 = tau(tau_ind);
c0 = c(c_ind);
beta0 = beta(beta_ind);
R0 = R(R_ind);
Lp10 = CFF_common_pulse_footprint(c0,tau0,beta0);
Lp20 = CFF_exact_pulse_footprint(R0,c0,tau0,beta0);
Lpdiff = 100.*(1-Lp10./Lp20);
sprintf(['For a pulse duration of %gs, a sound velocity of %gm/s,\n ' ...
         'an incident angle of %gdeg and a range of %gm,\n ' ...
         'the classic pulse length is %gm while my new estimate is %gm,\n ' ... 
         'which is different by %g%%.'],tau0, c0, rad2deg(beta0), R0, Lp10, Lp20, Lpdiff)

% next in the case of beam footprint
[Lb_perc_diff_max,ind] = max(Lb_perc_diff(:));
[tau_ind,c_ind,beta_ind,phi_ind,R_ind] = ind2sub(size(Lb_perc_diff),ind);

% verify
beta0 = beta(beta_ind);
phi0 = phi(phi_ind);
R0 = R(R_ind);
Lb10 = CFF_common_beam_footprint(R0,phi0,beta0);
Lb20 = CFF_exact_beam_footprint(R0,phi0,beta0);
Lbdiff = 100.*(1-Lb10./Lb20);
sprintf(['For a beamwidth of %gdeg, an incident angle of %gdeg and a range of %gm,\n ' ...
    'the classic beam footprint is %gm while my new estimate is %gm,\n which is different by %g%%.'], rad2deg(phi0), rad2deg(beta0), R0, Lb10, Lb20, Lbdiff)

% conclusion: now we have large differences but for values where those
% regimes are not the dominant ones in practice. Modifying the parameters
% to fit the appropriate regimes (near normal for beam, grazing for pulse)
% yield little differences.




%% 2. next, testing calculating the intersection of the footprints, thanks to our new functions
% the problem in the classical approach is that it calculates the min value
% between beam and pulse footprints, which assumes that one contains the
% other. In reality, we'd calculate the overlap between the two.

% some test parameters
clear all
c = 1500; % sound velocity (m/s)
tau = 100*10^-6; % pulse duration (s)
phid = 1; % receive beamwidth (deg)
thetad(:,1) = 0:0.1:70; % beam steering angles away from nadir

phi   = deg2rad(phid);
theta = deg2rad(thetad);

% now we need range R and incident angle beta, and to keep things simple
% we'll assume a flat seafloor and constant c
H = 20; % sounding depth

% the actual range corresponding to the seafloor should be, as a function
% of steering angle:
R = H./cos(theta);

% and the incidence angle is simply the steering angle if we assume a flat
% seafloor:
beta = theta;

% The classical calculation would be that, in the "pulse-limited" case away
% from nadir, the footprint is considered to be that of the pulse, while in
% the "beam-limited" case, close to nadir, the footprint is considered to
% be that of the beam. We calculate both and the across-track width
% insonified is estimated as the minimum value between the two:
pulse_lim = CFF_common_pulse_footprint(c,tau,beta);
beam_lim = CFF_common_beam_footprint(R,phi,beta);
L_common = min(pulse_lim,beam_lim);

% In our improved calculation, we not only use the exact equations, but
% measure the leading and trailing edges of the footprint to measure how
% much they intersect

% for the pulse footprint:
[pulse_footprint_width, pulse_footprint_lead, pulse_footprint_trail] = CFF_exact_pulse_footprint(R,c,tau,beta);
pulse_acrossdist_lead = sqrt( R.^2 - H.^2 ) + pulse_footprint_lead;
pulse_acrossdist_lead(imag(pulse_acrossdist_lead)~=0) = NaN;
pulse_acrossdist_trail = sqrt( R.^2 - H.^2 ) - pulse_footprint_trail;
pulse_acrossdist_trail(imag(pulse_acrossdist_trail)~=0) = NaN;

% for the beam footprint:
[beam_footprint_width, beam_footprint_lead, beam_footprint_trail] = CFF_exact_beam_footprint(R,phi,beta);
beam_acrossdist_lead = sqrt( R.^2 - H.^2 ) + beam_footprint_lead;
beam_acrossdist_trail = sqrt( R.^2 - H.^2 ) - beam_footprint_trail;

% and the length of the intersection is:
L_new = CFF_footprint_intersection(pulse_acrossdist_lead, pulse_acrossdist_trail, beam_acrossdist_lead, beam_acrossdist_trail);

% results:
figure(2)
plot(thetad,pulse_lim,'b')
hold on
plot(thetad,beam_lim,'r')
plot(thetad,L_common,'k')
plot(thetad,pulse_footprint_width,'b--')
plot(thetad,beam_footprint_width,'r--')
plot(thetad,L_new,'g.-')
legend('classical pulse footprint','classical beam footprint','minimum between the two','actual pulse footprint','actual beam footprint','intersection of the two')
xlabel('steering angle away from nadir (deg)')
ylabel('across track width (m)')
grid on

% conclusion:
%
% - at higher steered angles, the new calculation matches the common one,
% which are both the pulse footprint. That's because the beam footprint
% gets so large that it fully includes the pulse footprint, hence the
% minimum calculation (classic approach) and the intersection (new
% approach) match. 
%
% - at lower steered angles, the calculations don't match, and the new one
% is consistently smaller than the other, yet following the same curve
% which is that of the beam footprint. That is because at that regime, the
% pulse footprint is larger, but does not fully include the beam footprint
% since the (large) pulse footprint lags behind R while approximately half
% of the (short) beam footprint is still ahead. The minimum value, which is
% the beam footprint in that case, is an inaccurate representation of the
% intersection between the footprints.
%
% - at normal incidence, the intersection is zero because the pulse
% footprint, lagging behind R, is zero. To fix this, we'd need to separate
% time and steering angle, which we'll do now.





%% 3. separate time and steering angle

% The classical method of calculating footprint (minimum between beam print
% and pulse print) uses a range that corresponds to the bottom, and are
% thus linked: for each steering angle, one beam, one sample corresponding
% to the bottom and thus, one range. 
% But the samples in a signal are not all on bottom. Actually only one is.
% What about all the others? As one can tell by looking at the signal in a
% beam, the echo spreads on several samples. For each sample in that
% returned echo, what is the extent of the footprint contributing to it?
%
% Let's consider the range and the sttering angle separately

% some test parameters
clear all
c = 1500; % sound velocity (m/s)
tau = 100*10^-6; % pulse duration (s)
phid = 1; % receive beamwidth (deg)
thetad(:,1) = 0:0.1:70; % beam steering angles away from nadir

phi   = deg2rad(phid);
theta = deg2rad(thetad);

% we still assume a flat seafloor and constant c
H = 20; % sounding depth

% for each beam, the range to the point on the seafloor where the steered
% beam points at, is:
beam_R = H./cos(theta);

% and the corresponding incidence angle is simply the steering angle if we
% assume a flat seafloor:
beam_beta = theta;

% Since the steering is fixed and independent of the time sample t, we can
% measure the beam footprint and corresponding across-track distances that
% are valid for all time samples for that beam:
[beam_footprint_width, beam_footprint_lead, beam_footprint_trail] = CFF_exact_beam_footprint(beam_R,phi,beam_beta);
beam_acrossdist_lead = sqrt( beam_R.^2 - H.^2 ) + beam_footprint_lead;
beam_acrossdist_trail = sqrt( beam_R.^2 - H.^2 ) - beam_footprint_trail;

% but now consider an actual signal received:
f = 60000; % sampling frequency (Hz)
t_lim = 0.1; % end of time record (s)
t = 0:1/f:t_lim; % our time vector

% For each time sample t, the leading edge of the pulse will be at range:
pulse_R = c.*t./2;

% and the trailing edge of the pulse is slightly behind:
pulse_trail_R = c.*(t-tau)./2;

% at low values of t, the pulse is not yet on the seafloor but starting at
% range = H, it is. For any pulse at range R beyond, it intersects the
% seafloor at incident angle:
pulse_beta = acos(H./pulse_R);
pulse_beta(imag(pulse_beta)~=0) = NaN;

% and since the trailing edge is at a different range, it correspond to a
% bottom with a different incident angle
pulse_trail_beta = acos(H./pulse_trail_R);
pulse_trail_beta(imag(pulse_trail_beta)~=0) = NaN;

% So, if we were not limited by beamwidth, the section of seafloor that
% contribute to the signal a time t would be defined by:
[pulse_footprint_width, pulse_footprint_lead, pulse_footprint_trail] = CFF_exact_pulse_footprint(pulse_R,c,tau,pulse_beta);
pulse_acrossdist_lead = sqrt( pulse_R.^2 - H.^2 ) + pulse_footprint_lead;
pulse_acrossdist_lead(imag(pulse_acrossdist_lead)~=0) = NaN;
pulse_acrossdist_trail = sqrt( pulse_R.^2 - H.^2 ) - pulse_footprint_trail;
pulse_acrossdist_trail(imag(pulse_acrossdist_trail)~=0) = NaN;

% so we have beam footprints dependent on beam steering, and pulse
% footprints dependent on signal time. The intersection of those prints is
% a function of time and steering angle:
L = CFF_footprint_intersection(pulse_acrossdist_lead, pulse_acrossdist_trail, beam_acrossdist_lead, beam_acrossdist_trail);


% results
figure(3)
subplot(222)
imagesc(t,thetad,L,'AlphaData',~isnan(L));
xl = xlim;
xlabel('record time (s)')
ylabel('steering angle away from nadir (deg)')
colorbar('Location','east')
title('across-track width of the intersection between pulse and beam footprints on seafloor (m)')
set(gca,'YDir','normal')
grid on
subplot(224)
plot(t,pulse_footprint_width);
xlim(xl)
xlabel('record time (s)')
ylabel('across track width of pulse footprint on seafloor (m)')
grid on
subplot(221)
plot(beam_footprint_width,thetad);
xlabel('across track width of beam footprint on seafloor (m)')
ylabel('steering angle away from nadir (deg)')
grid on

% one can see how, for a given steering angle, the intersection is nill
% outside of a limited range. as t increases towards that range and the
% pulse print starts intersecting the beam print, the total intersection
% rises, reach a steady value, and then decreases as t gets higher.
%
% where in that plot is the standard assumption of time and steered angle
% being related? R = c.*t./2 for pulse and R = H./cos(theta) for beam so:

t_link = 2.*H./(c.*cos(theta));
subplot(222); hold on
plot(t_link, thetad,'k.-')

% notice how that time corresponds to the leading edge of the overlap
% regime at earlier times/angles, and gradually reaches the center of that
% overlap at higher values

% Let's extract the corresponding intersection value:
A = abs(t-t_link);
[~,ind] = min(A,[],2);
linearInd = sub2ind(size(L),1:length(theta),ind');
L_link = L(linearInd);

% how does this compare to our previous graph?
figure(2);
hold on
plot(thetad,L_link,'c')


% the squiggly start is due to the lower resolution of the time sample but
% we can see it matches the curve. Increasing sampling frequency improves
% the match

% FINAL CONCLUSION:
% the classic way had good approximations of pulse footprint and beam
% footprint and our exact value barely improves on it. However, the choice
% of calculating the minimum value was wrong because the pulse print lags
% behing the seabed hit, while the beam print encompasses it. In the
% classic way therefore, the proper solution would be to take the minimum
% between the pulse footprint and the trailing extent of the beam
% footprint.
%
% Furhter, with our improved calculations, we could separate time and
% steered angle, allowing us to find a different corrective factor for each
% sample in the signal.
%
% Now the problem remains that this was all done assuming flat seafloor.
% Next steps would 


