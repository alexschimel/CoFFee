% Radiometric correction of backscatter requires the estimation of the area
% insonified, which Lurton (2002) calls the "effective extent of the
% scattering surface" (equation 3.32).


%% 1. Background

% Lurton (2002) considers separately the cases of "grazing incidence" and
% "normal incidence".
%
% At grazing incidence, the area insonified A (in m.^2) is written:
A = @(PHI,R,c,T,beta) 0.5.*PHI.*R.*c.*T./sin(beta);

% Where:
%  PHI is the "equivalent beam aperture" (in rad)
%  R is the range (in m)
%  c is the sound speed (in m.s.-2)
%  T is the pulse lenght (in s)
%  beta is the angle of incidence (depression from seafloor normal, in rad)

% At normal incidence, there are two different expressions. 

% The first one is the intersection of the directivty lobe, assumed
% vertical, and the surface, and valid if "the signal is transmitted for a
% sufficiently long time for the beam footprint to be insonifed at once".
% It is called the "long-pulse regime".
A = @(psi,H) psi.*H.^2;

% Where:
%  psi is the equivalent solid aperture (in steradians)
%  H is the hight from the source to the target (in m)

% The second expression is valid "for a short pulse", aka the "short-pulse
% regime":
A = @(H,c,T) pi.*H.*c.*T;

% Where:
%  H is the hight from the source to the target (in m)
%  c is the sound speed (in m.s.-2)
%  T is the pulse lenght (in s)

% Lurton (2002) adds the transition between the two regimes, but only
% defined for a conical beam. It is at the height H_trans (in m):
H_trans = @(c,T,phi) c.*T./(tan(phi).^2);

% Where:
%  c is the sound speed (in m.s.-2)
%  T is the pulse lenght (in s)
%  phi is the half-aperture of the conical beam


%% 2. Rewriting

% The text and equations reveal the two different "pulse regimes". 

% In the "long pulse regime", the pulse is so long relative to the
% beamwidth that the beamwidth is the limiting factor in defining a length
% insonified.
%
% In the "short pulse regime", the pulse is so short relative to the
% beamwidth that the pulse is the limiting factor in defining a length
% insonified.

% Now examining the equations.

%% 2.1 Grazing incidence

% The area in Lurton's equation for grazing incidence really is the product
% of the beam footprint in the along-track and the pulse footprint in the
% across-track. 

% The beam footprint in the along-track is the along-track beamwidth
% intercepting a seafloor with normal incidence at range R.
L_b_al = @(phi_al,R) phi_al.*R;

% Where:
%  phi_al is the along-track beamwidth (in rad)
%  R is the range (in m)

% The pulse footprint in the across-track is the length of seafloor
% intercepted by the pulse, considering the angle of incidence:
L_p_ac = @(c,T,beta) 0.5.*c.*T./sin(beta);

% Where:
%  c is the sound speed (in m.s.-2)
%  T is the pulse lenght (in s)
%  beta is the angle of incidence (depression from seafloor normal, in rad)

% And the insonified area is the product of the two:
A = @(phi_al,R,c,T,beta) L_b_al(phi_al,R).*L_p_ac(c,T,beta);

% Now some analysis:
%  1. Along-track, the equation calculating the beam footprint shows that
%  we are considering that the relative incidence in this plane is normal,
%  and that the footprint is limited by the along-track beam. Aka, we are
%  in "long-pulse" regime. What if there is a slope? What if the pulse is
%  short relative to the beamwidth?
%  3. Across-track, the equation calculating the pulse footprint shows that
%  the pulse length is sufficiently short relative to the beamwdith for the
%  pulse to be entierely contained in the beam projected on the seafloor.
%  Aka this is a "short-pulse regime". What if the pulse is long relative
%  to the beamwidth?

% In short, why did Lurton split the short-pulse and long-pulse regimes for
% the normal incidence, but did not do the same for grazing incidence?

%% 2.2 Normal incidence

% In the long pulse regime, the equivalent solid aperture psi is the
% product of the along-track and beam-track beamwidths, so let's rewrite
% the area as the product of the along-track and across-track footprints.
% Let's use R instead of H to aknowledge the possibility that normal
% incidence can also occur away from nadir
L_b_al = @(phi_al,R) phi_al.*R;
L_b_ac = @(phi_ac,R) phi_ac.*R;
A = @(phi_al,phi_ac,R) L_b_al(phi_al,R).*L_b_ac(phi_ac,R);

% In the short-pulse regime, let's reuse Lurton's equation for the disk
% radius insonifed by the pulse, within the beam:
L_p = @(R,c,T) sqrt(R.*c.*T);

