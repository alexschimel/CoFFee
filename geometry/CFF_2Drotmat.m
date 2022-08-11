function R = CFF_2Drotmat(rotAngle)
%
% angle in radians
%
%


R = CFF_3Drotmat(rotAngle,'z','rad');
R = R(1:2,1:2,:);