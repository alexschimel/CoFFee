function CFF_mustBeVector(a)
%CFF_MUSTBEVECTOR  Validation function
%
%   See also CFF_MUSTBEVECTOR.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

condition = isreal(a) && isnumeric(a) && sum(size(a)==1)>=ndims(a)-1;
if ~condition
    eidType = 'CoFFee:notValid';
    msgType = 'Input must be vector.';
    throwAsCaller(MException(eidType,msgType))
end
end