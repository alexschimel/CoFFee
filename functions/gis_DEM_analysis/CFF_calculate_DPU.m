function DPU = CFF_calculate_DPU(U1,U2)
% DPU = CFF_calculate_DPU(U1,U2)
%
% DESCRIPTION
%
% Simply calculate the root of the sum of squared inputs, to be used at
% unceratinty propagation in quadrature. Inputs must be coregistered.
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
% std1 = '.\DATA\WH1_uncertaintyZ_50cm_UTM54S_p.tif';
% std2 = '.\DATA\WH2_uncertaintyZ_50cm_UTM54S_p.tif';
%
%%%
% Alex Schimel, Deakin University
%%%

if any(size(U1)~=size(U2))
    error('inputs are not co-registered')
end


% Uncertainty propagated in quadrature:
DPU = sqrt( U1.^2 + U2.^2 );



