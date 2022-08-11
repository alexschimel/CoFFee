function z = CFF_critical_z_value(confidence)
% z = CFF_critical_z_value(confidence)
%
% DESCRIPTION
%
% z value corresponding to confidence limit in percentage. eg 95% -> 1.96,
% 68% -> 1.
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

z = -sqrt(2).*erfcinv(1+confidence./100);



