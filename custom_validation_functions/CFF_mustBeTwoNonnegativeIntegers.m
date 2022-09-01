function CFF_mustBeTwoNonnegativeIntegers(a)
condition = isvector(a) && numel(a)==2 && isreal(a) && isnumeric(a) && all(ge(a,0)) && all(a==floor(a));
if ~condition
    eidType = 'mustBeTwoNonnegativeIntegers:notTwoNonnegativeIntegers';
    msgType = 'Input must be two non-negative integers.';
    throwAsCaller(MException(eidType,msgType))
end
end