function kmallRev = CFF_get_kmall_revision(EMdgmIIP)
%CFF_GET_KMALL_REVISION  Get the KMALL format revision (single letter)
%

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

idx = strfind(EMdgmIIP.install_txt,'KMALL:Rev ') + 10;
kmallRev = EMdgmIIP.install_txt(idx);

end