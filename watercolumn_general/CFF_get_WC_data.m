function data_tot = CFF_get_WC_data(fData,fieldN,varargin)
%CFF_GET_WC_DATA  Grab water column data in a fData structure
%
%   Grab water column data in a fData structure, possibly subsampled in
%   range or beams, or any pings required, in raw format or true value.
%
%   *INPUT VARIABLES*
%   * |fData|: Required. Structure for the storage of kongsberg EM series
%   multibeam data in a format more convenient for processing. The data is
%   recorded as fields coded "a_b_c" where "a" is a code indicating data
%   origing, "b" is a code indicating data dimensions, and "c" is the data
%   name. See the help of function CFF_convert_ALLdata_to_fData.m for
%   description of codes.
%   * |fieldN|: Required. Description (Information).
%   * |iPing|: Optional. Description (Information). Default []. 
%   * |dr_sub|: Optional. Description (Information). Default 1.
%   * |db_sub|: Optional. Description (Information). Default 1.
%   * |output_format|: Optional. Description (Information). 'raw' or 'true'
%   (default)

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021

% input parser
p = inputParser;
addRequired(p,'fieldN',@ischar);
addOptional(p,'iPing',[],@(x) isnumeric(x) ||isempty(x));
addOptional(p,'dr_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x) && x>0);
addOptional(p,'output_format','true',@(x) ischar(x) && ismember(x,{'raw' 'true'}));
addParameter(p,'iBeam',[],@(x) isnumeric(x) ||isempty(x));
addParameter(p,'iRange',[],@(x) isnumeric(x) ||isempty(x));
parse(p,fieldN,varargin{:})
iPing  = round(p.Results.iPing);
iBeam  = p.Results.iBeam;
iRange = p.Results.iRange;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
output_format = p.Results.output_format;

if ~isfield(fData,fieldN)
    data_tot = [];
    return;
end

datagramSource = CFF_get_datagramSource(fData);
if ~ismember(datagramSource,{'WC','AP'})
    data_tot = [];
    return;
end

if isempty(iPing)
    iPing = 1:cellfun(@(x) nansum(size(x.Data.val,3)),fData.(fieldN));
end
if isempty(iBeam)
    iBeam = 1:cellfun(@(x) nanmax(size(x.Data.val,2)),fData.(fieldN));
end
if isempty(iRange)
    iRange = 1:cellfun(@(x) nanmax(size(x.Data.val,1)),fData.(fieldN));
end

% finding relevant groups of pings
p_start = fData.(sprintf('%s_n_start',datagramSource));
p_end   = fData.(sprintf('%s_n_end',datagramSource));
pingCounter = fData.(sprintf('%s_1P_PingCounter',datagramSource));
p_end(p_end>numel(pingCounter))     = numel(pingCounter);
p_start(p_start>numel(pingCounter)) = numel(pingCounter);

% indices of first and last group of pings where requested data is found
istart = find(p_start<=nanmin(iPing),1,'last');
iend   = find(p_end>=nanmax(iPing),1,'first');

% init data output
data_tot = nan(ceil(numel(iRange)/dr_sub),ceil(numel(iBeam)/db_sub),numel(iPing),'single');

% init ???
ip = 0;

% debug graph
debug_disp = 0;
if debug_disp
    f = figure();
    ax = axes(f);
end

% read through each memmapped file
for ig = istart:iend
    
    % indices of data to grab, with decimation
    iRange_src = iRange(1):dr_sub:min([iRange(end) size(fData.(fieldN){ig}.Data.val,1)]);
    iBeam_src  = iBeam(1):db_sub:min([iBeam(end) size(fData.(fieldN){ig}.Data.val,2)]);
    

%     iPing_src = pingCounter(iPing);
%     iPing_src_gr = intersect(iPing_src,ping_group_start(ig):ping_group_end(ig));
%     iPing_src = iPing_src_gr-ping_group_start(ig)+1;
%     iPing_src(iPing_src>size(fData.(fieldN){ig}.Data.val,3)) = [];
    
    iPing_src = intersect(iPing,p_start(ig):p_end(ig));
    iPing_src = iPing_src - p_start(ig) + 1;
    
    
    if isempty(iRange_src)||isempty(iBeam_src)||isempty(iPing_src)
        data_tot = [];
        continue;
    end
    
    % grab data
    data = fData.(fieldN){ig}.Data.val(iRange_src,iBeam_src,iPing_src);
    
    % transform to true values if required
    switch output_format
        
        case 'true'
            
            % get info about data
            idx_undsc = regexp(fieldN,'_');
            datagramSource = fieldN(1:idx_undsc(1)-1);
            fieldname = fieldN(idx_undsc(2)+1:end);
            
            % get NaN value (should be a single value)
            Nanval = fData.(sprintf('%s_1_%s_Nanval',datagramSource,fieldname));
            
            % get factor (one per memmap file in the new format)
            Fact = fData.(sprintf('%s_1_%s_Factor',datagramSource,fieldname));
            if numel(Fact)>1
                Fact = Fact(ig);
            end
            
            % get offset (doesn't exist for older format, one per memmap
            % file in the new format)
            offset_fieldname = sprintf('%s_1_%s_Offset',datagramSource,fieldname);
            if isfield(fData, offset_fieldname)
                Offset = fData.(offset_fieldname);
            else
                Offset = 0;
            end
            
            if numel(Offset)>1
                Offset = Offset(ig);
            end
            
            if ~isa(data,'single')
                
                % first, convert to single class
                data = single(data);
                
                % reset NaN value
                data(data==single(Nanval)) = single(NaN);
                
                % decode data, minimizing calculation time
                if Fact~=1 && Offset~=0
                    data = data*Fact+Offset;
                elseif Fact~=1 && Offset==0
                    data = data*Fact;
                elseif Fact==1 && Offset~=0
                    data = data+Offset;
                end
                
            end
            
    end
    
    if debug_disp
        for ii = 1:size(data_tot,3)
            imagesc(ax,squeeze(data(:,:,ii)));
            drawnow;
        end
    end
    
    % add to full array
    data_tot(1:size(data,1),1:(size(data,2)),ip+(1:(size(data,3)))) = data;
    
    % update ?
    ip = ip + (size(data,3));
    
end



