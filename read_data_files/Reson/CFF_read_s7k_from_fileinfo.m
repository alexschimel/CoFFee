function S7Kdata = CFF_read_s7k_from_fileinfo(S7Kfilename,S7Kfileinfo,varargin)
%CFF_READ_S7K_FROM_FILEINFO  Read contents of s7k file
%
%   Reads contents of one Kongsberg EM series binary .s7k or .wcd data
%   file, using S7Kfileinfo to indicate which datagrams to be parsed.
%
%   S7Kdata = CFF_READ_S7K_FROM_FILEINFO(S7Kfilename, S7Kfileinfo) reads
%   s7k datagrams in S7Kfilename for which S7Kfileinfo.parsed equals 1, and
%   store them in S7Kdata.
%
%   *INPUT VARIABLES*
%   * |S7Kfilename|: Required. String filename to parse (extension in
%   .s7k).
%   * |S7Kfileinfo|: structure containing information about datagrams in
%   S7Kfilename, with fields:
%     * |S7Kfilename|: input file name
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
%
%   *OUTPUT VARIABLES*
%   * |S7Kdata|: structure containing the data. Each field corresponds a
%   different type of datagram. The field |S7Kdata.info| contains a copy of
%   S7Kfileinfo described above.
%
%   *DEVELOPMENT NOTES*
%   * PU Status output datagram structure seems different to the datagram
%   manual description. Find the good description.#edit 21aug2013: updated
%   to Rev Q. Need to be checked though.
%   * The parsing code for some datagrams still need to be coded. To
%   update.
%
%   See also CFF_READ_S7K.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% Input arguments management
p = inputParser;

% name of the .s7k file
argName = 'S7Kfilename';
argCheck = @(x) CFF_check_S7Kfilename(x);
addRequired(p,argName,argCheck);

% fileinfo from CFF_S7K_FILE_INFO containing indexes of datagrams to read
argName = 'S7Kfileinfo';
argCheck = @isstruct;
addRequired(p,argName,argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,S7Kfilename,S7Kfileinfo,varargin{:});

% and get results
S7Kfilename = p.Results.S7Kfilename;
S7Kfileinfo = p.Results.S7Kfileinfo;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end


%% Prep

% start message
filename = CFF_file_name(S7Kfilename,1);
comms.start(sprintf('Reading records in file %s',filename));

% store filename
S7Kdata.S7Kfilename = S7Kfilename;

% open file
[fid,~] = fopen(S7Kfilename, 'r');

% parse only datagrams indicated in S7Kfileinfo
datagToParse = find(S7Kfileinfo.parsed==1);
nDatagsToParse = numel(datagToParse);

% start progress
comms.progress(0,nDatagsToParse);


