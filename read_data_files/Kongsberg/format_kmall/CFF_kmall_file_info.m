function KMALLfileinfo = CFF_kmall_file_info(KMALLfilename, varargin)
%CFF_KMALL_FILE_INFO  Records basic info about contents of .kmall file
%
%   Records basic info about the datagrams contained in one Kongsberg EM
%   series binary data file in .kmall format (.kmall or .kmwcd).
%
%   KMALLFILEINFO = CFF_KMALL_FILE_INFO(KMALLFILENAME) opens the file
%   designated by the string KMALLFILENAME, reads through the start of each
%   datagram to get basic information about it, and store it all in
%   structure KMALLFILEINFO. KMALLfileinfo has for fields:
%     * fileName: input file name (i.e. KMALLFILENAME)
%     * fileSize: file size in bytes
%     * dgm_num: number of datagrams in file
%     * dgm_type_code: datagram type as string, e.g. '#IIP', '#MRZ', etc.
%     (Kongsberg .kmall format)
%     * dgm_type_text: datagram type description (Kongsberg .kmall
%     format) 
%     * dgm_type_version: version for this type of datagram, as int
%     (Kongsberg .kmall format)
%     * dgm_counter: counter for this type and version of datagram
%     in the file. There should not be multiple versions of a same type in
%     a same file, but we never know...
%     * dgm_start_pif: position of beginning of datagram in
%     file 
%     * dgm_size: datagram size in bytes
%     * dgm_sys_ID: System ID. Parameter used for separating datagrams
%     from different echosounders.
%     * dgm_EM_ID: Echo sounder identity, e.g. 124, 304, 712, 2040,
%     2045 (EM 2040C)
%     * date_time: datagram date in datetime format
%     * syncCounter: number of bytes of unrecognized data (e.g. rubbish
%     data, incomplete datagram, datagram with unexpected information,
%     etc.) found between the end of the previous datagram and the
%     beggining of this datagram
%     * finalSyncCounter: number of bytes of unrecognized data (as above)
%     at the end of the file. If 0, this means the file ended with the end
%     of a complete datagram. If more than 0, this means the file ended
%     with unrecognized data, most likely meaning the file has been clipped
%     so that the last datagram is incomplete (and could indicate more data
%     is missing).
%     * list_dgm_type: list of unique datagram types (in text format) in
%     this file.
%     * list_dgm_counter: number of datagrams for each type listed in
%     list_dgm_type.
%     * parsed: flag for whether the datagram has been parsed. Initialized
%     at 0 at this stage. To be later turned to 1 for parsing using
%     CFF_READ_KMALL_FROM_FILEINFO
%
%   See also CFF_ALL_FILE_INFO, CFF_S7K_FILE_INFO,
%   CFF_READ_KMALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (Kongsberg, yoann.ladroit@km.kongsberg.com)
%   2017-2024; Last revision: 29-02-2024

debugFlag = 0;

%% Input arguments management
p = inputParser;

% name of the .kmall or .kmwcd file
argName = 'KMALLfilename';
argCheck = @(x) CFF_check_KMALLfilename(x);
addRequired(p,argName,argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,KMALLfilename,varargin{:});

% and get results
KMALLfilename = p.Results.KMALLfilename;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
if debugFlag
    comms = CFF_Comms('oneline');
end

%% Start message
filename = CFF_file_name(KMALLfilename,1);
comms.start(sprintf('Listing datagrams in file %s',filename));


%% Open file and initializing
% kmall files are in little Endian, but just use the default with fopen
[fid,~] = fopen(KMALLfilename, 'r');

% go to end of file to get number of bytes in file then rewind
fseek(fid,0,1);
fileSize = ftell(fid);
fseek(fid,0,-1);

% init output info
KMALLfileinfo.fileName = KMALLfilename;
KMALLfileinfo.fileSize = fileSize;

% common datagram info for reading and checking
% A complete kmall datagram is organized as a sequence of:
% * GH - General Header EMdgmHeader (20 bytes), which starts with:
%     * The datagram size (uint32, aka 4 bytes)
%     * The datagram type code (4 char, aka 4 bytes), e.g. '#IIP'
% * DB - Datagram Body (variable size)
% * DS - Datagram size (uint32, aka 4 bytes)
headerSize = 20;
datagramCodePattern = "#" + characterListPattern("A","Z") ...
                          + characterListPattern("A","Z") ...
                          + characterListPattern("A","Z");

