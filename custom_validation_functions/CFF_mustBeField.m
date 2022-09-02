function CFF_mustBeField(S,field)
condition = isfield(S,field);
if ~condition
    eidType = 'mustBeField:notField';
    msgType = 'Input must be existing field in structure.';
    throwAsCaller(MException(eidType,msgType))
end
end