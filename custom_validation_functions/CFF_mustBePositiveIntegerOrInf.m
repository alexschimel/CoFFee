function CFF_mustBePositiveIntegerOrInf(a)
%CFF_MUSTBEPOSITIVEINTEGERORINF  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isnumeric(a) && isscalar(a) && a>0 && (a == inf || mod(a,1) == 0);
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be one positive integer or inf.';
    throwAsCaller(MException(eidType,msgType))
end
end