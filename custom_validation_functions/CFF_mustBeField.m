function CFF_mustBeField(S,field)
%CFF_MUSTBEFIELD  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isfield(S,field);
if ~condition
    eidType = 'mustBeField:notField';
    msgType = 'Input must be existing field in structure.';
    throwAsCaller(MException(eidType,msgType))
end
end