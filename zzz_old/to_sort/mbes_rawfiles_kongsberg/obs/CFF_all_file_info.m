%% CFF_all_file_info.m
%
% Records basic info about the datagrams contained in one Kongsberg EM
% series binary .all or .wcd data file.
%
%% Help
%
% *USE*
%
% ALLfileinfo = CFF_all_file_info(ALLfilename) opens ALLfilename and reads
% through quickly to get information about each datagram, and store this
% info in ALLfileinfo.
%
% *INPUT VARIABLES*
%
% REQUIRED:
% * |ALLfilename|: string filename to parse (extension in .all or .wcd)
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
% * The code currently lists the EM model numbers supported as a test for
% sync. Add your model number in the list if it is not currently there. It
% would be better to remove this test and try to sync on ETX and Checksum
% instead.
% * Check regularly with Kongsberg doc to keep updated with new datagrams.
%
% *NEW FEATURES*
%
% * 2017-10-17: changed way filesize is calculated without it reading the
% entire file (Alex Schimel)
% * 2017-06-29: header updated (Alex Schimel)
% * 2015-09-30: first version taking from convert_all_to_mat (Alex Schimel)
%
% *EXAMPLE*
%
% ALLfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.all';
% ALLfileinfo = CFF_all_file_info(ALLfilename);
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function ALLfileinfo = CFF_all_file_info(ALLfilename)

%% supported systems:
% see help for info
emNumberList = [300; 302; 2040; 2045; 3000; 3002; 3020]; %2045 is 2040c


%% Input arguments management using inputParser
p = inputParser;

% ALLfilename to parse as only required argument. Test for file existence and
% extension.
argName = 'ALLfilename';
argCheck = @(x) exist(x,'file') && any(strcmp(CFF_file_extension(x),{'.all','.ALL','.wcd','.WCD'}));
addRequired(p,argName,argCheck);

% now parse inputs
parse(p,ALLfilename)

% and get results
ALLfilename = p.Results.ALLfilename;


%% Checking byte ordering
% - Luciano's all files are in 'b'
% - Erik's all file is in 'l'
% - my converted files are in 'b'
% - DataDistrib files are in 'b' but datagram size in 'l'! We need to
% separate the byte ordering tests for these two types.

% opening file
[fid,~] = fopen(ALLfilename, 'r');

% number of bytes in file
% OLD APPROACH was reading and saving into memory the entire file!!!
% temp = fread(fid,inf,'uint8');
% filesize = length(temp);
% clear temp
% NEW APPROACH
% go to end of file
fseek(fid,0,1);
filesize = ftell(fid);
% rewind to start
fseek(fid,0,-1);

% reading data from first datagram
while 1
    
    % read in little endian
    pif    = ftell(fid);
    nbDatagL = fread(fid,1,'uint32','l'); % number of bytes in datagram
    if isempty(nbDatagL)
        %file finished
        error('.all file parsing synchronization failed');
    end
    fseek(fid,pif,-1); % come back to re-read in b
    nbDatagB        = fread(fid,1,'uint32','b'); % number of bytes in datagram
    stxDatag        = fread(fid,1,'uint8');      % STX (always H02)
    datagTypeNumber = fread(fid,1,'uint8');      % SIMRAD type of datagram
    emNumberL       = fread(fid,1,'uint16','l'); % EM Model Number
    fseek(fid,-2,0); % come back to re-read in b
    emNumberB       = fread(fid,1,'uint16','b'); % EM Model Number
    
    % trying to read ETX
    if fseek(fid,pif+4+nbDatagL-3,-1) + 1
        etxDatagL = fread(fid,1,'uint8'); % ETX (always H03)
    else
        etxDatagL = NaN;
    end
    if fseek(fid,pif+4+nbDatagB-3,-1) + 1
        etxDatagB = fread(fid,1,'uint8'); % ETX (always H03)
    else
        etxDatagB = NaN;
    end
    
    % testing need for synchronization
    synchronized =    (sum(emNumberL==emNumberList) || sum(emNumberB==emNumberList)) ...
        & (etxDatagB==3 || etxDatagL==3) ...
        & stxDatag==2;
    if synchronized
        break
    else
        % trying to re-synchronize: fwd one byte and repeat the above
        fseek(fid,pif+1,-1);
        continue
    end