% start progress
comms.progress(0,fileSize);
comms.step('Parsing datagrams')


%% Reading datagrams
list_dgmType = {}; % list of datagram types recorded
list_dgmType_counter = []; % counter of datagram types recorded
kk = 0; % counter of datagrams in file
continueReading = 1; % reading flag for while loop
syncCounter = 0; % synchronization counter
resyncAborted = 0; % flag if resync/reading was aborted
while continueReading
    
    if debugFlag
        fprintf('Position in file: %i/%i bytes (%.2f%%). sync counter: %i\n', ftell(fid),fileSize,100.* ftell(fid)./fileSize,syncCounter);
    end
    
    % record current position in file, normally at the start of a new datagram 
    dgm_start_pif = ftell(fid);

    
    %% Checks
    
    % check if there is room to read a header. Exit loop if not.
    if dgm_start_pif + headerSize >= fileSize
       continueReading = 0;
       continue
    end
    
    % parse presumed header
    header = CFF_read_EMdgmHeader(fid);
    
    % check header. Assume header is OK if all following conditions are true.
    % Add conditions if you encounter cases where these are not sufficient to
    % assert header is OK.
    % 1) numBytesDgm is not null
    isDatagramSizeBytesPositive = header.numBytesDgm > 0;
    % 2) dgmType has pattern of hash symbol followed by 3 upper case letters
    isDatagramCodeOk = matches(header.dgmType,datagramCodePattern);
    isHeaderOK = isDatagramSizeBytesPositive && isDatagramCodeOk;
    
    if ~isHeaderOK
        % We are not at the beggining of a new datagram (ie out of sync). Go
        % back to the presumed datagram start, advance one byte, and try reading
        % again
        fseek(fid, dgm_start_pif+1, -1);
        syncCounter = syncCounter+1; % update sync counter
        if syncCounter == 1
            % we only just lost sync, throw an error message
            comms.error(sprintf('Lost sync while reading datagrams (approx. %.2f perc into the file). Trying to resync...',100.*dgm_start_pif./fileSize));
            tStart = tic;
        end
        % put a time and size limit to synchronizing
        nSecondsLimit = 20;
        if isfield(KMALLfileinfo,'dgm_size')
            syncCounterLimit = 2.*max(KMALLfileinfo.dgm_size);
        else
            syncCounterLimit = 0;
        end
        if toc(tStart)>nSecondsLimit && syncCounter>syncCounterLimit
            comms.error(sprintf('Limit for resync was reached (approx. %.2f perc into the file). Abort reading.',100.*dgm_start_pif./fileSize));
            resyncAborted = 1;
            continueReading = 0;
            continue
        end
        continue
    end
    
    % header is OK, message that we are in sync if we had lost it
    if syncCounter
        comms.info(sprintf('Back in sync (%i bytes later, approx. %.2f perc into the file). Resume reading.',syncCounter,100.*dgm_start_pif./fileSize));
    end
    
    % pif of presumed end of datagram and start of next one
    next_dgm_start_pif = dgm_start_pif + header.numBytesDgm;
    
    % check if datagram is complete (ie, does not overshoot file size)
    isDatagramComplete = next_dgm_start_pif <= fileSize;
    if ~isDatagramComplete
        continueReading = 0;
        continue
    end
    
    
    %% Datagram is complete. Get addditional info
    
    % index of datagram type in the list
    idx_dgmType = find(cellfun(@(x) strcmp(header.dgmType,x), list_dgmType));
    
    % if type encountered for the first time, add it to the list and
    % initialize counter
    if isempty(idx_dgmType)
        idx_dgmType = numel(list_dgmType) + 1;
        list_dgmType{idx_dgmType,1} = header.dgmType;
        list_dgmType_counter(idx_dgmType,1) = 0;
    end
    
    % increment datagram type counter
    list_dgmType_counter(idx_dgmType) = list_dgmType_counter(idx_dgmType) + 1;
    
    % check that repeat datagram size matches
    fseek(fid, next_dgm_start_pif-4, -1);
    numBytesDgm_repeat  = fread(fid,1,'uint32'); % Datagram length in bytes
    if isempty(numBytesDgm_repeat)
        numBytesDgm_repeat = -1;
    end
    datagramSizeRepeatMatch = header.numBytesDgm==numBytesDgm_repeat;
    
    
    %% Record datagram info for output
    
    % datagram number in file
    kk = kk + 1;
    KMALLfileinfo.dgm_num(kk,1) = kk;
    
    % datagram info
    KMALLfileinfo.dgm_type_code{kk,1}           = header.dgmType;
    KMALLfileinfo.dgm_type_text{kk,1}           = get_dgm_type_txt(header.dgmType);
    KMALLfileinfo.dgm_type_version(kk,1)        = header.dgmVersion;
    KMALLfileinfo.dgm_counter(kk,1)             = list_dgmType_counter(idx_dgmType);
    KMALLfileinfo.dgm_start_pif(kk,1)           = dgm_start_pif;
    KMALLfileinfo.dgm_size(kk,1)                = header.numBytesDgm;
    
    % system info
    KMALLfileinfo.dgm_sys_ID(kk,1) = header.systemID;
    KMALLfileinfo.dgm_EM_ID(kk,1)  = header.echoSounderID;

    % time info
    KMALLfileinfo.date_time(kk,1) = datetime(header.time_sec + header.time_nanosec.*10^-9,'ConvertFrom','posixtime');
    
    % issues info
    KMALLfileinfo.datagramSizeRepeatMatch(kk,1) = datagramSizeRepeatMatch;
    KMALLfileinfo.syncCounter(kk,1) = syncCounter; % sync needed before record
    
    
    %% Prepare for reloop
    
    % reinitialize sync counter
    syncCounter = 0;
    
    % go to end of datagram
    fseek(fid, next_dgm_start_pif, -1);
    
    % communicate progress
    comms.progress(next_dgm_start_pif,fileSize);
