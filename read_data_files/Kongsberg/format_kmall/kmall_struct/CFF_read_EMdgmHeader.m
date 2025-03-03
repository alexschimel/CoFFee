function out_struct = CFF_read_EMdgmHeader(fid)
%CFF_READ_EMDGMHEADER  Read header struct of a kmall datagram
%
%   Definition of general datagram header.
%
%   Verified correct for kmall format revisions F-I
%
%   Dev notes - tried to accelerate code with block reading and typecasting but
%   just this series of fread calls is faster.
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% Datagram length in bytes. The length field at the start (4 bytes) and end
% of the datagram (4 bytes) are included in the length count.
out_struct.numBytesDgm = fread(fid,1,'uint32');

% Multi beam datagram type definition, e.g. #AAA (4 bytes)
out_struct.dgmType = fscanf(fid,'%c',4);

% Datagram version.
out_struct.dgmVersion = fread(fid,1,'uint8');

% System ID. Parameter used for separating datagrams from different
% echosounders if more than one system is connected to SIS/K-Controller.
out_struct.systemID = fread(fid,1,'uint8');

% Echo sounder identity, e.g. 124, 304, 712, 2040, 2045 (EM 2040C)
out_struct.echoSounderID = fread(fid,1,'uint16');

% UTC time in seconds. Epoch 1970-01-01. time_nanosec part to be added for
% more exact time.
out_struct.time_sec = fread(fid,1,'uint32');

% Nano seconds remainder. time_nanosec part to be added to time_sec for
% more exact time.
out_struct.time_nanosec = fread(fid,1,'uint32');


end