function S7Kfileinfo = CFF_s7k_file_info(S7Kfilename, varargin)
%CFF_S7K_FILE_INFO  Records basic info about contents of .s7k file
%
%   Records basic info about the datagrams contained in one binary raw data
%   file in the Teledyne-Reson format .s7k.
%
%   S7KFILEINFO = CFF_S7K_FILE_INFO(S7KFILENAME) opens the file designated
%   by the string S7KFILENAME, reads through the start of each datagram to
%   get basic information about it, and store it all in structure
%   S7KFILEINFO. S7KFILEINFO has for fields:
%     * fileName: input file name (i.e. S7KFILENAME)
%     * fileSize: file size in bytes
%     * recordNumberInFile: number of record in file
%     * recordTypeIdentifier: record type in int (Reson .s7k format) 
%     * recordTypeText: record type description (Reson .s7k format)
%     * recordTypeCounter: counter of this type of record in the file (ie
%     first record of that type is 1 and last record is the total
%     number of record of that type)
%     * recordStartPositionInFile: position of beginning of record in
%     file 
%     * recordSize: record size in bytes
%     * DRF_size: size of the "Data Record Frame" part of the record
%     (Reson .s7k format)
%     * RTHandRD_size: combined size of the "Record Type Header" and
%     "Record Data" parts of the record (Reson .s7k format)
%     * OD_offset: offset of the "Optional Data" part of the record
%     (Reson .s7k format)
%     * OD_size: size of the "Optional Data" part of the record (Reson
%     .s7k format)
%     * CS_size: size of the "Checksum" part of the record (Reson .s7k
%     format)
%     * date: datagram date in YYYMMDD
%     * timeSinceMidnightInMilliseconds: time since midnight in
%     milliseconds
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
%     * parsed: flag for whether the datagram has been parsed. Initialized
%     at 0 at this stage. To be later turned to 1 for parsing using
%     CFF_READ_S7K_FROM_FILEINFO
%
%   DEV NOTES
%   * Check regularly with Reson doc to keep updated with new datagrams.
%
%   See also CFF_KMALL_FILE_INFO, CFF_ALL_FILE_INFO,
%   CFF_READ_S7K_FROM_FILEINFO. 

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2023; Last revision: 02-11-2023


%% Input arguments management
p = inputParser;

% name of the .s7k file
argName = 'S7Kfilename';
argCheck = @(x) CFF_check_S7Kfilename(x);
addRequired(p,argName,argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,S7Kfilename,varargin{:});

% and get results
S7Kfilename = p.Results.S7Kfilename;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end


%% Start message
filename = CFF_file_name(S7Kfilename,1);
comms.start(sprintf('Listing datagrams in file %s',filename));


%% Open file and initializing
% s7k files are in little Endian, but just use the default with fopen
[fid,~] = fopen(S7Kfilename, 'r');

% go to end of file to get number of bytes in file then rewind
fseek(fid,0,1);
fileSize = ftell(fid);
fseek(fid,0,-1);

% init output info
S7Kfileinfo.fileName = S7Kfilename;
S7Kfileinfo.fileSize = fileSize;

% initialize the counter of total records in this file, and records of
% given type
kk = 0;
listRecordTypeText = CFF_s7K_record_types();
listRecordTypeIdentifier = cellfun(@(x) str2double(x(1:5)), listRecordTypeText);
listRecordTypeCounter = zeros(size(listRecordTypeIdentifier));

% initializing synchronization counter: the number of bytes that needed to
% be passed before this datagram appeared
syncCounter = 0;


%% Start progress
comms.progress(0,fileSize);
comms.step('Parsing datagrams')