%% Reading datagrams
for iDatag = datagToParse'
    
    % A full s7k record is organized as a sequence of:
    % * DRF - Data Record Frame (64 bytes, at least for protocol version 5)
    % * RTH - Record Type Header (variable size)
    % * RD - Record Data (optional, variable size)
    % * OD - Optional Data (optional, variable size)
    % * CS - Checksum (optional, 4 bytes)
    
    % DRF info was already read so get relevant parameters in fileinfo
    pif_recordstart      = S7Kfileinfo.recordStartPositionInFile(iDatag);
    recordTypeIdentifier = S7Kfileinfo.recordTypeIdentifier(iDatag);
    DRF_size             = S7Kfileinfo.DRF_size(iDatag);
    RTHandRD_size        = S7Kfileinfo.RTHandRD_size(iDatag);
    OD_size              = S7Kfileinfo.OD_size(iDatag);
    CS_size              = S7Kfileinfo.CS_size(iDatag);
    OD_offset            = S7Kfileinfo.OD_offset(iDatag);
    
    % Go to start of dgm
    fseek(fid, pif_recordstart+DRF_size, -1);

    % get recordName
    recordTypeText = S7Kfileinfo.recordTypeText{iDatag};
    recordName = ['R' regexprep(replace(recordTypeText,' ',''),'\W','_')]; % remove problematic characters
    
    % get record counter
    if isfield(S7Kdata, recordName)
        iRec = numel(S7Kdata.(recordName).Date) +1 ;
    else
        iRec = 1;
    end
    
    % reset the parsed switch
    parsed = 0;

    switch recordTypeIdentifier
        
        case 1003 % Position
            % Description: Position Record used in conjunction with Record
            % Type 1011.
            
            % NOTE
            % * 1003 record created by the 7k sonar source is using the
            % sensor (GPS) data. 1003 created by Teledyne PDS is using
            % reference point data.
            % * Latency of 1003 created by Teledyne PDS and 7k sonar is
            % always 0.
            
            % start parsing RTH
            S7Kdata.(recordName).Datum_id(iRec) = fread(fid,1,'uint32'); % 0 – WGS84; >0 – Reserved
            S7Kdata.(recordName).Latency(iRec)  = fread(fid,1,'float32'); % In seconds
            
            % Latitude in radians or northing in meters
            S7Kdata.(recordName).LatitudeOrNorthing(iRec) = fread(fid,1,'float64');
            
            % Longitude in radians or easting in meters
            S7Kdata.(recordName).LongitudeOrEasting(iRec) = fread(fid,1,'float64');
            
            S7Kdata.(recordName).Height(iRec) = fread(fid,1,'float64'); % In meters
            
            % 0 – Geographical coordinates; 1 – Grid coordinates
            S7Kdata.(recordName).PositionTypeFlag(iRec) = fread(fid,1,'uint8');
            
            S7Kdata.(recordName).UTMZone(iRec) = fread(fid,1,'uint8'); % UTM Zone
            
            % 0 – Navigation Data; 1 – Dead-Reckoning
            S7Kdata.(recordName).QualityFlag(iRec) = fread(fid,1,'uint8');
           
            S7Kdata.(recordName).PositioningMethod(iRec) = fread(fid,1,'uint8'); % see doc
            S7Kdata.(recordName).NumberOfSatellites(iRec) = fread(fid,1,'uint8'); % Optional
            
            parsed = 1;
            
        case 1012 % Roll Pitch Heave
            % Description: Motion Data Record.
            
            % start parsing RTH
            S7Kdata.(recordName).Roll(iRec)  = fread(fid,1,'float32'); % Vessel roll in radians
            S7Kdata.(recordName).Pitch(iRec) = fread(fid,1,'float32'); % Vessel pitch in radians
            S7Kdata.(recordName).Heave(iRec) = fread(fid,1,'float32'); % Vessel heave in meters
            
            parsed = 1;
            
        case 1013 % Heading
            % Description: Vessel Heading Record.
            
            % start parsing RTH
            S7Kdata.(recordName).Heading(iRec) = fread(fid,1,'float32'); % Vessel heading in radians
            
            parsed = 1;
            
        case 1015 % Navigation
            % Description: This record will be output at the input
            % navigation rate.

            % start parsing RTH
            
            % 1– Ellipsoid; 2 – Geoid; 3 – Chart datum
            S7Kdata.(recordName).VerticalReference(iRec) = fread(fid,1,'uint8');
            
            % Latitude of vessel reference point in radians -pi/2 to pi/2, -south
            S7Kdata.(recordName).Latitude(iRec) = fread(fid,1,'float64');
            
            % Longitude of vessel reference point in radians -pi to pi, -west
            S7Kdata.(recordName).Longitude(iRec) = fread(fid,1,'float64');
            
            % Position accuracy in meters
            S7Kdata.(recordName).HorizontalPositionAccuracy(iRec) = fread(fid,1,'float32');
            
            % Height of vessel reference point above vertical reference in meters
            S7Kdata.(recordName).VesselHeight(iRec) = fread(fid,1,'float32');
            
            % In meters
            S7Kdata.(recordName).HeightAccuracy(iRec) = fread(fid,1,'float32');
            
            % Speed over ground at position time in m/s
            S7Kdata.(recordName).SpeedOverGround(iRec) = fread(fid,1,'float32');
            
            % Course over ground at position time in radians
            S7Kdata.(recordName).CourseOverGround(iRec) = fread(fid,1,'float32'); 
            
            % Heading of vessel at position time in radians
            S7Kdata.(recordName).Heading(iRec) = fread(fid,1,'float32');
            
            parsed = 1;
            
        case 7000 % Sonar Settings
            % Description: This record is produced by the SeaBat™ 7k sonar
            % 7-P processor series. It contains the current sonar settings.
            % The 7k sonar source updates this data for each ping. The
            % record can be subscribed to from the 7k sonar source. For
            % details about requesting and subscribing to records, see
            % section 10.62 7500 – Remote Control together with section 11
            % 7k Remote Control Definitions.
            
            % NOTE
            % * Pitch and yaw stabilization are not implemented.
            % * When the roll stabilization flag is not zero the beam
            % pattern is roll stabilized; beam pattern is relative the
            % vertical.
            % * Projector beam steering is pitch stabilization.
            % * Projector beam steering is not redundant when messages 7004
            % and 7006 are received; this value needs to take into account.
            % (Unless the sonar does not have pitch steer capacity.)
            
            % start parsing RTH
            S7Kdata.(recordName).SonarID(iRec)    = fread(fid,1,'uint64'); % Sonar serial number
            S7Kdata.(recordName).PingNumber(iRec) = fread(fid,1,'uint32'); % Sequential number
            
            % Flag to indicate multi-ping sequence. Always 0 (zero) if not
            % in multi-ping mode; otherwise this is the sequence number of
            % the ping in the multi-ping sequence.
            S7Kdata.(recordName).MultiPingSequence(iRec) = fread(fid,1,'uint16'); 
            
            S7Kdata.(recordName).Frequency(iRec)         = fread(fid,1,'float32'); % Transmit frequency in Hertz
            S7Kdata.(recordName).SampleRate(iRec)        = fread(fid,1,'float32'); % Sample rate in Hertz
            S7Kdata.(recordName).ReceiverBandwidth(iRec) = fread(fid,1,'float32'); % In Hertz
            S7Kdata.(recordName).TxPulseWidth(iRec)      = fread(fid,1,'float32'); % In seconds
            S7Kdata.(recordName).TXPulseIdentifier(iRec) = fread(fid,1,'uint32'); % 0 – CW; 1 – Linear chirp (FM)
            S7Kdata.(recordName).TXPulseEnvelopeIdentifier(iRec) = fread(fid,1,'uint32'); % 0 – Tapered rectangular; 1 – Tukey; 2 – Hamming; 3 – Han; 4 – Rectangular            
            S7Kdata.(recordName).TXPulseEnvelopeParameter(iRec)  = fread(fid,1,'float32'); % Some envelopes don’t use this parameter
            S7Kdata.(recordName).TXPulseMode(iRec)               = fread(fid,1,'uint16'); % 1 – Single ping; 2 – Multi-ping 2; 3 – Multi-ping 3; 4 – Multi-ping 4
            S7Kdata.(recordName).TXPulseReserved(iRec)           = fread(fid,1,'uint16'); % Reserved
            S7Kdata.(recordName).MaxPingRate(iRec)               = fread(fid,1,'float32'); % Maximum ping rate in pings per second
            S7Kdata.(recordName).PingPeriod(iRec)                = fread(fid,1,'float32'); % Seconds since last ping
            S7Kdata.(recordName).RangeSelection(iRec)            = fread(fid,1,'float32'); % Range selection in meters
            S7Kdata.(recordName).PowerSelection(iRec)            = fread(fid,1,'float32'); % Power selection in dB re 1 microPa
            S7Kdata.(recordName).GainSelection(iRec)             = fread(fid,1,'float32'); % Gain selection in dB
            S7Kdata.(recordName).ControlFlags(iRec)              = fread(fid,1,'uint32'); % see doc
            S7Kdata.(recordName).ProjectIdentifier(iRec)         = fread(fid,1,'uint32'); % Projector selection
            S7Kdata.(recordName).ProjectorBeamSteeringAngleVerticalRad(iRec)   = fread(fid,1,'float32'); % In radians
            S7Kdata.(recordName).ProjectorBeamSteeringAngleHorizontalRad(iRec) = fread(fid,1,'float32'); % In radians. Along track beam width
            S7Kdata.(recordName).ProjectorBeam3dBWidthVerticalRad(iRec)        = fread(fid,1,'float32'); % In radians. Across track beam width
            S7Kdata.(recordName).ProjectorBeam3dBWidthHorizontalRad(iRec)      = fread(fid,1,'float32'); % In meters
            S7Kdata.(recordName).ProjectorBeamFocalPoint(iRec)                 = fread(fid,1,'float32');
            S7Kdata.(recordName).ProjectorBeamWeightingWindowType(iRec)        = fread(fid,1,'uint32'); % 0 – Rectangular; 1 – Chebychev; 2 – Gauss
            S7Kdata.(recordName).ProjectorBeamWeightingWindowParameter(iRec)   = fread(fid,1,'float32'); % N/A
            S7Kdata.(recordName).TransmitFlags(iRec)                           = fread(fid,1,'uint32'); % see doc
            S7Kdata.(recordName).HydrophoneIdentifier(iRec)                    = fread(fid,1,'uint32'); % Hydrophone selection
            S7Kdata.(recordName).ReceiveBeamWeightingWindowType(iRec)          = fread(fid,1,'uint32'); % 0 – Chebychev; 1 – Kaiser
            S7Kdata.(recordName).ReceiveBeamWeightingWindowParameter(iRec)     = fread(fid,1,'float32'); % N/A
            S7Kdata.(recordName).ReceiveFlags(iRec)        = fread(fid,1,'uint32'); % see doc
            S7Kdata.(recordName).ReceiveBeamWidthRad(iRec) = fread(fid,1,'float32'); % Angle in radians
            S7Kdata.(recordName).BottomDetectFilter{iRec}  = fread(fid,4,'float32'); % [min_range max_range min_depth max_depth]
            S7Kdata.(recordName).Absorption(iRec)          = fread(fid,1,'float32'); % Absorption in dB/km
            S7Kdata.(recordName).SoundVelocity(iRec)       = fread(fid,1,'float32'); % Sound velocity in m/s
            S7Kdata.(recordName).Spreading(iRec)           = fread(fid,1,'float32'); % Spreading loss in dB
            S7Kdata.(recordName).Reserved(iRec)            = fread(fid,1,'uint16'); % Reserved
            
            parsed = 1;
            
        case 7001 % Configuration
            % Description: This record is produced by the SeaBat™ 7k sonar
            % 7-P processor series. It contains the configuration
            % information about the sonar capabilities. Each sonar
            % configuration can be found in the record’s module info
            % section (see Table 42). The record is created on system
            % startup and does not change during operation. The record can
            % be manually requested from the 7-P processor. This record is
            % not available for subscription. For details about requesting
            % and subscribing to records, see section 10.62 7500 – Remote
            % Control together with section 11 7k Remote Control
            % Definitions.
            
            % start parsing RTH
            S7Kdata.(recordName).SonarId(iRec) = fread(fid,1,'uint64'); % Sonar serial number
            
            N_info = fread(fid,1,'uint32'); % Number of devices/sonar’s
            S7Kdata.(recordName).N(iRec) = N_info;
            
            % start parsing RD
            S7Kdata.(recordName).DeviceID{iRec}            = NaN(1,N_info); 
            S7Kdata.(recordName).DeviceDescription{iRec}   = cell(1,N_info); 
            S7Kdata.(recordName).DeviceAlphaDataCard{iRec} = NaN(1,N_info); 
            S7Kdata.(recordName).DeviceSerialNumber{iRec}  = NaN(1,N_info);
            S7Kdata.(recordName).DeviceInfo{iRec}          = cell(1,N_info); 
            
            for i_inf = 1:N_info
                
                S7Kdata.(recordName).DeviceID{iRec}(i_inf)            = fread(fid,1,'uint32'); % Unique identifier number
                S7Kdata.(recordName).DeviceDescription{iRec}{i_inf}   = fread(fid,60,'*char')'; % UTF-8 string
                S7Kdata.(recordName).DeviceAlphaDataCard{iRec}(i_inf) = fread(fid,1,'uint32'); % see doc
                S7Kdata.(recordName).DeviceSerialNumber{iRec}(i_inf)  = fread(fid,1,'uint64');
                
                l_tmp = fread(fid,1,'uint32'); % In bytes
                S7Kdata.(recordName).DeviceInfo{iRec}{i_inf} = fread(fid,l_tmp,'*char')'; % Varies with device type
                
            end
            
            parsed = 1;
            
        case 7004 % Beam Geometry
            % Description: This record is produced by the 7k sonar source.
            % It contains the receive beam widths and steering. The 7k
            % sonar source updates this data for each ping. The record can
            % be manually requested for the last ping or subscribed to from
            % the 7k sonar source. For details about requesting and
            % subscribing to records, see section 10.62 7500 – Remote
            % Control together with section 11 7k Remote Control
            % Definitions.

            % NOTE
            % * Beam angles are relative to sonar frame when beam
            % stabilization is switched off. When enabled it will be
            % relative to the vertical.  
            % * Beam vertical is always zero, angles are relative to sonar
            % frame. 
            
            % start parsing RTH
            S7Kdata.(recordName).SonarID(iRec) = fread(fid,1,'uint64'); % Sonar serial number
            S7Kdata.(recordName).N(iRec)       = fread(fid,1,'uint32'); % Number of receiver beams
            
            N = S7Kdata.(recordName).N(iRec);
            
            % start parsing RD
            
            % Angle in radians. The receiver beam steering angle (relative
            % to nadir) applied in the alongtrack direction (typically 0). 
            S7Kdata.(recordName).BeamVerticalDirectionAngleRad{iRec} = fread(fid,N,'float32');
            
            % Angle in radians. The receiver beam steering angle (relative
            % to nadir) applied in the acrosstrack direction (varies
            % according to beam number). Typically -75 to +75 degrees. In
            % equidistant mode, this will not change. In equiangular mode,
            % steering angles will vary.
            S7Kdata.(recordName).BeamHorizontalDirectionAngleRad{iRec} = fread(fid,N,'float32');
            
            % Angle in radians. The receiver along-track beam width
            % measured at the -3dB points (typically <30deg).
            S7Kdata.(recordName).BeamWidth3dBAlongTrackRad{iRec} = fread(fid,N,'float32');
            
            % Angle in radians. The receiver across-track beam width
            % measured at the -3dB points (typically <5deg). 
            S7Kdata.(recordName).BeamWidth3dBAcrossTrackRad{iRec} = fread(fid,N,'float32');
            
            % Tx Delay for the beam in fractional samples, zero when not
            % applicable. 
            % The Tx Delay is not existing on all sonar models. Up to now
            % this is only supported for the HydroSweep sonars (see section
            % 9.3).
            % When the sonar does not has Tx Delay the item will not be in
            % the Record Data, check record length in the Data Record
            % Frame.
            S7Kdata.(recordName).TxDelay{iRec} = fread(fid,N,'float32');
            
            parsed = 1;
            
        case 7012 % Ping Motion Data
            % Description: This record is produced by the 7k sonar source
            % series. It contains the description of various parameters
            % used in detection computations. The 7k sonar source updates
            % this data for each ping. The record can be subscribed to from
            % the 7k sonar source. For details about requesting and
            % subscribing to records, see section 10.62 7500 – Remote
            % Control together with section 11 7k Remote Control
            % Definitions.
            
            % NOTE
            % These are not actual steering angles. In order to get actual
            % steering angles this data should be used in conjunction with
            % base transmit and receive angles from record 7004 – 7k Beam
            % Geometry. 
             
            % start parsing RTH
            S7Kdata.(recordName).SonarID(iRec)    = fread(fid,1,'uint64'); % Sonar serial number
            S7Kdata.(recordName).PingNumber(iRec) = fread(fid,1,'uint32'); % Sequential number
            
            % Flag to indicate multi-ping sequence.
            % Always 0 (zero) if not in multi-ping mode; otherwise this
            % represents the sequence number of the ping in the multi-ping
            % sequence.
            S7Kdata.(recordName).MultiPingSequence(iRec) = fread(fid,1,'uint16');

            S7Kdata.(recordName).NumberOfSamples(iRec) = fread(fid,1,'uint32'); % Number of samples
            S7Kdata.(recordName).Flags(iRec)           = fread(fid,1,'uint16'); % BIT FIELD. See doc
            S7Kdata.(recordName).ErrorFlags(iRec)      = fread(fid,1,'uint32'); % BIT FIELD. See doc
            S7Kdata.(recordName).SamplingRate(iRec)    = fread(fid,1,'float32'); % Sampling frequency in Hz
            
            % NOTE
            % The fields, Pitch, Roll, Heading, and Heave, are present only
            % if corresponding flags are set. The new fields may be added
            % (refer to the record size in the record header for the total
            % size). For sign explanations, see section 2.2 Sign
            % Conventions.
    
            % read and parse flags
            flags = CFF_get_R7012_flags(S7Kdata.(recordName).Flags(iRec));
            
            % Pitch value at the ping time in radians
            if flags.pitchStab > 0
                S7Kdata.(recordName).Pitch(iRec) = fread(fid,1,'float32');
            else
                S7Kdata.(recordName).Pitch(iRec) = NaN;
            end
            
            N = S7Kdata.(recordName).NumberOfSamples(iRec);
            
            % Roll value per sample in radians
            if flags.rollStab > 0
                S7Kdata.(recordName).Roll{iRec} = fread(fid,N,'float32');
            else
                S7Kdata.(recordName).Roll{iRec} = NaN;
            end
            
            % Heading value per sample in radians
            if flags.yawStab > 0
                S7Kdata.(recordName).Heading{iRec} = fread(fid,N,'float32');
            else
                S7Kdata.(recordName).Heading{iRec} = NaN;
            end
            
            % Heave value per sample in meters
            if flags.heaveStab > 0
                S7Kdata.(recordName).Heave{iRec} = fread(fid,N,'float32');
            else
                S7Kdata.(recordName).Heave{iRec} = NaN;
            end
            
            parsed = 1;
            
        case 7018 % Beamformed Data
            % Description: This record is produced by the 7k sonar source
            % series. It contains the sonar beam intensity (magnitude) and
            % phase data. The 7k sonar source updates this data for each
            % ping. The record can be subscribed to from the 7k sonar
            % source. For details about requesting and subscribing to
            % records, see section 10.62 7500 – Remote Control together
            % with section 11 7k Remote Control Definitions.
            % This record is available by subscription only.
            % Beams and samples are numbered from 0. Data is sample
            % followed by beams.
            % First sample 0 of all beams then sample 1 of all beams etc.
            % The sampling continues until the set range is reached. (Every
            % beam will have the same number of samples)
            % Data rates:
            % Equation for no data reduction, beam limits, and all sonar
            % settings:
            % beams * data format bits * sample rate * 10% (header overhead)
            % Example:
            % 128 beams * 32 bits (sonar setting 6) * 34500 samples/s * 1.1
            % = 155.4432 Mbits/s
            
            % ----- DEV NOTE ----------------------------------------------
            % This datagram's data is too to be stored in memory. Instead,
            % we record the metadata and the position-in-file location of
            % the data, which be extracted and stored in binary format at
            % the next stage of data conversion.
            % -------------------------------------------------------------
            
            % start parsing RTH
            S7Kdata.(recordName).SonarId(iRec)    = fread(fid,1,'uint64'); % Sonar serial number
            S7Kdata.(recordName).PingNumber(iRec) = fread(fid,1,'uint32'); % Sequential number
            
            % Flag to indicate multi-ping sequence.
            % Always 0 (zero) if not in multi-ping mode; otherwise this
            % represents the sequence number of the ping in the multi-ping
            % sequence.  
            S7Kdata.(recordName).MultipingSequence(iRec) = fread(fid,1,'uint16');
            
            S7Kdata.(recordName).N(iRec)        = fread(fid,1,'uint16'); % Total number of beams in ping record 
            S7Kdata.(recordName).S(iRec)        = fread(fid,1,'uint32'); % Total number of samples per beam in ping record
            S7Kdata.(recordName).Reserved{iRec} = fread(fid,8,'uint32'); % Reserved for future use
            
            % start parsing RD
            
            % rest of the record are S cycles of N cycles of a amplitude
            % (uint16) / phase (int16) pair. Save position.
            S7Kdata.(recordName).BeamformedDataPos(iRec)  = ftell(fid);
            
            parsed = 1;
            
        case 7022 % Sonar Source Version
            % Description: This record provides the 7k sonar source version
            % as a NULL terminated string.
            
            % start parsing RTH
            
            S7Kdata.(recordName).VersionString{iRec} = fread(fid,32,'*char'); % UTF-8 string, max length 31 characters + null
            
            parsed = 1;
            
        case 7027 % Raw Detection Data
            % Description: This record is produced by the 7k sonar source
            % series. It contains noncompensated detection results. The 7k
            % sonar source updates this record on every ping. This record
            % is available by subscription only.
            % Refer to Appendix F on page 246 for a description of handling
            % the 7027 record.
            
            % start parsing RTH
            S7Kdata.(recordName).SonarId(iRec)    = fread(fid,1,'uint64'); % Sonar serial number
            S7Kdata.(recordName).PingNumber(iRec) = fread(fid,1,'uint32'); % Sequential number
            
            % Flag to indicate multi-ping sequence. 
            % Always 0 (zero) if not in multi-ping mode; otherwise this
            % represents the sequence number of the ping in the multi-ping
            % sequence. 
            S7Kdata.(recordName).MultipingSequence(iRec) = fread(fid,1,'uint16');
            
            S7Kdata.(recordName).N(iRec)             = fread(fid,1,'uint32'); % Number of detection points
            S7Kdata.(recordName).DataFieldSize(iRec) = fread(fid,1,'uint32'); % Size of detection information block in bytes

            % Detection algorithm:
            % 0 – G1_Simple
            % 1 – G1_BlendFilt
            % 2 – G2
            % 3 – G3
            % 4 – IF1
            % 5 – PS1 (beam detection)
            % 6 – HS1 (beam detection)
            % 7 – HS2 (pseudo beam detection)
            % 8-255 – Reserved for future use
            S7Kdata.(recordName).DetectionAlgorithm(iRec) = fread(fid,1,'uint8');

            % Flags:
            % BIT FIELD:
            % Bit 0-3: Uncertainty method
            %   0 – Not calculated
            %   1 – Rob Hare’s method
            %   2 – Ifremer’s method
            %   3-15 – Reserved for future use
            % Bit 4: Multi-detection enabled
            % Bit 5: Reserved
            % Bit 6: Has Snippets detection point flag
            % Bit 7: Has clipping flag
            % Bit 8-31: Reserved for future use
            S7Kdata.(recordName).Flags(iRec) = fread(fid,1,'uint32');
            
            S7Kdata.(recordName).SamplingRate(iRec) = fread(fid,1,'float32'); % Sonar’s sampling frequency in Hz
            
            % Applied transmitter steering angle, in radians
            % This angle is used for pitch stabilization. It will be zero
            % if the system doesn’t have this feature. The value is the
            % same as the Projector beam steering angle of the 7000 record.
            % They are both filled from the same variable.
            S7Kdata.(recordName).TxAngle(iRec) = fread(fid,1,'float32'); 
            
            % Roll value (in radians) applied to gates; zero if roll
            % stabilization is ON. 
            % This value is made available to be able to draw the gating
            % lines in the real-time user interface wedge display.
            S7Kdata.(recordName).AppliedRoll(iRec) = fread(fid,1,'float32'); 
            
            S7Kdata.(recordName).Reserved{iRec} = fread(fid,15,'uint32'); % Reserved for future use
                        
            % start parsing RD
            
            % NOTE
            % The following data section is repeated for each detection
            % point as defined in RTH. The size of each field is always
            % defined in RTH. If the size of this definition does not match
            % the size specified in the record’s header, the user must
            % assume that there is an updated revision of this record and
            % that new fields are added at the end.
            
            % repeat cycle: N entries of S bytes
            temp = ftell(fid);
            N = S7Kdata.(recordName).N(iRec);
            S = S7Kdata.(recordName).DataFieldSize(iRec);
            
            % Beam number the detection is taken from
            S7Kdata.(recordName).BeamDescriptor{iRec} = fread(fid,N,'uint16',S-2);
            fseek(fid,temp+2,'bof'); % to next data type
            
            % Non-corrected fractional sample number with reference to
            % receiver’s acoustic center with the zero sample at the
            % transmit time
            S7Kdata.(recordName).DetectionPoint{iRec} = fread(fid,N,'float32',S-4);
            fseek(fid,temp+6,'bof'); % to next data type
            
            % Beam steering angle with reference to receiver’s acoustic
            % center in the sonar reference frame, at the detection point;
            % in radians
            S7Kdata.(recordName).RxAngle{iRec} = fread(fid,N,'float32',S-4);
            fseek(fid,temp+10,'bof'); % to next data type
            
            % BIT FIELD
            % see doc
            S7Kdata.(recordName).Flags2{iRec} = fread(fid,N,'uint32',S-4);
            fseek(fid,temp+14,'bof'); % to next data type
            
            % Detection quality
            % see doc
            S7Kdata.(recordName).Quality{iRec} = fread(fid,N,'uint32',S-4);
            fseek(fid,temp+18,'bof'); % to next data type
            
            % Detection uncertainty represented as an error normalized to
            % the detection point 
            S7Kdata.(recordName).Uncertainty{iRec} = fread(fid,N,'float32',S-4);
            fseek(fid,temp+22,'bof'); % to next data type
            
            % Intensity of detection point
            S7Kdata.(recordName).Intensity{iRec} = fread(fid,N,'float32',S-4);
            fseek(fid,temp+26,'bof'); % to next data type
            
            % Minimum sample number of gate limit
            S7Kdata.(recordName).MinLimit{iRec} = fread(fid,N,'float32',S-4);
            fseek(fid,temp+30,'bof'); % to next data type
            
            % Maximum sample number of gate limit
            S7Kdata.(recordName).MaxLimit{iRec} = fread(fid,N,'float32',S-4);
            fseek(fid,4-S,'cof'); % we need to come back after last jump
            
            % NOTE
            % Transmit and receive steering angles provided in this record
            % are total steering angles applied. Refer to record 7004 –
            % Beam Geometry and/or record 7012 – Ping Motion Data in order
            % to isolate steering components. For sign explanations, see
            % section 2.2 Sign Conventions.
            
            % Optional data 7027 record
            if OD_size~=0
                tmp_pos = ftell(fid);
                
                % start parsing OD
                fread(fid,OD_offset-(tmp_pos-pif_recordstart),'uint8');
                
                S7Kdata.(recordName).Frequency(iRec) = fread(fid,1,'float32'); % Ping Frequency in Hz
                S7Kdata.(recordName).Latitude(iRec)  = fread(fid,1,'float64'); % Latitude of vessel reference point in radians -pi/2 to pi/2, south negative
                S7Kdata.(recordName).Longitude(iRec) = fread(fid,1,'float64'); % Longitude of vessel reference point in radians -pi to pi, west negative
                S7Kdata.(recordName).Heading(iRec)   = fread(fid,1,'float32'); % Heading of vessel at transmit time in radians
                
                % Method used to correct to chart datum. If height source = 1, then Tide = ‘0’.
                % 0 – None
                % 1 – RTK
                % 2 – Tide
                S7Kdata.(recordName).HeightSource{iRec} = fread(fid,1,'uint8');
                
                S7Kdata.(recordName).Tide(iRec)         = fread(fid,1,'float32'); % In meters
                S7Kdata.(recordName).Roll(iRec)         = fread(fid,1,'float32'); % Roll (in radians) at transmit time
                S7Kdata.(recordName).Pitch(iRec)        = fread(fid,1,'float32'); % Pitch (in radians) at transmit time
                S7Kdata.(recordName).Heave(iRec)        = fread(fid,1,'float32'); % Heave (in radians???) at transmit time
                S7Kdata.(recordName).VehicleDepth(iRec) = fread(fid,1,'float32'); % Vehicle depth at transmit time in meters
                
                % The following set of data items are repeated for each
                % beam:
                tmp_beam_data = fread(fid,[5 N],'float32');
                
                % Depth relative chart datum (or relative waterline if
                % Height source = 0) (in meters) 
                S7Kdata.(recordName).Depth{iRec} = tmp_beam_data(1,:);
                
                % Along track distance in vessel grid (in meters)
                S7Kdata.(recordName).AlongTrackDistance{iRec} = tmp_beam_data(2,:);
                
                % Across track distance in vessel grid (in meters)
                S7Kdata.(recordName).AcrossTrackDistance{iRec} = tmp_beam_data(3,:);
                
                % Beam pointing angle from vertical in radians
                S7Kdata.(recordName).PointingAngle{iRec} = tmp_beam_data(4,:);
                
                % Beam azimuth angle in radians
                S7Kdata.(recordName).AzimuthAngle{iRec} = tmp_beam_data(5,:);
                
            else
                
                S7Kdata.(recordName).Frequency(iRec)    = NaN;
                S7Kdata.(recordName).Latitude(iRec)     = NaN;
                S7Kdata.(recordName).Longitude(iRec)    = NaN;
                S7Kdata.(recordName).Heading(iRec)      = NaN;
                S7Kdata.(recordName).HeightSource{iRec} = '';
                S7Kdata.(recordName).Tide(iRec)         = NaN;
                S7Kdata.(recordName).Roll(iRec)         = NaN;
                S7Kdata.(recordName).Pitch(iRec)        = NaN;
                S7Kdata.(recordName).Heave(iRec)        = NaN;
                S7Kdata.(recordName).VehicleDepth(iRec) = NaN;
                S7Kdata.(recordName).Depth{iRec}        = NaN(1,N);
                S7Kdata.(recordName).AlongTrackDistance{iRec}  = NaN(1,N);
                S7Kdata.(recordName).AcrossTrackDistance{iRec} = NaN(1,N);
                S7Kdata.(recordName).PointingAngle{iRec}       = NaN(1,N);
                S7Kdata.(recordName).AzimuthAngle{iRec}        = NaN(1,N);
                
            end
            
            % start parsing CS
            if CS_size == 4
                S7Kdata.(recordName).Checksum(iRec) = fread(fid,1,'uint32');
            elseif CS_size == 0
                S7Kdata.(recordName).Checksum(iRec) = NaN;
            else
                comms.error('%s: unexpected CS size',recordName);
            end
            % check data integrity with checksum... TO DO XXX2
            
            % confirm parsing
            parsed = 1;
            
        case 7028 % Snippet data
            % Description: This record is produced by the SeaBat™ 7k sonar.
            % It contains the sonar snippet imagery data. The 7k sonar
            % source updates this record on every ping.  This record is
            % available by subscription only. It is not available for
            % forward-looking  sonar. 
            % For details about requesting and subscribing to records, see
            % section 10.62 7500 –  Remote Control together with section 11
            % 7k Remote Control Definitions. 
            % For information on optional data, see Appendix A Teledyne PDS
            % Optional Data Beams and samples are numbered from 0. Data is
            % beams followed by samples 
            
            % ----- DEV NOTES ---------------------------------------------
            % 1. Have coded this (May 2024) but not tested with data yet. 
            % 2. Since I have had no use for it yet, I haven't developped
            % the code to read the snippets. For now we are only recording
            % the start position for the snippets, like we do for WCD.
            % Remains to be assessed if that is what we want to do..
            % -------------------------------------------------------------
             
            % start parsing RTH
            S7Kdata.(recordName).SonarId(iRec)    = fread(fid,1,'uint64'); % Sonar serial number
            S7Kdata.(recordName).PingNumber(iRec) = fread(fid,1,'uint32'); % Sequential number

            % Flag to indicate multi-ping sequence. 
            % Always 0 (zero) if not in multi-ping mode; otherwise this
            % represents the sequence number of the ping in the multi-ping
            % sequence. 
            S7Kdata.(recordName).MultipingSequence(iRec) = fread(fid,1,'uint16');
            
            S7Kdata.(recordName).N(iRec) = fread(fid,1,'uint16'); % Number of detection points

            % Error flag:
            % If set, record will not contain any data. Flag
            % itself will indicate an error.
            % 0 – OK
            % 1-5 – Reserved
            % 6 – Bottom detection failed (R7006)
            % 7-255 – Reserved
            S7Kdata.(recordName).ErrorFlag(iRec) = fread(fid,1,'uint8');
            
            % Control flags:
            % Control settings from RC 1118
            % 0 – Automatic snippet window is used
            % 1 – Quality Filter enabled
            % 2 – Minimum window size is required
            % 3 – Maximum window size is required
            % 4-7 – Reserved
            S7Kdata.(recordName).ControlFlags(iRec) = fread(fid,1,'uint8');
            
            % Flags:
            % BIT FIELD:
            % Bit 0: 0: 16 bit snippets
            %        1: 32 bit snippets
            % Bit 1: 0: Use global sample rate
            %        1: Use local sample rate used for snippets
            S7Kdata.(recordName).Flags(iRec) = fread(fid,1,'uint32');
            
            S7Kdata.(recordName).SampleRate(iRec) = fread(fid,1,'float32'); % Snippets sample rate
            S7Kdata.(recordName).Reserved{iRec}   = fread(fid,5,'uint32'); % Reserved for future use
            
            % start parsing RD
            
            % repeat cycle: N entries of 14 bytes
            temp = ftell(fid);
            N = S7Kdata.(recordName).N(iRec);
            
            % Beam number
            S7Kdata.(recordName).BeamDescriptor{iRec} = fread(fid,N,'uint16',14-2);
            fseek(fid,temp+2,'bof'); % to next data type
            
            % First sample included in the snippet
            S7Kdata.(recordName).SnippetStart{iRec} = fread(fid,N,'uint32',14-4);
            fseek(fid,temp+6,'bof'); % to next data type
            
            % Detection point
            S7Kdata.(recordName).DetectionSample{iRec} = fread(fid,N,'uint32',14-4);
            fseek(fid,temp+10,'bof'); % to next data type
            
            % Last sample included in the snippet
            S7Kdata.(recordName).SnippetEnd{iRec} = fread(fid,N,'uint32',14-4);
            fseek(fid,temp+14,'bof'); % to next data type
            
            % Intensity series for each sample. Array is populated with
            % samples from the first sample to the last as defined above.
            % ----- DEV NOTES ---------------------------------------------
            % Recording just the start position for this, as I am coding
            % this with no use for it for the moment 
            % -------------------------------------------------------------
            S7Kdata.(recordName).SnippetsPos(iRec) = ftell(fid);
            
            % Optional data 7028 record
            if OD_size~=0
                tmp_pos = ftell(fid);
                
                % start parsing OD
                fread(fid,OD_offset-(tmp_pos-pif_recordstart),'uint8');
                
                S7Kdata.(recordName).Frequency(iRec) = fread(fid,1,'float32'); % Ping Frequency in Hz
                S7Kdata.(recordName).Latitude(iRec)  = fread(fid,1,'float64'); % Latitude of vessel reference point in radians -pi/2 to pi/2, south negative
                S7Kdata.(recordName).Longitude(iRec) = fread(fid,1,'float64'); % Longitude of vessel reference point in radians -pi to pi, west negative
                S7Kdata.(recordName).Heading(iRec)   = fread(fid,1,'float32'); % Heading of vessel at transmit time in radians
                
                % The following set of data items are repeated for each
                % beam:
                tmp_beam_data = fread(fid,[3 N],'float32');
                
                 % Along track distance in vessel grid in meters
                S7Kdata.(recordName).AlongTrackDistance{iRec} = tmp_beam_data(1,:);
                
                % Across track distance in vessel grid in meters
                S7Kdata.(recordName).AcrossTrackDistance{iRec} = tmp_beam_data(2,:);
                
                % Sample number at detection point of beam
                S7Kdata.(recordName).CenterSampleNumber{iRec} = cast(tmp_beam_data(3,:),'uint32');

            else
                S7Kdata.(recordName).Frequency(iRec) = NaN;
                S7Kdata.(recordName).Latitude(iRec)  = NaN;
                S7Kdata.(recordName).Longitude(iRec) = NaN;
                S7Kdata.(recordName).Heading(iRec)   = NaN;
                S7Kdata.(recordName).AlongTrackDistance{iRec}  = NaN(1,N);
                S7Kdata.(recordName).AcrossTrackDistance{iRec} = NaN(1,N);
                S7Kdata.(recordName).CenterSampleNumber{iRec}  = NaN(1,N);
            end
            
            % start parsing CS
            if CS_size == 4
                S7Kdata.(recordName).Checksum(iRec) = fread(fid,1,'uint32');
            elseif CS_size == 0
                S7Kdata.(recordName).Checksum(iRec) = NaN;
            else
                comms.error('%s: unexpected CS size',recordName);
            end
            % check data integrity with checksum... TO DO XXX2
            
            % confirm parsing
            parsed = 1;
            
        case 7042 % Compressed Water Column Data
            % Description: This record is produced by the 7k sonar source
            % series. It contains compressed water column data. The 7k
            % sonar source updates this record on every ping. This record
            % is available by subscription only. For details about
            % requesting and subscribing to records, see section 10.62 7500
            % – Remote Control together with section 11 7k Remote Control
            % Definitions.
            
            % NOTE
            % Remote command 7500 sub7042 is used to configure this record.
            
            % NOTE
            % See Appendix I 7042 Compressed water column data for a
            % description of the compression algorithms used to fill the
            % 7042 record.
            
            % The Compressed Water Column record allows for the reduction
            % in record data size (vs. the standard 7018 full
            % magnitude/phase record) via the several possible options
            % listed here. “Downsampling” means that only 1 of N mag/phase
            % samples are kept. Where ‘N’ is the “downsampling factor”
            % value. The “downsampling type” controls how that 1 value is
            % determined. The three choices are:
            % 1. Middle of window:
            % The 1 sample value kept is the middle one in each “window”
            % (e.g. if N = 5, then we keep sample 3, 8, 13, 18, …)
            % 2. Peak:
            % The 1 sample value kept is the largest of each “window” of N
            % samples.
            % 3. Average:
            % The 1 sample value kept is the average of all N samples in
            % each “window”.
            
            % For example, if the “Remove phase data” option and the
            % Downsampling option (with factor 5) are selected, then the
            % resulting Compressed Water Column record will be 1/2 * 1/5 =
            % 1/10 the size of corresponding 7018 mag+phase Water Column
            % Record.
            
            % ----- DEV NOTE ----------------------------------------------
            % This datagram's data is too to be stored in memory. Instead,
            % we record the metadata and the position-in-file location of
            % the data, which be extracted and stored in binary format at
            % the next stage of data conversion.
            % -------------------------------------------------------------
            
            % start parsing RTH
            S7Kdata.(recordName).SonarId(iRec)    = fread(fid,1,'uint64'); % Sonar serial number.
            S7Kdata.(recordName).PingNumber(iRec) = fread(fid,1,'uint32'); % Sequential number.
            
            % Flag to indicate multi-ping sequence.
            % Always 0 (zero) if not in Multi-Ping mode; otherwise this
            % represents the sequence number of the ping in the multi-ping
            % sequence. 
            S7Kdata.(recordName).MultiPingSequence(iRec) = fread(fid,1,'uint16');
            
            S7Kdata.(recordName).Beams(iRec)   = fread(fid,1,'uint16'); % Number of beams.
            S7Kdata.(recordName).Samples(iRec) = fread(fid,1,'uint32'); % Number of samples (nominal, based on range)
            
            % Number of samples (maximum over all beams if Flags bit 0 set
            % [samples per beam varies]. Otherwise same as Samples(N) )
            % When all beams come with the same number of samples
            % 'Compressed Samples' is the same as 'Samples(N)' for each
            % beam in the data section of the record. But if bit 0 is set
            % in the 'Flags' the beams are individually cut based on bottom
            % detection and thus have all different length. 'Compressed
            % Samples' then gives you the maximum number of samples of the
            % beam with the longest range. Same as the largest value of
            % 'Samples(N)' in the data section.
            S7Kdata.(recordName).CompressedSamples(iRec) = fread(fid,1,'uint32');
            
            % BIT FIELD. See CFF_get_R7042_flags
            S7Kdata.(recordName).Flags(iRec) = fread(fid,1,'uint32');
            
            % flag processing
            [flags,sample_size,~,~] = CFF_get_R7042_flags(S7Kdata.(recordName).Flags(iRec));
            
            % First sample included for each beam. Normally zero, unless
            % power saving mode “Range Blank” or absolute gate (bit 3) is
            % in effect. See RC 1046 for details. Thus, the samples in each
            % beam data section will run from F to F+N-1. Construction of a
            % correct water column image must take this into account.
            S7Kdata.(recordName).FirstSample(iRec) = fread(fid,1,'uint32');
            
            S7Kdata.(recordName).SampleRate(iRec)        = fread(fid,1,'float32'); % Effective sample rate after downsampling, if specified.
            S7Kdata.(recordName).CompressionFactor(iRec) = fread(fid,1,'float32'); % Factor used in intensity (magnitude) compression.
            S7Kdata.(recordName).Reserved(iRec)          = fread(fid,1,'uint32'); % Zero. Reserved for future use
            
            % NOTE
            % The following data section is repeated for each beam (B) as
            % defined in RTH. The size may vary for each beam if bottom
            % detection truncation is in effect (Flags bit 0 is set).
            % IMPORTANT: This is “reversed” compared to the data ordering
            % in the standard 7018 Water Column record!
            
            % start parsing RD
            % repeat cycle: B entries of a possibly variable number of
            % bits. Reading everything first and using a for loop to parse
            % the data in it
            pos_2 = ftell(fid); % position at start of data
            RTH_size = 44;
            RD_size = RTHandRD_size - RTH_size;
            blocktmp = fread(fid,RD_size,'int8=>int8')'; % read all that data block
            
            wc_parsing_error = 0; % initialize flag
            
            % initialize outputs
            B = S7Kdata.(recordName).Beams(iRec);
            S7Kdata.(recordName).BeamNumber{iRec}                = NaN(1,B);
            S7Kdata.(recordName).SegmentNumber{iRec}             = NaN(1,B);
            S7Kdata.(recordName).NumberOfSamples{iRec}           = NaN(1,B);
            S7Kdata.(recordName).SampleStartPositionInFile{iRec} = NaN(1,B);
            
            Ns = zeros(1,B); % Number of samples in matrix form
            id  = zeros(1,B+1); % offset for start of each Nrx block
            % now parse the data
            if flags.segmentNumbersAvailable
                for jj = 1:B
                    try
                        % Beam Number for this data.
                        S7Kdata.(recordName).BeamNumber{iRec}(jj) = typecast(blocktmp(1+id(jj):2+id(jj)),'uint16');
                        
                        % Segment number for this beam. Optional field, see ‘Bit 14’ of Flags.
                        S7Kdata.(recordName).SegmentNumber{iRec}(jj) = typecast(blocktmp(3+id(jj)),'uint8');
                        
                        % Number of samples included for this beam.
                        S7Kdata.(recordName).NumberOfSamples{iRec}(jj) = typecast(blocktmp(4+id(jj):7+id(jj)),'uint32');
                        
                        % Record position of data
                        S7Kdata.(recordName).SampleStartPositionInFile{iRec}(jj) = pos_2 + id(jj) + 7;
                        
                        Ns(jj) = S7Kdata.(recordName).NumberOfSamples{iRec}(jj);
                        id(jj) = 7*jj + sum(Ns)*sample_size;
                    catch
                        % if any issue in the recording, flag and exit the loop
                        S7Kdata.(recordName).NumberOfSamples{iRec}(jj) = 0;
                        Ns(jj) = 0;
                        wc_parsing_error = 1;
                        continue;
                    end
                end
            else
                % same process but without reading segment number
                for jj = 1:B
                    try
                        % Beam Number for this data.
                        S7Kdata.(recordName).BeamNumber{iRec}(jj) = typecast(blocktmp(1+id(jj):2+id(jj)),'uint16');
                        
                        % Number of samples included for this beam.
                        S7Kdata.(recordName).NumberOfSamples{iRec}(jj) = typecast(blocktmp(3+id(jj):6+id(jj)),'uint32');
                        
                        % Record position of data
                        S7Kdata.(recordName).SampleStartPositionInFile{iRec}(jj) = pos_2 + id(jj) + 6;
                        
                        Ns(jj) = S7Kdata.(recordName).NumberOfSamples{iRec}(jj);
                        id(jj+1) = 6*jj + sum(Ns).*sample_size;
                    catch
                        % if any issue in the recording, flag and exit the loop
                        S7Kdata.(recordName).NumberOfSamples{iRec}(jj) = 0;
                        Ns(jj) = 0;
                        wc_parsing_error = 1;
                        continue;
                    end
                end
            end
            
            if wc_parsing_error == 0
                % HERE if data parsing all went well
                
                if OD_size~=0
                    tmp_pos = ftell(fid);
                    % start parsing OD
                    fread(fid,OD_offset-(tmp_pos-pif_recordstart),'uint8');
                    tmp_OD = fread(fid,OD_size,'uint8');
                else
                    tmp_OD = NaN;
                end
                
                % parsing CS
                if CS_size == 4
                    S7Kdata.(recordName).Checksum(iRec) = fread(fid,1,'uint32');
                elseif CS_size == 0
                    S7Kdata.(recordName).Checksum(iRec) = NaN;
                else
                    comms.error(sprintf('%s: unexpected CS size',recordName));
                end
                % check data integrity with checksum... TO DO XXX2
                
                % confirm parsing
                parsed = 1;
                
            else
                % HERE if data parsing failed, add a blank datagram in
                % output
                comms.error(sprintf('%s: error while parsing datagram',recordName));
                % copy field names of previous entries
                fields_wc = recordNames(S7Kdata.(recordName));
                
                % add blanks fields for those missing
                for ifi = 1:numel(fields_wc)
                    if numel(S7Kdata.(recordName).(fields_wc{ifi})) >= iRec
                        S7Kdata.(recordName).(fields_wc{ifi})(iRec) = [];
                    end
                end
                
                iRec = iRec-1; % XXX1 if we do that, then we'll rewrite over the blank record we just entered??
                parsed = 0;
                
            end
            
        case 7200 % File Header
            % Description: First record of 7k data file.
            
            % start parsing RTH
            S7Kdata.(recordName).FileIdentifier{iRec}                = fread(fid,2,'uint64');
            S7Kdata.(recordName).VersionNumber(iRec)                 = fread(fid,1,'uint16'); % File format version number
            S7Kdata.(recordName).Reserved(iRec)                      = fread(fid,1,'uint16'); % Reserved
            S7Kdata.(recordName).SessionIdentifier{iRec}             = fread(fid,2,'uint64'); % User defined session identifier. Used to associate multiple files for a given session.
            S7Kdata.(recordName).RecordDataSize(iRec)                = fread(fid,1,'uint32'); % Size of record data. 0 – If not present
            S7Kdata.(recordName).N(iRec)                             = fread(fid,1,'uint32'); % Number of devices (N >= 0)
            S7Kdata.(recordName).RecordingName{iRec}                 = fread(fid,64,'*char'); % Null terminated UTF-8 string
            S7Kdata.(recordName).RecordingProgramVersionNumber{iRec} = fread(fid,16,'*char'); % Null terminated UTF-8 string
            S7Kdata.(recordName).UserDefinedName{iRec}               = fread(fid,64,'*char'); % Null terminated UTF-8 string
            S7Kdata.(recordName).Notes{iRec}                         = fread(fid,128,'*char'); % Null terminated UTF-8 string
            
            % start parsing RD
            
            % repeat cycle: N entries of 6 bytes
            temp = ftell(fid);
            N = S7Kdata.(recordName).N(iRec);
            S7Kdata.(recordName).DeviceIdentifier{iRec} = fread(fid,N,'uint32',6-4); % Identifier for record type of embedded data
            fseek(fid,temp+4,'bof'); % to next data type
            S7Kdata.(recordName).SystemEnumerator{iRec} = fread(fid,N,'uint16',6-2); % Identifier for the device enumerator
            fseek(fid,2-6,'cof'); % we need to come back after last jump
            
            % This record may have optional data that contains information
            % about the file catalog (7300 record) at the end of the log
            % file. The optional data identifier (in the record frame) will
            % be 7300.
            
            if OD_size>= 12
                tmp_pos = ftell(fid);
                % start parsing OD
                fread(fid,OD_offset-(tmp_pos-pif_recordstart),'uint8');
                S7Kdata.(recordName).Size(iRec)   = fread(fid,1,'uint32'); % Size of the file catalog record
                S7Kdata.(recordName).Offset(iRec) = fread(fid,1,'uint64'); % File offset of the file catalog record
            elseif OD_size == 0
                S7Kdata.(recordName).Size(iRec)   = NaN;
                S7Kdata.(recordName).Offset(iRec) = NaN;
            else
                comms.error(sprintf('%s: unexpected OD size',recordName));
            end
            
            % start parsing CS
            if CS_size == 4
                S7Kdata.(recordName).Checksum(iRec) = fread(fid,1,'uint32');
            elseif CS_size == 0
                S7Kdata.(recordName).Checksum(iRec) = NaN;
            else
                comms.error(sprintf('%s: unexpected CS size',recordName));
            end
            % check data integrity with checksum... TO DO XXX2
            
            % confirm parsing
            parsed = 1;
            
        case 7610 % Sound Velocity
            % Description: This record can be used to set the SeaBat 7k
            % sonar series systems current sound velocity value. The record
            % can be manually requested or subscribed to from the 7k sonar
            % source. For details about requesting and subscribing to
            % records, see section 10.62 7500 – Remote Control together
            % with section 11 7k Remote Control Definitions.
            
            % start parsing RTH
            S7Kdata.(recordName).SoundVelocity(iRec) = fread(fid,1,'float32'); % In meters/second
            S7Kdata.(recordName).Temperature(iRec)   = fread(fid,1,'float32'); % Kelvin (optional)
            S7Kdata.(recordName).Pressure(iRec)      = fread(fid,1,'float32'); % Pascal (optional)
            
            % NOTE
            % The Pressure field is for information only. It is not used in
            % the 7k sonar source. The 7k sonar source simply passes the
            % record along to subscribers and raw data recording with no
            % source code changes.
            % The field is not present with a version of the IO Module
            % older than V4.0.0.8. When the value is zero it is not valid.
            
            % NOTE
            % If filtering is enabled in record 7510 (see section 10.67
            % 7510 – SV Filtering), record 7610 will contain filtered
            % values used by 7k sonar source when broadcasted by 7k sonar
            % source, except when in manual overwrite mode.
            
            % NOTE
            % Record 7610 is updated for single request, but not broadcast
            % when manual value is received via remote control command
            % 7610.
            % Record 7610 is generated every time surface sound velocity
            % value is received via record 7610 even if 7k sonar source is
            % in manual overwrite mode and the value was ignored. In this
            % case, returned sound velocity value will be unfiltered.
            
            parsed = 1;
            
        otherwise
            % recordTypeIdentifier is not recognized yet
            
    end
    
    % modify parsed status in info
    S7Kfileinfo.parsed(iDatag,1) = parsed;
    
    % and date and time
    if parsed == 1
        S7Kdata.(recordName).TimeSinceMidnightInMilliseconds(iRec) = S7Kfileinfo.timeSinceMidnightInMilliseconds(iDatag);
        S7Kdata.(recordName).Date(iRec)                            = str2double(S7Kfileinfo.date{iDatag});
    end
    
    % communicate progress
    comms.progress(iDatag,nDatagsToParse);
    
end


%% finalise

% close fid
fclose(fid);

% add info to parsed data
S7Kdata.info = S7Kfileinfo;

% end message
comms.finish('Done');

end
