function [KMALLdata,datagrams_parsed_idx] = CFF_read_kmall(KMALLfilename,varargin)
%CFF_READ_KMALL  Read kmall file or pair of files
%
%   Reads contents of one Kongsberg EM series binary data file in .kmall
%   format (.kmall or .kmwcd), or a pair of .kmall/.kmwcd files, allowing
%   choice on which type of datagrams to parse.
%
%   KMALLdata = CFF_READ_KMALL(KMALLfilename) reads all datagrams in a
%   Kongsberg file (extension .kmall or .kmwcd) KMALLfilenamem, and store
%   them in KMALLdata.
%
%   KMALLdata = CFF_READ_KMALL(KMALLfilename,datagrams) reads only those
%   datagrams in KMALLfilename that are specified by datagrams, and store
%   them in KMALLdata.
%
%   KMALLdata = CFF_READ_KMALL(KMALLfilename,'datagrams',datagrams) does
%   the same.
%
%   Note this function will extract all datagram types of interest. For
%   more control (say you only want the first ten depth datagrams and the
%   last position datagram), use CFF_READ_KMALL_FROM_FILEINFO.
%
%   See also CFF_KMALL_FILE_INFO, CFF_READ_KMALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021


%% Input arguments management
p = inputParser;

% name of the .kmall or .kmwcd file (or pair)
argName = 'KMALLfilename';
argCheck = @(x) CFF_check_KMALLfilename(x);
addRequired(p,argName,argCheck);

% types of datagram to read
argName = 'datagrams';
argDefault = [];
argCheck = @(x) isnumeric(x)||iscell(x)||(ischar(x)&&~strcmp(x,'datagrams')); % that last part allows the use of the couple name,param
addOptional(p,argName,argDefault,argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,KMALLfilename,varargin{:});

% and get results
KMALLfilename      = p.Results.KMALLfilename;
datagrams_to_parse = p.Results.datagrams;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p;

% check input
if ischar(KMALLfilename)
    % single file .kmall OR .kmwcd. Convert filename to cell.
    KMALLfilename = {KMALLfilename};
else
    % matching file pair .kmall AND .kmwcd.
    % make sure .kmwcd is listed first because this function only reads in
    % the 2nd file what it could not find in the first, and we want to only
    % grab from the .kmall file what is needed and couldn't be found in the
    % .kmwcd file.
    if strcmpi(CFF_file_extension(KMALLfilename{1}),'.kmall')
        KMALLfilename = fliplr(KMALLfilename);
    end
end


%% Prep

% number of files
nFiles = numel(KMALLfilename);

% start message
filename = CFF_file_name(KMALLfilename{1},1);
if nFiles == 1
    comms.start(sprintf('Reading data in file %s',filename));
else
    filename_2_ext = CFF_file_extension(KMALLfilename{2});
    comms.start(sprintf('Reading data in pair of files %s and %s',filename,filename_2_ext));
end

% start progress
comms.progress(0,nFiles);


%% FIRST FILE

% Get info from first (or only) file
if nFiles == 1
    comms.step('Listing datagrams');
else
    comms.step('Listing datagrams in paired file #1/2');
end
info = CFF_kmall_file_info(KMALLfilename{1});

% communicate progress
comms.progress(0.5,nFiles);

if isempty(datagrams_to_parse)
    % parse all datagrams in first file
    
    info.parsed(:) = 1;
    datagrams_parsed_in_first_file = unique(info.dgm_type_code);
    datagrams_parsed_idx = [];
    
else
    % datagrams to parse are listed in input
    
    if ischar(datagrams_to_parse)
        datagrams_to_parse = {datagrams_to_parse};
    end
    
    % datagrams available
    datagrams_available = unique(info.dgm_type_code);
    
    % find which datagrams can be read here
    datagrams_parsable_idx = ismember(datagrams_to_parse,datagrams_available);
    
    % if any, read those datagrams
    if any(datagrams_parsable_idx)
        idx = ismember(info.dgm_type_code,datagrams_to_parse(datagrams_parsable_idx));
        info.parsed(idx) = 1;
    end
    datagrams_parsed_idx = datagrams_parsable_idx;
    
end

% read data
if nFiles == 1
    comms.step('Reading datagrams');
else
    comms.step('Reading datagrams in paired file #1/2');
end
KMALLdata = CFF_read_kmall_from_fileinfo(KMALLfilename{1}, info);

% communicate progress
comms.progress(1,nFiles);
    

%% SECOND FILE (if any)
if nFiles>1
    
    % parse only if we requested to read all datagrams (in which case, the
    % second file might have datagrams not read in the first and we need to
    % grab those) OR if we requested a specific set of datagrams and didn't
    % get them all from the first file.
    if isempty(datagrams_to_parse) || ~all(datagrams_parsed_idx)
        
        % Get info in second file
        comms.step('Listing datagrams in paired file #2/2');
        info = CFF_kmall_file_info(KMALLfilename{2});
        
        % communicate progress
        comms.progress(1.5,nFiles);
        
        if isempty(datagrams_to_parse)
            % parse all datagrams in second file which we didn't get in the
            % first one.
            
            % datagrams in second file
            datagrams_available_in_second_file = unique(info.dgm_type_code);
            
            % those in second file that were not in first
            datagrams_to_parse_in_second_file = setdiff(datagrams_available_in_second_file,datagrams_parsed_in_first_file);
            
            % parse those
            idx = ismember(info.dgm_type_code,datagrams_to_parse_in_second_file);
            info.parsed(idx) = 1;
            
            % for output
            datagrams_parsed_idx = [];
            
        else
            % datagrams to parse are listed
            
            datagrams_available_in_second_file = unique(info.dgm_type_code);
            
            % find which remaining datagram types can be read here
            datagrams_to_parse_in_second_file_idx = ismember(datagrams_to_parse,datagrams_available_in_second_file) & ~datagrams_parsed_idx;
            
            % if any, read those datagrams
            if any(datagrams_to_parse_in_second_file_idx)
                idx = ismember(info.dgm_type_code,datagrams_to_parse(datagrams_to_parse_in_second_file_idx));
                info.parsed(idx) = 1;
            end
            datagrams_parsed_idx = datagrams_parsed_idx | datagrams_to_parse_in_second_file_idx;
            
        end
        
        % read data in second file
        comms.step('Reading datagrams in paired file #2/2');
        KMALLdata2 = CFF_read_kmall_from_fileinfo(KMALLfilename{2}, info);
        
        % combine to data from first file
        KMALLdata = {KMALLdata KMALLdata2};
        
    end
    
    % communicate progress
    comms.progress(2,nFiles);
    
end


%% end message
comms.finish('Done');