end


%% Finalizing
comms.step('Finished reading file. Finalizing')
comms.progress(fileSize-1,fileSize);

% report errors

% sync status at the end of file.
% For each datagram, KMALLfileinfo.syncCounter records if resynchronization
% was necessary between this datagrams and the previous one, so it does not
% inform if there were issues at the end of the file. Add a field that
% records this status
KMALLfileinfo.finalSyncCounter = syncCounter;
if KMALLfileinfo.finalSyncCounter
    if resyncAborted
        comms.error('Reading was aborted as resync reached limit. This file has major corruption issues.');
    else
        comms.error('End of file occured during resync. This file may have been clipped.');
    end
end

% adding lists
KMALLfileinfo.list_dgm_type = list_dgmType;
KMALLfileinfo.list_dgm_counter = list_dgmType_counter;

% initialize parsing field
if isfield(KMALLfileinfo,'dgm_num')
    KMALLfileinfo.parsed = zeros(size(KMALLfileinfo.dgm_num));
else
    KMALLfileinfo.parsed = [];
end

% closing file
fclose(fid);

% end message
comms.finish('Done');

end


%% subfunctions

%% get KMALL datagram type from code
function dgm_type_text = get_dgm_type_txt(dgm_type_code)

list_dgm_type_text = {...
    '#IIP - Installation parameters and sensor setup';...
    '#IOP - Runtime parameters as chosen by operator';...
    '#IBE - Built in test (BIST) error report';...
    '#IBR - Built in test (BIST) reply';...
    '#IBS - Built in test (BIST) short reply';...
    '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram';...
    '#MWC - Multibeam (M) water (W) column (C) datagram';...
    '#SPO - Sensor (S) data for position (PO)';...
    '#SKM - Sensor (S) KM binary sensor format';...
    '#SVP - Sensor (S) data from sound velocity (V) profile (P) or CTD';...
    '#SVT - Sensor (S) data for sound velocity (V) at transducer (T)';...
    '#SCL - Sensor (S) data from clock (CL)';...
    '#SDE - Sensor (S) data from depth (DE) sensor';...
    '#SHI - Sensor (S) data for height (HI)';...
    '#CPO - Compatibility (C) data for position (PO)';...
    '#CHE - Compatibility (C) data for heave (HE)';...
    '#FCF - Backscatter calibration (C) file (F) datagram' ...
    };

idx = find(cellfun(@(x) strcmp(x(1:4),dgm_type_code), list_dgm_type_text));

if ~isempty(idx)
    dgm_type_text = list_dgm_type_text{idx};
else
    dgm_type_text = sprintf('%i - UNKNOWN DATAGRAM TYPE',dgm_type_code);
end

end
