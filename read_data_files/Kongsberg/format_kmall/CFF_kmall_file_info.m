function KMALLfileinfo = CFF_kmall_file_info(KMALLfilename, varargin)
%CFF_KMALL_FILE_INFO  Records basic info about contents of .kmall file
%
%   Records basic info about the datagrams contained in one Kongsberg EM
%   series binary data file in .kmall format (.kmall or .kmwcd).
%
%   KMALLfileinfo = CFF_KMALL_FILE_INFO(KMALLfilename) opens file
%   KMALLfilename and reads through the start of each datagram to get basic
%   information about it, and store it all in KMALLfileinfo.
%
%   *INPUT VARIABLES*
%   * |KMALLfilename|: Required. String filename to parse (extension in
%   .kmall or .kmwcd) 
%
%   *OUTPUT VARIABLES*
%   * |KMALLfileinfo|: structure containing information about datagrams in
%   KMALLfilename, with fields:
%     * |file_name|: input file name
%     * |fileSize|: file size in bytes
%     * |dgm_num|: number of datagram in file
%     * |dgm_type_code|: datagram type as string, e.g. '#IIP' (Kongsberg
%     .kmall format)
%     * |dgm_type_text|: datagram type description (Kongsberg .kmall
%     format) 
%     * |dgm_type_version|: version for this type of datagram, as int
%     (Kongsberg .kmall format)
%     * |dgm_counter|: counter for this type and version of datagram
%     in the file. There should not be multiple versions of a same type in
%     a same file, but we never know...
%     * |dgm_start_pif|: position of beginning of datagram in
%     file 
%     * |dgm_size|: datagram size in bytes
%     * |dgm_sys_ID|: System ID. Parameter used for separating datagrams
%     from different echosounders.
%     * |dgm_EM_ID|: Echo sounder identity, e.g. 124, 304, 712, 2040,
%     2045 (EM 2040C)
%     * |sync_counter|: number of bytes found between this datagram and the
%     previous one (any number different than zero indicates a sync error)
%     * |date_time|: datagram date in datetime format
%     * |parsed|: flag for whether the datagram has been parsed. Initiated
%     at 0 at this stage. To be later turned to 1 for parsing.
%
%   See also CFF_ALL_FILE_INFO, CFF_S7K_FILE_INFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021


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

% initialize list of datagram types and counter
list_dgmType = {};
list_dgmType_counter = [];

% intitializing the counter of datagrams in this file
kk = 0;

% initializing synchronization counter: the number of bytes that needed to
% be passed before this datagram appeared
sync_counter = 0;


%% Start progress
comms.progress(0,fileSize);


%% Reading datagrams
next_dgm_start_pif = 0;
while next_dgm_start_pif < fileSize
    
    %% new datagram begins
    dgm_start_pif = ftell(fid);
      
    % A full kmall datagram is organized as a sequence of:
    % * GH - General Header EMdgmHeader (20 bytes, at least for Rev H)
    % * DB - Datagram Body (variable size)
    % * DS - Datagram size (uint32, aka 4 bytes)
    %
    % The General Header is read here. It starts with:
    % * The datagram size (uint32, aka 4 bytes)
    % * The datagram type code (4 char, aka 4 bytes), e.g. '#IIP'
    %
    % We will test for both datagram completeness and sync by matching the
    % two datagram size fields, and checking for the hash symbol at the
    % beggining of the datagram type code.
    
    % parsing general header
    header = CFF_read_EMdgmHeader(fid);
    
    % pif of presumed end of datagram
    dgm_end_pif = dgm_start_pif + header.numBytesDgm - 4;
    
    % get the repeat fileSize at the end of the datagram
    if dgm_end_pif < fileSize
        fseek(fid, dgm_end_pif, -1);
        numBytesDgm_repeat  = fread(fid,1,'uint32'); % Datagram length in bytes
        next_dgm_start_pif = ftell(fid);
    else
        % Being here can be due to two things:
        % 1) we are in sync but this datagram is incomplete, or 
        % 2) we are out of sync.
        numBytesDgm_repeat = -1;
    end
    
    
    %% test for synchronization
    % check for matching datagram size, amd the hash symbol of datagram
    % type code.
    flag_numBytesDgm_match = (header.numBytesDgm == numBytesDgm_repeat);
    flag_hash = strcmp(header.dgmType(1), '#');
    if ~flag_numBytesDgm_match || ~flag_hash
        % NOT SYNCHRONIZED
        % We've either lost sync, or the last datagram is incomplete.
        % Go back to new record start, advance one byte, and restart
        % reading
        fseek(fid, dgm_start_pif+1, -1);
        next_dgm_start_pif = -1;
        sync_counter = sync_counter+1; % update sync counter
        if sync_counter == 1
            % just lost sync, throw a message just now
            comms.error('Lost sync while reading datagrams. A datagram may be corrupted. Trying to resync...');
        end
        continue
    else
        % SYNCHRONIZED
        if sync_counter
            % if we had lost sync, warn here we're back
            comms.info(sprintf('Back in sync (%i bytes later). Resume process.',sync_counter));
            % reinitialize sync counter
            sync_counter = 0;
        end
    end

    
    %% datagram type counter
    
    % index of datagram type in the list
    idx_dgmType = find(cellfun(@(x) strcmp(header.dgmType,x), list_dgmType));
    
    % if type encountered for the first time, add it to the list and
    % initialize counter
    if isempty(idx_dgmType)
        idx_dgmType = numel(list_dgmType) + 1;
        list_dgmType{idx_dgmType,1} = header.dgmType;
        list_dgmType_counter(idx_dgmType,1) = 0;
    end
    
    % increment counter
    list_dgmType_counter(idx_dgmType) = list_dgmType_counter(idx_dgmType) + 1;

    
    %% write output KMALLfileinfo
    
    % Datagram complete
    kk = kk + 1;
    
    % Datagram number in file
    KMALLfileinfo.dgm_num(kk,1) = kk;
    
    % Datagram info
    KMALLfileinfo.dgm_type_code{kk,1}    = header.dgmType;
    KMALLfileinfo.dgm_type_text{kk,1}    = get_dgm_type_txt(header.dgmType);
    KMALLfileinfo.dgm_type_version(kk,1) = header.dgmVersion;
    KMALLfileinfo.dgm_counter(kk,1)      = list_dgmType_counter(idx_dgmType);
    KMALLfileinfo.dgm_start_pif(kk,1)    = dgm_start_pif;
    KMALLfileinfo.dgm_size(kk,1)         = header.numBytesDgm;
    
    % System info
    KMALLfileinfo.dgm_sys_ID(kk,1) = header.systemID;
    KMALLfileinfo.dgm_EM_ID(kk,1)  = header.echoSounderID;

    % Time info
    KMALLfileinfo.date_time(kk,1) = datetime(header.time_sec + header.time_nanosec.*10^-9,'ConvertFrom','posixtime');
    
    % Report any sync issue in reading
    KMALLfileinfo.sync_counter(kk,1) = sync_counter;
    
    
    %% prepare for reloop
    
    % go to end of datagram
    fseek(fid, next_dgm_start_pif, -1);
    
    % communicate progress
    comms.progress(next_dgm_start_pif,fileSize);
end


%% finalizing

% adding lists
KMALLfileinfo.list_dgm_type = list_dgmType;
KMALLfileinfo.list_dgm_counter = list_dgmType_counter;

% initialize parsing field
KMALLfileinfo.parsed = zeros(size(KMALLfileinfo.dgm_num));

% closing file
fclose(fid);

% end message
comms.finish('Done');

end


%% subfunctions

%%
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
