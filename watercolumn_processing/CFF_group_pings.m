function [maxNSamples_groups,ping_group_start,ping_group_end] = CFF_group_pings(num_samp_per_dtgrm, ping_counter, dtgrm_ping_number)
%CFF_GROUP_PINGS  Makes groups of pings based on number of samples
%
%   Make groups of pings based on the max number of samples in each ping.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/



%% BUG FIX
% Getting errors in the final calculation ("calculate the max number of samples
% in a ping, per group") when ping counter wraps down from 65535 back to 1. We
% had a last bit of code to modify ping_group_start and ping_group_end (now
% commented) to avoid such errors downstream, but recent examples show this
% wrapping does break this code too. So best solution is to unwrap ping counters
% right here at the begginning.

% assess if we have ping wraps
indexWrapInPingCounter = find(diff(ping_counter)<0)+1;
nWraps = numel(indexWrapInPingCounter);

if nWraps
    % need to unwrap ping_counter and dtgrm_ping_number
    
    % initialize
    unwrappedPingCounter = ping_counter;
    datagramUnwrappedPingCounter = dtgrm_ping_number;
    
    % unwrap
    for iWrap = 1:nWraps
        % wrap index and offset
        thisIndex = indexWrapInPingCounter(iWrap);
        offset = unwrappedPingCounter(thisIndex-1) - unwrappedPingCounter(thisIndex) + 1;
        
        % unwrap ping counter is easy
        unwrappedPingCounter(thisIndex:end) = unwrappedPingCounter(thisIndex:end) + offset;
        
        % unwrap dtgrm_ping_number is a bit more difficult in case there are
        % more than one wrap. This code assumes the values in dtgrm_ping_number
        % are consistently increasing, so this may create an error down the line
        % if this is not valid.
        idxfirstDtgmBeforeWrap = find(datagramUnwrappedPingCounter==unwrappedPingCounter(thisIndex-1),1,'first');
        thatIndex = idxfirstDtgmBeforeWrap + find(dtgrm_ping_number(idxfirstDtgmBeforeWrap+1:end)==ping_counter(thisIndex),1,'first');
        datagramUnwrappedPingCounter(thatIndex:end) = datagramUnwrappedPingCounter(thatIndex:end) + offset;
    end
    
    dbug = 0;
    if dbug
        figure;
        plot(ping_counter,'.-'); ylabel('ping counter'); hold on
        plot(unwrappedPingCounter,'ro-'); grid on; legend({'wrapped','unwrapped'});
    end
    
    % save unrwapped variables back into original variables to as to not change
    % the rest of the code
    ping_counter = unwrappedPingCounter;
    dtgrm_ping_number = datagramUnwrappedPingCounter; 
end

%% END BUG FIX

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
% changed the ping groups back to 1. After the bug fix above, this is now just
% bringing numbers back to 1.
for ui = 1:num_groups
    ping_group_start(ui) = find(ping_counter==ping_group_start(ui),1);
    ping_group_end(ui) = find(ping_counter==ping_group_end(ui),1);
end




