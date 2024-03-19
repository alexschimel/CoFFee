function DOD = CFF_calculate_DOD(Z1,Z2)
%CFF_CALCULATE_DOD  Output the difference between two co-registered DEMs
%
%   See also CFF_CALCULATE_DOD.

%   Copyright 2015-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if any(size(Z1)~=size(Z2))
    error('DEMs are not co-registered')
end

DOD = Z2-Z1;



