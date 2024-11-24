function CFF_mustBeTwoPositiveIncreasingIntegers(a)
%CFF_MUSTBETWOPOSITIVEINCREASINGINTEGERS  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isvector(a) && numel(a)==2 && isreal(a) && isnumeric(a) && all(ge(a,1)) && all(a==floor(a)) && (a(1)<a(2));
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be two positive increasing integers.';
    throwAsCaller(MException(eidType,msgType))
end
end