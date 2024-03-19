function fData = CFF_set_bottom_sample(fData,bot)
%CFF_SET_BOTTOM_SAMPLE  One-line description
%

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

datagramSource = CFF_get_datagramSource(fData);
fData.(sprintf('X_BP_bottomSample_%s',datagramSource)) = bot; %in sample number
