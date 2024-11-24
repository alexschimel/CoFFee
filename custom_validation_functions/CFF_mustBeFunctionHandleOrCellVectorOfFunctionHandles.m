function CFF_mustBeFunctionHandleOrCellVectorOfFunctionHandles(a)
%CFF_MUSTBEFUNCTIONHANDLEORCELLVECTOROFFUNCTIONHANDLES  Validation function
%
%   See also CFF_MUSTBECELLVECTOROFSTRUCTS, CFF_MUSTBESTRUCT

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isa(a, 'function_handle') || (iscell(a) && isvector(a) && all(cellfun(@(f) isa(f, 'function_handle'), a)));
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be a function handle or a cell vector of function handles.';
    throwAsCaller(MException(eidType, msgType))
end
end