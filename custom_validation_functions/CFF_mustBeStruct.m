function CFF_mustBeStruct(a)
%CFF_MUSTBESTRUCT  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isstruct(a);
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be structure.';
    throwAsCaller(MException(eidType,msgType))
end
end