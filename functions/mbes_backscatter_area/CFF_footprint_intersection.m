function L = CFF_footprint_intersection(pulse_lead, pulse_trail, beam_lead, beam_trail)
% given leading and trailing across track distances of pulse and beam
% footprints on the seafloor, do they intersect, and if so, what is the
% distance of the intersection?


% pulse and beam vector size are the same.
% They must have been calculated on the same time/angle

% extent of the intersection
min_lead = min(pulse_lead,beam_lead,'includenan');
max_trail = max(pulse_trail,beam_trail,'includenan');
L = min_lead - max_trail;

% if negative, there is no intersection
L(L<0) = nan;

