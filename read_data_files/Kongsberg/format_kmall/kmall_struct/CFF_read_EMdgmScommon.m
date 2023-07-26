function out_struct = CFF_read_EMdgmScommon(fid, dtgType)
%CFF_READ_EMDGMSCOMMON  Read common part of Sensor struct of kmall file
%
%   Sensor (S) output datagram - common part for all external sensors.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021

% Size in bytes of current struct.
out_struct.numBytesCmnPart = fread(fid,1,'uint16');

% sensorSystem
tmp = fread(fid,1,'uint16');
out_struct.sensorSystem = CFF_decode_sensorSystem(tmp, dtgType);

% sensorStatus
tmp = fread(fid,1,'uint16');
out_struct.sensorStatus = CFF_decode_sensorStatus(tmp, dtgType);

out_struct.padding = fread(fid,1,'uint16');

end

function out_struct = CFF_decode_sensorSystem(dataDec, dtgType)
% Sensor system number, as indicated when setting up the system in
% K-Controller installation menu. E.g. position system 0 referes to system
% POSI_1 in installation datagram #IIP. Check if this sensor system is
% active by using #IIP datagram.
%
% #SCL - clock datagram:
% Bit number 	Sensor system
% 0             Time syncronisation from clock data
% 1             Time syncronisation from active position data
% 2             1 PPS is used

% init output
out_struct = struct();

switch dtgType
    case '#SCL'
        dataBin = dec2bin(reshape(dataDec,[],1), 16);
        
        out_struct.TimeSyncronisationFromClockData          = bin2dec(dataBin(:,end));
        out_struct.TimeSyncronisationFromActivePositionData = bin2dec(dataBin(:,end-1));
        out_struct.OnePPSisUsed                             = bin2dec(dataBin(:,end-2));

    otherwise
        out_struct.SensorSystemNumber = dataDec;
end

end


function out = CFF_decode_sensorStatus(dataDec, dtgType)
% Sensor status. To indicate quality of sensor data is valid or invalid.
% Quality may be invalid even if sensor is active and the PU receives data.
% Bit code vary according to type of sensor.
%
% Bits 0 -7 common to all sensors and #MRZ sensor status:
% Bit number 	Sensor data
% 0             For rev H: 0 = Data OK, 1 = Data OK and sensor is chosen as active
%               For rev I: 1 = Sensor is chosen as active
%               #SCL only: 1 = Valid data and 1PPS OK
% 1             0
% 2             0 = Data OK
%               1 = Reduced performance
%               #SCL only: 1 = Reduced performance, no time synchronisation of PU
% 3             0
% 4             0 = Data OK
%               1 = Invalid data
% 5             0
% 6             0 = Velocity from sensor
%               1 = Velocity calculated by PU
% 7             0
%
% For #SPO (position) and CPO (position compatibility) datagrams, bit 8-15:
%
% Bit number 	Sensor data
% 8             0
% 9             0 = Time from PU used (system)
%               1 = Time from datagram used (e.g. from GGA telegram)
% 10            0 = No motion correction
%               1 = With motion correction
% 11            0 = Normal quality check
%               1 = Operator quality check. Data always valid
% 12            0
% 13            0
% 14            0
% 15            0

% init output
out = struct();

dataBin = dec2bin(reshape(dataDec,[],1), 16);

% bit 0
switch dtgType
    case '#SCL'
        out.validDataAndOnePPSoK = bin2dec(dataBin(:,end));
    otherwise
        out.activeSensor = bin2dec(dataBin(:,end));
end

% bit 2
switch dtgType
    case '#SCL'
        out.dataQuality = categorical(bin2dec(dataBin(:,end-2)),[0,1],{'Data OK','Reduced Performance, no time synchronisation of PU'});
    otherwise
        out.dataQuality = categorical(bin2dec(dataBin(:,end-2)),[0,1],{'Data OK','Reduced Performance'});
end

% bit 4
out.dataValidity = categorical(bin2dec(dataBin(:,end-4)),[0,1],{'Data OK','Invalid data'});

% bit 6
out.velocitySource = categorical(bin2dec(dataBin(:,end-6)),[0,1],{'Velocity from sensor','Velocity calculated by PU'});

% bits 8-15
switch dtgType
    case {'#SPO','#CPO'}
        % bit 9
        out.timeSource = categorical(bin2dec(dataBin(:,end-9)),[0,1],{'Time from PU used (system)','Time from datagram used'});

        % bit 10
        out.motionCorrection = categorical(bin2dec(dataBin(:,end-10)),[0,1],{'No motion correction','With motion correction'});
        
        % bit 11
        out.qualityCheck = categorical(bin2dec(dataBin(:,end-11)),[0,1],{'Normal quality check','Operator quality check. Data always valid'});
end

end
