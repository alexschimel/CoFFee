function CFF_mustBeCellVectorOfFunctionHandles(a)
%CFF_MUSTBECELLVECTOROFFUNCTIONHANDLES  Validation function
%
%   See also CFF_MUSTBEFUNCTIONHANDLE.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = iscell(a) && isvector(a) && all(cellfun(@(f) isa(f, 'function_handle'), a));
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be a cell vector of function handles.';
    throwAsCaller(MException(eidType, msgType))
end
end