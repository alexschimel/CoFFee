function L = CFF_annulus_chord_length(r1,r2,theta)
% an annulus is the area contained between two concentric circles of outer
% radius "r1" (m) and inner radius "r2" (m). The angle of the segment
% compared to the circles is defined by the
% intercept angle at the circle origin "theta" (rad), by analogy with the
% function for length of chord of a circle.
%
% we define here a chord of an annulus a single segment within this area.
%
% There are two cases: either (1) the segment intersects both circles, or
% (2) it intersects the outer circle twice while remaining outside the
% inner circle.

% test data 1:
% r1 = [10;9;8];
% r2 = [5;6;7];
% thetad = [15;90;120];
% theta = deg2rad(thetad);
% L = CFF_annulus_chord_length(r1,r2,theta)

% test data 2:
% clear r1 r2 thetad theta
% r1(:,1,1) = [10;9;8];
% r2(1,:,1) = [5;6;7];
% thetad(1,1,:) = [15;90;120];
% theta = deg2rad(thetad);
% L = CFF_annulus_chord_length(r1,r2,theta)

% test data 3:
% clear r1 r2 thetad theta
% r1(:,1,1) = [10;9];
% r2(1,:,1) = [5;6;7];
% thetad(1,1,:) = [15;45;90;120];
% theta = deg2rad(thetad);
% L = CFF_annulus_chord_length(r1,r2,theta)

% For practical reasons, we will rather use the angle "alpha"
% measuring the deviation of the segment from the line that cross the
% circle origin, that is:
alpha = (pi - theta)./2;

%% case 1
% the strict section of an annulus.
% Proof alex niwa notebook #1
L_annulus = r1.*sqrt(1-sin(alpha).^2) - sqrt( r2.^2 - (r1.*sin(alpha)).^2 );

%% case 2
% a chord for the outer circle only
L_circle = CFF_circle_chord_length(r1,theta);

%% the limit angle between the two cases is:
alpha_lim = asin(r2./r1);
ind_case2 = alpha>alpha_lim;

%% before combining the two..
% in case input variables were on separate dimensions, L_circle will be
% missing the r2 dimensions, so we need to replicate in the r2 dimensions.
L_circle_dims = size(L_circle);
L_annulus_dims = size(L_annulus);
if ~all(L_circle_dims==L_annulus_dims)
    
    % get the dimensions that L_circle is missing
    ind = L_annulus_dims~=L_circle_dims;
    
    % replicate the dimensions of L_annulus, that L_circle is missing
    rep_scheme = ones(1,ndims(L_circle));
    rep_scheme(ind) = L_annulus_dims(ind);
    
    % use the scheme to replicate L_circle in its missing dimensions
    L_circle = repmat(L_circle,rep_scheme);
    
end

%% combination of the two
L = L_annulus;
L(ind_case2) = L_circle(ind_case2);



