function CFF_mustBeTwoIncreasingNumerics(a)
%CFF_MUSTBETWOINCREASINGNUMERICS  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isreal(a) && isnumeric(a) && numel(a)==2 && (a(1)<a(2));
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be two increasing numerics.';
    throwAsCaller(MException(eidType,msgType))
end
end