%% Reading records
pifNextRecordStart = 0;
while pifNextRecordStart < fileSize
    
    %% new record begins
    pifRecordStart = ftell(fid);
    
    % A full s7k record is organized as a sequence of:
    % * DRF - Data Record Frame (64 bytes, at least for protocol version 5)
    % * RTH - Record Type Header (variable size)
    % * RD - Record Data (optional, variable size)
    % * OD - Optional Data (optional, variable size)
    % * CS - Checksum (optional, 4 bytes)
    
    % start parsing DRF
    protocolVersion = fread(fid,1,'uint16'); % should be 5
    DRF_offset      = fread(fid,1,'uint16'); % should be 60, for version 5
    syncPattern     = fread(fid,1,'uint32'); % should be 65535
    
    
    %% Test for synchronization
    % we assume we are synchronized if all following conditions are true:
    % 1) protocolVersion equals 5
    flag_protocolVersionOK = protocolVersion==5;
    % 2) DRF_offset equals 60
    flag_DRFoffsetOK = DRF_offset==60;
    % 3) syncPattern equals 65535
    flag_syncPatternOK = syncPattern==65535;
    syncTest = flag_protocolVersionOK && flag_DRFoffsetOK && flag_syncPatternOK;
    if syncTest
        % SYNCHRONIZED
        % if we had lost sync, warn here that we are back in sync
        if syncCounter
            comms.info(sprintf('Back in sync (%i bytes later). Resume process.',syncCounter));
        end
    else
        % NOT SYNCHRONIZED
        % we either lost sync, or the datagram is incomplete. Go back to
        % the record start, advance one byte, and try reading again.
        fseek(fid, pifRecordStart+1, -1);
        pifNextRecordStart = -1;
        syncCounter = syncCounter+1; % update sync counter
        if syncCounter == 1
            % We only just lost sync, throw an error message
            comms.error('Lost sync while reading datagrams. A datagram may be corrupted. Trying to resync...');
        end
        continue
    end
    
    
    %% Read more information from start of record
    
    % finish parsing DRF
    recordSize             = fread(fid,1,'uint32');
    optionalDataOffset     = fread(fid,1,'uint32');
    optionalDataIdentifier = fread(fid,1,'uint32');
    sevenKTime_year        = fread(fid,1,'uint16');
    sevenKTime_day         = fread(fid,1,'uint16');
    sevenKTime_seconds     = fread(fid,1,'float32');
    sevenKTime_hours       = fread(fid,1,'uint8');
    sevenKTime_minutes     = fread(fid,1,'uint8');
    recordVersion          = fread(fid,1,'uint16');
    recordTypeIdentifier   = fread(fid,1,'uint32');
    deviceIdentifier       = fread(fid,1,'uint32');
    reserved1              = fread(fid,1,'uint16');
    systemEnumerator       = fread(fid,1,'uint16');
    reserved2              = fread(fid,1,'uint32');
    flags                  = fread(fid,1,'uint16');
    reserved3              = fread(fid,1,'uint16');
    reserved4              = fread(fid,1,'uint32');
    totalRecordsInFragmentedDataRecordSet = fread(fid,1,'uint32');
    fragmentNumber         = fread(fid,1,'uint32');
    
    % size of DRF in bytes
    DRF_size = DRF_offset + 4;
    
    % checksum size
    if mod(flags,2)
        % flag is an odd number, aka the last 4 bytes of the record are the
        % checksum 
        CS_size = 4;
    else
        % flag is an even number, aka no checksum
        CS_size = 0;
    end
    
    % position in file of start of RTH (this is where we should be now)
    % pif_RTHstart = pifRecordStart + DRF_size;
    
    % position in file of next record
    pifNextRecordStart = pifRecordStart + recordSize;
    
    % size of OD and position in file
    if optionalDataOffset == 0
        % no OD
        OD_size = 0;
        % pif_ODstart = NaN;
    else
        OD_size = recordSize - ( optionalDataOffset + CS_size);
        % pif_ODstart = pifRecordStart + optionalDataOffset;
    end
    
    % size of the actual data section (RTH and RD)
    RTHandRD_size = recordSize - ( DRF_size + OD_size + CS_size);
    
    
    %% Record type counter
    
    % index of record type in the list
    recordType_idx = find(recordTypeIdentifier == listRecordTypeIdentifier);
    
    if isempty(recordType_idx)
        % this record type is not recognized
        recordTypeText = sprintf('%i - UNKNOWN RECORD TYPE',recordTypeIdentifier);
        recordTypeCounter = NaN; 
    else
        % record type text
        recordTypeText = listRecordTypeText{recordType_idx};
        % increment counter for this record type
        listRecordTypeCounter(recordType_idx) = listRecordTypeCounter(recordType_idx) + 1;
        recordTypeCounter = listRecordTypeCounter(recordType_idx);
    end
   
    
    %% Write output S7Kfileinfo
    
    % record complete
    kk = kk + 1;
    
    % record number in file
    S7Kfileinfo.recordNumberInFile(kk,1) = kk;
    
    % type of record info
    S7Kfileinfo.recordTypeIdentifier(kk,1) = recordTypeIdentifier;
    S7Kfileinfo.recordTypeText{kk,1}       = recordTypeText;
    S7Kfileinfo.recordTypeCounter(kk,1)    = recordTypeCounter;
    
    % position of start of record in file
    S7Kfileinfo.recordStartPositionInFile(kk,1) = pifRecordStart;
    
    % size of record and its components
    S7Kfileinfo.recordSize(kk,1)    = recordSize;
    S7Kfileinfo.DRF_size(kk,1)      = DRF_size;
    S7Kfileinfo.RTHandRD_size(kk,1) = RTHandRD_size;
    S7Kfileinfo.OD_offset(kk,1)     = optionalDataOffset;
    S7Kfileinfo.OD_size(kk,1)       = OD_size;
    S7Kfileinfo.CS_size(kk,1)       = CS_size;
    
    % time info
    S7Kfileinfo.date{kk,1} = datestr(datenum(sevenKTime_year,0,sevenKTime_day),'yyyymmdd');
    S7Kfileinfo.timeSinceMidnightInMilliseconds(kk,1) = (sevenKTime_hours.*3600 + sevenKTime_minutes.*60 + sevenKTime_seconds).*1000;

    % report if re-synchronization was necessary before reading this record
    S7Kfileinfo.syncCounter(kk,1) = syncCounter;
    
    
    %% Prepare for reloop
    
    % reinitialize sync counter
    syncCounter = 0;
    
    % go to end of record
    fseek(fid, pifNextRecordStart, -1);
    
    % communicate progress
    comms.progress(pifNextRecordStart,fileSize);
end


%% Finalizing
comms.step('End of file reached. Finalizing')
comms.progress(fileSize-1,fileSize);

% record sync status at the end of file.
% For each datagram, S7Kfileinfo.syncCounter records if resynchronization
% was necessary between this datagrams and the previous one, so it does not
% inform if there were issues at the end of the file. Add a field that
% records this status
S7Kfileinfo.finalSyncCounter = syncCounter;
if S7Kfileinfo.finalSyncCounter
    % File reading ended out of sync. Inform
    comms.error('Never recovered sync before end of file. This file may have been clipped.');
end

% initialize parsing field
S7Kfileinfo.parsed = zeros(size(S7Kfileinfo.recordNumberInFile));

% close file
fclose(fid);

% end message
comms.finish('Done');

end

