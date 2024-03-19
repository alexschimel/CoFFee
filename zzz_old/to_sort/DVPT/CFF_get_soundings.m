function FPBS = CFF_get_soundings(FPBS)
%CFF_GET_SOUNDINGS  One-line description
%
%   Calculates soundings projected position (Easting,Northing) from the
%   sonar projected position (Easting,Northing), ship heading and grid
%   convergence. This function adds fields Easting and Northing to
%   FPBS.Beam.
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2010-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% get beam data for calculations
AlongtrackDistanceX  = FPBS.Beam.AlongtrackDistanceX;
AcrosstrackDistanceY = FPBS.Beam.AcrosstrackDistanceY;

% get ping data for calculations
Heading              = FPBS.Ping.Heading(FPBS.Beam.Index);
GridConvergence      = FPBS.Ping.GridConvergence(FPBS.Beam.Index);
SonarEasting         = FPBS.Ping.Easting(FPBS.Beam.Index);
SonarNorthing        = FPBS.Ping.Northing(FPBS.Beam.Index);

% Turning X,Y into Easting,Northing taking into account heading and grid
% convergence. This calculation assumes X,Y are in the ship frame which
% stays vertical... May have to be improved...
[THETA,RHO] = cart2pol(AcrosstrackDistanceY,AlongtrackDistanceX);
THETA = THETA - Heading.*pi/180 - GridConvergence.*pi./180;
[SoundingEastingFromSonar,SoundNorthingFromSonar] = pol2cart(THETA,RHO);
SoundingEasting  = SonarEasting + SoundingEastingFromSonar;
SoundingNorthing = SonarNorthing + SoundNorthingFromSonar;

% round data
SoundingEasting  = 0.01.*round(SoundingEasting.*100);
SoundingNorthing = 0.01.*round(SoundingNorthing.*100);

% save
FPBS.Beam.Easting  = SoundingEasting;
FPBS.Beam.Northing = SoundingNorthing;




