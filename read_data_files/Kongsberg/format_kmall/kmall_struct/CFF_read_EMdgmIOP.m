function out_struct = CFF_read_EMdgmIOP(fid, dgmVersion_warning_flag)
%CFF_READ_EMDGMIOP  Read kmall structure #IOP
%
%   Definition of #IOP datagram containing runtime parameters, exactly as
%   chosen by operator in the K-Controller/SIS menus.
%   For detailed description of text strings, see the separate document
%   Runtime parameters set by operator.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

out_struct.header = CFF_read_EMdgmHeader(fid);

IOP_VERSION = out_struct.header.dgmVersion;
if IOP_VERSION>0 && dgmVersion_warning_flag
    % definitions in this function valid for IOP_VERSION:
    % 0 (kmall format revisions F-I, and presumably earlier ones?)
    warning('#IOP datagram version (%i) unsupported. Continue reading but there may be issues.',IOP_VERSION);
end

% Size in bytes of body part struct. Used for denoting size of rest of
% the datagram.
out_struct.numBytesCmnPart = fread(fid,1,'uint16');

% Information. For future use.
out_struct.info = fread(fid,1,'uint16');

% Status. For future use.
out_struct.status = fread(fid,1,'uint16');

% Runtime paramters as text format. Parameters separated by ; and lines
% separated by , delimiter. Text strings refer to names in menues of
% the K-Controller/SIS.
% For detailed description of text strings, see the separate document
% Runtime parameters set by operator
out_struct.runtime_txt = fscanf(fid, '%c',out_struct.numBytesCmnPart-6);

end