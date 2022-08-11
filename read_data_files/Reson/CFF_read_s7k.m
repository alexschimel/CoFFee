function [S7Kdata,datagrams_parsed_idx] = CFF_read_s7k(S7Kfilename,varargin)
%CFF_READ_S7K  Read s7k file
%
%   Reads contents of one Teledyne-Reson binary data file in .s7k format,
%   allowing choice on which type of datagrams to parse.
%
%   S7Kdata = CFF_READ_S7K(S7Kfilename) reads all datagrams in a
%   Teledyne-Reson file (extension .s7k) S7Kfilenamem, and store them in
%   S7Kdata.
%
%   S7Kdata = CFF_READ_S7K(S7Kfilename,datagrams) reads only those
%   datagrams in S7Kfilename that are specified by datagrams, and store
%   them in S7Kdata.
%
%   S7Kdata = CFF_READ_S7K(S7Kfilename,'datagrams',datagrams) does
%   the same.
%
%   Note this function will extract all datagram types of interest. For
%   more control (say you only want the first ten depth datagrams and the
%   last position datagram), use CFF_READ_S7K_FROM_FILEINFO.
%
%   See also CFF_S7K_FILE_INFO, CFF_READ_S7K_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021


%% Input arguments management
p = inputParser;

% name of the .s7k file
argName = 'S7Kfilename';
argCheck = @(x) CFF_check_S7Kfilename(x);
addRequired(p,argName,argCheck);

% types of datagram to read
argName = 'datagrams';
argDefault = {};
argCheck = @(x) isnumeric(x)||isempty(x);
addOptional(p,argName,argDefault,argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,S7Kfilename,varargin{:});

% and get results
S7Kfilename        = p.Results.S7Kfilename;
datagrams_to_parse = p.Results.datagrams;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p;


%% Prep

% start message
filename = CFF_file_name(S7Kfilename,1);
comms.start(sprintf('Reading data in file %s',filename));

% start progress
comms.progress(0,1);


%% Processing

% get info from file
comms.step('Listing datagrams');
info = CFF_s7k_file_info(S7Kfilename);

% communicate progress
comms.progress(0.5,1);

if isempty(datagrams_to_parse)
    % parse all datagrams in file
    idx_to_parse = true(size(info.recordTypeIdentifier));
    datagrams_parsed_idx = [];

else
    % datagrams to parse are listed in input
    
    % datagrams available
    datagrams_available = unique(info.recordTypeIdentifier);
    
    % find which datagrams can be read here
    datagrams_parsable_idx = ismember(datagrams_to_parse,datagrams_available);
    
    % list datagrams to be parsed
    idx_to_parse = ismember(info.recordTypeIdentifier,datagrams_to_parse(datagrams_parsable_idx));
    datagrams_parsed_idx = datagrams_parsable_idx;
    
end

% find and remove possibly corrupted datagrams
idx_corrupted = info.syncCounter~=0;
idx_corrupted = [idx_corrupted(2:end);false]; % the possibly corrupted datagram is the one before the one with syncCounter~=0;
if any(idx_corrupted & idx_to_parse)
    comms.info('%i of the %i datagrams to be parsed in this file may be corrupted and will not be parsed.',sum(idx_corrupted & idx_to_parse), sum(idx_to_parse) );
end

% parsable datagrams to be parsed
info.parsed(idx_to_parse & ~idx_corrupted) = 1;

% read data
comms.step('Reading datagrams');
S7Kdata = CFF_read_s7k_from_fileinfo(S7Kfilename, info);


%% end message
comms.finish('Done');
