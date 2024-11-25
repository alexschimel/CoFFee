function CFF_mustBeBoolean(a)
%CFF_MUSTBEBOOLEAN  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = islogical(a) || isnumeric(a) && all(a(:)==0 | a(:)==1);
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be boolean (true, false, 0, 1)';
    throwAsCaller(MException(eidType,msgType))
end
end