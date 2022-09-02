function CFF_mustBeTwoIncreasingNumerics(a)
condition = isreal(a) && isnumeric(a) && numel(a)==2 && (a(1)<a(2));
if ~condition
    eidType = 'mustBeTwoIncreasingNumerics:notTwoIncreasingNumerics';
    msgType = 'Input must be two increasing numerics.';
    throwAsCaller(MException(eidType,msgType))
end
end