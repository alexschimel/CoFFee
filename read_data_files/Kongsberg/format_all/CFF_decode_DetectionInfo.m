function [S2, cat, ReflectivityCorrection, BScat] = CFF_decode_DetectionInfo(data)

% decoding the "Detection info(rmation)" field in:
% * "XYZ 88" datagram (p43, note 4)
% * "Extra detections" datagram (p47, note 8)
% * "Raw range and angle 78" datagram (p55, note 3)
% * "Seabed image data 89" datagram (p60, note 2)

dat = reshape(data,[],1);

% init output
S = nan(size(dat));

cat = categorical({...
    'valid, amplitude detection',... % 0
    'valid, phase detection',... % 1
    'invalid, normal detection',... % 2
    'invalid, interpolated or extrapolated from neighbour detections',... % 3
    'invalid, estimated',... % 4
    'invalid, rejected candidate',... % 5
    'invalid, no detection data available'... % 6
    });

dat = dec2bin(dat, 8);

bit7 = str2num(dat(:,1));
bits0to3 = bin2dec(dat(:,5:end));

S(~bit7 & bits0to3==0) = 0;
S(~bit7 & bits0to3==1) = 1;
S(bit7 & bits0to3==0) = 2;
S(bit7 & bits0to3==1) = 3;
S(bit7 & bits0to3==2) = 4;
S(bit7 & bits0to3==3) = 5;
S(bit7 & bits0to3==4) = 6;

S2 = reshape(S,size(data));

%% Additional code for reflectivity
% in "XYZ 88", "Extra detections", and "Raw range and angle 78", but NOT in
% "Seabed image data 89" datagram

% "Bit 4 Reflectivity (used in Beam intensity display) correction for
% Lamberts law and for normal incidence: 0= not compensated (xxx0 xxxx) (to
% show beam incidence angle dependency) 1= compensated (xxx1 xxxx) ( uses
% same correction as for seabed image data)"
% This refers to the "detection Infromation" field

BScat = categorical({...
    'not compensated',... % 0 "(to show beam incidence angle dependency)"
    'compensated'... % 1 "(uses same correction as for seabed image data)"
    });

ReflectivityCorrection = str2num(dat(:,4));