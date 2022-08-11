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
% USE
%
% This is a bit more detailed description of how to use the function. DELETE THIS LINE IF UNUSED
%
% PROCESSING SUMMARY
%
% This is a summary of the steps in the processing. DELETE THIS LINE IF UNUSED
%
% REQUIRED INPUT ARGUMENTS
%
% - md: distance (in m) from sonar head to centre of patch
% - H: water-column height (in m) 
% - D: % diameter (in m) of patch area
% - theta: % max angle (in deg) for the half swath
%
% OPTIONAL INPUT ARGUMENTS
%
% - 'XXX': description of the optional arguments with list of valid values and what they do. DELETE THIS LINE IF UNUSED
%
% PARAMETERS INPUT ARGUMENTS
%
% - 'XXX': description of the optional parameter arguments (name-value pair). DELETE THIS LINE IF UNUSED
%
% OUTPUT VARIABLES
%
% - OUT: description of output variables. DELETE THIS LINE IF UNUSED
%
% RESEARCH NOTES
%
% This describes what features are temporary or needed future developments. DELETE THIS LINE IF UNUSED
%
% NEW FEATURES
%
% YYYY-MM-DD: second version. Describes the update. DELETE THIS LINE IF UNUSED
% YYYY-MM-DD: first version.
%
% EXAMPLES
%
% This section contains examples of valid function calls. DELETE THIS LINE IF UNUSED
%
%%%
% Alex Schimel, Deakin University. CHANGE AUTHOR IF NEEDED.
%%%

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



