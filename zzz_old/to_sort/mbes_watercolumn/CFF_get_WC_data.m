function data = CFF_get_WC_data(fData,fieldN,varargin)
% CFF_get_WC_data.m
%
% Function to grab water column data in a fData structure, possibly
% subsampled in range or beams, or any pings required, in raw format or
% true value.

%   Copyright 2017-2018 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% input parsing

% init
p = inputParser;

% required
addRequired(p,'fData',@isstruct);
addRequired(p,'fieldN',@ischar);

% optional
addOptional(p,'iPing',[],@(x) isnumeric(x) ||isempty(x));
addOptional(p,'dr_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'output_format','true',@(x) ischar(x) && ismember(x,{'raw' 'true'}));

% parse
parse(p,fData,fieldN,varargin{:})

% get results
iPing = p.Results.iPing;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
output_format = p.Results.output_format;
clear p

%% get raw data
if ~isempty(iPing)
    data = fData.(fieldN).Data.val(1:dr_sub:end,1:db_sub:end,iPing);
else
    data = fData.(fieldN).Data.val(1:dr_sub:end,1:db_sub:end,:);
end


%% transform to true values if required
switch output_format
    
    case 'true'
        
        % get info about data
        idx_undsc = regexp(fieldN,'_');
        fact    = fData.(sprintf('%s_1_%s_Factor',fieldN(1:idx_undsc(1)-1),fieldN(idx_undsc(2)+1:end)));
        nan_val = fData.(sprintf('%s_1_%s_Nanval',fieldN(1:idx_undsc(1)-1),fieldN(idx_undsc(2)+1:end)));
        
        % convert to single class
        data = single(data);
        
        % add nans
        data(data==nan_val) = NaN;
        
        % factor top get true values
        data = data*fact;
        
end




