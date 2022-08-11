function kmallRev = CFF_get_kmall_revision(EMdgmIIP)
%CFF_GET_KMALL_REVISION  Get the KMALL format revision (single letter)
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

idx = strfind(EMdgmIIP.install_txt,'KMALL:Rev ') + 10;
kmallRev = EMdgmIIP.install_txt(idx);

end