% And calculate the area from it
A = @(R,c,T) pi.*L_p(R,c,T).^2;

%% 2.3 Rewriting

% Ideally, we would:
%  1. Consider short and long-pulse regimes also for grazing incidence
%  2. Create a single equation that automatically uses the right regime, at
%  the appropriate incidence

% to complete
...


%% 3. For snippets
% The equations before are for the seafloor located at range R. But 
% The echo of the seafloor in a given beam is a time signal, converted to
% range, aka snippets. The instant area insonified changes with R. For
% example, before the pulse intercepts the seafloor in the beam, there is
% NO area insonified. The area becomes non-zero when the pulse starts
% intercepting the seafloor. Then, the area increases, defined by the
% portion of pulse now intercepting the seafloor. Once the pulse is fully
% within the beam, THEN the area is defined by the full pulse intercepting
% the seafloor, written with the short pulse regime equation from above. So
% THAT equation really is for ONE range, admittedly the range where maximum
% backscattering is happening. But to find the are FOR ALL RANGES R, we
% need a bit more work than that.


% Considering the signal in a beam B of beamwidth phi (in rad),
% intersecting a flat seafloor at range R_0, with an angle of incidence
% beta (depression from seafloor normal, in rad). Assuming we are
% sufficiently far from the source to consider that the edges of the beam
% are parallel and that the normal intercept of the beam can be written
% phi.*R_0. 

% The range of the first contribution of seafloor to the signal is the
% range of the start of the beam intercepting the seafloor, written R_1 (in
% m), and given by:
R_1 = @(R_0,phi,beta) R_0.*(1-0.5.*phi.*tan(beta));

% The length of flat seafloor contributing to the returned signal at time t
% (in sec) corresponding to range R = c*t./2 (in m) is L (in m), given by:
L = @(R,R_0,phi,beta) min(max(0,(R-R_1(R_0,phi,beta))./sin(beta)),phi.*R_0./cos(beta));

% checks

% single values
R_0 = 10;
R = 10; 
phi = 1; % deg
beta = 45; % deg
L(R,R_0,deg2rad(phi),deg2rad(beta))

% vary range
R_0 = 10;
R = [R_0-0.2:0.001:R_0+0.2]; 
phi = 1; % deg
beta = 45; % deg
figure; plot(R,L(R,R_0,deg2rad(phi),deg2rad(beta)),'.'); grid on; xlabel('range (m)'); ylabel('beam footprint (m)'); 
title(sprintf('seafloor range: %.3f m, beamwidth: %.3f deg, incidence angle: %.3f deg',R_0,phi,beta));

% vary seafloor range
R = 10; 
R_0 = [R-0.2:0.001:R+0.2];
phi = 1; % deg
beta = 45; % deg
figure; plot(R_0,L(R,R_0,deg2rad(phi),deg2rad(beta)),'.'); grid on; xlabel('seafloor range (m)'); ylabel('beam footprint (m)'); 
title(sprintf('range: %.3f m, beamwidth: %.3f deg, incidence angle: %.3f deg',R,phi,beta));

% vary phi
R_0 = 10; 
R = R_0;
phi = [0.01:0.01:3]; % deg
beta = 45; % deg
figure; plot(phi,L(R,R_0,deg2rad(phi),deg2rad(beta)),'.'); grid on; xlabel('beamwidth (deg)'); ylabel('beam footprint (m)'); 
title(sprintf('range: %.3f m, seafloor range: %.3f m, incidence angle: %.3f deg',R,R_0,beta));

% vary beta
R_0 = 10; 
R = R_0;
phi = 1; % deg
beta = [0:1:85]; % deg
figure; plot(beta,L(R,R_0,deg2rad(phi),deg2rad(beta)),'.'); grid on; xlabel('incidence angle (deg)'); ylabel('beam footprint (m)'); 
title(sprintf('range: %.3f m, seafloor range: %.3f m, beamwidth: %.3f deg',R,R_0,phi));

% check all of the above, I am not 100% sure

% next, do the same for pulse footprint, assuming infinite beam

% last, take the smallest of the two values as the length to use in
% practice.

% this is one dimension footprint, typically acrosstrack. For along-track,
% for now just assume normal incidence and take beam footrpint phi.*R.

% Multiply the two to get the instant area insonifed A as a function of
% range R (and other parameters)

% Finally code this as TS = S_v + lo10(A), to be used for radiometic
% correction of seafloor backscatter. Not sure how that could be applicable
% to WCD