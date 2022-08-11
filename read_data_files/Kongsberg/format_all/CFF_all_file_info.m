function ALLfileinfo = CFF_all_file_info(ALLfilename, varargin)
%CFF_ALL_FILE_INFO  Records basic info about contents of .all file
%
%   Records basic info about the datagrams contained in one Kongsberg EM
%   series binary data file in .all format (.all or .wcd)
%
%   ALLfileinfo = CFF_ALL_FILE_INFO(ALLfilename) opens file ALLfilename and
%   reads through the start of each datagram to get basic information about
%   it, and store it all in ALLfileinfo.
%
%   *INPUT VARIABLES*
%   * |ALLfilename|: Required. String filename to parse (extension in .all
%   or .wcd)
%
%   *OUTPUT VARIABLES*
%   * |ALLfileinfo|: structure containing information about datagrams in
%   ALLfilename, with fields:
%     * |ALLfilename|: input file name
%     * |filesize|: file size in bytes
%     * |datagsizeformat|: endianness of the datagram size field 'b' or 'l'
%     * |datagramsformat|: endianness of the datagrams 'b' or 'l'
%     * |datagNumberInFile|: number of datagram in file
%     * |datagPositionInFile|: position of beginning of datagram in file
%     * |datagTypeNumber|: datagram type in decimal (Kongsberg .all format)
%     * |datagTypeText|: datagram type description (Kongsberg .all format)
%     * |parsed|: flag for whether the datagram has been parsed. Initiated
%     at 0 at this stage. To be later turned to 1 for parsing.
%     * |counter|: counter of this type of datagram in the file (ie
%     first datagram of that type is 1 and last datagram is the total
%     number of datagrams of that type)
%     * |number|: the number/counter found in the datagram (usually
%     different to counter)
%     * |size|: datagram size in bytes
%     * |syncCounter|: number of bytes found between this datagram and the
%     previous one (any number different than zero indicates a sync error)
%     * |emNumber|: EM Model number (eg 2045 for EM2040c)
%     * |systemSerialNumber|: System serial number
%     * |date|: datagram date in YYYMMDD
%     * |timeSinceMidnightInMilliseconds|: time since midnight in
%     milliseconds
%
%   *DEVELOPMENT NOTES*
%   * The code currently lists the EM model numbers supported as a test for
%   sync. Add your model number in the list if it is not currently there
%   (and if the parsing works). It would be better to remove this test and
%   try to sync on ETX and Checksum instead.
%   * Check regularly with Kongsberg doc to keep updated with new
%   datagrams.


%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021



%% HARD-CODED PARAMETERS

% supported systems:
emNumberList = [122; 300; 302; 304; 710; 712; 2040; 2045; 3000; 3002; 3020; 12040]; %2045 is 2040c


%% Input arguments management
p = inputParser;

% name of the .all or .wcd file
argName = 'ALLfilename';
argCheck = @(x) CFF_check_ALLfilename(x);
addRequired(p,argName,argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,ALLfilename,varargin{:});

% and get results
ALLfilename = p.Results.ALLfilename;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end


%% Start message
filename = CFF_file_name(ALLfilename,1);
comms.start(sprintf('Listing datagrams in file %s',filename));


%% Checking byte ordering
% - Luciano's all files are in 'b'
% - Erik's all file is in 'l'
% - my converted files are in 'b'
% - DataDistrib files are in 'b' but datagram size in 'l'! We need to
% separate the byte ordering tests for these two types.

% opening file
[fid,~] = fopen(ALLfilename, 'r');

% go to end of file
fseek(fid,0,1);

% number of bytes in file
filesize = ftell(fid);

% rewind to start
fseek(fid,0,-1);

% counter for resynchornization attempts
syncCounter = 0;

