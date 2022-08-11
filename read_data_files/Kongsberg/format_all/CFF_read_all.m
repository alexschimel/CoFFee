function [ALLdata,datagrams_parsed_idx] = CFF_read_all(ALLfilename,varargin)
%CFF_READ_ALL  Read all file or pair of files
%
%   Reads contents of one Kongsberg EM series binary data file in .all
%   format (.all or .wcd), or a pair of .all/.wcd files, allowing choice on
%   which type of datagrams to parse.
%
%   ALLdata = CFF_READ_ALL(ALLfilename) reads all datagrams in a Kongsberg
%   file (extension .all or .wcd) ALLfilenamem, and store them in ALLdata.
%
%   ALLdata = CFF_READ_ALL(ALLfilename,datagrams) reads only those
%   datagrams in ALLfilename that are specified by datagrams, and store
%   them in ALLdata.
%
%   ALLdata = CFF_READ_ALL(ALLfilename,'datagrams',datagrams) does the
%   same.
%
%   Considering ALLfilename is the common root filename of a .all/.wcd pair
%   (that is, ALLfilename = 'myfile' for a myfile.all and myfile.wcd pair),
%   then the above commands will extract the requested datagrams from the
%   .wcd file and the remaining in the .all file.
%
%   Note this function will extract all datagram types of interest. For
%   more control (say you only want the first ten depth datagrams and the
%   last position datagram), use CFF_READ_ALL_FROM_FILEINFO.
%
%   *INPUT VARIABLES*
%   * |ALLfilename|: Required. String filename to parse (extension in .all
%   or .wcd and existing file) OR the common root filename of a .all/.wcd
%   pair.
%   * |datagrams|: Optional. character string, or cell array of character
%   string, or numeric values designating the types of datagrams to be
%   parsed. If character string or cell array of character string, the
%   string must match the datagTypeText of the datagram. If numeric, it
%   must match the datagTypeNumber. The possible values are:
%     datagTypeNumber = 49. datagTypeText = 'PU STATUS OUTPUT (31H)';
%     datagTypeNumber = 65. datagTypeText = 'ATTITUDE (41H)';
%     datagTypeNumber = 67. datagTypeText = 'CLOCK (43H)';
%     datagTypeNumber = 68. datagTypeText = 'DEPTH DATAGRAM (44H)';
%     datagTypeNumber = 72. datagTypeText = 'HEADING (48H)';
%     datagTypeNumber = 73. datagTypeText = 'INSTALLATION PARAMETERS - START (49H)';
%     datagTypeNumber = 78. datagTypeText = 'RAW RANGE AND ANGLE 78 (4EH)';
%     datagTypeNumber = 79. datagTypeText = 'QUALITY FACTOR DATAGRAM 79 (4FH)';
%     datagTypeNumber = 80. datagTypeText = 'POSITION (50H)';
%     datagTypeNumber = 82. datagTypeText = 'RUNTIME PARAMETERS (52H)';
%     datagTypeNumber = 83. datagTypeText = 'SEABED IMAGE DATAGRAM (53H)';
%     datagTypeNumber = 85. datagTypeText = 'SOUND SPEED PROFILE (55H)';
%     datagTypeNumber = 88. datagTypeText = 'XYZ 88 (58H)';
%     datagTypeNumber = 89. datagTypeText = 'SEABED IMAGE DATA 89 (59H)';
%     datagTypeNumber = 102. datagTypeText = 'RAW RANGE AND BEAM ANGLE (f) (66H)';
%     datagTypeNumber = 104. datagTypeText = 'DEPTH (PRESSURE) OR HEIGHT DATAGRAM (68H)';
%     datagTypeNumber = 105. datagTypeText = 'INSTALLATION PARAMETERS -  STOP (69H)';
%     datagTypeNumber = 107. datagTypeText = 'WATER COLUMN DATAGRAM (6BH)';
%     datagTypeNumber = 110. datagTypeText = 'NETWORK ATTITUDE VELOCITY DATAGRAM 110 (6EH)';
%     datagTypeNumber = 114. datagTypeText = 'AMPLITUDE AND PHASE WC DATAGRAM 114 (72H)';
%
%   *OUTPUT VARIABLES*
%   * |ALLdata|: structure containing the data. Each field corresponds a
%   different type of datagram. The field |ALLfileinfo| is a structure
%   containing information about datagrams in ALLfilename, with fields:
%     * |ALLfilename|: input file name
%     * |filesize|: file size in bytes
%     * |datagsizeformat|: endianness of the datagram size field 'b' or 'l'
%     * |datagramsformat|: endianness of the datagrams 'b' or 'l'
%     * |datagNumberInFile|: number of datagram in file
%     * |datagPositionInFile|: position of beginning of datagram in file
%     * |datagTypeNumber|: for each datagram, SIMRAD datagram type in
%     decimal
%     * |datagTypeText|: for each datagram, SIMRAD datagram type
%     description
%     * |parsed|: 0 for each datagram at this stage. To be later turned to
%     1 for parsing
%     * |counter|: the counter of this type of datagram in the file (ie
%     first datagram of that type is 1 and last datagram is the total
%     number of datagrams of that type)
%     * |number|: the number/counter found in the datagram (usually
%     different to counter)
%     * |size|: for each datagram, datagram size in bytes
%     * |syncCounter|: for each datagram, the number of bytes founds
%     between this datagram and the previous one (any number different than
%     zero indicates a sync error)
%     * |emNumber|: EM Model number (eg 2045 for EM2040c)
%     * |date|: datagram date in YYYMMDD
%     * |timeSinceMidnightInMilliseconds|: time since midnight in msecs
%   * |datagrams_parsed_idx|: array of logical values of the same dimension
%   as input |datagrams| indicating which of these datagrams have been
%   parsed (1) or not (0). If no datagrams were specified in input, this
%   output is empty.
%
%   *DEVELOPMENT NOTES*
%   * Research notes for CFF_ALL_FILE_INFO.m and
%   CFF_READ_ALL_FROM_FILEINFO.m apply.
%
%   See also CFF_ALL_FILE_INFO, CFF_READ_ALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021


