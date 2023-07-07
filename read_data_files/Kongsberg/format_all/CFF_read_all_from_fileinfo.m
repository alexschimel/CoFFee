function ALLdata = CFF_read_all_from_fileinfo(ALLfilename, ALLfileinfo, varargin)
%CFF_READ_ALL_FROM_FILEINFO  Read contents of all file
%
%   Reads contents of one Kongsberg EM series binary data file in .all
%   format (.all or .wcd), using ALLfileinfo to indicate which datagrams to
%   be parsed.
%
%   ALLdata = CFF_READ_ALL_FROM_FILEINFO(ALLfilename, ALLfileinfo) reads
%   all datagrams in ALLfilename for which ALLfileinfo.parsed equals 1, and
%   store them in ALLdata.
%
%   *INPUT VARIABLES*
%   * |ALLfilename|: Required. String filename to parse (extension in .all
%   or .wcd).
%   * |ALLfileinfo|: structure containing information about datagrams in
%   ALLfilename, with fields:
%     * |ALLfilename|: input file name
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
%   * |ALLdata|: structure containing the data. Each field corresponds a
%   different type of datagram. The field |ALLdata.info| contains a copy of
%   ALLfileinfo described above.
%
%   *DEVELOPMENT NOTES*
%   * PU Status output datagram structure seems different to the datagram
%   manual description. Find the good description.#edit 21aug2013: updated
%   to Rev Q. Need to be checked though.
%   * The parsing code for some datagrams still need to be coded. To
%   update.
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021


%% Input arguments management
p = inputParser;

% name of the .all or .wcd file
argName = 'ALLfilename';
argCheck = @(x) CFF_check_ALLfilename(x);
addRequired(p,argName,argCheck);

% fileinfo from CFF_ALL_FILE_INFO containing indexes of datagrams to read
argName = 'ALLfileinfo';
argCheck = @isstruct;
addRequired(p,argName,argCheck);

% ?? XXX3
argName = 'OutputFields';
argCheck = @iscell;
addParameter(p,argName,{},argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,ALLfilename,ALLfileinfo,varargin{:});

% and get results
ALLfilename  = p.Results.ALLfilename;
ALLfileinfo  = p.Results.ALLfileinfo;
OutputFields = p.Results.OutputFields;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end


%% Prep

% start message
filename = CFF_file_name(ALLfilename,1);
comms.start(sprintf('Reading datagrams in file %s',filename));

% get basic info for file opening
filesize = ALLfileinfo.filesize;
datagsizeformat = ALLfileinfo.datagsizeformat;
datagramsformat = ALLfileinfo.datagramsformat;
ALLdata.ALLfilename=ALLfilename;
ALLdata.datagramsformat=datagramsformat;

% open file
[fid,~] = fopen(ALLfilename, 'r',datagramsformat);

% parse only datagrams indicated in ALLfileinfo
datagToParse = find(ALLfileinfo.parsed==1);
nDatagsToPars = numel(datagToParse);

% start progress
comms.progress(0,nDatagsToPars);


