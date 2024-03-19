function out_struct = CFF_read_EMdgmSKM(fid, dgmVersion_warning_flag)
%CFF_READ_EMDGMSKM  Read kmall structure #SKM
%
%   #SKM - data from attitude and attitude velocity sensors.
%
%   Datagram may contain several sensor measurements. The number of samples
%   in datagram is listed in numSamplesArray in the struct
%   EMdgmSKMinfo_def. Time given in datagram header, is time of arrival of
%   data on serial line or on network. Time inside #KMB sample is time from
%   the sensors data. If input is other than KM binary sensor input format,
%   the data are converted to the KM binary format by the PU. All
%   parameters are uncorrected. For processing of data, installation
%   offsets, installation angles and attitude values are needed to correct
%   the data for motion.
%
%   Verified correct for kmall format revisions F,I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

out_struct.header = CFF_read_EMdgmHeader(fid);

SKM_VERSION = out_struct.header.dgmVersion;
if SKM_VERSION~=1 && dgmVersion_warning_flag
    % definitions in this function and subfunctions valid for SKM_VERSION:
    % 1 (kmall format revisions C-I)
    warning('#SKM datagram version (%i) unsupported. Continue reading but there may be issues.',SKM_VERSION);
end

out_struct.infoPart = CFF_read_EMdgmSKMinfo(fid);

Nsamp = out_struct.infoPart.numSamplesArray;
for iS = 1:Nsamp
    out_struct.sample(iS) = CFF_read_EMdgmSKMsample_def(fid);
end

end


function out_struct = CFF_read_EMdgmSKMinfo(fid)
% Sensor (S) output datagram - info of KMB datagrams.
%
% Verified correct for kmall versions F-I

% Size in bytes of current struct. Used for denoting size of rest of
% datagram in cases where only one datablock is attached.
out_struct.numBytesInfoPart = fread(fid,1,'uint16');

% Attitude system number, as numbered in installation parameters. E.g.
% system 0 referes to system ATTI_1 in installation datagram #IIP.
out_struct.sensorSystem = fread(fid,1,'uint8');

% Sensor status. Summarise the status fields of all KM binary samples added
% in this datagram (status in struct KMbinary_def). Only available data
% from input sensor format is summarised. Available data found in
% sensorDataContents.
% Bits 0 -7 common to all sensors and #MRZ sensor status:
% Bit number 	Sensor data
% 0             1 = Sensor is chosen as active
% 1             0
% 2             0 = Data OK
%               1 = Reduced performance
% 3             0
% 4             0 = Data OK
%               1 = Invalid data
% 5             0
% 6             0 = Velocity from sensor
%               1 = Velocity calculated by PU
out_struct.sensorStatus = fread(fid,1,'uint8');

% Format of raw data from input sensor, given in numerical code according
% to table below.
% Code 	Sensor format
% 1 	KM binary Sensor Input
% 2 	EM 3000 data
% 3 	Sagem
% 4 	Seapath binary 11
% 5 	Seapath binary 23
% 6 	Seapath binary 26
% 7 	POS M/V GRP 102/103
out_struct.sensorInputFormat = fread(fid,1,'uint16');

% Number of KM binary sensor samples added in this datagram.
out_struct.numSamplesArray = fread(fid,1,'uint16');

% Length in bytes of one whole KM binary sensor sample.
out_struct.numBytesPerSample = fread(fid,1,'uint16');

% Field to indicate which information is available from the input sensor,
% at the given sensor format.
% 0 = not available
% 1 = data is available
% The bit pattern is used to detemine sensorStatus from status field in
% #KMB samples. Only data available from sensor is check up against
% invalid/reduced performance in status, and summaries in sensorStatus.
% E.g. the binary 23 format does not contain delayed heave. This is
% indicated by setting bit 6 in sensorDataContents to 0. In each sample in
% #KMB output from PU, the status field (struct KMbinary_def) for INVALID
% delayed heave (bit 6) is set to 1. The summaries sensorStatus in struct
% EMdgmSKMinfo_def will then be sets to 0 if all available data is ok.
% Expected data field in sensor input:
%
% Bit number 	Sensor data
% 0             Horizontal position and velocity
% 1             Roll and pitch
% 2             Heading
% 3             In Rev H: Heave and vertical velocity
%               In Rev I: Heave
% 4             Acceleration
% 5             Error fields
% 6             Delayed heave
out_struct.sensorDataContents = fread(fid,1,'uint16');

end

function out_struct = CFF_read_EMdgmSKMsample_def(fid)
% #SKM - all available data.
%
% An implementation of the KM Binary sensor input format.
%
% Verified correct for kmall format revisions F-I

out_struct.KMdefault = CFF_read_KMbinary(fid);
out_struct.delayedHeave = CFF_read_KMdelayedHeave(fid);

end


