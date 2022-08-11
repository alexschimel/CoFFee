function fData = CFF_set_bottom_sample(fData,bot)
%CFF_SET_BOTTOM_SAMPLE  One-line description
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

datagramSource = CFF_get_datagramSource(fData);
fData.(sprintf('X_BP_bottomSample_%s',datagramSource)) = bot; %in sample number
