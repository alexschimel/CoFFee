function CFF_mustBeTwoNumerics(a)
%CFF_MUSTBETWONUMERICS  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isreal(a) && isnumeric(a) && numel(a)==2;
if ~condition
    eidType = 'mustBeTwoNumerics:notTwoNumerics';
    msgType = 'Input must be two numerics.';
    throwAsCaller(MException(eidType,msgType))
end
end