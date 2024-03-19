function L = CFF_circle_chord_length(r,theta)
% definition of a length of a chord of a circle, given the circle radius
% "r" (m) and the intercept angle "theta" (rad). Proof online

%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

L = 2.*r.*sin(theta./2);