%% CFF_read_all.m
%
% Reads contents of one Kongsberg EM series binary .all or .wcd data file,
% or a pair of .all/.wcd files, allowing choice on which type of datagrams
% to parse. 
%
%% Help
%
% *USE*
%
% Considering ALLfilename is a Kongsberg file (extension .all or .wcd) that
% exists, ALLdata = CFF_read_all(ALLfilename) reads all datagrams in
% ALLfilename and store them in ALLdata.
%
% ALLdata = CFF_read_all(ALLfilename,datagrams) reads only those
% datagrams in ALLfilename that are specified by datagrams, and store them
% in ALLdata.
%
% ALLdata = CFF_read_all(ALLfilename,'datagrams',datagrams) does the same.
%
% Considering ALLfilename is the common root filename of a .all/.wcd pair
% (that is, ALLfilename = 'myfile' for a myfile.all and myfile.wcd pair),
% then the above commands will extract the requested datagrams from the
% .wcd file and the remaining in the .all file.
% 
% Note this function will extract all datagram types of interest. For more
% control (say you only want the first ten depth datagrams and the last
% position datagram), use CFF_read_all_from_fileinfo.
%
% *INPUT VARIABLES*
%
% * |ALLfilename|: Required. String filename to parse (extension in .all or
% .wcd and existing file) OR the common root filename of a .all/.wcd pair.
% * |datagrams|: Optional. character string, or cell array of character
% string, or numeric values designating the types of datagrams to be
% parsed. If character string or cell array of character string, the string
% must match the datagTypeText of the datagram. If numeric, it must matches
% the datagTypeNumber. The possible values are:
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
% *OUTPUT VARIABLES*
%
% * |ALLdata|: structure containing the data. Each field corresponds a
% different type of datagram. The field |ALLfileinfo| is a structure
% containing information about datagrams in ALLfilename, with fields:
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
% * |datagrams_parsed_idx|: array of logical values of the same dimension
% as input |datagrams| indicating which of these datagrams have been parsed
% (1) or not (0). If no datagrams were specified in input, this output is
% empty.
%
% *DEVELOPMENT NOTES*
%
% * Research notes for CFF_all_file_info.m and CFF_read_all_from_fileinfo.m
% apply.
%
% *NEW FEATURES*
%
% * 2018-10-31: updated to read pair of .all/.wcd files.
% * 2018-10-11: updated header before adding to Coffee v3
% * 2017-06-28: first version. Adapated from CFF_convert_all_to_mat_v2.m
%
% *EXAMPLE*
%
% ALLfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.all';
% ALLdata = CFF_read_all(ALLfilename); % read all datagrams
% ALLdata = CFF_read_all(ALLfilename, 'ATTITUDE (41H)'); % read only attitude datagrams
% ALLdata = CFF_read_all(ALLfilename, {'ATTITUDE (41H)','POSITION (50H)'}); % read attitude and position datagrams
% ALLdata = CFF_read_all(ALLfilename, [65,80]); % same, but using datagram type numbers intead of names
% ALLdata = CFF_read_all(ALLfilename,'datagrams',[65,80]); % same, but using proper input variable name
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Waikato University, Deakin University, NIWA.
% Yoann Ladroit, NIWA.

%% Function
function [ALLdata,datagrams_parsed_idx] = CFF_read_all(ALLfilename, varargin)


%% Input arguments management using inputParser

p = inputParser;

% ALLfilename to parse as required argument.
% Check file existence
argName = 'ALLfilename';
argCheck = @(x) CFF_check_ALLfilename(x);
addRequired(p,argName,argCheck);

% datagrams as optional argument.
% Check that cell array
argName = 'datagrams';
argDefault = [];
argCheck = @(x) isnumeric(x)||iscell(x)||(ischar(x)&&~strcmp(x,'datagrams')); % that last part allows the use of the couple name,param
addOptional(p,argName,argDefault,argCheck);

% now parse inputs
parse(p,ALLfilename,varargin{:});

% and get input variables from parser
ALLfilename        = p.Results.ALLfilename;
datagrams_to_parse = p.Results.datagrams;


%% PREP

% if filename has no extension, build the full all/wcd filenames
if ~isempty(CFF_file_extension(ALLfilename))
    
    ALLfilename = {ALLfilename};
    
else
    
    ALLfilename = CFF_get_Kongsberg_files(ALLfilename);
    
    % in case of a pair of all/wcd files, the order is important as this
    % function only reads in the 2nd file what it could not find in the
    % 1st. By default, we want the wcd file to be read first, and only grab
    % from the all file what is needed and couldn't be found in the wcd
    % file. Flipping it here rather than in CFF_get_Kongsberg_files because
    % I want this function to output all/wcd by default and not wcd/all
    if ~strcmp(CFF_file_extension(ALLfilename{1}),'.wcd')
        ALLfilename = fliplr(ALLfilename);
    end
    
end


%% FIRST FILE

% Get info in first (or only) file
info = CFF_all_file_info(ALLfilename{1});

if isempty(datagrams_to_parse)
    % parse all datagrams in firt file
    
    info.parsed(:) = 1;
    datagrams_parsed_in_first_file = unique(info.datagTypeNumber);
    
    datagrams_parsed_idx = [];
    
else
    % datagrams to parse are listed

    if isnumeric(datagrams_to_parse)
        
        % datagrams available
        datagrams_available = unique(info.datagTypeNumber);
    
        % find which datagrams can be read here
        datagrams_parsable_idx = ismember(datagrams_to_parse,datagrams_available);
        
        % if any, read those datagrams
        if any(datagrams_parsable_idx)
            idx = ismember(info.datagTypeNumber,datagrams_to_parse(datagrams_parsable_idx));
            info.parsed(idx) = 1;
            datagrams_parsed_idx = datagrams_parsable_idx;
        end
        
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
            datagrams_parsed_idx = datagrams_parsable_idx;
        end
       
    end
    
end

% read data
ALLdata = CFF_read_all_from_fileinfo(ALLfilename{1}, info);



%% SECOND FILE
% do only if we have a second file, and either we requested to read all
% datagrams (in which case, the second file might have datagrams not read
% in the first and we need to grab those) OR we requested a specific set of
% datagrams and didn't get them all from the first file.
if numel(ALLfilename)>1 && (isempty(datagrams_to_parse) || ~all(datagrams_parsed_idx))
    
    % Get info in second file
    info = CFF_all_file_info(ALLfilename{2});
    
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
                datagrams_parsed_idx = datagrams_parsed_idx | datagrams_to_parse_in_second_file_idx;
                
            end

        elseif ischar(datagrams_to_parse) || iscell(datagrams_to_parse)
            % datagrams is one or several datagTypeText
            
            datagrams_available_in_second_file = unique(info.datagTypeText);
            
            % find which remaining datagram types can be read here
            datagrams_to_parse_in_second_file_idx = ismember(datagrams_to_parse,datagrams_available_in_second_file) & ~datagrams_parsed_idx;
            
            % if any, read those datagrams
            if any(datagrams_to_parse_in_second_file_idx)
                
                idx = ismember(info.datagTypeText,datagrams_to_parse(datagrams_to_parse_in_second_file_idx));
                info.parsed(idx) = 1;                
                datagrams_parsed_idx = datagrams_parsed_idx | datagrams_to_parse_in_second_file_idx;
                
            end
                
        end
        
    end
    
    % read data in second file
    ALLdata2 = CFF_read_all_from_fileinfo(ALLfilename{2}, info);
    
    % combine to data from first file
    ALLdata = {ALLdata ALLdata2};
    
      
end













