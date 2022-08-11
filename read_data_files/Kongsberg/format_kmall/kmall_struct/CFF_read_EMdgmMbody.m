function out_struct = CFF_read_EMdgmMbody(fid)
%CFF_READ_EMDGMMBODY  Read Body part of a Multibeam datagram in kmall file
%
%   Multibeam (M) datagrams - body part. Start of body of all M datagrams.
%
%   Contains information of transmitter and receiver used to find data in
%   datagram. The table below illustrates how the indexes will be filled
%   out in different system configurations. Each vertical column is data
%   from one datagram. See index description table and figure below for
%   more information. See the chapter for #MRZ datagram, for more details.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021

% Used for denoting size of current struct, EMdgmMbody_def.
out_struct.numBytesCmnPart = fread(fid,1,'uint16');

% A ping is made of one or more RX fans and one or more TX pulses
% transmitted at approximately the same time. Ping counter is incremented
% at every set of TX pulses (one or more pulses transmitted at
% approximately the same time).
out_struct.pingCnt = fread(fid,1,'uint16');

% Number of rx fans per ping gives information of how many #MRZ datagrams
% are generated per ping. Combined with swathsPerPing, number of datagrams
% to join for a complete swath can be found.
out_struct.rxFansPerPing = fread(fid,1,'uint8');

% Index 0 is the aft swath, port side.
out_struct.rxFanIndex = fread(fid,1,'uint8');

% Number of swaths per ping. A swath is a complete set of across track
% data. A swath may contain several transmit sectors and RX fans.
out_struct.swathsPerPing = fread(fid,1,'uint8');

% Alongship index for the location of the swath in multi swath mode. Index
% 0 is the aftmost swath.
out_struct.swathAlongPosition = fread(fid,1,'uint8');

% Transducer used in this rx fan. Index:
% 0 = TRAI_TX1
% 1 = TRAI_TX2 etc.
out_struct.txTransducerInd = fread(fid,1,'uint8');

% Transducer used in this rx fan. Index:
% 0 = TRAI_RX1
% 1 = TRAI_RX2 etc.
out_struct.rxTransducerInd = fread(fid,1,'uint8');

% Total number of receiving units.
out_struct.numRxTransducers = fread(fid,1,'uint8');

% For future use. 0 - current algorithm, >0 - future algorithms.
out_struct.algorithmType = fread(fid,1,'uint8');

end