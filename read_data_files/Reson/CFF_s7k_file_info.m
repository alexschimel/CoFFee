function S7Kfileinfo = CFF_s7k_file_info(S7Kfilename, varargin)
%CFF_S7K_FILE_INFO  Records basic info about contents of .s7k file
%
%   Records basic info about the datagrams contained in one binary raw data
%   file in the Teledyne-Reson format .s7k.
%
%   S7Kfileinfo = CFF_S7K_FILE_INFO(S7Kfilename) opens file S7Kfilename and
%   reads through the start of each datagram to get basic information about
%   it, and store it all in S7Kfileinfo.
%
%   *INPUT VARIABLES*
%   * |S7Kfilename|: Required. String filename to parse (extension in .s7k)
%
%   *OUTPUT VARIABLES*
%   * |S7Kfileinfo|: structure containing information about records in
%   S7Kfilename, with fields:
%     * |S7Kfilename|: input file name
%     * |fileSize|: file size in bytes
%     * |datagsizeformat|: endianness of the datagram size field. Always
%     'l' for .s7k files
%     * |datagramsformat|: endianness of the datagrams 'b' or 'l'. Always
%     'l' for .s7k files
%     * |recordNumberInFile|: number of record in file
%     * |recordTypeIdentifier|: record type in int (Reson .s7k format) 
%     * |recordTypeText|: record type description (Reson .s7k format)
%     * |recordTypeCounter|: counter of this type of record in the file (ie
%     first record of that type is 1 and last record is the total
%     number of record of that type)
%     * |recordStartPositionInFile|: position of beginning of record in
%     file 
%     * |recordSize|: record size in bytes
%     * |DRF_size|: size of the "Data Record Frame" part of the record
%     (Reson .s7k format)
%     * |RTHandRD_size|: combined size of the "Record Type Header" and
%     "Record Data" parts of the record (Reson .s7k format)
%     * |OD_offset|: offset of the "Optional Data" part of the record
%     (Reson .s7k format)
%     * |OD_size|: size of the "Optional Data" part of the record (Reson
%     .s7k format)
%     * |CS_size|: size of the "Checksum" part of the record (Reson .s7k
%     format)
%     * |syncCounter|: number of bytes found between this record and the
%     previous one (any number different than zero indicates a sync error)
%     * |date|: datagram date in YYYMMDD
%     * |timeSinceMidnightInMilliseconds|: time since midnight in
%     milliseconds
%     * |parsed|: flag for whether the record has been parsed. Initiated
%     at 0 at this stage. To be later turned to 1 for parsing.
%
%   *DEVELOPMENT NOTES*
%   * Check regularly with Reson doc to keep updated with new datagrams.
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-08-2021


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
    
    
    %% test for synchronization
    if protocolVersion~=5 || DRF_offset~=60 || syncPattern~=65535
        % NOT SYNCHRONIZED
        % go back to new record start, advance one byte, and restart
        % reading
        fseek(fid, pifRecordStart+1, -1);
        pifNextRecordStart = -1;
        syncCounter = syncCounter+1; % update sync counter
        if syncCounter == 1
            % just lost sync, throw a message just now
            comms.error('Lost sync while reading records. A record may be corrupted. Trying to resync...');
        end
        continue;
    else
        % SYNCHRONIZED
        if syncCounter
            % if we had lost sync, warn here we're back
            comms.info(sprintf('Back in sync (%i bytes later)',syncCounter));
            % reinitialize sync counter
            syncCounter = 0;
        end
    end
    
    
    %% read more information from start of record
    
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
    
    
    %% record type counter
    
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
   
    
    %% write output S7Kfileinfo
    
    % Record complete
    kk = kk + 1;
    
    % Record number in file
    S7Kfileinfo.recordNumberInFile(kk,1) = kk;
    
    % Type of record info
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
    
    % report sync issue if any
    S7Kfileinfo.syncCounter(kk,1) = syncCounter;
    
    % record time info
    S7Kfileinfo.date{kk,1} = datestr(datenum(sevenKTime_year,0,sevenKTime_day),'yyyymmdd');
    S7Kfileinfo.timeSinceMidnightInMilliseconds(kk,1) = (sevenKTime_hours.*3600 + sevenKTime_minutes.*60 + sevenKTime_seconds).*1000;
    
    
    %% prepare for reloop
    
    % go to end of record
    fseek(fid, pifNextRecordStart, -1);
    
    % communicate progress
    comms.progress(pifNextRecordStart,fileSize);
    
end


%% finalizing

% initialize parsing field
S7Kfileinfo.parsed = zeros(size(S7Kfileinfo.recordNumberInFile));

% close file
fclose(fid);

% end message
comms.finish('Done');

end

