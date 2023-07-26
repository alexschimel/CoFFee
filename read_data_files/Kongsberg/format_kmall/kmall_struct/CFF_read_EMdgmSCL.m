function out_struct = CFF_read_EMdgmSCL(fid, dgmVersion_warning_flag)
%CFF_READ_EMDGMSCL  Read kmall structure #SCL
%
%   #SCL - CLock datagram.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021

out_struct.header = CFF_read_EMdgmHeader(fid);

SCL_VERSION = out_struct.header.dgmVersion;
if SCL_VERSION>0 && dgmVersion_warning_flag
    % definitions in this function and subfunctions valid for SCL_VERSION:
    % 0 (kmall format revisions F-I, and presumably earlier ones?)
    warning('#SCL datagram version (%i) unsupported. Continue reading but there may be issues.',SCL_VERSION);
end

out_struct.cmnPart = CFF_read_EMdgmScommon(fid,'#SCL');

% number of bytes in the actual SCL data is the total datagram size
% (need to remove 4 bytes for the final numBytes field) minus what was
% read in the header (20 bytes, as currently defined), the common part
% (8 bytes, as currently defined), and the data block until the actual
% data (8 bytes, as currently defined)
SCL_data_numBytes = (out_struct.header.numBytesDgm - 4) ...
    - 20 ...
    - out_struct.cmnPart.numBytesCmnPart ...
    - 8;

out_struct.sensData = CFF_read_EMdgmSCLdataFromSensor(fid, SCL_data_numBytes);

end

function out_struct = CFF_read_EMdgmSCLdataFromSensor(fid, SCL_data_numBytes)
% Part of clock datagram giving offsets and the raw input in text format.
%
% Verified correct for kmall format revisions F-I

% Offset in seconds from K-Controller operator input.
out_struct.offset_sec = fread(fid,1,'float');

% Clock deviation from PU. Difference between time stamp at receive of
% sensor data and time in the clock source. Unit nanoseconds. Difference
% smaller than +/- 1 second if 1PPS is active and sync from ZDA.
out_struct.clockDevPU_nanosec = fread(fid,1,'int32');

% Clock data as received from sensor, in text format. Data are uncorrected
% for offsets.
out_struct.dataFromSensor = fscanf(fid, '%c', SCL_data_numBytes);

end