%% Input arguments management
p = inputParser;

% name of the .all or .wcd file (or pair)
argName = 'ALLfilename';
argCheck = @(x) CFF_check_ALLfilename(x);
addRequired(p,argName,argCheck);

% types of datagram to read
argName = 'datagrams';
argDefault = [];
argCheck = @(x) isnumeric(x)||iscell(x)||(ischar(x)&&~strcmp(x,'datagrams')); % that last part allows the use of the couple name,param
addOptional(p,argName,argDefault,argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,ALLfilename,varargin{:});

% and get results
ALLfilename        = p.Results.ALLfilename;
datagrams_to_parse = p.Results.datagrams;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p;

% check input
if ischar(ALLfilename)
    % single file .all OR .wcd. Convert filename to cell.
    ALLfilename = {ALLfilename};
else
    % matching file pair .all AND .wcd.
    % make sure .wcd is listed first because this function only reads in
    % the 2nd file what it could not find in the first, and we want to only
    % grab from the .all file what is needed and couldn't be found in the
    % .wcd file.
    if strcmp(CFF_file_extension(ALLfilename{1}),'.all')
        ALLfilename = fliplr(ALLfilename);
    end
end


%% Prep

% number of files
nFiles = numel(ALLfilename);

% start message
filename = CFF_file_name(ALLfilename{1},1);
if nFiles == 1
    comms.start(sprintf('Reading data in file %s',filename));
else
    filename_2_ext = CFF_file_extension(ALLfilename{2});
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
info = CFF_all_file_info(ALLfilename{1});

% communicate progress
comms.progress(0.5,nFiles);

if isempty(datagrams_to_parse)
    % parse all datagrams in first file
    
    info.parsed(:) = 1;
    datagrams_parsed_in_first_file = unique(info.datagTypeNumber);
    datagrams_parsed_idx = [];
    