% reading data from first datagram
while 1
    
    % read in little endian
    dgm_start_pif = ftell(fid);
    nbDatagL = fread(fid,1,'uint32','l'); % number of bytes in datagram
    
    if isempty(nbDatagL)
        %file finished
        error('.all file parsing synchronization failed');
    end
    
    fseek(fid,dgm_start_pif,-1); % come back to re-read in b
    nbDatagB        = fread(fid,1,'uint32','b'); % number of bytes in datagram
    stxDatag        = fread(fid,1,'uint8');      % STX (always H02)
    datagTypeNumber = fread(fid,1,'uint8');      % SIMRAD type of datagram
    emNumberL       = fread(fid,1,'uint16','l'); % EM Model Number
    fseek(fid,-2,0); % come back to re-read in b
    emNumberB       = fread(fid,1,'uint16','b'); % EM Model Number
    
    % trying to read ETX
    if fseek(fid,dgm_start_pif+4+nbDatagL-3,-1) + 1
        etxDatagL = fread(fid,1,'uint8'); % ETX (always H03)
    else
        etxDatagL = NaN;
    end
    
    if fseek(fid,dgm_start_pif+4+nbDatagB-3,-1) + 1
        etxDatagB = fread(fid,1,'uint8'); % ETX (always H03)
    else
        etxDatagB = NaN;
    end
    
    % testing need for synchronization
    synchronized = (sum(emNumberL==emNumberList) || sum(emNumberB==emNumberList)) ...
        & (etxDatagB==3 || etxDatagL==3) ...
        & stxDatag==2;
    if synchronized
        break
    else
        % trying to re-synchronize: fwd one byte and repeat the above
        syncCounter = syncCounter+1;
        if syncCounter == 10000
            error('Struggling to recognize start of file. Ensure your EM model is in the list of this function.');
        end
        fseek(fid,dgm_start_pif+1,-1);
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

clear emNumberL emNumberB fid nbDatagL nbDatagB stxDatag datagTypeNumber dgm_start_pif etxDatagL etxDatagB synchronized

% init output info
ALLfileinfo.ALLfilename     = ALLfilename;
ALLfileinfo.filesize        = filesize;
ALLfileinfo.datagsizeformat = datagsizeformat;
ALLfileinfo.datagramsformat = datagramsformat;


%% Reopening file with the good byte ordering

[fid,~] = fopen(ALLfilename, 'r',datagramsformat);

% intitializing the counter of datagrams in this file
kk = 0;

% initializing synchronization counter: the number of bytes that needed to
% be passed before this datagram appeared
syncCounter = 0;


%% Start progress
comms.progress(0,filesize);


