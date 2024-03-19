function ratio = CFF_calculate_ratio_area_insonified(md,H,D,theta)
% ratio = CFF_calculate_ratio_area_insonified(md,H,D,theta)
%
% DESCRIPTION
%
% Calculate the ratio of area insonified (in the water-column data plane)
% by a swath of half-width "theta" of a section of water-column "D" wide,
% when the center of that section is at a distance "md" from the sonar, and
% in "H" water depth.
%
% REQUIRED INPUT ARGUMENTS
%
% - md: distance (in m) from sonar head to centre of patch
% - H: water-column height (in m) 
% - D: % diameter (in m) of patch area
% - theta: % max angle (in deg) for the half swath
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% total area for patch
totA = H.*D;

% half-swath distance
halfswath = H.*tand(theta);

if md<=D./2
    % patch contains nadir. Split the area covered on each side of the
    % sonar head
    
    % big area:
    D1=D./2 + md;
    h=(D1./2)./tand(theta);
    A1 = (H-h).*D1;
    
    % small area:
    D2=D./2 - md;
    h=(D2./2)./tand(theta);
    A2 = (H-h).*D2;
    
    % total
    A = A1+A2;
    
elseif md>D./2 & md<=halfswath-D./2
    % patch is fully contained in one half swath
    h = md./tand(theta);
    A = (H-h).*D;
    
elseif md>halfswath-D./2 & md<=halfswath+D./2
    % patch contains swath edge
    
    base = D./2 - (md-halfswath);
    hh=base./tand(theta);
    
    A = hh.*base./2;
    
else
    A = 0;
end

ratio = A./totA;



