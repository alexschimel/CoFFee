function R = CFF_2Drotmat(rotAngle)
%
% angle in radians
%
%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


R = CFF_3Drotmat(rotAngle,'z','rad');
R = R(1:2,1:2,:);