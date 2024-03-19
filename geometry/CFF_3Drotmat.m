function R = CFF_3Drotmat(rotAngle,varargin)
% Rotation matrix for a given angle about a given axis.
% By default angle in radians, but can be specified in degrees with
% argument 'unit'.
% A set of angles can be specified to output a set of rotation matrices. In
% that case, the angle input must be a vector (row or column). The rotation
% matrices in output will be 3x3xN matrices with N being the number of
% angles requested in input.
%
% IMPORTANT NOTE: HOW TO USE A ROTATION MATRIX DEPENDS ON WHETHER YOU WANT
% TO 1) ROTATE A VECTOR IN A COORDINATE SYSTEM ("VECTOR ROTATION") OR 2)
% GET THE COORDINATES OF A VECTOR IN AN ALTERNATIVE, ROTATED COORDINATE
% SYSTEM ("AXES ROTATION")
%
% Vector rotation: In a UNIQUE coordinate system, a 3D column vector v =
% [x;y;z] rotated about an axis will result in a new 3D column vector v'
% with coordinates [x';y';z'] = R*v.
%
% For example, if you have a vector on the x axis [n;0;0] and you want to
% rotate it +90 degrees around the z-axis (positive means
% counter-clockwise), then the rotated vector will be lying on the y axis
% with coordinates [0;n;0].
%
% Axes rotation: Considering a NEW coordinate system (x',y',z') created
% from an EARLIER coordinate system (x,y,z) by rotation about an axis, a
% vector v with coordinates [x;y;z] in the EARLIER system will have
% coordinates [x';y';z'] = R'*v in the NEW system.
%
% For example, if you have a vector on the x axis [n;0;0] in a given
% coordinate system, that SAME vector in a NEW system
% rotated +90 degrees around the z-axis from the original one (positive
% means counter-clockwise) will be negative along the y-axis, with
% coordaintes [0;-n;0].
%
% Note in both cases, the rotation follows the standard counter-clockwise
% rule, e.g. a positive rotation about the x axis is a rotation from y
% towards z (for y: from z towards x. For z; from x towards y).
%
% https://en.wikipedia.org/wiki/Rotation_matrix

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% parsing inputs
p = inputParser;
addRequired(p,'rotAngle',@CFF_mustBeVector);
addOptional(p,'rotAxis','z',@(x) ismember(lower(x),{'x','y','z'}));
addOptional(p,'angleUnit','rad',@(x) ismember(lower(x),{'r','rad','radian','radians','d','deg','degree','degrees'}));
parse(p,rotAngle,varargin{:});
rotAxis = lower(p.Results.rotAxis);
angleUnit = lower(p.Results.angleUnit);
clear p

% turn degrees to radians if necessary
switch angleUnit
    case {'d','deg','degree','degrees'}
        rotAngle = deg2rad(rotAngle);
end

% make rotAngle a 3rd-dimension vector
rotAngle = permute(reshape(rotAngle,1,[]),[1,3,2]);
n = numel(rotAngle);

% rotation matrix elements as 3rd-dimension vectors
O = zeros(1,1,n);
I = ones(1,1,n);
C = cos(rotAngle);
S = sin(rotAngle);

% create rotation matrices
switch rotAxis
    case 'x'
        R = [[ I, O   O ];...
            [  O, C, -S ];...
            [  O, S,  C ]];
        
    case 'y'
        R = [[ C, O, S ];...
            [  O, I, O ];...
            [ -S, O, C ]];
        
    case 'z'
        R = [[ C, -S, O ];...
            [  S,  C, O ];...
            [  O,  O, I ]];
end