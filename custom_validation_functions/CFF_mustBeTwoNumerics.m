function CFF_mustBeTwoNumerics(a)
condition = isreal(a) && isnumeric(a) && numel(a)==2;
if ~condition
    eidType = 'mustBeTwoNumerics:notTwoNumerics';
    msgType = 'Input must be two numerics.';
    throwAsCaller(MException(eidType,msgType))
end
end