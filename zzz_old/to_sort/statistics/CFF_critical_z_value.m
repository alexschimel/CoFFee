function z = CFF_critical_z_value(confidence)
%
% z value corresponding to confidence limit in percentage. eg 95% -> 1.96,
% 68% -> 1.

%   Copyright 2015-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

z = -sqrt(2).*erfcinv(1+confidence./100);



