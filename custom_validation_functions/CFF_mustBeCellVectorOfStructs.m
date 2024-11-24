function CFF_mustBeCellVectorOfStructs(a)
%CFF_MUSTBECELLVECTOROFSTRUCTS  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = iscell(a) && isvector(a) && all(cellfun(@isstruct, a));
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be a cell vector of structures.';
    throwAsCaller(MException(eidType,msgType))
end
end