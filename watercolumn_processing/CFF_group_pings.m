function [maxNSamples_groups,ping_group_start,ping_group_end] = CFF_group_pings(num_samp_per_dtgrm, ping_counter, dtgrm_ping_number)
%CFF_GROUP_PINGS  Makes groups of pings based on number of samples
%
%   Makes groups of pings based on the max number of samples in each ping.


%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 30-08-2021

% get the maximum number of samples for each ping
if iscell(num_samp_per_dtgrm)
    % if num_samp_per_dtgrm is a cell array, it holds the number of
    % samples per datagram. Group them by ping and find the max
    max_num_samp_per_ping = nan(1,numel(ping_counter));
    for ii = 1:numel(ping_counter)
        ix = dtgrm_ping_number==ping_counter(ii);
        max_num_samp_per_ping(ii) = max(cellfun(@(x) max(x),num_samp_per_dtgrm(ix)));
    end
else
    % if num_samp_per_dtgrm is normal array, it already is the max number
    % of samples per ping
    max_num_samp_per_ping = num_samp_per_dtgrm;
end

% Yoann's mystery algorithm to make groups of sequential pings based on the
% max number of samples they contain
nb_min_s = 50;
nb_min_win = 50;
perc_inc = 10/100;
X_fact = prctile(ceil(max_num_samp_per_ping/nb_min_s)*nb_min_s,90)/prctile(floor(max_num_samp_per_ping/nb_min_s)*nb_min_s,10);
div_factor = (perc_inc/(X_fact-1))*min(max_num_samp_per_ping);
div_factor = ceil(div_factor/nb_min_s)*nb_min_s;
group_by_nb_s = ceil(filter2(ones(1,nb_min_win),ceil(max_num_samp_per_ping/div_factor),'same')./...
    filter2(ones(1,nb_min_win),ones(size(ping_counter)),'same'));
idx_change = find(diff(group_by_nb_s)~=0);
idx_change_2 = find(diff(ping_counter)>1)+1;
idx_change = union(idx_change,idx_change_2);

% % mystery plot for the mystery algorithm
% figure();
% plot(ping_counter,ceil(max_num_samp_per_ping/div_factor));
% hold on;
% plot(ping_counter,group_by_nb_s);
% plot(ping_counter,max_num_samp_per_ping/div_factor);
% for uil = 1:numel(idx_change)
%     xline(ping_counter(idx_change(uil)),'--k');
% end

% and the resulting grouping of pings:
idx_new_group = unique([1 idx_change]);
ping_group_start = ping_counter(idx_new_group);
ping_group_end   = ping_counter([idx_new_group(2:end)-1 numel(ping_counter)]);
num_groups = numel(idx_new_group);

% calculate the max number of samples in a ping, per group
maxNSamples_groups = nan(1,num_groups);
for uig = 1:num_groups
    if iscell(num_samp_per_dtgrm)
        % indices of datagrams in this group
        ix = (dtgrm_ping_number>=ping_group_start(uig))&(dtgrm_ping_number<=ping_group_end(uig));
        maxNSamples_groups(uig) = max(cellfun(@(x) max(x),num_samp_per_dtgrm(ix)));
    else
        % indices of datagrams in this group
        ix = (ping_counter>=ping_group_start(uig))&(ping_counter<=ping_group_end(uig));
        maxNSamples_groups(uig) = max(num_samp_per_dtgrm(ix));
    end
end

% because ping counters often wrap around (i.e. max ping counter is 65536
% then it goes back to 1), this can trip up later code, so Yoann here
% changes the ping groups back to 1.
for ui = 1:num_groups
    ping_group_start(ui) = find(ping_counter==ping_group_start(ui),1);
    ping_group_end(ui) = find(ping_counter==ping_group_end(ui),1);
end




