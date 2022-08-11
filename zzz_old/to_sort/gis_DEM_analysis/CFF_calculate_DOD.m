function DOD = CFF_calculate_DOD(Z1,Z2)
% DOD = CFF_calculate_DOD(Z1,Z2)
%
% DESCRIPTION
%
% Simply output the difference between two co-registered DEMs
%
% USE
%
% ...
%
% PROCESSING SUMMARY
%
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - varagin
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% YYYY-MM-DD: second version.
% YYYY-MM-DD: first version.
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%

if any(size(Z1)~=size(Z2))
    error('DEMs are not co-registered')
end

DOD = Z2-Z1;