%% Reading datagrams
next_dgm_start_pif = 0;
while next_dgm_start_pif < filesize
    
    %% new datagram begins
    dgm_start_pif = ftell(fid);
    
    % .all datagrams are composed of
    % - nbDatag (4 bytes): total size of datagram (excluding this field)
    % - STX = 2 (1 byte)
    % ...
    % - ETX = 3 (1 byte)
    % - checksum (2 bytes)
    
    % read start of datagram
    nbDatag  = fread(fid,1,'uint32',datagsizeformat); % number of bytes in datagram
    stxDatag = fread(fid,1,'uint8');  % STX (always H02)
    
    % pif of presumed end of datagram
    next_dgm_start_pif = dgm_start_pif + 4 + nbDatag;
    
    % read STX at end of datagram
    if next_dgm_start_pif <= filesize
        fseek(fid,next_dgm_start_pif-3,-1);
        etxDatag = fread(fid,1,'uint8'); % ETX (always H03)
        % checkSum = fread(fid,1,'uint16'); % Check sum of data between STX and ETX
        fseek(fid,dgm_start_pif+5, -1); % rewind to where we left reading
    else
        % would be here if overshooting the end of the file, aka datagram
        % is incomplete, or nbDatag is wrong. Set a wrong etxDatag to
        % trigger resync
        etxDatag = 0;
    end
    
    %% test for synchronization
    flag_inSync = ~isempty(stxDatag) && stxDatag==2 && etxDatag==3;
    if ~flag_inSync
        % NOT SYNCHRONIZED
        % trying to re-synchronize: fwd one byte and repeat the above
        next_dgm_start_pif = dgm_start_pif+1;
        fseek(fid,next_dgm_start_pif,-1);
        syncCounter = syncCounter+1; % update sync counter
        if syncCounter == 1
            % just lost sync, throw a message just now
            comms.error('Lost sync while reading datagrams. A datagram may be corrupted. Trying to resync...');
        end
        continue
    else
        % SYNCHRONIZED
        if syncCounter
            % if we had lost sync, warn here we're back
            comms.info(sprintf('Back in sync (%i bytes later). Resume process.',syncCounter));
            % reinitialize sync counter
            syncCounter = 0;
        end
    end
    
    % read rest of start of datagram
    datagTypeNumber                 = fread(fid,1,'uint8');  % SIMRAD type of datagram
    emNumber                        = fread(fid,1,'uint16'); % EM Model Number
    date                            = fread(fid,1,'uint32'); % date
    timeSinceMidnightInMilliseconds = fread(fid,1,'uint32'); % time since midnight in milliseconds
    number                          = fread(fid,1,'uint16'); % datagram or ping number
    systemSerialNumber              = fread(fid,1,'uint16'); % EM system serial number
    
    % reset the datagram counter and parsed switch
    counter = NaN;
    
    switch datagTypeNumber
        
        case 48
            datagTypeText = 'PU ID OUTPUT (30H)';
            try i48=i48+1; catch, i48=1; end
            counter = i48;
        case 49
            datagTypeText = 'PU STATUS OUTPUT (31H)';
            try i49=i49+1; catch, i49=1; end
            counter = i49;
        case 51
            datagTypeText = 'EXTRAPARAMETERS DATAGRAM (33H)';
            try i51=i51+1; catch, i51=1; end
            counter = i51;
        case 65
            datagTypeText = 'ATTITUDE (41H)';
            try i65=i65+1; catch, i65=1; end
            counter = i65;
        case 66
            datagTypeText = 'PU BIST RESULT OUTPUT (42H)';
            try i66=i66+1; catch, i66=1; end
            counter = i66;
        case 67
            datagTypeText = 'CLOCK (43H)';
            try i67=i67+1; catch, i67=1; end
            counter = i67;
        case 68
            datagTypeText = 'DEPTH DATAGRAM (44H)';
            try i68 = i68+1; catch, i68=1; end
            counter = i68;
        case 69
            datagTypeText = 'SINGLE BEAM ECHO SOUNDER DEPTH (45H)';
            try i69=i69+1; catch, i69=1; end
            counter = i69;
        case 70
            datagTypeText = 'RAW RANGE AND BEAM ANGLE (F) (46H)';
            try i70=i70+1; catch, i70=1; end
            counter = i70;
        case 71
            datagTypeText = 'SURFACE SOUND SPEED (47H)';
            try i71=i71+1; catch, i71=1; end
            counter = i71;
        case 72
            datagTypeText = 'HEADING (48H)';
            try i72=i72+1; catch, i72=1; end
            counter = i72;
        case 73
            datagTypeText = 'INSTALLATION PARAMETERS - START (49H)';
            try i73=i73+1; catch, i73=1; end
            counter = i73;
        case 74
            datagTypeText = 'MECHANICAL TRANSDUCER TILT (4AH)';
            try i74=i74+1; catch, i74=1; end
            counter = i74;
        case 75
            datagTypeText = 'CENTRAL BEAMS ECHOGRAM (4BH)';
            try i75=i75+1; catch, i75=1; end
            counter = i75;
        case 78
            datagTypeText = 'RAW RANGE AND ANGLE 78 (4EH)';
            try i78=i78+1; catch, i78=1; end
            counter = i78;
        case 79
            datagTypeText = 'QUALITY FACTOR DATAGRAM 79 (4FH)';
            try i79=i79+1; catch, i79=1; end
            counter = i79;
        case 80
            datagTypeText = 'POSITION (50H)';
            try i80=i80+1; catch, i80=1; end
            counter = i80;
        case 82
            datagTypeText = 'RUNTIME PARAMETERS (52H)';
            try i82=i82+1; catch, i82=1; end
            counter = i82;
        case 83
            datagTypeText = 'SEABED IMAGE DATAGRAM (53H)';
            try i83=i83+1; catch, i83=1; end
            counter = i83;
        case 84
            datagTypeText = 'TIDE DATAGRAM (54H)';
            try i84=i84+1; catch, i84=1; end
            counter = i84;
        case 85
            datagTypeText = 'SOUND SPEED PROFILE (55H)';
            try i85=i85+1; catch, i85=1; end
            counter = i85;
        case 87
            datagTypeText = 'KONGSBERG MARITIME SSP OUTPUT DATAGRAM (057H)';
            try i87=i87+1; catch, i87=1; end
            counter = i87;
        case 88
            datagTypeText = 'XYZ 88 (58H)';
            try i88=i88+1; catch, i88=1; end
            counter = i88;
        case 89
            datagTypeText = 'SEABED IMAGE DATA 89 (59H)';
            try i89=i89+1; catch, i89=1; end
            counter = i89;
        case 102
            datagTypeText = 'RAW RANGE AND BEAM ANGLE (f) (66H)';
            try i102=i102+1; catch, i102=1; end
            counter = i102;
        case 104
            datagTypeText = 'DEPTH (PRESSURE) OR HEIGHT DATAGRAM (68H)';
            try i104=i104+1; catch, i104=1; end
            counter = i104;
        case 105
            datagTypeText = 'INSTALLATION PARAMETERS -  STOP (69H)';
            try i105=i105+1; catch, i105=1; end
            counter = i105;
        case 107
            datagTypeText = 'WATER COLUMN DATAGRAM (6BH)';
            try i107=i107+1; catch, i107=1; end
            counter = i107;
        case 108
            datagTypeText = 'EXTRA DETECTIONS (6CH)';
            try i108=i108+1; catch, i108=1; end
            counter = i108;
        case 110
            datagTypeText = 'NETWORK ATTITUDE VELOCITY DATAGRAM 110 (6EH)';
            try i110=i110+1; catch, i110=1; end
            counter = i110;
        case 112
            datagTypeText = 'INSTALLATION PARAMETERS - REMOTE INFO (70H)';
            try i112=i112+1; catch, i112=1; end
            counter = i112;
        case 114
            datagTypeText = 'AMPLITUDE AND PHASE WC DATAGRAM 114 (72H)';
            try i114=i114+1; catch, i114=1; end
            counter = i114;
        otherwise
            % this datagTypeNumber is not recognized yet
            datagTypeText = sprintf('UNKNOWN DATAGRAM (%sH)',dec2hex(datagTypeNumber));
            
    end
    
    %% write output ALLfileinfo
    
    % Datagram complete
    kk = kk+1;
    
    % Datagram number in file
    ALLfileinfo.datagNumberInFile(kk,1) = kk;
    
    % Datagram info
    ALLfileinfo.datagTypeNumber(kk,1) = datagTypeNumber;
    ALLfileinfo.datagTypeText{kk,1} = datagTypeText;
    ALLfileinfo.counter(kk,1) = counter;
    ALLfileinfo.datagPositionInFile(kk,1) = dgm_start_pif;
    ALLfileinfo.size(kk,1) = nbDatag;
    ALLfileinfo.number(kk,1) = number;
    ALLfileinfo.parsed(kk,1) = 0;
    
    % System info
    ALLfileinfo.emNumber(kk,1) = emNumber;
    ALLfileinfo.systemSerialNumber(kk,1)=systemSerialNumber;
    
    % Time info
    ALLfileinfo.date(kk,1) = date;
    ALLfileinfo.timeSinceMidnightInMilliseconds(kk,1) = timeSinceMidnightInMilliseconds;
    
    % Report any sync issue in reading
    ALLfileinfo.syncCounter(kk,1) = syncCounter;
    
    
    %% Prepare for reloop
    
    % go to end of datagram
    fseek(fid,next_dgm_start_pif,-1);
    
    % communicate progress
    comms.progress(next_dgm_start_pif,filesize);
end


%% finalizing

% closing file
fclose(fid);

% end message
comms.finish('Done');




