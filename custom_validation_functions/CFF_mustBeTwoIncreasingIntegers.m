function CFF_mustBeTwoIncreasingIntegers(a)
%CFF_MUSTBETWOINCREASINGINTEGERS  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isvector(a) && numel(a)==2 && isreal(a) && isnumeric(a) && all(a==floor(a)) && (a(1)<a(2));
if ~condition
    eidType = 'mustBeTwoIncreasingIntegers:notTwoIncreasingIntegers';
    msgType = 'Input must be two increasing integers.';
    throwAsCaller(MException(eidType,msgType))
end
end