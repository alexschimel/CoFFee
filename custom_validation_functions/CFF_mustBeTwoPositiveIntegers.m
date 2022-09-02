function CFF_mustBeTwoPositiveIntegers(a)
condition = isvector(a) && numel(a)==2 && isreal(a) && isnumeric(a) && all(ge(a,1)) && all(a==floor(a));
if ~condition
    eidType = 'mustBeTwoPositiveIntegers:notTwoPositiveIntegers';
    msgType = 'Input must be two positive integers.';
    throwAsCaller(MException(eidType,msgType))
end
end