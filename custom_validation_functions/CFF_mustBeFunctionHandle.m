function CFF_mustBeFunctionHandle(a)
%CFF_MUSTBEFUNCTIONHANDLE  Validation function
%
%   See also CFF_MUSTBESTRUCT.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isa(a, 'function_handle');
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be a function handle.';
    throwAsCaller(MException(eidType, msgType))
end
end