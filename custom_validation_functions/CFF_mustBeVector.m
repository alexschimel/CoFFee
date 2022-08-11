function CFF_mustBeVector(a)
condition = isreal(a) && isnumeric(a) && sum(size(a)==1)>=ndims(a)-1;
if ~condition
    eidType = 'mustBeVector:notVector';
    msgType = 'Input must be vector.';
    throwAsCaller(MException(eidType,msgType))
end
end