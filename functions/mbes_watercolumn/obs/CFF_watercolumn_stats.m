function stats = CFF_watercolumn_stats(fData)
% stats = CFF_watercolumn_stats(fData)
%
% DESCRIPTION
%
% calculate statistics on both L0 and L1 datasets
%
% USE
%
% This is a bit more detailed description of how to use the function. DELETE THIS LINE IF UNUSED
%
% PROCESSING SUMMARY
% 
% This is a summary of the steps in the processing. DELETE THIS LINE IF UNUSED
%
% REQUIRED INPUT ARGUMENTS
%
% - 'argRequired': description of the first required argument. If several, add after this line. 
%
% OPTIONAL INPUT ARGUMENTS
%
% - 'XXX': description of the optional arguments with list of valid values and what they do. DELETE THIS LINE IF UNUSED
%
% PARAMETERS INPUT ARGUMENTS
%
% - 'XXX': description of the optional parameter arguments (name-value pair). DELETE THIS LINE IF UNUSED
%
% OUTPUT VARIABLES
%
% - OUT: description of output variables. DELETE THIS LINE IF UNUSED
%
% RESEARCH NOTES
%
% This describes what features are temporary or needed future developments. DELETE THIS LINE IF UNUSED
%
% NEW FEATURES
%
% YYYY-MM-DD: second version. Describes the update. DELETE THIS LINE IF UNUSED
% YYYY-MM-DD: first version.
%
% EXAMPLES
%
% This section contains examples of valid function calls. DELETE THIS LINE IF UNUSED
%
%%%
% Alex Schimel, Deakin University. CHANGE AUTHOR IF NEEDED.
%%%


L0 = fData.WC_PBS_SampleAmplitudes; % original level

% L0 stats across all samples, per ping and per beam
stats.X_PB_L0_all_min    = nanmin(L0,[],3);
stats.X_PB_L0_all_max    = nanmax(L0,[],3);
stats.X_PB_L0_all_mean   = nanmean(L0,3);
stats.X_PB_L0_all_median = nanmedian(L0,3);
stats.X_PB_L0_all_std    = nanstd(L0,0,3);

% L0 stats across all samples, per ping
stats.X_P_L0_all_min  = nanmin(stats.X_PB_L0_all_min,[],2);
stats.X_P_L0_all_max  = nanmax(stats.X_PB_L0_all_max,[],2);
stats.X_P_L0_all_mean = nanmean(stats.X_PB_L0_all_mean,2);

% L0 stats across all samples, for entire file
stats.X_L0_all_min     = nanmin(L0(:));
stats.X_L0_all_max     = nanmax(L0(:));
stats.X_L0_all_mean    = nanmean(L0(:));
stats.X_L0_all_median  = nanmedian(L0(:));
stats.X_L0_all_std     = nanstd(L0(:),0);
stats.X_L0_all_90perc  = CFF_invpercentile(L0(:),90);
stats.X_L0_all_95perc  = CFF_invpercentile(L0(:),95);
stats.X_L0_all_99perc  = CFF_invpercentile(L0(:),99);
stats.X_L0_all_999perc = CFF_invpercentile(L0(:),99.9);

% Now keep only samples above the filtered bottom detect
for ii = 1:size(L0,1)
    for jj = 1:size(L0,2)
        L0(ii,jj,b1(ii,jj)+1:end) = NaN;
    end
end

% L0 stats across water-column ("dirty") samples, per ping and per beam
stats.X_PB_L0_dirty_min    = nanmin(L0,[],3);
stats.X_PB_L0_dirty_max    = nanmax(L0,[],3);
stats.X_PB_L0_dirty_mean   = nanmean(L0,3);
stats.X_PB_L0_dirty_median = nanmedian(L0,3);
stats.X_PB_L0_dirty_std    = nanstd(L0,0,3);

% L0 stats across water-column ("dirty") samples, per ping
stats.X_P_L0_dirty_min  = nanmin(stats.X_PB_L0_dirty_min,[],2);
stats.X_P_L0_dirty_max  = nanmax(stats.X_PB_L0_dirty_max,[],2);
stats.X_P_L0_dirty_mean = nanmean(stats.X_PB_L0_dirty_mean,2);

% L0 stats across water-column ("dirty") samples, for entire file
stats.X_L0_dirty_min     = nanmin(L0(:));
stats.X_L0_dirty_max     = nanmax(L0(:));
stats.X_L0_dirty_mean    = nanmean(L0(:));
stats.X_L0_dirty_median  = nanmedian(L0(:));
stats.X_L0_dirty_std     = nanstd(L0(:),0);
stats.X_L0_dirty_90perc  = CFF_invpercentile(L0(:),90);
stats.X_L0_dirty_95perc  = CFF_invpercentile(L0(:),95);
stats.X_L0_dirty_99perc  = CFF_invpercentile(L0(:),99);
stats.X_L0_dirty_999perc = CFF_invpercentile(L0(:),99.9);

% keep only samples above the first return artefact
for ii = 1:size(L0,1)
    firstreturn = min(b1(ii,:));
    for jj = 1:size(L0,2)
        L0(ii,jj,firstreturn-1:end) = NaN;
    end
end

% L0 stats across water-column ("clean") samples, per ping and per beam
stats.X_PB_L0_clean_min    = nanmin(L0,[],3);
stats.X_PB_L0_clean_max    = nanmax(L0,[],3);
stats.X_PB_L0_clean_mean   = nanmean(L0,3);
stats.X_PB_L0_clean_median = nanmedian(L0,3);
stats.X_PB_L0_clean_std    = nanstd(L0,0,3);

% L0 stats across water-column ("clean") samples, per ping
stats.X_P_L0_clean_min  = nanmin(stats.X_PB_L0_clean_min,[],2);
stats.X_P_L0_clean_max  = nanmax(stats.X_PB_L0_clean_max,[],2);
stats.X_P_L0_clean_mean = nanmean(stats.X_PB_L0_clean_mean,2);

% L0 stats across water-column ("clean") samples, for entire file
stats.X_L0_clean_min     = nanmin(L0(:));
stats.X_L0_clean_max     = nanmax(L0(:));
stats.X_L0_clean_mean    = nanmean(L0(:));
stats.X_L0_clean_median  = nanmedian(L0(:));
stats.X_L0_clean_std     = nanstd(L0(:),0);
stats.X_L0_clean_90perc  = CFF_invpercentile(L0(:),90);
stats.X_L0_clean_95perc  = CFF_invpercentile(L0(:),95);
stats.X_L0_clean_99perc  = CFF_invpercentile(L0(:),99);
stats.X_L0_clean_999perc = CFF_invpercentile(L0(:),99.9);
