function y = CFF_nansum3(x,dim)

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if nargin<2
    y = CFF_nanfunc3('sum',x);
else
    y = CFF_nanfunc3('sum',x,dim);
end
