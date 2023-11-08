function CFF_mustBeTwoIncreasingIntegers(a)
condition = isvector(a) && numel(a)==2 && isreal(a) && isnumeric(a) && all(a==floor(a)) && (a(1)<a(2));
if ~condition
    eidType = 'mustBeTwoIncreasingIntegers:notTwoIncreasingIntegers';
    msgType = 'Input must be two increasing integers.';
    throwAsCaller(MException(eidType,msgType))
end
end