else
    % datagrams to parse are listed in input
    
    if isnumeric(datagrams_to_parse)
        
        % datagrams available
        datagrams_available = unique(info.datagTypeNumber);
        
        % find which datagrams can be read here
        datagrams_parsable_idx = ismember(datagrams_to_parse,datagrams_available);
        
        % if any, read those datagrams
        if any(datagrams_parsable_idx)
            idx = ismember(info.datagTypeNumber,datagrams_to_parse(datagrams_parsable_idx));
            info.parsed(idx) = 1;
        end
        datagrams_parsed_idx = datagrams_parsable_idx;
        
    elseif ischar(datagrams_to_parse) || iscell(datagrams_to_parse)
        % datagrams is one or several datagTypeText
        
        if ischar(datagrams_to_parse)
            datagrams_to_parse = {datagrams_to_parse};
        end
        
        % datagrams available
        datagrams_available = unique(info.datagTypeText);
        
        % find which datagrams can be read here
        datagrams_parsable_idx = ismember(datagrams_to_parse,datagrams_available);
        
        % if any, read those datagrams
        if any(datagrams_parsable_idx)
            idx = ismember(info.datagTypeText,datagrams_to_parse(datagrams_parsable_idx));
            info.parsed(idx) = 1;
        end
        datagrams_parsed_idx = datagrams_parsable_idx;
        
    end
    
end

% read data
if nFiles == 1
    comms.step('Reading datagrams');
else
    comms.step('Reading datagrams in paired file #1/2');
end
ALLdata = CFF_read_all_from_fileinfo(ALLfilename{1}, info);

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
        info = CFF_all_file_info(ALLfilename{2});
        
        % communicate progress
        comms.progress(1.5,nFiles);
        
        if isempty(datagrams_to_parse)
            % parse all datagrams in second file which we didn't get in the
            % first one.
            
            % datagrams in second file
            datagrams_available_in_second_file = unique(info.datagTypeNumber);
            
            % those in second file that were not in first
            datagrams_to_parse_in_second_file = setdiff(datagrams_available_in_second_file,datagrams_parsed_in_first_file);
            
            % parse those
            idx = ismember(info.datagTypeNumber,datagrams_to_parse_in_second_file);
            info.parsed(idx) = 1;
            
            % for output
            datagrams_parsed_idx = [];
            
        else
            % datagrams to parse are listed
            
            if isnumeric(datagrams_to_parse)
                
                datagrams_available_in_second_file = unique(info.datagTypeNumber);
                
                % find which remaining datagram types can be read here
                datagrams_to_parse_in_second_file_idx = ismember(datagrams_to_parse,datagrams_available_in_second_file) & ~datagrams_parsed_idx;
                
                % if any, read those datagrams
                if any(datagrams_to_parse_in_second_file_idx)
                    idx = ismember(info.datagTypeNumber,datagrams_to_parse(datagrams_to_parse_in_second_file_idx));
                    info.parsed(idx) = 1;
                end
                datagrams_parsed_idx = datagrams_parsed_idx | datagrams_to_parse_in_second_file_idx;
                
            elseif ischar(datagrams_to_parse) || iscell(datagrams_to_parse)
                % datagrams is one or several datagTypeText
                
                datagrams_available_in_second_file = unique(info.datagTypeText);
                
                % find which remaining datagram types can be read here
                datagrams_to_parse_in_second_file_idx = ismember(datagrams_to_parse,datagrams_available_in_second_file) & ~datagrams_parsed_idx;
                
                % if any, read those datagrams
                if any(datagrams_to_parse_in_second_file_idx)
                    idx = ismember(info.datagTypeText,datagrams_to_parse(datagrams_to_parse_in_second_file_idx));
                    info.parsed(idx) = 1;
                end
                datagrams_parsed_idx = datagrams_parsed_idx | datagrams_to_parse_in_second_file_idx;
                
            end
            
        end
        
        % read data in second file
        comms.step('Reading datagrams in paired file #2/2');
        ALLdata2 = CFF_read_all_from_fileinfo(ALLfilename{2}, info);
        
        % combine to data from first file
        ALLdata = {ALLdata ALLdata2};
        
    end
    
    % communicate progress
    comms.progress(2,nFiles);
    
end


%% end message
comms.finish('Done');
