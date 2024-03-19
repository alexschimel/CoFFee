function DPU = CFF_calculate_DPU(U1,U2)
%CFF_CALCULATE_DPU  Calculate the root of the sum of squared inputs
%
%   Simply calculate the root of the sum of squared inputs, to be used at
%   unceratinty propagation in quadrature. Inputs must be coregistered.
%
%   See also CFF_CALCULATE_DOD.

%   Copyright 2015-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if any(size(U1)~=size(U2))
    error('inputs are not co-registered')
end

% Uncertainty propagated in quadrature:
DPU = sqrt( U1.^2 + U2.^2 );



