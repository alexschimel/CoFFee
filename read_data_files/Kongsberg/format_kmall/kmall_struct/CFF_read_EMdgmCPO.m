function out_struct = CFF_read_EMdgmCPO(fid, dgmVersion_warning_flag)
%CFF_READ_EMDGMCPO  Read kmall structure #CPO
%
%   #CPO - Struct of compatibility position sensor datagram.
%
%   Data from active sensor will be motion corrected if indicated by
%   operator. Motion correction is applied to latitude, longitude, speed,
%   course and ellipsoidal height.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

out_struct.header = CFF_read_EMdgmHeader(fid);

CPO_VERSION = out_struct.header.dgmVersion;
if CPO_VERSION>0 && dgmVersion_warning_flag
    % definitions in this function and subfunctions valid for CPO_VERSION:
    % 0 (kmall format revisions F-I, and presumably earlier ones?)
    warning('#CPO datagram version (%i) unsupported. Continue reading but there may be issues.',CPO_VERSION);
end

out_struct.cmnPart = CFF_read_EMdgmScommon(fid,'#CPO');

% number of bytes in the actual CPO data is the total datagram size
% (need to remove 4 bytes for the final numBytes field) minus what was
% read in the header (20 bytes, as currently defined), the common part
% (8 bytes, as currently defined), and the data block until the actual
% data (40 bytes, as currently defined)
CPO_data_numBytes = (out_struct.header.numBytesDgm - 4) ...
    - 20 ...
    - out_struct.cmnPart.numBytesCmnPart ...
    - 40;

out_struct.sensorData = CFF_read_EMdgmCPOdataBlock(fid, CPO_data_numBytes);

end


function out_struct = CFF_read_EMdgmCPOdataBlock(fid, CPO_data_numBytes)
% #CPO - Compatibility sensor position compatibility data block. Data from
% active sensor is referenced to position at antenna footprint at water
% level. Data is corrected for motion ( roll and pitch only) if enabled by
% K-Controller operator. Data given both decoded and corrected (active
% sensors), and raw as received from sensor in text string.
%
% Verified correct for kmall format revisions F-I

% UTC time from position sensor. Unit seconds. Epoch 1970-01-01. Nanosec
% part to be added for more exact time.
out_struct.timeFromSensor_sec = fread(fid,1,'uint32');

% UTC time from position sensor. Unit nano seconds remainder.
out_struct.timeFromSensor_nanosec = fread(fid,1,'uint32');

% Only if available as input from sensor. Calculation according to format.
out_struct.posFixQuality_m = fread(fid,1,'float');

% Motion corrected (if enabled in K-Controller) data as used in depth
% calculations. Referred to antenna footprint at water level. Unit decimal
% degree.
% For Rev H: Parameter is set to define UNAVAILABLE_LATITUDE if sensor
% inactive.
out_struct.correctedLat_deg = fread(fid,1,'double');

% Motion corrected (if enabled in K-Controller) data as used in depth
% calculations. Referred to antenna footprint at water level. Unit decimal
% degree.
% For Rev H: Parameter is set to define UNAVAILABLE_LONGITUDE if sensor
% inactive.
out_struct.correctedLong_deg = fread(fid,1,'double');

% Speed over ground. Unit m/s. Motion corrected (if enabled in
% K-Controller) data as used in depth calculations.
% For Rev H: If unavailable or from inactive sensor, value set to define
% UNAVAILABLE_SPEED.
% For Rev I: If unavailable, value set to define UNAVAILABLE_SPEED.
out_struct.speedOverGround_mPerSec = fread(fid,1,'float');

% Course over ground. Unit degree. Motion corrected (if enabled in
% K-Controller) data as used in depth calculations.
% For Rev H: If unavailable or from inactive sensor, value set to define
% UNAVAILABLE_COURSE.
% For Rev I: If unavailable, value set to define UNAVAILABLE_COURSE.
out_struct.courseOverGround_deg = fread(fid,1,'float');

% Height of antenna footprint above the ellipsoid. Unit meter. Motion
% corrected (if enabled in K-Controller) data as used in depth
% calculations.
% For Rev H: If unavailable or from inactive sensor, value set to define
% UNAVAILABLE_ELLIPSOIDHEIGHT.
% For Rev I: If unavailable, value set to define
% UNAVAILABLE_ELLIPSOIDHEIGHT.
out_struct.ellipsoidHeightReRefPoint_m = fread(fid,1,'float');

% Position data as received from sensor, i.e. uncorrected for motion etc.
out_struct.posDataFromSensor = fscanf(fid, '%c', CPO_data_numBytes);

end