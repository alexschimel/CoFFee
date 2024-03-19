function out_struct = CFF_read_EMdgmCHE(fid, dgmVersion_warning_flag)
%CFF_READ_EMDGMCHE  Read kmall structure #CHE
%
%   #CHE - Struct of compatibility heave sensor datagram.
%
%   Used for backward compatibility with .all datagram format. Sent before
%   #MWC (water column datagram) datagram if compatibility mode is enabled.
%   The multibeam datagram body is common with the #MWC datagram.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


out_struct.header = CFF_read_EMdgmHeader(fid);

CHE_VERSION = out_struct.header.dgmVersion;
if CHE_VERSION>0 && dgmVersion_warning_flag
    % definitions in this function and subfunctions valid for CHE_VERSION:
    % 0 (kmall format revisions F-I, and presumably earlier ones?)
    warning('#CHE datagram version (%i) unsupported. Continue reading but there may be issues.',CHE_VERSION);
end

out_struct.cmnPart = CFF_read_EMdgmMbody(fid);
out_struct.data    = CFF_read_EMdgmCHEdata(fid);

end


function out_struct = CFF_read_EMdgmCHEdata(fid)
% #CHE - Heave compatibility data part. Heave reference point is at
% transducer instead of at vessel reference point.
%
% Verified correct for kmall format revisions F-I

% Heave. Unit meter. Positive downwards.
out_struct.heave_m = fread(fid,1,'float');

end