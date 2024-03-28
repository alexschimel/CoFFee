function [sampleEasting, sampleNorthing, sampleHeight] = CFF_get_samples_ENH_v2(acDist,alDist,upDist,sonHead,sonE,sonN,AxRotAngle)
%CFF_GET_SAMPLES_ENH_V2  Compute sample coordinates in projected frame
%
%   Given coordinates of samples in the swath frame (distances across,
%   along and upwards), calculate coordinates in the projected frame
%   (Easting, Northing, Height).
%
%   The swath frame SF is defined as:
%   - origin: sonar face
%   - x_s: distance across-track (positive towards starboard)
%   - y_s: distance along-track (positive forward)
%   - z_s: distance upwards (positive up)
%
%   The projected frame PF is defined as:
%   - origin: the (0,0) Easting/Northing projection/datum reference
%   - x_p: Easting (positive towards grid East)
%   - y_p: Northing (positive towards grid North)
%   - z_p: Elevation/Height (positive up)
%
%   NOTE: This function works on the STRONG ASSUMPTION that the
%   swath frame and projected frames have THE SAME Z axis, so that going
%   from one to the other only requires considering the rotation about that
%   Z axis. This assumption is only valid if the system was corrected in
%   real time for pitch and roll, so that swath is pointed directly
%   downwards. Aka, this is most likely wrong for multi-sectors, and
%   systems using yaw-compensation.
% 
% %   The two frames share their z axis so the transformation is a simple
%   rotation around the z axis. We need the coordinates of the swath frame 
%   origin (i.e. sonar) in the projected frame, as well as the axes
%   rotation (i.e. angle between y_s and y_p, positive counter-clockwise. 

%   [E,N,H] = CFF_GET_SAMPLES_ENH(SE,SN,SH,SHEADING,SAMPACD,SAMPUPD)
%   returns the easting E, northing N, and height H in the projected
%   frame of samples, from the sonar easting SE (in m), sonar northing SN
%   (in m), sonar height SH (in m), sonar heading SHEADING (in radians
%   relative to North?), and the samples' across distance SAMPACD (in m)
%   and upward distance SAMPUPD (in m) in the swath frame. SE, SN, SH, and
%   SHEADING must be matching 1P matrices or compatible (e.g. scalars for
%   one ping). SAMPACD and SAMPUPD must be SBP tensors or compatible (e.g.
%   SB matrices for 1 ping).
%
%   See also CFF_GET_SAMPLES_DIST, CFF_GEOREFERENCE_SAMPLE

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% permute dimensions of input to get everything as SBP matrices
sonE  = permute(sonE,[3,1,2]);
sonN = permute(sonN,[3,1,2]);
sonH   = permute(sonH,[3,1,2]);
sonHead  = permute(sonHead,[3,1,2]);


% get axes rotation matrix
R = CFF_2Drotmat(-sonHead);
% normally with column vectors X' = R'*X 
xp = sonE  + acDist.*R(1,1,:) + y.*R(2,1,:);
yp = sonN + acDist.*R(1,2,:) + y.*R(2,2,:);
zp = sonH   + upDist;

% % compute outputs
% sampleEasting  = sonE  + acDist.*cos(sonHead);
% sampleNorthing = sonN + acDist.*sin(sonHead);
% sampleHeight   = sonH   + upDist;





end
