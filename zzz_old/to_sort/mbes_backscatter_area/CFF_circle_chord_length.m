function L = CFF_circle_chord_length(r,theta)
% definition of a length of a chord of a circle, given the circle radius
% "r" (m) and the intercept angle "theta" (rad). Proof online

L = 2.*r.*sin(theta./2);