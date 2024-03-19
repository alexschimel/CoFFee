function ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename, varargin)
% CFF_convert_all_to_mat_v2.m
%
% Converts one Kongsberg EM series binary .all or .wcd data file to a .mat
% file, allowing choice on which type of datagrams to parse.
%
% *USE*
%
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename) converts all
% datagrams in ALLfilename to a .mat file with default name. 
%
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename,MATfilename) converts
% all datagrams in ALLfilename into MATfilename. 
%
% ALLfileinfo =
% CFF_convert_all_to_mat_v2(ALLfilename,MATfilename,datagrams) converts
% only those datagrams in ALLfilename that are specified by datagrams,
% into MATfilename.  
%
% ALLfileinfo =
% CFF_convert_all_to_mat_v2(ALLfilename,'datagrams',datagrams)
% converts only those datagrams in ALLfilename that are specified by
% datagrams, into a .mat file with default name. 
%
% See example for alternative calls that does the same.
%
% *INPUT VARIABLES*
%
% REQUIRED:
% * |ALLfilename|: string filename to parse (extension in .all or .wcd)
%
% OPTIONAL:
% * |MATfilename|: character string of the name of the .mat file to output.
%
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
% * |ALLfileinfo|: structure containing information about datagrams in
% ALLfilename, with fields: 
%   * |ALLfilename|: input file name
%   * |filesize|: file size in bytes
%   * |datagsizeformat|: endianness of the datagram size field 'b' or 'l'
%   * |datagramsformat|: endianness of the datagrams 'b' or 'l'
%   * |datagNumberInFile|: number of datagram in file
%   * |datagPositionInFile|: position of beginning of datagram in file
%   * |datagTypeNumber|: for each datagram, SIMRAD datagram type in decimal
%   * |datagTypeText|: for each datagram, SIMRAD datagram type description
%   * |parsed|: 0 for each datagram at this stage. To be later turned to 1 for parsing
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
% * Research notes for CFF_read_all.m apply.
%
% *NEW FEATURES*
%
% * 2017-06-29: header updated (Alex Schimel).
% * 2015-09-30: first version taking from last version of convert_all_to_mat (Alex Schimel).
%
% *EXAMPLE*
%
% ALLfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.all';
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename); % convert all datagrams, in default mat file name
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename, '.\testfolder\temp1.mat'); % convert all datagrams in desire mat file
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename, 'temp1.mat', 'ATTITUDE (41H)'); % convert only attitude datagrams in desire mat file
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename, 'temp1.mat', {'ATTITUDE (41H)','POSITION (50H)'}); % convert attitude and position datagrams in desire mat file
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename, 'temp1.mat', [65,80]); % same, but using datagram type numbers intead of names
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename, 'MATfilename', 'temp1.mat', 'datagrams', [65,80]); % same, but using proper input variable names
% ALLfileinfo = CFF_convert_all_to_mat_v2(ALLfilename, 'datagrams', 88); % convert xyz88 datagrams into default mat file
%
%   Copyright 2007-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% Input arguments management using inputParser

p = inputParser;

% ALLfilename to parse as required argument.
% Check file existence and extension.
argName = 'ALLfilename';
argCheck = @(x) exist(x,'file') && any(strcmp(CFF_file_extension(x),{'.all','.ALL','.wcd','.WCD'}));
addRequired(p,argName,argCheck);

% MATfilename as optional argument.
% Check that string of character
argName = 'MATfilename';
argDefault = [ALLfilename(1:end-3) 'mat'];
argCheck = @(x) ischar(x) && strcmp(x(end-3:end),'.mat');
addOptional(p,argName,argDefault,argCheck);

% datagrams as optional argument.
% Check that cell array
argName = 'datagrams';
argDefault = [];
argCheck = @(x) isnumeric(x)||iscell(x)||(ischar(x)&&~strcmp(x,'datagrams')); % that last part allows the use of the couple name,param
addOptional(p,argName,argDefault,argCheck);

% now parse inputs
parse(p,ALLfilename,varargin{:});

% and get input variables from parser
ALLfilename = p.Results.ALLfilename;
MATfilename = p.Results.MATfilename;
datagrams   = p.Results.datagrams;


%% Read data
ALLdata = CFF_read_all(ALLfilename,'datagrams',datagrams);


%% if output folder doesn't exist, create it
MATfilepath = fileparts(MATfilename);
if ~exist(MATfilepath,'dir') && ~isempty(MATfilepath)
    mkdir(MATfilepath);
end


%% Save the result into a MAT file
ALLfileinfo = CFF_save_mat_from_all(ALLdata, MATfilename);

