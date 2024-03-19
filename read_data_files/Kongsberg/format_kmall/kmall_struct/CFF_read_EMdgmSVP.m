function out_struct = CFF_read_EMdgmSVP(fid, dgmVersion_warning_flag)
%CFF_READ_EMDGMSVP  Read kmall structure #SVP
%
%   #SVP - Sound Velocity Profile. Data from sound velocity profile or from
%   CTD profile. Sound velocity is measured directly or estimated,
%   respectively.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

out_struct.header = CFF_read_EMdgmHeader(fid);

SVP_VERSION = out_struct.header.dgmVersion;
if SVP_VERSION~=1 && dgmVersion_warning_flag
    % definitions in this function and subfunctions valid for SVP_VERSION:
    % 1 (kmall format revisions F-I)
    warning('#SVP datagram version (%i) unsupported. Continue reading but there may be issues.',SVP_VERSION);
end

% Size in bytes of body part struct. Used for denoting size of rest of
% the datagram.
out_struct.numBytesCmnPart = fread(fid,1,'uint16');

% Number of sound velocity samples.
out_struct.numSamples = fread(fid,1,'uint16');

% Sound velocity profile format:
% 'S00' = sound velocity profile
% 'S01' = CTD profile
out_struct.sensorFormat = fscanf(fid,'%c',4);

% Time extracted from the Sound Velocity Profile. Parameter is set to
% zero if not found.
out_struct.time_sec = fread(fid,1,'uint32');

% Latitude in degrees. Negative if southern hemisphere. Position
% extracted from the Sound Velocity Profile. Parameter is set to define
% UNAVAILABLE_LATITUDE if not available.
out_struct.latitude_deg = fread(fid,1,'double');

% Longitude in degrees. Negative if western hemisphere. Position
% extracted from the Sound Velocity Profile. Parameter is set to define
% UNAVAILABLE_LONGITUDE if not available.
out_struct.longitude_deg = fread(fid,1,'double');

% SVP point samples, repeated numSamples times.
for iS = 1:out_struct.numSamples
    out_struct.sensorData(iS) = CFF_read_EMdgmSVPpoint(fid);
end

end


function out_struct = CFF_read_EMdgmSVPpoint(fid)
% #SVP - Sound Velocity Profile. Data from one depth point contains
% information specified in this struct.
%
% Verified correct for kmall format revisions F-I

% Depth at which measurement is taken. Unit m. Valid range from 0.00 m to
% 12000 m.
out_struct.depth_m = fread(fid,1,'float');

% Measured sound velocity from profile. Unit m/s. For a CTD profile, this
% will be the calculated sound velocity.
out_struct.soundVelocity_mPerSec = fread(fid,1,'float');

% Former absorption coefficient. Voided.
out_struct.padding = fread(fid,1,'uint32');

% Water temperature at given depth. Unit Celsius. For a Sound velocity
% profile (S00), this will be set to 0.00.
out_struct.temp_C = fread(fid,1,'float');

% Salinity of water at given depth. For a Sound velocity profile (S00),
% this will be set to 0.00.
out_struct.salinity = fread(fid,1,'float');

end