function out_struct = CFF_read_KMbinary(fid)
% #SKM - Sensor attitude data block. Data given timestamped, not corrected.
%
% See Coordinate systems for definition of positive angles and axis.
%
% Verified correct for kmall format revisions F-I

% #KMB
out_struct.dgmType = fscanf(fid,'%c',4);

% Datagram length in bytes. The length field at the start (4 bytes) and end
% of the datagram (4 bytes) are included in the length count.
out_struct.numBytesDgm = fread(fid,1,'uint16');

% Datagram version.
out_struct.dgmVersion = fread(fid,1,'uint16');

% UTC time from inside KM sensor data. Unit second. Epoch 1970-01-01 time.
% Nanosec part to be added for more exact time.
% If time is unavailable from attitude sensor input, time of reception on
% serial port is added to this field.
out_struct.time_sec = fread(fid,1,'uint32');

% Nano seconds remainder. Nanosec part to be added to time_sec for more
% exact time.
% If time is unavailable from attitude sensor input, time of reception on
% serial port is added to this field.
out_struct.time_nanosec = fread(fid,1,'uint32');

% Bit pattern for indicating validity of sensor data, and reduced
% performance. The status word consists of 32 single bit flags numbered
% from 0 to 31, where 0 is the least significant bit.
% Bit number 0-7 indicate if from a sensor data is invalid. 0 = valid data,
% 1 = invalid data.
% Bit number 16-> indicate if data from sensor has reduced performance. 0 =
% valid data, 1 = reduced performance.
%
% Invalid data:
%
% Bit number 	Sensor data
% 0             Horizontal position and velocity
% 1             Roll and pitch
% 2             Heading
% 3             Heave and vertical velocity
% 4             Acceleration
% 5             For Rev H: Error fields
%               For Rev I: Delayed heave
% 6             Delayed heave
%
% Reduced performance:
%
% Bit number 	Sensor data
% 16            Horizontal position and velocity
% 17            Roll and pitch
% 18            Heading
% 19            Heave and vertical velocity
% 20            Acceleration
% 21            For Rev H: Error fields
%               For Rev I: Delayed heave
% 22            Delayed heave
out_struct.status = fread(fid,1,'uint32');

% Position in decimal degrees.
out_struct.latitude_deg = fread(fid,1,'double');

% Position in decimal degrees.
out_struct.longitude_deg = fread(fid,1,'double');

% Height of sensor reference point above the ellipsoid. Positive above
% ellipsoid. ellipsoidHeight_m is not corrected for motion and installation
% offsets of the position sensor.
out_struct.ellipsoidHeight_m = fread(fid,1,'float');

% Roll. Unit degree.
out_struct.roll_deg = fread(fid,1,'float');

% Pitch. Unit degree
out_struct.pitch_deg = fread(fid,1,'float');

% Heading of vessel. Unit degree. Relative to the fixed coordinate system,
% i.e. true north.
out_struct.heading_deg = fread(fid,1,'float');

% Heave. Unit meter. Positive downwards.
out_struct.heave_m = fread(fid,1,'float');

% Roll rate. Unit degree/s
out_struct.rollRate = fread(fid,1,'float');

% Pitch rate. Unit degree/s
out_struct.pitchRate = fread(fid,1,'float');

% Yaw (heading) rate. Unit degree/s
out_struct.yawRate = fread(fid,1,'float');

% Velocity North (X). Unit m/s
out_struct.velNorth = fread(fid,1,'float');

% Velocity East (Y). Unit m/s
out_struct.velEast = fread(fid,1,'float');

% Velocity downwards (Z). Unit m/s
out_struct.velDown = fread(fid,1,'float');

% Latitude error. Unit meter.
out_struct.latitudeError_m = fread(fid,1,'float');

% Longitude error. Unit meter.
out_struct.longitudeError_m = fread(fid,1,'float');

% Ellipsoid height error. Unit meter.
out_struct.ellipsoidHeightError_m = fread(fid,1,'float');

% Roll error. Unit degree.
out_struct.rollError_deg = fread(fid,1,'float');

% Pitch error. Unit degree.
out_struct.pitchError_deg = fread(fid,1,'float');

% Heading error. Unit degree.
out_struct.headingError_deg = fread(fid,1,'float');

% Heave error. Unit meter.
out_struct.heaveError_m = fread(fid,1,'float');

% Unit m/s^2.
out_struct.northAcceleration = fread(fid,1,'float');

% Unit m/s^2.
out_struct.eastAcceleration = fread(fid,1,'float');

% Unit m/s^2.
out_struct.downAcceleration = fread(fid,1,'float');

end

function out_struct = CFF_read_KMdelayedHeave(fid)
% #SKM - delayed heave. Included if available from sensor.
%
% Verified correct for kmall format revisions F-I

out_struct.time_sec = fread(fid,1,'uint32');
out_struct.time_nanosec = fread(fid,1,'uint32');

% Delayed heave. Unit meter.
out_struct.delayedHeave_m = fread(fid,1,'float');

end

