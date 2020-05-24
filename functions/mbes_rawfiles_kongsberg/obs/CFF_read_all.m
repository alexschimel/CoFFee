%% CFF_read_all.m
%
% Reads contents of one Kongsberg EM series binary .all or .wcd data file,
% allowing choice on which type of datagrams to parse.
%
%% Help
%
% *USE*
%
% ALLdata = CFF_read_all(ALLfilename) reads all datagrams in ALLfilename
% and store them in ALLdata.
%
% ALLdata = CFF_read_all(ALLfilename,datagrams) reads only those
% datagrams in ALLfilename that are specified by datagrams, and store them
% in ALLdata. 
%
% ALLdata = CFF_read_all(ALLfilename,'datagrams',datagrams) does the same.
%
% Note this function will extract all datagram types of interest. For more
% control (say you only want the first ten depth datagrams and the last
% position datagram), use CFF_read_all_from_fileinfo.
%
% *INPUT VARIABLES*
%
% REQUIRED:
% * |ALLfilename|: string filename to parse (extension in .all or .wcd).
%
% OPTIONAL:
% * |datagrams|: character string, or cell array of character string, or
% numeric values designating the types of datagrams to be parsed. If
% character string or cell array of character string, the string must match
% the datagTypeText of the datagram. If numeric, it must matches the
% datagTypeNumber. The possible values are:
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
% 
% *OUTPUT VARIABLES*
%
% * |ALLdata|: structure containing the data. Each field corresponds a
% different type of datagram. The field |ALLdata.info| contains information
% about the datagrams in the original input file, with fields: 
%   * |ALLfilename|: input file name
%   * |filesize|: file size in bytes
%   * |datagsizeformat|: endianness of the datagram size field 'b' or 'l'
%   * |datagramsformat|: endianness of the datagrams 'b' or 'l'
%   * |datagNumberInFile|: number of datagram in file
%   * |datagPositionInFile|: position of beginning of datagram in file
%   * |datagTypeNumber|: for each datagram, SIMRAD datagram type in decimal
%   * |datagTypeText|: for each datagram, SIMRAD datagram type description
%   * |parsed|: for each datagram, 1 if datagram has been parsed (or is to be parsed), 0 otherwise
%   * |counter|: the counter of this type of datagram in the file (ie first datagram of that type is 1 and last datagram is the total number of datagrams of that type)
%   * |number|: the number/counter found in the datagram (usually different to counter)
%   * |size|: for each datagram, datagram size in bytes
%   * |syncCounter|: for each datagram, the number of bytes founds between this datagram and the previous one (any number different than zero indicates a sync error)
%   * |emNumber|: EM Model number (eg 2045 for EM2040c)
%   * |date|: datagram date in YYYMMDD
%   * |timeSinceMidnightInMilliseconds|: time since midnight in msecs 
%
% *RESEARCH NOTES*
%
% * Research notes for CFF_all_file_info.m and CFF_read_all_from_fileinfo.m
% apply. 
%
% *NEW FEATURES*
%
% * 2017-06-28: first version. Adapated from CFF_convert_all_to_mat_v2.m (Alex Schimel). 
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
% Alexandre Schimel, NIWA.

%% Function
function ALLdata = CFF_read_all(ALLfilename, varargin)


%% Input arguments management using inputParser
p = inputParser;

% ALLfilename to parse as required argument.
% Check file existence and extension.
argName = 'ALLfilename';
argCheck = @(x) exist(x,'file') && any(strcmp(CFF_file_extension(x),{'.all','.ALL','.wcd','.WCD'}));
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
ALLfilename  = p.Results.ALLfilename;
datagrams = p.Results.datagrams;


%% Parse the entire file for info on datagrams
info = CFF_all_file_info(ALLfilename);


%% Decide which datagrams to record, based on datagrams
if isempty(datagrams)
    % parse all datagrams
    info.parsed(:) = 1;
elseif isnumeric(datagrams)
    % datagrams is one or several datagTypeNumber
    ind = ismember(info.datagTypeNumber,datagrams);
    info.parsed(ind) = 1;
elseif ischar(datagrams)
    % datagrams is one datagTypeText
    for ii = 1:length(info.datagTypeText)
        if strcmp(info.datagTypeText{ii},datagrams)
            info.parsed(ii) = 1;
        end
    end
elseif iscell(datagrams)
    % datagrams is one or several datagTypeText
    for jj = 1:length(datagrams)
        for ii = 1:length(info.datagTypeText)
            if strcmp(info.datagTypeText{ii},datagrams{jj})
                info.parsed(ii) = 1;
            end
        end
    end
end


%% Read the file, and only the datagrams desired
ALLdata = CFF_read_all_from_fileinfo(ALLfilename, info);


