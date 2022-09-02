function CFF_mustBeTwoPositiveIncreasingIntegers(a)
condition = isvector(a) && numel(a)==2 && isreal(a) && isnumeric(a) && all(ge(a,1)) && all(a==floor(a)) && (a(1)<a(2));
if ~condition
    eidType = 'mustBeTwoPositiveIncreasingIntegers:notTwoPositiveIncreasingIntegers';
    msgType = 'Input must be two positive increasing integers.';
    throwAsCaller(MException(eidType,msgType))
end
end