%% Reading datagrams
for iDatag = datagToParse'
    
    % current position in file
    curpos = ftell(fid);
    
    % position of datagram in file
    datpos = ALLfileinfo.datagPositionInFile(iDatag);
    
    % go to datagram position
    fread(fid, datpos - curpos);
    
    % start reading
    nbDatag                         = fread(fid,1,'uint32',datagsizeformat); % number of bytes in datagram
    stxDatag                        = fread(fid,1,'uint8');  % STX (always H02)
    datagTypeNumber                 = fread(fid,1,'uint8');  % SIMRAD type of datagram
    emNumber                        = fread(fid,1,'uint16'); % EM Model Number
    date                            = fread(fid,1,'uint32'); % date
    timeSinceMidnightInMilliseconds = fread(fid,1,'uint32'); % time since midnight in milliseconds
    number                          = fread(fid,1,'uint16'); % datagram or ping number
    systemSerialNumber              = fread(fid,1,'uint16'); % EM system serial number
    
    % reset the parsed switch
    parsed = 0;
        
    switch datagTypeNumber
        
        case 49 % 'PU STATUS OUTPUT (31H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_PUStatus',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i49=i49+1; catch, i49=1; end
            
            % parsing
            % SOMETHING WRONG WITH THIS DATAGRAM, NEW TEMPLATE? REWRITE
            % USING LATEST KONGSBERG DOCUMENTATION XXX1
            %             ALLdata.EM_PUStatus.STX(i49)                                    = stxDatag;
            %             ALLdata.EM_PUStatus.TypeOfDatagram(i49)                         = datagTypeNumber;
            %             ALLdata.EM_PUStatus.EMModelNumber(i49)                          = emNumber;
            %             ALLdata.EM_PUStatus.Date(i49)                                   = date;
            %             ALLdata.EM_PUStatus.TimeSinceMidnightInMilliseconds(i49)        = timeSinceMidnightInMilliseconds;
            %             ALLdata.EM_PUStatus.StatusDatagramCounter(i49)                  = number;
            %             ALLdata.EM_PUStatus.SystemSerialNumber(i49)                     = systemSerialNumber;
            %
            %             ALLdata.EM_PUStatus.PingRate(i49)                               = fread(fid,1,'uint16');
            %             ALLdata.EM_PUStatus.PingCounterOfLatestPing(i49)                = fread(fid,1,'uint16');
            %             ALLdata.EM_PUStatus.DistanceBetweenSwath(i49)                   = fread(fid,1,'uint8');
            %             ALLdata.EM_PUStatus.SensorInputStatusUDPPort2(i49)              = fread(fid,1,'uint32');
            %             ALLdata.EM_PUStatus.SensorInputStatusSerialPort1(i49)           = fread(fid,1,'uint32');
            %             ALLdata.EM_PUStatus.SensorInputStatusSerialPort2(i49)           = fread(fid,1,'uint32');
            %             ALLdata.EM_PUStatus.SensorInputStatusSerialPort3(i49)           = fread(fid,1,'uint32');
            %             ALLdata.EM_PUStatus.SensorInputStatusSerialPort4(i49)           = fread(fid,1,'uint32');
            %             ALLdata.EM_PUStatus.PPSStatus(i49)                              = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.PositionStatus(i49)                         = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.AttitudeStatus(i49)                         = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.ClockStatus(i49)                            = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.HeadingStatus (i49)                         = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.PUStatus(i49)                               = fread(fid,1,'uint8');
            %             ALLdata.EM_PUStatus.LastReceivedHeading(i49)                    = fread(fid,1,'uint16');
            %             ALLdata.EM_PUStatus.LastReceivedRoll(i49)                       = fread(fid,1,'int16');
            %             ALLdata.EM_PUStatus.LastReceivedPitch(i49)                      = fread(fid,1,'int16');
            %             ALLdata.EM_PUStatus.LastReceivedHeave(i49)                      = fread(fid,1,'int16');
            %             ALLdata.EM_PUStatus.SoundSpeedAtTransducer(i49)                 = fread(fid,1,'uint16');
            %             ALLdata.EM_PUStatus.LastReceivedDepth(i49)                      = fread(fid,1,'uint32');
            %             ALLdata.EM_PUStatus.AlongShipVelocity(i49)                      = fread(fid,1,'int16');
            %             ALLdata.EM_PUStatus.AttitudeVelocitySensor(i49)                 = fread(fid,1,'uint8');
            %             ALLdata.EM_PUStatus.MammalProtectionRamp(i49)                   = fread(fid,1,'uint8');
            %             ALLdata.EM_PUStatus.BackscatterAtObliqueAngle(i49)              = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.BackscatterAtNormalIncidence(i49)           = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.FixedGain(i49)                              = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.DepthToNormalIncidence(i49)                 = fread(fid,1,'uint8');
            %             ALLdata.EM_PUStatus.RangeToNormalIncidence(i49)                 = fread(fid,1,'uint16');
            %             ALLdata.EM_PUStatus.PortCoverage(i49)                           = fread(fid,1,'uint8');
            %             ALLdata.EM_PUStatus.StarboardCoverage(i49)                      = fread(fid,1,'uint8');
            %             ALLdata.EM_PUStatus.SoundSpeedAtTransducerFoundFromProfile(i49) = fread(fid,1,'uint16');
            %             ALLdata.EM_PUStatus.YawStabilization(i49)                       = fread(fid,1,'int16');
            %             ALLdata.EM_PUStatus.PortCoverageOrAcrossShipVelocity(i49)       = fread(fid,1,'int16');
            %             ALLdata.EM_PUStatus.StarboardCoverageOrDownwardVelocity(i49)    = fread(fid,1,'int16');
            %             ALLdata.EM_PUStatus.EM2040CPUtemp(i49)                          = fread(fid,1,'int8');
            %             ALLdata.EM_PUStatus.ETX(i49)                                    = fread(fid,1,'uint8');
            %             ALLdata.EM_PUStatus.CheckSum(i49)                               = fread(fid,1,'uint16');
            %
            %             % ETX check
            %             if ALLdata.EM_PUStatus.ETX(i49)~=3
            %                 error('wrong ETX value (ALLdata.EM_PUStatus)');
            %             end
            %
            %             % confirm parsing
            %             parsed = 1;
            
        case 65 % 'ATTITUDE (41H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_Attitude',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i65=i65+1; catch, i65=1; end
            
            % parsing
            ALLdata.EM_Attitude.NumberOfBytesInDatagram(i65)                = nbDatag;
            ALLdata.EM_Attitude.STX(i65)                                    = stxDatag;
            ALLdata.EM_Attitude.TypeOfDatagram(i65)                         = datagTypeNumber;
            ALLdata.EM_Attitude.EMModelNumber(i65)                          = emNumber;
            ALLdata.EM_Attitude.Date(i65)                                   = date;
            ALLdata.EM_Attitude.TimeSinceMidnightInMilliseconds(i65)        = timeSinceMidnightInMilliseconds;
            ALLdata.EM_Attitude.AttitudeCounter(i65)                        = number;
            ALLdata.EM_Attitude.SystemSerialNumber(i65)                     = systemSerialNumber;
            
            ALLdata.EM_Attitude.NumberOfEntries(i65)                        = fread(fid,1,'uint16'); %N
            
            % repeat cycle: N entries of 12 bits
            temp = ftell(fid);
            N = ALLdata.EM_Attitude.NumberOfEntries(i65) ;
            ALLdata.EM_Attitude.TimeInMillisecondsSinceRecordStart{i65} = fread(fid,N,'uint16',12-2);
            fseek(fid,temp+2,'bof'); % to next data type
            ALLdata.EM_Attitude.SensorStatus{i65}                       = fread(fid,N,'uint16',12-2);
            fseek(fid,temp+4,'bof'); % to next data type
            ALLdata.EM_Attitude.Roll{i65}                               = fread(fid,N,'int16',12-2);
            fseek(fid,temp+6,'bof'); % to next data type
            ALLdata.EM_Attitude.Pitch{i65}                              = fread(fid,N,'int16',12-2);
            fseek(fid,temp+8,'bof'); % to next data type
            ALLdata.EM_Attitude.Heave{i65}                              = fread(fid,N,'int16',12-2);
            fseek(fid,temp+10,'bof'); % to next data type
            ALLdata.EM_Attitude.Heading{i65}                            = fread(fid,N,'uint16',12-2);
            fseek(fid,2-12,'cof'); % we need to come back after last jump
            
            ALLdata.EM_Attitude.SensorSystemDescriptor(i65)                 = fread(fid,1,'uint8');
            ALLdata.EM_Attitude.ETX(i65)                                    = fread(fid,1,'uint8');
            ALLdata.EM_Attitude.CheckSum(i65)                               = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_Attitude.ETX(i65)~=3
                error('wrong ETX value (ALLdata.EM_Attitude)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 67 % 'CLOCK (43H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_Clock',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i67=i67+1; catch, i67=1; end
            
            % parsing
            ALLdata.EM_Clock.NumberOfBytesInDatagram(i67)                          = nbDatag;
            ALLdata.EM_Clock.STX(i67)                                              = stxDatag;
            ALLdata.EM_Clock.TypeOfDatagram(i67)                                   = datagTypeNumber;
            ALLdata.EM_Clock.EMModelNumber(i67)                                    = emNumber;
            ALLdata.EM_Clock.Date(i67)                                             = date;
            ALLdata.EM_Clock.TimeSinceMidnightInMilliseconds(i67)                  = timeSinceMidnightInMilliseconds;
            ALLdata.EM_Clock.ClockCounter(i67)                                     = number;
            ALLdata.EM_Clock.SystemSerialNumber(i67)                               = systemSerialNumber;
            
            ALLdata.EM_Clock.DateFromExternalClock(i67)                            = fread(fid,1,'uint32');
            ALLdata.EM_Clock.TimeSinceMidnightInMillisecondsFromExternalClock(i67) = fread(fid,1,'uint32');
            ALLdata.EM_Clock.OnePPSUse(i67)                                        = fread(fid,1,'uint8');
            ALLdata.EM_Clock.ETX(i67)                                              = fread(fid,1,'uint8');
            ALLdata.EM_Clock.CheckSum(i67)                                         = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_Clock.ETX(i67)~=3
                error('wrong ETX value (ALLdata.EM_Clock)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 68 % 'DEPTH DATAGRAM (44H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_Depth',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i68=i68+1; catch, i68=1; end
            
            % parsing
            ALLdata.EM_Depth.NumberOfBytesInDatagram(i68)           = nbDatag;
            ALLdata.EM_Depth.STX(i68)                               = stxDatag;
            ALLdata.EM_Depth.TypeOfDatagram(i68)                    = datagTypeNumber;
            ALLdata.EM_Depth.EMModelNumber(i68)                     = emNumber;
            ALLdata.EM_Depth.Date(i68)                              = date;
            ALLdata.EM_Depth.TimeSinceMidnightInMilliseconds(i68)   = timeSinceMidnightInMilliseconds;
            ALLdata.EM_Depth.PingCounter(i68)                       = number;
            ALLdata.EM_Depth.SystemSerialNumber(i68)                = systemSerialNumber;
            
            ALLdata.EM_Depth.HeadingOfVessel(i68)                   = fread(fid,1,'uint16');
            ALLdata.EM_Depth.SoundSpeedAtTransducer(i68)            = fread(fid,1,'uint16');
            ALLdata.EM_Depth.TransmitTransducerDepth(i68)           = fread(fid,1,'uint16');
            ALLdata.EM_Depth.MaximumNumberOfBeamsPossible(i68)      = fread(fid,1,'uint8');
            ALLdata.EM_Depth.NumberOfValidBeams(i68)                = fread(fid,1,'uint8'); %N
            ALLdata.EM_Depth.ZResolution(i68)                       = fread(fid,1,'uint8');
            ALLdata.EM_Depth.XAndYResolution(i68)                   = fread(fid,1,'uint8');
            ALLdata.EM_Depth.SamplingRate(i68)                      = fread(fid,1,'uint16'); % OR: ALLdata.EM_Depth.DepthDifferenceBetweenSonarHeadsInTheEM3000D(i68) = fread(fid,1,'int16');
            
            % repeat cycle: N entries of 16 bits
            temp = ftell(fid);
            N = ALLdata.EM_Depth.NumberOfValidBeams(i68);
            ALLdata.EM_Depth.DepthZ{i68}                        = fread(fid,N,'int16',16-2); % OR 'uint16' for EM120 and EM300
            fseek(fid,temp+2,'bof'); % to next data type
            ALLdata.EM_Depth.AcrosstrackDistanceY{i68}          = fread(fid,N,'int16',16-2);
            fseek(fid,temp+4,'bof'); % to next data type
            ALLdata.EM_Depth.AlongtrackDistanceX{i68}           = fread(fid,N,'int16',16-2);
            fseek(fid,temp+6,'bof'); % to next data type
            ALLdata.EM_Depth.BeamDepressionAngle{i68}           = fread(fid,N,'int16',16-2);
            fseek(fid,temp+8,'bof'); % to next data type
            ALLdata.EM_Depth.BeamAzimuthAngle{i68}              = fread(fid,N,'uint16',16-2);
            fseek(fid,temp+10,'bof'); % to next data type
            ALLdata.EM_Depth.Range{i68}                         = fread(fid,N,'uint16',16-2);
            fseek(fid,temp+12,'bof'); % to next data type
            ALLdata.EM_Depth.QualityFactor{i68}                 = fread(fid,N,'uint8',16-1);
            fseek(fid,temp+13,'bof'); % to next data type
            ALLdata.EM_Depth.LengthOfDetectionWindow{i68}       = fread(fid,N,'uint8',16-1);
            fseek(fid,temp+14,'bof'); % to next data type
            ALLdata.EM_Depth.ReflectivityBS{i68}                = fread(fid,N,'int8',16-1);
            fseek(fid,temp+15,'bof'); % to next data type
            ALLdata.EM_Depth.BeamNumber{i68}                    = fread(fid,N,'uint8',16-1);
            fseek(fid,1-16,'cof'); % we need to come back after last jump
            
            ALLdata.EM_Depth.TransducerDepthOffsetMultiplier(i68) = fread(fid,1,'int8');
            ALLdata.EM_Depth.ETX(i68)                             = fread(fid,1,'uint8');
            ALLdata.EM_Depth.CheckSum(i68)                        = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_Depth.ETX(i68)~=3
                error('wrong ETX value (ALLdata.EM_Depth)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 70 % 'RAW RANGE AND BEAM ANGLE (F) (46H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_RawRangeBeamAngle',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i70=i70+1; catch, i70=1; end
            
            % parsing
            % ...to write...
            
        case 71 % 'SURFACE SOUND SPEED (47H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_SurfaceSoundSpeed',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i71=i71+1; catch, i71=1; end
            
            % parsing
            ALLdata.EM_SurfaceSoundSpeed.NumberOfBytesInDatagram(i71)           = nbDatag;
            ALLdata.EM_SurfaceSoundSpeed.STX(i71)                               = stxDatag;
            ALLdata.EM_SurfaceSoundSpeed.TypeOfDatagram(i71)                    = datagTypeNumber;
            ALLdata.EM_SurfaceSoundSpeed.EMModelNumber(i71)                     = emNumber;
            ALLdata.EM_SurfaceSoundSpeed.Date(i71)                              = date;
            ALLdata.EM_SurfaceSoundSpeed.TimeSinceMidnightInMilliseconds(i71)   = timeSinceMidnightInMilliseconds;
            ALLdata.EM_SurfaceSoundSpeed.SoundSpeedCounter(i71)                 = number;
            ALLdata.EM_SurfaceSoundSpeed.SystemSerialNumber(i71)                = systemSerialNumber;
            
            ALLdata.EM_SurfaceSoundSpeed.NumberOfEntries(i71)                   = fread(fid,1,'uint16'); %N
            
            % repeat cycle: N entries of 4 bits
            temp = ftell(fid);
            N = ALLdata.EM_SurfaceSoundSpeed.NumberOfEntries(i71);
            ALLdata.EM_SurfaceSoundSpeed.TimeInSecondsSinceRecordStart{i71} = fread(fid,N,'uint16',4-2);
            fseek(fid,temp+2,'bof'); % to next data type
            ALLdata.EM_SurfaceSoundSpeed.SoundSpeed{i71}                    = fread(fid,N,'uint16',4-2);
            fseek(fid,2-4,'cof'); % we need to come back after last jump
            
            ALLdata.EM_SurfaceSoundSpeed.Spare(i71)                             = fread(fid,1,'uint8');
            ALLdata.EM_SurfaceSoundSpeed.ETX(i71)                               = fread(fid,1,'uint8');
            ALLdata.EM_SurfaceSoundSpeed.CheckSum(i71)                          = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_SurfaceSoundSpeed.ETX(i71)~=3
                error('wrong ETX value (ALLdata.EM_SurfaceSoundSpeed)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 72 % 'HEADING (48H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_Heading',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i72=i72+1; catch, i72=1; end
            
            % parsing
            % ...to write...
            
        case 73 % 'INSTALLATION PARAMETERS - START (49H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_InstallationStart',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i73=i73+1; catch, i73=1; end
            
            % parsing
            ALLdata.EM_InstallationStart.NumberOfBytesInDatagram(i73)         = nbDatag;
            ALLdata.EM_InstallationStart.STX(i73)                             = stxDatag;
            ALLdata.EM_InstallationStart.TypeOfDatagram(i73)                  = datagTypeNumber;
            ALLdata.EM_InstallationStart.EMModelNumber(i73)                   = emNumber;
            ALLdata.EM_InstallationStart.Date(i73)                            = date;
            ALLdata.EM_InstallationStart.TimeSinceMidnightInMilliseconds(i73) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_InstallationStart.SurveyLineNumber(i73)                = number;
            ALLdata.EM_InstallationStart.SystemSerialNumber(i73)              = systemSerialNumber;
            
            ALLdata.EM_InstallationStart.SerialNumberOfSecondSonarHead(i73)   = fread(fid,1,'uint16');
            
            % 18 bytes of binary data already recorded and 3 more to come = 21.
            % but nbDatag will always be even thanks to SpareByte. so
            % nbDatag is 22 if there is no ASCII data and more if there is
            % ASCII data. read the rest as ASCII (including SpareByte) with
            % 1 byte for 1 character.
            ALLdata.EM_InstallationStart.ASCIIData{i73}                       = fscanf(fid, '%c', nbDatag-21);
            
            ALLdata.EM_InstallationStart.ETX(i73)                             = fread(fid,1,'uint8');
            ALLdata.EM_InstallationStart.CheckSum(i73)                        = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_InstallationStart.ETX(i73)~=3
                error('wrong ETX value (ALLdata.EM_InstallationStart)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 78 % 'RAW RANGE AND ANGLE 78 (4EH)'
            if ~(isempty(OutputFields)||any(strcmp('EM_RawRangeAngle78',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i78=i78+1; catch, i78=1; end
            
            % parsing
            ALLdata.EM_RawRangeAngle78.NumberOfBytesInDatagram(i78)           = nbDatag;
            ALLdata.EM_RawRangeAngle78.STX(i78)                               = stxDatag;
            ALLdata.EM_RawRangeAngle78.TypeOfDatagram(i78)                    = datagTypeNumber;
            ALLdata.EM_RawRangeAngle78.EMModelNumber(i78)                     = emNumber;
            ALLdata.EM_RawRangeAngle78.Date(i78)                              = date;
            ALLdata.EM_RawRangeAngle78.TimeSinceMidnightInMilliseconds(i78)   = timeSinceMidnightInMilliseconds;
            ALLdata.EM_RawRangeAngle78.PingCounter(i78)                       = number;
            ALLdata.EM_RawRangeAngle78.SystemSerialNumber(i78)                = systemSerialNumber;
            
            ALLdata.EM_RawRangeAngle78.SoundSpeedAtTransducer(i78)            = fread(fid,1,'uint16');
            ALLdata.EM_RawRangeAngle78.NumberOfTransmitSectors(i78)           = fread(fid,1,'uint16'); %Ntx
            ALLdata.EM_RawRangeAngle78.NumberOfReceiverBeamsInDatagram(i78)   = fread(fid,1,'uint16'); %Nrx
            ALLdata.EM_RawRangeAngle78.NumberOfValidDetections(i78)           = fread(fid,1,'uint16');
            ALLdata.EM_RawRangeAngle78.SamplingFrequencyInHz(i78)             = fread(fid,1,'float32');
            ALLdata.EM_RawRangeAngle78.Dscale(i78)                            = fread(fid,1,'uint32');
            
            % repeat cycle #1: Ntx entries of 24 bits
            temp = ftell(fid);
            C = 24;
            Ntx = ALLdata.EM_RawRangeAngle78.NumberOfTransmitSectors(i78);
            ALLdata.EM_RawRangeAngle78.TiltAngle{i78}                     = fread(fid,Ntx,'int16',C-2);
            fseek(fid,temp+2,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.FocusRange{i78}                    = fread(fid,Ntx,'uint16',C-2);
            fseek(fid,temp+4,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.SignalLength{i78}                  = fread(fid,Ntx,'float32',C-4);
            fseek(fid,temp+8,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.SectorTransmitDelay{i78}           = fread(fid,Ntx,'float32',C-4);
            fseek(fid,temp+12,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.CentreFrequency{i78}               = fread(fid,Ntx,'float32',C-4);
            fseek(fid,temp+16,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.MeanAbsorptionCoeff{i78}           = fread(fid,Ntx,'uint16',C-2);
            fseek(fid,temp+18,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.SignalWaveformIdentifier{i78}      = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,temp+19,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.TransmitSectorNumberTxArrayIndex{i78} = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,temp+20,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.SignalBandwidth{i78}               = fread(fid,Ntx,'float32',C-4);
            fseek(fid,4-C,'cof'); % we need to come back after last jump
            
            % repeat cycle #2: Nrx entries of 16 bits
            temp = ftell(fid);
            C = 16;
            Nrx = ALLdata.EM_RawRangeAngle78.NumberOfReceiverBeamsInDatagram(i78);
            ALLdata.EM_RawRangeAngle78.BeamPointingAngle{i78}             = fread(fid,Nrx,'int16',C-2);
            fseek(fid,temp+2,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.TransmitSectorNumber{i78}          = fread(fid,Nrx,'uint8',C-1);
            fseek(fid,temp+3,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.DetectionInfo{i78}                 = fread(fid,Nrx,'uint8',C-1);
            fseek(fid,temp+4,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.DetectionWindowLength{i78}         = fread(fid,Nrx,'uint16',C-2);
            fseek(fid,temp+6,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.QualityFactor{i78}                 = fread(fid,Nrx,'uint8',C-1);
            fseek(fid,temp+7,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.Dcorr{i78}                         = fread(fid,Nrx,'int8',C-1);
            fseek(fid,temp+8,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.TwoWayTravelTime{i78}              = fread(fid,Nrx,'float32',C-4);
            fseek(fid,temp+12,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.ReflectivityBS{i78}                = fread(fid,Nrx,'int16',C-2);
            fseek(fid,temp+14,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.RealTimeCleaningInfo{i78}          = fread(fid,Nrx,'int8',C-1);
            fseek(fid,temp+15,'bof'); % to next data type
            ALLdata.EM_RawRangeAngle78.Spare{i78}                         = fread(fid,Nrx,'uint8',C-1);
            fseek(fid,1-C,'cof'); % we need to come back after last jump
            
            ALLdata.EM_RawRangeAngle78.Spare2(i78)                            = fread(fid,1,'uint8');
            ALLdata.EM_RawRangeAngle78.ETX(i78)                               = fread(fid,1,'uint8');
            ALLdata.EM_RawRangeAngle78.CheckSum(i78)                          = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_RawRangeAngle78.ETX(i78)~=3
                error('wrong ETX value (ALLdata.EM_RawRangeAngle78)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 79 % 'QUALITY FACTOR DATAGRAM 79 (4FH)'
            if ~(isempty(OutputFields)||any(strcmp('EM_QF',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i79=i79+1; catch, i79=1; end
            
            % parsing
            ALLdata.EM_QualityFactor79.NumberOfBytesInDatagram(i79)         = nbDatag;
            ALLdata.EM_QualityFactor79.STX(i79)                             = stxDatag;
            ALLdata.EM_QualityFactor79.TypeOfDatagram(i79)                  = datagTypeNumber;
            ALLdata.EM_QualityFactor79.EMModelNumber(i79)                   = emNumber;
            ALLdata.EM_QualityFactor79.Date(i79)                            = date;
            ALLdata.EM_QualityFactor79.TimeSinceMidnightInMilliseconds(i79) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_QualityFactor79.PingCounter(i79)                     = number;
            ALLdata.EM_QualityFactor79.SystemSerialNumber(i79)              = systemSerialNumber;
            
            ALLdata.EM_QualityFactor79.NumberOfReceiveBeams(i79)      = fread(fid,1,'uint16'); %Nrx
            ALLdata.EM_QualityFactor79.NumberOfParametersPerBeam(i79) = fread(fid,1,'uint8'); %Npar
            ALLdata.EM_QualityFactor79.Spare(i79)                     = fread(fid,1,'uint8');
            
            % Repeate cycle. Nrx entries of: 4*Npar bits
            % DEV NOTE: This code was written July '21 based on Rev W of
            % the .all datagrams documentation, which lists the IFREMER QF
            % as the ONLY parameter in this loop, but the format makes
            % provision for additional parameters using "Npar". The code
            % written below SHOULD work whatever the number of parameters
            % but will only read the IMREMER QF. To read additional
            % parameters, you'll need to modify the code to make it like
            % other loops including fseek between data types and fseek
            % after the final jump.
            Nrx = ALLdata.EM_QualityFactor79.NumberOfReceiveBeams(i79);
            Npar = ALLdata.EM_QualityFactor79.NumberOfParametersPerBeam(i79);
            C = 4*Npar;
            ALLdata.EM_QualityFactor79.IFREMERqualityFactor{i79} = fread(fid,Nrx,'float32',C-4);

            ALLdata.EM_QualityFactor79.Spare2(i79)   = fread(fid,1,'uint8');
            ALLdata.EM_QualityFactor79.ETX(i79)      = fread(fid,1,'uint8');
            ALLdata.EM_QualityFactor79.CheckSum(i79) = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_QualityFactor79.ETX(i79)~=3
                error('wrong ETX value (ALLdata.EM_QualityFactor79)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 80 % 'POSITION (50H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_Position',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i80=i80+1; catch, i80=1; end
            
            % parsing
            ALLdata.EM_Position.NumberOfBytesInDatagram(i80)         = nbDatag;
            ALLdata.EM_Position.STX(i80)                             = stxDatag;
            ALLdata.EM_Position.TypeOfDatagram(i80)                  = datagTypeNumber;
            ALLdata.EM_Position.EMModelNumber(i80)                   = emNumber;
            ALLdata.EM_Position.Date(i80)                            = date;
            ALLdata.EM_Position.TimeSinceMidnightInMilliseconds(i80) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_Position.PositionCounter(i80)                 = number;
            ALLdata.EM_Position.SystemSerialNumber(i80)              = systemSerialNumber;
            
            ALLdata.EM_Position.Latitude(i80)                        = fread(fid,1,'int32');
            ALLdata.EM_Position.Longitude(i80)                       = fread(fid,1,'int32');
            ALLdata.EM_Position.MeasureOfPositionFixQuality(i80)     = fread(fid,1,'uint16');
            ALLdata.EM_Position.SpeedOfVesselOverGround(i80)         = fread(fid,1,'uint16');
            ALLdata.EM_Position.CourseOfVesselOverGround(i80)        = fread(fid,1,'uint16');
            ALLdata.EM_Position.HeadingOfVessel(i80)                 = fread(fid,1,'uint16');
            ALLdata.EM_Position.PositionSystemDescriptor(i80)        = fread(fid,1,'uint8');
            ALLdata.EM_Position.NumberOfBytesInInputDatagram(i80)    = fread(fid,1,'uint8');
            
            % next data size is variable. 34 bits of binary data already
            % recorded and 3 more to come = 37. read the rest as ASCII
            % (including SpareByte)
            ALLdata.EM_Position.PositionInputDatagramAsReceived{i80} = fscanf(fid, '%c', nbDatag-37);
            
            ALLdata.EM_Position.ETX(i80)                             = fread(fid,1,'uint8');
            ALLdata.EM_Position.CheckSum(i80)                        = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_Position.ETX(i80)~=3
                error('wrong ETX value (ALLdata.EM_Position)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 82 % 'RUNTIME PARAMETERS (52H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_Runtime',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i82=i82+1; catch, i82=1; end
            
            % parsing
            ALLdata.EM_Runtime.NumberOfBytesInDatagram(i82)                 = nbDatag;
            ALLdata.EM_Runtime.STX(i82)                                     = stxDatag;
            ALLdata.EM_Runtime.TypeOfDatagram(i82)                          = datagTypeNumber;
            ALLdata.EM_Runtime.EMModelNumber(i82)                           = emNumber;
            ALLdata.EM_Runtime.Date(i82)                                    = date;
            ALLdata.EM_Runtime.TimeSinceMidnightInMilliseconds(i82)         = timeSinceMidnightInMilliseconds;
            ALLdata.EM_Runtime.PingCounter(i82)                             = number;
            ALLdata.EM_Runtime.SystemSerialNumber(i82)                      = systemSerialNumber;
            
            ALLdata.EM_Runtime.OperatorStationStatus(i82)                   = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.ProcessingUnitStatus(i82)                    = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.BSPStatus(i82)                               = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.SonarHeadStatus(i82)                         = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.Mode(i82)                                    = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.FilterIdentifier(i82)                        = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.MinimumDepth(i82)                            = fread(fid,1,'uint16');
            ALLdata.EM_Runtime.MaximumDepth(i82)                            = fread(fid,1,'uint16');
            ALLdata.EM_Runtime.AbsorptionCoefficient(i82)                   = fread(fid,1,'uint16');
            ALLdata.EM_Runtime.TransmitPulseLength(i82)                     = fread(fid,1,'uint16');
            ALLdata.EM_Runtime.TransmitBeamwidth(i82)                       = fread(fid,1,'uint16');
            ALLdata.EM_Runtime.TransmitPowerReMaximum(i82)                  = fread(fid,1,'int8');
            ALLdata.EM_Runtime.ReceiveBeamwidth(i82)                        = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.ReceiveBandwidth(i82)                        = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.ReceiverFixedGainSetting(i82)                = fread(fid,1,'uint8'); % OR mode 2
            ALLdata.EM_Runtime.TVGLawCrossoverAngle(i82)                    = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.SourceOfSoundSpeedAtTransducer(i82)          = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.MaximumPortSwathWidth(i82)                   = fread(fid,1,'uint16');
            ALLdata.EM_Runtime.BeamSpacing(i82)                             = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.MaximumPortCoverage(i82)                     = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.YawAndPitchStabilizationMode(i82)            = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.MaximumStarboardCoverage(i82)                = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.MaximumStarboardSwathWidth(i82)              = fread(fid,1,'uint16');
            ALLdata.EM_Runtime.DurotongSpeed(i82)                           = fread(fid,1,'uint16'); % OR: ALLdata.EM_Runtime.TransmitAlongTilt(i82) = fread(fid,1,'int16');
            ALLdata.EM_Runtime.HiLoFrequencyAbsorptionCoefficientRatio(i82) = fread(fid,1,'uint8'); % OR filter identifier 2
            ALLdata.EM_Runtime.ETX(i82)                                     = fread(fid,1,'uint8');
            ALLdata.EM_Runtime.CheckSum(i82)                                = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_Runtime.ETX(i82)~=3
                error('wrong ETX value (ALLdata.EM_Runtime)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 83 % 'SEABED IMAGE DATAGRAM (53H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_SeabedImage',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i83=i83+1; catch, i83=1; end
            
            % parsing
            ALLdata.EM_SeabedImage.NumberOfBytesInDatagram(i83)         = nbDatag;
            ALLdata.EM_SeabedImage.STX(i83)                             = stxDatag;
            ALLdata.EM_SeabedImage.TypeOfDatagram(i83)                  = datagTypeNumber;
            ALLdata.EM_SeabedImage.EMModelNumber(i83)                   = emNumber;
            ALLdata.EM_SeabedImage.Date(i83)                            = date;
            ALLdata.EM_SeabedImage.TimeSinceMidnightInMilliseconds(i83) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_SeabedImage.PingCounter(i83)                     = number;
            ALLdata.EM_SeabedImage.SystemSerialNumber(i83)              = systemSerialNumber;
            
            ALLdata.EM_SeabedImage.MeanAbsorptionCoefficient(i83)       = fread(fid,1,'uint16'); % 'this field had earlier definition'
            ALLdata.EM_SeabedImage.PulseLength(i83)                     = fread(fid,1,'uint16'); % 'this field had earlier definition'
            ALLdata.EM_SeabedImage.RangeToNormalIncidence(i83)          = fread(fid,1,'uint16');
            ALLdata.EM_SeabedImage.StartRangeSampleOfTVGRamp(i83)       = fread(fid,1,'uint16');
            ALLdata.EM_SeabedImage.StopRangeSampleOfTVGRamp(i83)        = fread(fid,1,'uint16');
            ALLdata.EM_SeabedImage.NormalIncidenceBS(i83)               = fread(fid,1,'int8'); %BSN
            ALLdata.EM_SeabedImage.ObliqueBS(i83)                       = fread(fid,1,'int8'); %BSO
            ALLdata.EM_SeabedImage.TxBeamwidth(i83)                     = fread(fid,1,'uint16');
            ALLdata.EM_SeabedImage.TVGLawCrossoverAngle(i83)            = fread(fid,1,'uint8');
            ALLdata.EM_SeabedImage.NumberOfValidBeams(i83)              = fread(fid,1,'uint8'); %N
            
            % repeat cycle: N entries of 6 bits
            temp = ftell(fid);
            N = ALLdata.EM_SeabedImage.NumberOfValidBeams(i83);
            ALLdata.EM_SeabedImage.BeamIndexNumber{i83}             = fread(fid,N,'uint8',6-1);
            fseek(fid,temp+1,'bof'); % to next data type
            ALLdata.EM_SeabedImage.SortingDirection{i83}            = fread(fid,N,'int8',6-1);
            fseek(fid,temp+2,'bof'); % to next data type
            ALLdata.EM_SeabedImage.NumberOfSamplesPerBeam{i83}      = fread(fid,N,'uint16',6-2); %Ns
            fseek(fid,temp+4,'bof'); % to next data type
            ALLdata.EM_SeabedImage.CentreSampleNumber{i83}          = fread(fid,N,'uint16',6-2);
            fseek(fid,2-6,'cof'); % we need to come back after last jump
            
            % reading image data
            Ns = [ALLdata.EM_SeabedImage.NumberOfSamplesPerBeam{i83}];
            tmp = fread(fid,sum(Ns),'int8');
            ALLdata.EM_SeabedImage.SampleAmplitudes(i83).beam = mat2cell(tmp,Ns);
            
            % "spare byte if required to get even length (always 0 if used)"
            if floor(sum(Ns)/2) == sum(Ns)/2
                % even so far, since ETX is 1 byte, add a spare here
                ALLdata.EM_SeabedImage.Data.SpareByte(i83)              = fread(fid,1,'uint8');
            else
                % odd so far, since ETX is 1 bytes, no spare
                ALLdata.EM_SeabedImage.Data.SpareByte(i83) = NaN;
            end
            ALLdata.EM_SeabedImage.ETX(i83)                             = fread(fid,1,'uint8');
            ALLdata.EM_SeabedImage.CheckSum(i83)                        = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_SeabedImage.ETX(i83)~=3
                error('wrong ETX value (ALLdata.EM_SeabedImage)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 85 % 'SOUND SPEED PROFILE (55H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_SoundSpeedProfile',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i85=i85+1; catch, i85=1; end
            
            % parsing
            ALLdata.EM_SoundSpeedProfile.NumberOfBytesInDatagram(i85)                           = nbDatag;
            ALLdata.EM_SoundSpeedProfile.STX(i85)                                               = stxDatag;
            ALLdata.EM_SoundSpeedProfile.TypeOfDatagram(i85)                                    = datagTypeNumber;
            ALLdata.EM_SoundSpeedProfile.EMModelNumber(i85)                                     = emNumber;
            ALLdata.EM_SoundSpeedProfile.Date(i85)                                              = date;
            ALLdata.EM_SoundSpeedProfile.TimeSinceMidnightInMilliseconds(i85)                   = timeSinceMidnightInMilliseconds;
            ALLdata.EM_SoundSpeedProfile.ProfileCounter(i85)                                    = number;
            ALLdata.EM_SoundSpeedProfile.SystemSerialNumber(i85)                                = systemSerialNumber;
            
            ALLdata.EM_SoundSpeedProfile.DateWhenProfileWasMade(i85)                            = fread(fid,1,'uint32');
            ALLdata.EM_SoundSpeedProfile.TimeSinceMidnightInMillisecondsWhenProfileWasMade(i85) = fread(fid,1,'uint32');
            ALLdata.EM_SoundSpeedProfile.NumberOfEntries(i85)                                   = fread(fid,1,'uint16'); %N
            ALLdata.EM_SoundSpeedProfile.DepthResolution(i85)                                   = fread(fid,1,'uint16');
            
            % repeat cycle: N entries of 8 bits
            temp = ftell(fid);
            N = ALLdata.EM_SoundSpeedProfile.NumberOfEntries(i85);
            ALLdata.EM_SoundSpeedProfile.Depth{i85}      = fread(fid,N,'uint32',8-4);
            fseek(fid,temp+4,'bof'); % to next data type
            ALLdata.EM_SoundSpeedProfile.SoundSpeed{i85} = fread(fid,N,'uint32',8-4);
            fseek(fid,4-8,'cof'); % we need to come back after last jump
            
            ALLdata.EM_SoundSpeedProfile.SpareByte(i85) = fread(fid,1,'uint8');
            ALLdata.EM_SoundSpeedProfile.ETX(i85)       = fread(fid,1,'uint8');
            ALLdata.EM_SoundSpeedProfile.CheckSum(i85)  = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_SoundSpeedProfile.ETX(i85)~=3
                error('wrong ETX value (ALLdata.EM_SoundSpeedProfile)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 88 % 'XYZ 88 (58H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_XYZ88',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i88=i88+1; catch, i88=1; end
            
            % parsing
            ALLdata.EM_XYZ88.NumberOfBytesInDatagram(i88)         = nbDatag;
            ALLdata.EM_XYZ88.STX(i88)                             = stxDatag;
            ALLdata.EM_XYZ88.TypeOfDatagram(i88)                  = datagTypeNumber;
            ALLdata.EM_XYZ88.EMModelNumber(i88)                   = emNumber;
            ALLdata.EM_XYZ88.Date(i88)                            = date;
            ALLdata.EM_XYZ88.TimeSinceMidnightInMilliseconds(i88) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_XYZ88.PingCounter(i88)                     = number;
            ALLdata.EM_XYZ88.SystemSerialNumber(i88)              = systemSerialNumber;
            
            ALLdata.EM_XYZ88.HeadingOfVessel(i88)         = fread(fid,1,'uint16');
            ALLdata.EM_XYZ88.SoundSpeedAtTransducer(i88)  = fread(fid,1,'uint16');
            ALLdata.EM_XYZ88.TransmitTransducerDepth(i88) = fread(fid,1,'float32');
            ALLdata.EM_XYZ88.NumberOfBeamsInDatagram(i88) = fread(fid,1,'uint16');
            ALLdata.EM_XYZ88.NumberOfValidDetections(i88) = fread(fid,1,'uint16');
            ALLdata.EM_XYZ88.SamplingFrequencyInHz(i88)   = fread(fid,1,'float32');
            ALLdata.EM_XYZ88.ScanningInfo(i88)            = fread(fid,1,'uint8');
            ALLdata.EM_XYZ88.Spare1(i88)                  = fread(fid,1,'uint8');
            ALLdata.EM_XYZ88.Spare2(i88)                  = fread(fid,1,'uint8');
            ALLdata.EM_XYZ88.Spare3(i88)                  = fread(fid,1,'uint8');
            
            % repeat cycle: N entries of 20 bits
            temp = ftell(fid);
            C = 20;
            N = ALLdata.EM_XYZ88.NumberOfBeamsInDatagram(i88);
            ALLdata.EM_XYZ88.DepthZ{i88}                       = fread(fid,N,'float32',C-4); fseek(fid,temp+4,'bof');  % to next data type
            ALLdata.EM_XYZ88.AcrosstrackDistanceY{i88}         = fread(fid,N,'float32',C-4); fseek(fid,temp+8,'bof');  
            ALLdata.EM_XYZ88.AlongtrackDistanceX{i88}          = fread(fid,N,'float32',C-4); fseek(fid,temp+12,'bof'); 
            ALLdata.EM_XYZ88.DetectionWindowLength{i88}        = fread(fid,N,'uint16',C-2);  fseek(fid,temp+14,'bof'); 
            ALLdata.EM_XYZ88.QualityFactor{i88}                = fread(fid,N,'uint8',C-1);   fseek(fid,temp+15,'bof'); 
            ALLdata.EM_XYZ88.BeamIncidenceAngleAdjustment{i88} = fread(fid,N,'int8',C-1);    fseek(fid,temp+16,'bof'); 
            ALLdata.EM_XYZ88.DetectionInformation{i88}         = fread(fid,N,'uint8',C-1);   fseek(fid,temp+17,'bof'); 
            ALLdata.EM_XYZ88.RealTimeCleaningInformation{i88}  = fread(fid,N,'int8',C-1);    fseek(fid,temp+18,'bof');
            ALLdata.EM_XYZ88.ReflectivityBS{i88}               = fread(fid,N,'int16',C-2);   fseek(fid,2-C,'cof');     % we need to come back after last jump
            
            ALLdata.EM_XYZ88.Spare4(i88)   = fread(fid,1,'uint8');
            ALLdata.EM_XYZ88.ETX(i88)      = fread(fid,1,'uint8');
            ALLdata.EM_XYZ88.CheckSum(i88) = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_XYZ88.ETX(i88)~=3
                warning('wrong ETX value (ALLdata.EM_XYZ88)');
                fields_xyz=fieldnames(ALLdata.EM_XYZ88);
                for ifi=1:numel(fields_xyz)
                    if numel(ALLdata.EM_XYZ88.(fields_xyz{ifi}))>=i88
                        ALLdata.EM_XYZ88.(fields_xyz{ifi})(i88)=[];
                    end
                end
                i88=i88-1;
                parsed=0;
            else
                
                % confirm parsing
                parsed = 1;
            end
        case 89 % 'SEABED IMAGE DATA 89 (59H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_SeabedImage89',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i89=i89+1; catch, i89=1; end
            
            % parsing
            ALLdata.EM_SeabedImage89.NumberOfBytesInDatagram(i89)         = nbDatag;
            ALLdata.EM_SeabedImage89.STX(i89)                             = stxDatag;
            ALLdata.EM_SeabedImage89.TypeOfDatagram(i89)                  = datagTypeNumber;
            ALLdata.EM_SeabedImage89.EMModelNumber(i89)                   = emNumber;
            ALLdata.EM_SeabedImage89.Date(i89)                            = date;
            ALLdata.EM_SeabedImage89.TimeSinceMidnightInMilliseconds(i89) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_SeabedImage89.PingCounter(i89)                     = number;
            ALLdata.EM_SeabedImage89.SystemSerialNumber(i89)              = systemSerialNumber;
            
            ALLdata.EM_SeabedImage89.SamplingFrequencyInHz(i89)  = fread(fid,1,'float32');
            ALLdata.EM_SeabedImage89.RangeToNormalIncidence(i89) = fread(fid,1,'uint16');
            ALLdata.EM_SeabedImage89.NormalIncidenceBS(i89)      = fread(fid,1,'int16'); %BSN
            ALLdata.EM_SeabedImage89.ObliqueBS(i89)              = fread(fid,1,'int16'); %BSO
            ALLdata.EM_SeabedImage89.TxBeamwidthAlong(i89)       = fread(fid,1,'uint16');
            ALLdata.EM_SeabedImage89.TVGLawCrossoverAngle(i89)   = fread(fid,1,'uint16');
            ALLdata.EM_SeabedImage89.NumberOfValidBeams(i89)     = fread(fid,1,'uint16');
            
            % repeat cycle: N entries of 6 bits
            temp = ftell(fid);
            C = 6;
            N = ALLdata.EM_SeabedImage89.NumberOfValidBeams(i89);
            ALLdata.EM_SeabedImage89.SortingDirection{i89}       = fread(fid,N,'int8',C-1);   fseek(fid,temp+1,'bof'); % to next data type
            ALLdata.EM_SeabedImage89.DetectionInfo{i89}          = fread(fid,N,'uint8',C-1);  fseek(fid,temp+2,'bof');
            ALLdata.EM_SeabedImage89.NumberOfSamplesPerBeam{i89} = fread(fid,N,'uint16',C-2); fseek(fid,temp+4,'bof'); % Ns
            ALLdata.EM_SeabedImage89.CentreSampleNumber{i89}     = fread(fid,N,'uint16',C-2); fseek(fid,2-C,'cof');    % we need to come back after last jump
            
            % reading image data
            Ns = [ALLdata.EM_SeabedImage89.NumberOfSamplesPerBeam{i89}];
            tmp = fread(fid,sum(Ns),'int16');
            ALLdata.EM_SeabedImage89.SampleAmplitudes(i89).beam = mat2cell(tmp,Ns);
            
            ALLdata.EM_SeabedImage89.Spare(i89)    = fread(fid,1,'uint8');
            ALLdata.EM_SeabedImage89.ETX(i89)      = fread(fid,1,'uint8');
            ALLdata.EM_SeabedImage89.CheckSum(i89) = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_SeabedImage89.ETX(i89)~=3
                error('wrong ETX value (ALLdata.EM_SeabedImage89)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 102 % 'RAW RANGE AND BEAM ANGLE (f) (66H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_RawBeamRangeAngle',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i102=i102+1; catch, i102=1; end
            
            % parsing
            % ...to write...
            
        case 104 % 'DEPTH (PRESSURE) OR HEIGHT DATAGRAM (68H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_Height',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i104=i104+1; catch, i104=1; end
            
            % parsing
            ALLdata.EM_Height.NumberOfBytesInDatagram(i104)         = nbDatag;
            ALLdata.EM_Height.STX(i104)                             = stxDatag;
            ALLdata.EM_Height.TypeOfDatagram(i104)                  = datagTypeNumber;
            ALLdata.EM_Height.EMModelNumber(i104)                   = emNumber;
            ALLdata.EM_Height.Date(i104)                            = date;
            ALLdata.EM_Height.TimeSinceMidnightInMilliseconds(i104) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_Height.HeightCounter(i104)                   = number;
            ALLdata.EM_Height.SystemSerialNumber(i104)              = systemSerialNumber;
            
            ALLdata.EM_Height.Height(i104)                          = fread(fid,1,'int32');
            ALLdata.EM_Height.HeigthType(i104)                      = fread(fid,1,'uint8');
            ALLdata.EM_Height.ETX(i104)                             = fread(fid,1,'uint8');
            ALLdata.EM_Height.CheckSum(i104)                        = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_Height.ETX(i104)~=3
                error('wrong ETX value (ALLdata.EM_Height)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 105 % 'INSTALLATION PARAMETERS -  STOP (69H)'
            if ~(isempty(OutputFields)||any(strcmp('EM_InstallationStop',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i105=i105+1; catch, i105=1; end
            
            % parsing
            ALLdata.EM_InstallationStop.NumberOfBytesInDatagram(i105)         = nbDatag;
            ALLdata.EM_InstallationStop.STX(i105)                             = stxDatag;
            ALLdata.EM_InstallationStop.TypeOfDatagram(i105)                  = datagTypeNumber;
            ALLdata.EM_InstallationStop.EMModelNumber(i105)                   = emNumber;
            ALLdata.EM_InstallationStop.Date(i105)                            = date;
            ALLdata.EM_InstallationStop.TimeSinceMidnightInMilliseconds(i105) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_InstallationStop.SurveyLineNumber(i105)                = number;
            ALLdata.EM_InstallationStop.SystemSerialNumber(i105)              = systemSerialNumber;
            
            ALLdata.EM_InstallationStop.SerialNumberOfSecondSonarHead(i105)   = fread(fid,1,'uint16');
            
            % 18 bytes of binary data already recorded and 3 more to come = 21.
            % but nbDatag will always be even thanks to SpareByte. so
            % nbDatag is 22 if there is no ASCII data and more if there is
            % ASCII data. read the rest as ASCII (including SpareByte) with
            % 1 byte for 1 character.
            ALLdata.EM_InstallationStop.ASCIIData{i105}                       = fscanf(fid, '%c', nbDatag-21);
            
            ALLdata.EM_InstallationStop.ETX(i105)                             = fread(fid,1,'uint8');
            ALLdata.EM_InstallationStop.CheckSum(i105)                        = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_InstallationStop.ETX(i105)~=3
                error('wrong ETX value (ALLdata.EM_InstallationStop)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 107 % 'WATER COLUMN DATAGRAM (6BH)'
            if ~(isempty(OutputFields)||any(strcmp('EM_WaterColumn',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i107=i107+1; catch, i107=1; end
            
            % ----- IMPORTANT NOTE ----------------------------------------
            % This datagram's data is too to be stored in memory. Instead,
            % we record the metadata and the position-in-file location of
            % the data, which be extracted and stored in binary format at
            % the next stage of data conversion.
            % -------------------------------------------------------------
            
            % parsing
            ALLdata.EM_WaterColumn.NumberOfBytesInDatagram(i107) = nbDatag;
            
            % position at STX identifier
            pos_1 = ftell(fid);
            
            % fields already read
            ALLdata.EM_WaterColumn.STX(i107)                             = stxDatag;
            ALLdata.EM_WaterColumn.TypeOfDatagram(i107)                  = datagTypeNumber;
            ALLdata.EM_WaterColumn.EMModelNumber(i107)                   = emNumber;
            ALLdata.EM_WaterColumn.Date(i107)                            = date;
            ALLdata.EM_WaterColumn.TimeSinceMidnightInMilliseconds(i107) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_WaterColumn.PingCounter(i107)                     = number;
            ALLdata.EM_WaterColumn.SystemSerialNumber(i107)              = systemSerialNumber;
            
            % remaining fields in start of datagram
            ALLdata.EM_WaterColumn.NumberOfDatagrams(i107)           = fread(fid,1,'uint16');
            ALLdata.EM_WaterColumn.DatagramNumbers(i107)             = fread(fid,1,'uint16');
            ALLdata.EM_WaterColumn.NumberOfTransmitSectors(i107)     = fread(fid,1,'uint16'); %Ntx
            ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(i107)   = fread(fid,1,'uint16');
            ALLdata.EM_WaterColumn.NumberOfBeamsInThisDatagram(i107) = fread(fid,1,'uint16'); %Nrx
            ALLdata.EM_WaterColumn.SoundSpeed(i107)                  = fread(fid,1,'uint16'); %SS
            ALLdata.EM_WaterColumn.SamplingFrequency(i107)           = fread(fid,1,'uint32'); %SF
            ALLdata.EM_WaterColumn.TXTimeHeave(i107)                 = fread(fid,1,'int16');
            ALLdata.EM_WaterColumn.TVGFunctionApplied(i107)          = fread(fid,1,'uint8'); %X
            ALLdata.EM_WaterColumn.TVGOffset(i107)                   = fread(fid,1,'int8'); %C
            ALLdata.EM_WaterColumn.ScanningInfo(i107)                = fread(fid,1,'uint8');
            ALLdata.EM_WaterColumn.Spare1(i107)                      = fread(fid,1,'uint8');
            ALLdata.EM_WaterColumn.Spare2(i107)                      = fread(fid,1,'uint8');
            ALLdata.EM_WaterColumn.Spare3(i107)                      = fread(fid,1,'uint8');
            
            % --- repeat cycle #1 -----------------------------------------
            % Ntx entries of 6 bits
            temp = ftell(fid);
            C = 6;
            Ntx = ALLdata.EM_WaterColumn.NumberOfTransmitSectors(i107);
            ALLdata.EM_WaterColumn.TiltAngle{i107}            = fread(fid,Ntx,'int16',C-2);
            fseek(fid,temp+2,'bof'); % to next data type
            ALLdata.EM_WaterColumn.CenterFrequency{i107}      = fread(fid,Ntx,'uint16',C-2);
            fseek(fid,temp+4,'bof'); % to next data type
            ALLdata.EM_WaterColumn.TransmitSectorNumber{i107} = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,temp+5,'bof'); % to next data type
            ALLdata.EM_WaterColumn.Spare{i107}                = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,1-C,'cof'); % we need to come back after last jump
            % --- end of repeat cycle #1 ----------------------------------
            
            % --- repeat cycle #2 -----------------------------------------
            % Nrx entries of a possibly variable number of bits.
            Nrx = ALLdata.EM_WaterColumn.NumberOfBeamsInThisDatagram(i107);
            
            % initialize flag of parsing error
            wc_parsing_error = 0;
            
            % initialize outputs
            ALLdata.EM_WaterColumn.BeamPointingAngle{i107}       = nan(1,Nrx);
            ALLdata.EM_WaterColumn.StartRangeSampleNumber{i107}  = nan(1,Nrx);
            ALLdata.EM_WaterColumn.NumberOfSamples{i107}         = nan(1,Nrx);
            ALLdata.EM_WaterColumn.DetectedRangeInSamples{i107}  = nan(1,Nrx);
            ALLdata.EM_WaterColumn.TransmitSectorNumber2{i107}   = nan(1,Nrx);
            ALLdata.EM_WaterColumn.BeamNumber{i107}              = nan(1,Nrx);
            ALLdata.EM_WaterColumn.SampleAmplitudePosition{i107} = nan(1,Nrx);
            Ns = zeros(1,Nrx);
            
            % now parse the data
            for jj = 1:Nrx
                
                try
                    
                    ALLdata.EM_WaterColumn.BeamPointingAngle{i107}(jj)      = fread(fid,1,'int16');
                    ALLdata.EM_WaterColumn.StartRangeSampleNumber{i107}(jj) = fread(fid,1,'uint16');
                    ALLdata.EM_WaterColumn.NumberOfSamples{i107}(jj)        = fread(fid,1,'uint16'); %Ns
                    ALLdata.EM_WaterColumn.DetectedRangeInSamples{i107}(jj) = fread(fid,1,'uint16'); %DR
                    ALLdata.EM_WaterColumn.TransmitSectorNumber2{i107}(jj)  = fread(fid,1,'uint8');
                    ALLdata.EM_WaterColumn.BeamNumber{i107}(jj)             = fread(fid,1,'uint8');
                    
                    % record number of samples
                    Ns(jj) = ALLdata.EM_WaterColumn.NumberOfSamples{i107}(jj);
                    
                    % Next are the samples data themselves, which you could
                    % record with:
                    % ALLdata.EM_WaterColumn.SampleAmplitude{i107}{jj} = fread(fid,Ns(jj),'int8');
                    % But instead, we're only going to record the position
                    % of the start of data:
                    ALLdata.EM_WaterColumn.SampleAmplitudePosition{i107}(jj) = ftell(fid);
                    
                    % and since we did not read that data, we need to
                    % move manually onto the next beam:
                    fseek(fid,Ns(jj),'cof');
                    
                catch
                    
                    % if there's any issue in the recording, flag and exit
                    % the loop
                    ALLdata.EM_WaterColumn.NumberOfSamples{i107}(jj) = 0;
                    Ns(jj) = 0;
                    wc_parsing_error = 1;
                    continue;
                    
                end
                
            end
            % --- end of repeat cycle #2 ----------------------------------
            
            % read the rest of the datagram. If all went well should be 3
            % or 4 bytes
            pos_end = ftell(fid);
            tmp_end = fread(fid,nbDatag-(pos_end-pos_1+1)-15,'int8=>int8');
            
            % "spare byte if required to get even length (always 0 if used)"
            if floor((Nrx*10+sum(Ns))/2) == (Nrx*10+sum(Ns))/2
                % all data parsed so far is an even number. Since ETX is 1
                % byte, add a spare byte here
                ALLdata.EM_WaterColumn.Spare4(i107) = double(typecast(tmp_end(1),'uint8'));
                
                % and remove it from tmp_end
                tmp_end(1) = [];
            else
                % odd. No added spare
                ALLdata.EM_WaterColumn.Spare4(i107) = NaN;
            end
            
            % record end of datagram
            ALLdata.EM_WaterColumn.ETX(i107)      = typecast(tmp_end(1),'uint8');
            ALLdata.EM_WaterColumn.CheckSum(i107) = typecast(tmp_end(2:3),'uint16');
            
            % ETX check
            if ALLdata.EM_WaterColumn.ETX(i107)~=3
                wc_parsing_error = 1;
            end
            
            if wc_parsing_error == 0
                % HERE if data parsing all went well
                
                % confirm parsing and exit
                parsed = 1;
                
            else
                % HERE if data parsing failed, add a blank datagram in
                % output
                
                % copy field names of previous entries
                fields_wc = fieldnames(ALLdata.EM_WaterColumn);
                
                % add blanks fields for those missing
                for ifi = 1:numel(fields_wc)
                    if numel(ALLdata.EM_WaterColumn.(fields_wc{ifi})) >= i107
                        ALLdata.EM_WaterColumn.(fields_wc{ifi})(i107) = [];
                    end
                end
                
                % failed parsing flag
                parsed = 0;
                
            end
            
        case 110 % 'NETWORK ATTITUDE VELOCITY DATAGRAM 110 (6EH)'
            if ~(isempty(OutputFields)||any(strcmp('EM_NetworkAttitude',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i110=i110+1; catch, i110=1; end
            
            % parsing
            ALLdata.EM_NetworkAttitude.NumberOfBytesInDatagram(i110)         = nbDatag;
            ALLdata.EM_NetworkAttitude.STX(i110)                             = stxDatag;
            ALLdata.EM_NetworkAttitude.TypeOfDatagram(i110)                  = datagTypeNumber;
            ALLdata.EM_NetworkAttitude.EMModelNumber(i110)                   = emNumber;
            ALLdata.EM_NetworkAttitude.Date(i110)                            = date;
            ALLdata.EM_NetworkAttitude.TimeSinceMidnightInMilliseconds(i110) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_NetworkAttitude.NetworkAttitudeCounter(i110)          = number;
            ALLdata.EM_NetworkAttitude.SystemSerialNumber(i110)              = systemSerialNumber;
            
            ALLdata.EM_NetworkAttitude.NumberOfEntries(i110)        = fread(fid,1,'uint16'); %N
            ALLdata.EM_NetworkAttitude.SensorSystemDescriptor(i110) = fread(fid,1,'int8');
            ALLdata.EM_NetworkAttitude.Spare(i110)                  = fread(fid,1,'uint8');
            
            % repeat cycle: N entries of a variable number of bits. Using a for loop
            N = ALLdata.EM_NetworkAttitude.NumberOfEntries(i110);
            Nx = nan(1,N);
            for jj = 1:N
                ALLdata.EM_NetworkAttitude.TimeInMillisecondsSinceRecordStart{i110}(jj) = fread(fid,1,'uint16');
                ALLdata.EM_NetworkAttitude.Roll{i110}(jj)                               = fread(fid,1,'int16');
                ALLdata.EM_NetworkAttitude.Pitch{i110}(jj)                              = fread(fid,1,'int16');
                ALLdata.EM_NetworkAttitude.Heave{i110}(jj)                              = fread(fid,1,'int16');
                ALLdata.EM_NetworkAttitude.Heading{i110}(jj)                            = fread(fid,1,'uint16');
                ALLdata.EM_NetworkAttitude.NumberOfBytesInInputDatagrams{i110}(jj)      = fread(fid,1,'uint8'); %Nx
                Nx(jj) = ALLdata.EM_NetworkAttitude.NumberOfBytesInInputDatagrams{i110}(jj);
                ALLdata.EM_NetworkAttitude.NetworkAttitudeInputDatagramAsReceived{i110}{jj} = fread(fid,Nx(jj),'uint8');
            end
            
            % "spare byte if required to get even length (always 0 if used)"
            if floor((N*11+sum(Nx))/2) == (N*11+sum(Nx))/2
                % even so far, since ETX is 1 byte, add a spare here
                ALLdata.EM_NetworkAttitude.Spare2(i110) = fread(fid,1,'uint8');
            else
                % odd so far, since ETX is 1 bytes, no spare
                ALLdata.EM_NetworkAttitude.Spare2(i110) = NaN;
            end
            
            ALLdata.EM_NetworkAttitude.ETX(i110)      = fread(fid,1,'uint8');
            ALLdata.EM_NetworkAttitude.CheckSum(i110) = fread(fid,1,'uint16');
            
            % ETX check
            if ALLdata.EM_NetworkAttitude.ETX(i110)~=3
                error('wrong ETX value (ALLdata.EM_NetworkAttitude)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 114 %'AMPLITUDE AND PHASE WC DATAGRAM 114 (72H)';
            if ~(isempty(OutputFields)||any(strcmp('EM_AmpPhase',OutputFields)))
                continue;
            end
            % counter for this type of datagram
            try i114=i114+1; catch, i114=1; end
            
            % ----- IMPORTANT NOTE ----------------------------------------
            % This datagram's data is too to be stored in memory. Instead,
            % we record the metadata and the position-in-file location of
            % the data, which be extracted and stored in binary format at
            % the next stage of data conversion.
            % -------------------------------------------------------------
            
            % parsing
            ALLdata.EM_AmpPhase.NumberOfBytesInDatagram(i114) = nbDatag;
            
            % position at STX identifier
            pos_1 = ftell(fid);
            
            % fields already read
            ALLdata.EM_AmpPhase.STX(i114)                             = stxDatag;
            ALLdata.EM_AmpPhase.TypeOfDatagram(i114)                  = datagTypeNumber;
            ALLdata.EM_AmpPhase.EMModelNumber(i114)                   = emNumber;
            ALLdata.EM_AmpPhase.Date(i114)                            = date;
            ALLdata.EM_AmpPhase.TimeSinceMidnightInMilliseconds(i114) = timeSinceMidnightInMilliseconds;
            ALLdata.EM_AmpPhase.PingCounter(i114)                     = number;
            ALLdata.EM_AmpPhase.SystemSerialNumber(i114)              = systemSerialNumber;
            
            % remaining fields in start of datagram
            ALLdata.EM_AmpPhase.NumberOfDatagrams(i114)           = fread(fid,1,'uint16');
            ALLdata.EM_AmpPhase.DatagramNumbers(i114)             = fread(fid,1,'uint16');
            ALLdata.EM_AmpPhase.NumberOfTransmitSectors(i114)     = fread(fid,1,'uint16'); %Ntx
            ALLdata.EM_AmpPhase.TotalNumberOfReceiveBeams(i114)   = fread(fid,1,'uint16');
            ALLdata.EM_AmpPhase.NumberOfBeamsInThisDatagram(i114) = fread(fid,1,'uint16'); %Nrx
            ALLdata.EM_AmpPhase.SoundSpeed(i114)                  = fread(fid,1,'uint16'); %SS
            ALLdata.EM_AmpPhase.SamplingFrequency(i114)           = fread(fid,1,'uint32'); %SF
            ALLdata.EM_AmpPhase.TXTimeHeave(i114)                 = fread(fid,1,'int16');
            ALLdata.EM_AmpPhase.TVGFunctionApplied(i114)          = fread(fid,1,'uint8'); %X
            ALLdata.EM_AmpPhase.TVGOffset(i114)                   = fread(fid,1,'uint8'); %C
            ALLdata.EM_AmpPhase.ScanningInfo(i114)                = fread(fid,1,'uint8');
            ALLdata.EM_AmpPhase.Spare1(i114)                      = fread(fid,1,'uint8');
            ALLdata.EM_AmpPhase.Spare2(i114)                      = fread(fid,1,'uint8');
            ALLdata.EM_AmpPhase.Spare3(i114)                      = fread(fid,1,'uint8');
            
            % --- repeat cycle #1 -----------------------------------------
            % Ntx entries of 6 bits
            temp = ftell(fid);
            C = 6;
            Ntx = ALLdata.EM_AmpPhase.NumberOfTransmitSectors(i114);
            ALLdata.EM_AmpPhase.TiltAngle{i114}            = fread(fid,Ntx,'int16',C-2);
            fseek(fid,temp+2,'bof'); % to next data type
            ALLdata.EM_AmpPhase.CenterFrequency{i114}      = fread(fid,Ntx,'uint16',C-2);
            fseek(fid,temp+4,'bof'); % to next data type
            ALLdata.EM_AmpPhase.TransmitSectorNumber{i114} = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,temp+5,'bof'); % to next data type
            ALLdata.EM_AmpPhase.Spare{i114}                = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,1-C,'cof'); % we need to come back after last jump
            % --- end of repeat cycle #1 ----------------------------------
            
            % --- repeat cycle #2 -----------------------------------------
            % Nrx entries of a possibly variable number of bits.
            Nrx = ALLdata.EM_AmpPhase.NumberOfBeamsInThisDatagram(i114);
            
            pos_2 = ftell(fid); % position at start of data
            tmp = fread(fid,nbDatag-(pos_2-pos_1+1)-15,'int8'); % read all that data block
            tmp = int8(tmp');
            id = 0; % offset for start of each Nrx block
            wc_parsing_error = 0; % initialize flag
            
            % initialize outputs
            ALLdata.EM_AmpPhase.BeamPointingAngle{i114}             = nan(1,Nrx);
            ALLdata.EM_AmpPhase.StartRangeSampleNumber{i114}        = nan(1,Nrx);
            ALLdata.EM_AmpPhase.NumberOfSamples{i114}               = nan(1,Nrx);
            ALLdata.EM_AmpPhase.DetectedRangeInSamples{i114}        = nan(1,Nrx);
            ALLdata.EM_AmpPhase.TransmitSectorNumber2{i114}         = nan(1,Nrx);
            ALLdata.EM_AmpPhase.BeamNumber{i114}                    = nan(1,Nrx);
            ALLdata.EM_AmpPhase.SamplePhaseAmplitudePosition{i114}  = nan(1,Nrx);
            Ns = zeros(1,Nrx);
            
            % now parse the data
            for jj = 1:Nrx
                
                try
                    
                    ALLdata.EM_AmpPhase.BeamPointingAngle{i114}(jj)             = typecast(tmp(1+id:2+id),'int16');
                    ALLdata.EM_AmpPhase.StartRangeSampleNumber{i114}(jj)        = typecast(tmp(3+id:4+id),'uint16');
                    ALLdata.EM_AmpPhase.NumberOfSamples{i114}(jj)               = typecast(tmp(5+id:6+id),'uint16');
                    ALLdata.EM_AmpPhase.DetectedRangeInSamples{i114}(jj)        = typecast(tmp(7+id:8+id),'uint16');
                    ALLdata.EM_AmpPhase.TransmitSectorNumber2{i114}(jj)         = typecast(tmp(9+id),'uint8');
                    ALLdata.EM_AmpPhase.BeamNumber{i114}(jj)                    = typecast(tmp(10+id),'uint8');
                    
                    % recording data position instead of data themselves
                    ALLdata.EM_AmpPhase.SamplePhaseAmplitudePosition{i114}(jj) = pos_2 + id + 10;
                    % actual data recording would be:
                    % ALLdata.EM_AmpPhase.SampleAmplitude{i114}{jj} = tmp((11+id):(11+id+Ns(jj)-1));
                    
                    if ALLdata.EM_AmpPhase.NumberOfSamples{i114}(jj) < 2^16/2
                        Ns(jj) = ALLdata.EM_AmpPhase.NumberOfSamples{i114}(jj);
                    else
                        % error in number of samples
                        ALLdata.EM_AmpPhase.NumberOfSamples{i114}(jj) = 0;
                        Ns(jj) = 0;
                    end
                    
                    % offset to next jj block
                    id = 10*jj + 4*sum(Ns);
                    
                catch
                    
                    % if there's any issue in the recording, flag and exit
                    % the loop
                    ALLdata.EM_AmpPhase.NumberOfSamples{i114}(jj) = 0;
                    Ns(jj) = 0;
                    wc_parsing_error = 1;
                    continue;
                    
                end
                
            end
            % --- end of repeat cycle #2 ----------------------------------
            
            if wc_parsing_error == 0
                % HERE if data parsing all went well
                
                % "spare byte if required to get even length (always 0 if used)"
                if floor((Nrx*10+4*sum(Ns))/2) == (Nrx*10+4*sum(Ns))/2
                    % even so far, since ETX is 1 byte, add a spare here
                    ALLdata.EM_AmpPhase.Spare4(i114) = double(typecast(tmp(1+id),'uint8'));
                    id = id+1;
                else
                    % odd so far, since ETX is 1 bytes, no spare
                    ALLdata.EM_AmpPhase.Spare4(i114) = NaN;
                end
                
                % end of datagram
                ALLdata.EM_AmpPhase.ETX(i114)      = typecast(tmp(id+1),'uint8');
                ALLdata.EM_AmpPhase.CheckSum(i114) = typecast(tmp(2+id:3+id),'uint16');
                
                % ETX check
                if ALLdata.EM_AmpPhase.ETX(i114)~=3
                    error('wrong ETX value (ALLdata.EM_AmpPhase)');
                end
                
                % confirm parsing
                parsed = 1;
                
            else
                % HERE if data parsing failed, add a blank datagram in
                % output
                
                % copy field names of previous entries
                fields_ap = fieldnames(ALLdata.EM_AmpPhase);
                
                % add blanks fields for those missing
                for ifi = 1:numel(fields_ap)
                    if numel(ALLdata.EM_AmpPhase.(fields_ap{ifi})) >= i114
                        ALLdata.EM_AmpPhase.(fields_ap{ifi})(i114) = [];
                    end
                end
                
                i114 = i114-1; % XXX1 if we do that, then we'll rewrite over the blank record we just entered??
                parsed = 0;
                
            end
            
        otherwise
            
            % datagTypeNumber is not recognized yet
            
    end
    
    % modify parsed status in info
    ALLfileinfo.parsed(iDatag,1) = parsed;
    
    % communicate progress
    comms.progress(iDatag,nDatagsToPars);

end


%% close fid
fclose(fid);


%% modify the ping numbers in case they have gone over intmax('uint16')

% do with all datagram types that have ping numbers
All_fields = fieldnames(ALLdata);
for ifif = 1:numel(All_fields)
    if isstruct(ALLdata.(All_fields{ifif})) && isfield(ALLdata.(All_fields{ifif}),'PingCounter')
        
        % list of ping numbers
        pings = ALLdata.(All_fields{ifif}).PingCounter;
        
        % search for indices where pings go from 65535 to 0
        % NOTE - the following works well when you have all pings in a
        % datagram type (like XYZ88), but not for datagram types that don't
        % have all pings (like Runtime Paramters). So changing the
        % following to detect a large drop in pingCounter instead.
        % idx_rollover = find(diff(pings)==-double(intmax('uint16')));
        idx_rollover = find(diff(pings)<=-100);
        
        % new ping numbers
        idx_high = [idx_rollover+1 numel(pings)];
        for iu = 1:numel(idx_high)-1
            pings(idx_high(iu):idx_high(iu+1)) = pings(idx_high(iu):idx_high(iu+1))+iu*double(intmax('uint16'))+1;
        end
        
        % save back into structure
        ALLdata.(All_fields{ifif}).PingCounter = pings;
    end
end


%% add info to parsed data
ALLdata.info = ALLfileinfo;


%% end message
comms.finish('Done');