end

% test for the byte ordering of the datagram size field
if etxDatagL == 3
    datagsizeformat = 'l';
elseif etxDatagB == 3
    datagsizeformat = 'b';
end

% test for byte ordering of datagrams
if sum(emNumberL==emNumberList)
    datagramsformat = 'l';
elseif sum(emNumberB==emNumberList)
    datagramsformat = 'b';
end

fclose(fid);

clear emNumberL emNumberB fid nbDatagL nbDatagB stxDatag datagTypeNumber pif etxDatagL etxDatagB synchronized

% create ouptut info file if required
if nargout
    ALLfileinfo.ALLfilename     = ALLfilename;
    ALLfileinfo.filesize        = filesize;
    ALLfileinfo.datagsizeformat = datagsizeformat;
    ALLfileinfo.datagramsformat = datagramsformat;
end


%% Reopening file with the good byte ordering

[fid,~] = fopen(ALLfilename, 'r',datagramsformat);

% intitializing the counter of datagrams in this file
kk = 0;

% initializing synchronization counter: the number of bytes that needed to
% be passed before this datagram appeared
syncCounter = 0;


%% Reading datagrams
while 1
    
    % new datagram begins, start reading
    pif   = ftell(fid);
    nbDatag = fread(fid,1,'uint32',datagsizeformat); % number of bytes in datagram
    if isempty(nbDatag)
        % file finished, leave the loop
        break;
    end
    stxDatag                        = fread(fid,1,'uint8');  % STX (always H02)
    datagTypeNumber                 = fread(fid,1,'uint8');  % SIMRAD type of datagram
    emNumber                        = fread(fid,1,'uint16'); % EM Model Number
    date                            = fread(fid,1,'uint32'); % date
    timeSinceMidnightInMilliseconds = fread(fid,1,'uint32'); % time since midnight in milliseconds
    number                          = fread(fid,1,'uint16'); % datagram or ping number
    systemSerialNumber              = fread(fid,1,'uint16'); % EM system serial number
    
    % test for synchronization
    % to pass, first data reading must show that:
    % - the number of bytes in following datagram doesn't overshoot file
    % size
    % - STX must be equal to 2.
    % - the EM model number must be in the list showed at beginning
    if nbDatag>filesize || stxDatag~=2 || ~sum(emNumber==emNumberList)
        fseek(fid,pif+1,-1); % re-synchronizing 1 byte
        syncCounter = syncCounter+1; % update counter
        continue;
    end
    
    % reset the datagram counter and parsed switch
    counter = NaN;
    
    switch datagTypeNumber
        
        case 49
            
            datagTypeText = 'PU STATUS OUTPUT (31H)';
            
            % counter for this type of datagram
            try i49=i49+1; catch, i49=1; end
            counter = i49;
            
        case 65
            
            datagTypeText = 'ATTITUDE (41H)';
            
            % counter for this type of datagram
            try i65=i65+1; catch, i65=1; end
            counter = i65;
            
        case 67
            
            datagTypeText = 'CLOCK (43H)';
            
            % counter for this type of datagram
            try i67=i67+1; catch, i67=1; end
            counter = i67;
            
        case 68
            
            datagTypeText = 'DEPTH DATAGRAM (44H)';
            
            % counter for this type of datagram
            try i68=i68+1; catch, i68=1; end
            counter = i68;
            
        case 72
            
            datagTypeText = 'HEADING (48H)';
            
            % counter for this type of datagram
            try i72=i72+1; catch, i72=1; end
            counter = i72;
            
        case 73
            
            datagTypeText = 'INSTALLATION PARAMETERS - START (49H)';
            
            % counter for this type of datagram
            try i73=i73+1; catch, i73=1; end
            counter = i73;
            
        case 78
            
            datagTypeText = 'RAW RANGE AND ANGLE 78 (4EH)';
            
            % counter for this type of datagram
            try i78=i78+1; catch, i78=1; end
            counter = i78;
            
        case 79
            
            datagTypeText = 'QUALITY FACTOR DATAGRAM 79 (4FH)';
            
            % counter for this type of datagram
            try i79=i79+1; catch, i79=1; end
            counter = i79;
            
        case 80
            
            datagTypeText = 'POSITION (50H)';
            
            % counter for this type of datagram
            try i80=i80+1; catch, i80=1; end
            counter = i80;
            
        case 82
            
            datagTypeText = 'RUNTIME PARAMETERS (52H)';
            
            % counter for this type of datagram
            try i82=i82+1; catch, i82=1; end
            counter = i82;
            
        case 83
            
            datagTypeText = 'SEABED IMAGE DATAGRAM (53H)';
            
            % counter for this type of datagram
            try i83=i83+1; catch, i83=1; end
            counter = i83;
            
        case 85
            
            datagTypeText = 'SOUND SPEED PROFILE (55H)';
            
            % counter for this type of datagram
            try i85=i85+1; catch, i85=1; end
            counter = i85;
            
        case 88
            
            datagTypeText = 'XYZ 88 (58H)';
            
            % counter for this type of datagram
            try i88=i88+1; catch, i88=1; end
            counter = i88;
            
        case 89
            
            datagTypeText = 'SEABED IMAGE DATA 89 (59H)';
            
            % counter for this type of datagram
            try i89=i89+1; catch, i89=1; end
            counter = i89;
            
        case 102
            
            datagTypeText = 'RAW RANGE AND BEAM ANGLE (f) (66H)';
            
            % counter for this type of datagram
            try i102=i102+1; catch, i102=1; end
            counter = i102;
            
        case 104
            
            datagTypeText = 'DEPTH (PRESSURE) OR HEIGHT DATAGRAM (68H)';
            
            % counter for this type of datagram
            try i104=i104+1; catch, i104=1; end
            counter = i104;
            
        case 105
            
            datagTypeText = 'INSTALLATION PARAMETERS -  STOP (69H)';
            
            % counter for this type of datagram
            try i105=i105+1; catch, i105=1; end
            counter = i105;
            
        case 107
            
            datagTypeText = 'WATER COLUMN DATAGRAM (6BH)';
            
            % counter for this type of datagram
            try i107=i107+1; catch, i107=1; end
            counter = i107;
            
        case 110
            
            datagTypeText = 'NETWORK ATTITUDE VELOCITY DATAGRAM 110 (6EH)';
            
            % counter for this type of datagram
            try i110=i110+1; catch, i110=1; end
            counter = i110;
            
        otherwise
            
            % this datagTypeNumber is not recognized yet
            datagTypeText = {sprintf('UNKNOWN DATAGRAM (%sH)',dec2hex(datagTypeNumber))};
            
    end
    
    % write output ALLfileinfo
    kk = kk+1;
    ALLfileinfo.datagNumberInFile(kk,1) = kk;
    ALLfileinfo.datagPositionInFile(kk,1) = pif;
    ALLfileinfo.datagTypeNumber(kk,1) = datagTypeNumber;
    ALLfileinfo.datagTypeText{kk,1} = datagTypeText;
    ALLfileinfo.parsed(kk,1) = 0;
    ALLfileinfo.counter(kk,1) = counter;
    ALLfileinfo.number(kk,1) = number;
    ALLfileinfo.size(kk,1) = nbDatag;
    ALLfileinfo.syncCounter(kk,1) = syncCounter;
    ALLfileinfo.emNumber(kk,1) = emNumber;
    ALLfileinfo.systemSerialNumber(kk,1)=systemSerialNumber;
    ALLfileinfo.date(kk,1) = date;
    ALLfileinfo.timeSinceMidnightInMilliseconds(kk,1) = timeSinceMidnightInMilliseconds;
    
    % reinitialize synccounter
    syncCounter = 0;
    
    % go to end of datagram
    fseek(fid,pif+4+nbDatag,-1);
    
end


%% closing file
fclose(fid);


