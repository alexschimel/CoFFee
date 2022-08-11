function out_struct = CFF_read_EMdgmMpartition(fid)
%CFF_READ_EMDGMMPARTITION  Read Partition of M datagram in kmall file
%
%   Multibeam (M) datagrams - data partition information. General for all M
%   datagrams.
%
%   If a multibeam depth datagram (or any other large datagram) exceeds the
%   limit of an UDP package (64 kB), the datagram is split into several
%   datagrams =< 64 kB before sending from the PU. The parameters in this
%   struct will give information of the partitioning of datagrams.
%   K-Controller/SIS merges all UDP packets/datagram parts to one datagram,
%   and store it as one datagram in the .kmall files. Datagrams stored in
%   .kmall files will therefore always have numOfDgm = 1 and dgmNum = 1,
%   and may have size > 64 kB. The maximum number of partitions from PU is
%   given by MAX_NUM_MWC_DGMS and MAX_NUM_MRZ_DGMS.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021

% Number of datagram parts to re-join to get one Multibeam datagram. E.g.
% 3.
out_struct.numOfDgms = fread(fid,1,'uint16');

% Datagram part number, e.g. 2 (of 3).
out_struct.dgmNum = fread(fid,1,'uint16');

end