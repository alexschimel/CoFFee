%% CFF_convert_all_to_mat.m
%
% WARNING: THIS FUNCTION IS OBSOLETE AND IS NOT SUPPORTED ANYMORE. 
% USE CFF_convert_all_to_mat_v2 instead
%
% Converts Kongsberg EM series binary .all or .wcd data files (ALL) to a
% Matlab format (MAT), conserving all information from the original as it
% is.
%
%% Help
%
% *USE*
%
% ...
%
% *INPUT VARIABLES*
%
% REQUIRED:
% * |ALLfilename|: string filename to parse (extension in .all or .wcd)
%
% OPTIONAL:
% * |MATfilename|: string filename to output. If not provided (default),
% the MAT file is saved in same folder as input file and bears the same
% name except for its extension changed to '.mat'. 
%
% *OUTPUT VARIABLES*
%
% * |ALLfileinfo|: structure for description of the datagrams in input
% file. Fields are:  
%   * |ALLfilename|: input file name
%   * |filesize|: file size in bytes
%   * |datagsizeformat|: endianness of the datagram size field 'b' or 'l'
%   * |datagramsformat|: endianness of the datagrams 'b' or 'l'
%   * |datagNumberInFile|: 
%   * |datagTypeNumber|: for each datagram, SIMRAD datagram type in decimal
%   * |datagTypeText|: for each datagram, SIMRAD datagram type description
%   * |parsed|: for each datagram, 1 if datagram has been parsed, 0 if not
%   * |counter|: the counter of this type of datagram in the file (ie
%   first datagram of that type is 1 and last datagram is the total number
%   of datagrams of that type).
%   * |number|: the number/counter found in the datagram (usually
%   different to counter)
%   * |size|: for each datagram, datagram size in bytes
%   * |syncCounter|: for each datagram, the number of bytes founds between
%   this datagram and the previous one (any number different than zero
%   indicates a sunc error
%   * |emNumber|: EM Model number (eg 2045 for EM2040c)
%   * |date|: datagram date in YYYMMDD
%   * |timeSinceMidnightInMilliseconds|: time since midnight in msecs 
%
% *RESEARCH NOTES*
%
% * PU Status output datagram structure seems different to the datagram
% manual description. Find the good description.#edit 21aug2013: updated to
% Rev Q. Need to be checked though.# 
%
% * code currently lists the EM model numbers supported as a test for sync.
% Add your model number in the list if it's not currently there. It would
% be better to remove this test and try to sync on ETX and Checksum
% instead.
%
% * to print out GPS datagrams (GGA), type: cell2mat(EM_Position.PositionInputDatagramAsReceived')
%
% * attitude datagrams contain several values of attitude. to pad cell values to allow plot, type:
% for ii = 1:length(EM_Attitude.TypeOfDatagram)
%     EM_Attitude.TimeInMillisecondsSinceRecordStart{ii} = [EM_Attitude.TimeInMillisecondsSinceRecordStart{ii};nan(max(EM_Attitude.NumberOfEntries)-length(EM_Attitude.TimeInMillisecondsSinceRecordStart{ii}),1)];
%     EM_Attitude.SensorStatus{ii} = [EM_Attitude.SensorStatus{ii};nan(max(EM_Attitude.NumberOfEntries)-length(EM_Attitude.SensorStatus{ii}),1)];
%     EM_Attitude.Roll{ii} = [EM_Attitude.Roll{ii};nan(max(EM_Attitude.NumberOfEntries)-length(EM_Attitude.Roll{ii}),1)];
%     EM_Attitude.Pitch{ii} = [EM_Attitude.Pitch{ii};nan(max(EM_Attitude.NumberOfEntries)-length(EM_Attitude.Pitch{ii}),1)];
%     EM_Attitude.Heave{ii} = [EM_Attitude.Heave{ii};nan(max(EM_Attitude.NumberOfEntries)-length(EM_Attitude.Heave{ii}),1)];
%     EM_Attitude.Heading{ii} = [EM_Attitude.Heading{ii};nan(max(EM_Attitude.NumberOfEntries)-length(EM_Attitude.Heading{ii}),1)];
% end
% % example: figure; grid on; plot(cell2mat(EM_Attitude.Roll))
%
% * to show soundspeed profile (if existing), type: figure;plot(cell2mat(EM_SoundSpeedProfile.Depth)./100, cell2mat(EM_SoundSpeedProfile.SoundSpeed)./10); grid on
%
% *NEW FEATURES*
%
% * 2017-09-28: Updated header to new format. Still obsolete function. Use CFF_convert_all_to_mat_v2.m (Alex Schimel).
% * 2015-09-30: Function made obsolete by convert_all_to_mat_v2.m. Added warning (Alex Schimel).
% - 2015-09-30: 
%   - inputParser
%   - added new fields to ALLfileinfo and moved it outside of the switch
% - 2014-04-28 (v1.2):
%   - first added to SVN repository
%   - test existence of output directory and make it if not
% - v1.1:
%   - PU Status output datagram updated to Rev Q (but not tested)
%   - XYZ 88, Seabed Image 89, Raw Range and Angle 78, Water Column
%   Datagram & Network Attitude Velocity Datagram 110 now supported.
% - v1.0:
%   - NA
% - v0.4.2:
%   - added synccounter
%   - changed ALLfileinfo field dimensions from 1 x nbping to nbping x 1
%   - very small change on test for input variables, for consistency with convxtf2all
% - v0.4:
%   - improved comments and general code
%   - test for byte ordering
%   - some EM_* structure names have been changed
%   - synchronization
%   - ETX check
%   - optional output information file
%   - separated start and stop installation parameters
% - v0.3.1:
%   - optional output MAT file name
%   - optional input machineformat
% - v0.2:
%   - optional soundspeed profiles supported
%
% *EXAMPLE*
%
% ALLfilename = '.\DATA\RAW\0001_20140213_052736_Yolla.all';
% ALLfileinfo = CFF_convert_all_to_mat(ALLfilename, 'temp.mat');
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alex Schimel, Deakin University, NIWA.

%% Function
function [ALLfileinfo] = CFF_convert_all_to_mat(ALLfilename, varargin)

warning('THIS FUNCTION (CFF_convert_all_to_mat) IS OBSOLETE AND IS NOT SUPPORTED ANYMORE. USE CFF_convert_all_to_mat_v2 instead');

%% Input arguments management using inputParser
p = inputParser;

% ALLfilename to parse as only required argument. Test for file existence and
% extension.
argName = 'ALLfilename';
argCheck = @(x) exist(x,'file') && any(strcmp(CFF_file_extension(x),{'.all','.ALL','.wcd','.WCD'}));
addRequired(p,argName,argCheck);

% MATfilename output as only optional argument.
argName = 'MATfilename';
argDefault = [ALLfilename(1:end-3) 'mat'];
argCheck = @isstr;
addOptional(p,argName,argDefault,argCheck)

% now parse inputs
parse(p,ALLfilename,varargin{:})

% and get results
ALLfilename = p.Results.ALLfilename;
MATfilename = p.Results.MATfilename;

% if output folder doesn't exist, create it
if ~exist(fileparts(MATfilename),'dir') && ~isempty(fileparts(MATfilename))
    mkdir(fileparts(MATfilename));
end

%% supported systems:
emNumberList = [300; 2045; 3000; 3002; 3020]; %2045 is 2040c


%% Checking byte ordering
% - Luciano's all files are in 'b'
% - Erik's all file is in 'l'
% - my converted files are in 'b'
% - DataDistrib files are in 'b' but datagram size in 'l'! We need to
% separate the byte ordering tests for these two types.

% opening file
[fid,~] = fopen(ALLfilename, 'r');

% number of bytes in file
temp = fread(fid,inf,'uint8');
filesize = length(temp);
clear temp
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
        continue
    end
    
    % reset the datagram counter and parsed switch
    counter = NaN;
    parsed = 0;
    
    switch datagTypeNumber
        
        case 49
            
            datagTypeText = 'PU STATUS OUTPUT (31H)';
            
            % counter for this type of datagram
            try i49=i49+1; catch, i49=1; end
            counter = i49;

% SOMETHING WRONG WITH THIS DATAGRAM, NEW TEMPLATE? REWRITE USING LATEST KONGSBERG DOCUMENTATION
%             % parsing
%             EM_PUStatus.STX(i49)                                    = stxDatag;
%             EM_PUStatus.TypeOfDatagram(i49)                         = datagTypeNumber;
%             EM_PUStatus.EMModelNumber(i49)                          = emNumber;
%             EM_PUStatus.Date(i49)                                   = date;
%             EM_PUStatus.TimeSinceMidnightInMilliseconds(i49)        = timeSinceMidnightInMilliseconds;
%             EM_PUStatus.StatusDatagramCounter(i49)                  = number;
%             EM_PUStatus.SystemSerialNumber(i49)                     = systemSerialNumber;
%             
%             EM_PUStatus.PingRate(i49)                               = fread(fid,1,'uint16');
%             EM_PUStatus.PingCounterOfLatestPing(i49)                = fread(fid,1,'uint16');
%             EM_PUStatus.DistanceBetweenSwath(i49)                   = fread(fid,1,'uint8');
%             EM_PUStatus.SensorInputStatusUDPPort2(i49)              = fread(fid,1,'uint32');
%             EM_PUStatus.SensorInputStatusSerialPort1(i49)           = fread(fid,1,'uint32');
%             EM_PUStatus.SensorInputStatusSerialPort2(i49)           = fread(fid,1,'uint32');
%             EM_PUStatus.SensorInputStatusSerialPort3(i49)           = fread(fid,1,'uint32');
%             EM_PUStatus.SensorInputStatusSerialPort4(i49)           = fread(fid,1,'uint32');
%             EM_PUStatus.PPSStatus(i49)                              = fread(fid,1,'int8');
%             EM_PUStatus.PositionStatus(i49)                         = fread(fid,1,'int8');
%             EM_PUStatus.AttitudeStatus(i49)                         = fread(fid,1,'int8');
%             EM_PUStatus.ClockStatus(i49)                            = fread(fid,1,'int8');
%             EM_PUStatus.HeadingStatus (i49)                         = fread(fid,1,'int8');
%             EM_PUStatus.PUStatus(i49)                               = fread(fid,1,'uint8');
%             EM_PUStatus.LastReceivedHeading(i49)                    = fread(fid,1,'uint16');
%             EM_PUStatus.LastReceivedRoll(i49)                       = fread(fid,1,'int16');
%             EM_PUStatus.LastReceivedPitch(i49)                      = fread(fid,1,'int16');
%             EM_PUStatus.LastReceivedHeave(i49)                      = fread(fid,1,'int16');
%             EM_PUStatus.SoundSpeedAtTransducer(i49)                 = fread(fid,1,'uint16');
%             EM_PUStatus.LastReceivedDepth(i49)                      = fread(fid,1,'uint32');
%             EM_PUStatus.AlongShipVelocity(i49)                      = fread(fid,1,'int16');
%             EM_PUStatus.AttitudeVelocitySensor(i49)                 = fread(fid,1,'uint8');
%             EM_PUStatus.MammalProtectionRamp(i49)                   = fread(fid,1,'uint8');
%             EM_PUStatus.BackscatterAtObliqueAngle(i49)              = fread(fid,1,'int8');
%             EM_PUStatus.BackscatterAtNormalIncidence(i49)           = fread(fid,1,'int8');
%             EM_PUStatus.FixedGain(i49)                              = fread(fid,1,'int8');
%             EM_PUStatus.DepthToNormalIncidence(i49)                 = fread(fid,1,'uint8');
%             EM_PUStatus.RangeToNormalIncidence(i49)                 = fread(fid,1,'uint16');
%             EM_PUStatus.PortCoverage(i49)                           = fread(fid,1,'uint8');
%             EM_PUStatus.StarboardCoverage(i49)                      = fread(fid,1,'uint8');
%             EM_PUStatus.SoundSpeedAtTransducerFoundFromProfile(i49) = fread(fid,1,'uint16');
%             EM_PUStatus.YawStabilization(i49)                       = fread(fid,1,'int16');
%             EM_PUStatus.PortCoverageOrAcrossShipVelocity(i49)       = fread(fid,1,'int16');
%             EM_PUStatus.StarboardCoverageOrDownwardVelocity(i49)    = fread(fid,1,'int16');
%             EM_PUStatus.EM2040CPUtemp(i49)                          = fread(fid,1,'int8');
%             EM_PUStatus.ETX(i49)                                    = fread(fid,1,'uint8');
%             EM_PUStatus.CheckSum(i49)                               = fread(fid,1,'uint16');
%             
%             % ETX check
%             if EM_PUStatus.ETX(i49)~=3
%                 error('wrong ETX value (EM_PUStatus)');
%             end
%  
%             % confirm parsing
%             parsed = 1;

        case 65
            
            datagTypeText = 'ATTITUDE (41H)';
            
            % counter for this type of datagram
            try i65=i65+1; catch, i65=1; end
            counter = i65;

            % parsing
            EM_Attitude.NumberOfBytesInDatagram(i65)                = nbDatag;
            EM_Attitude.STX(i65)                                    = stxDatag;
            EM_Attitude.TypeOfDatagram(i65)                         = datagTypeNumber;
            EM_Attitude.EMModelNumber(i65)                          = emNumber;
            EM_Attitude.Date(i65)                                   = date;
            EM_Attitude.TimeSinceMidnightInMilliseconds(i65)        = timeSinceMidnightInMilliseconds;
            EM_Attitude.AttitudeCounter(i65)                        = number;
            EM_Attitude.SystemSerialNumber(i65)                     = systemSerialNumber;
            
            EM_Attitude.NumberOfEntries(i65)                        = fread(fid,1,'uint16'); %N
            % repeat cycle: N entries of 12 bits
            temp = ftell(fid);
            N = EM_Attitude.NumberOfEntries(i65) ;
            EM_Attitude.TimeInMillisecondsSinceRecordStart{i65} = fread(fid,N,'uint16',12-2);
            fseek(fid,temp+2,'bof'); % to next data type
            EM_Attitude.SensorStatus{i65}                       = fread(fid,N,'uint16',12-2);
            fseek(fid,temp+4,'bof'); % to next data type
            EM_Attitude.Roll{i65}                               = fread(fid,N,'int16',12-2);
            fseek(fid,temp+6,'bof'); % to next data type
            EM_Attitude.Pitch{i65}                              = fread(fid,N,'int16',12-2);
            fseek(fid,temp+8,'bof'); % to next data type
            EM_Attitude.Heave{i65}                              = fread(fid,N,'int16',12-2);
            fseek(fid,temp+10,'bof'); % to next data type
            EM_Attitude.Heading{i65}                            = fread(fid,N,'uint16',12-2);
            fseek(fid,2-12,'cof'); % we need to come back after last jump
            EM_Attitude.SensorSystemDescriptor(i65)                 = fread(fid,1,'uint8');
            EM_Attitude.ETX(i65)                                    = fread(fid,1,'uint8');
            EM_Attitude.CheckSum(i65)                               = fread(fid,1,'uint16');
            
            % ETX check
            if EM_Attitude.ETX(i65)~=3
                error('wrong ETX value (EM_Attitude)');
            end
            
            % confirm parsing
            parsed = 1;
                
        case 67
            
            datagTypeText = 'CLOCK (43H)';
            
            % counter for this type of datagram
            try i67=i67+1; catch, i67=1; end
            counter = i67;
            
            % parsing
            EM_Clock.NumberOfBytesInDatagram(i67)                          = nbDatag;
            EM_Clock.STX(i67)                                              = stxDatag;
            EM_Clock.TypeOfDatagram(i67)                                   = datagTypeNumber;
            EM_Clock.EMModelNumber(i67)                                    = emNumber;
            EM_Clock.Date(i67)                                             = date;
            EM_Clock.TimeSinceMidnightInMilliseconds(i67)                  = timeSinceMidnightInMilliseconds;
            EM_Clock.ClockCounter(i67)                                     = number;
            EM_Clock.SystemSerialNumber(i67)                               = systemSerialNumber;
            
            EM_Clock.DateFromExternalClock(i67)                            = fread(fid,1,'uint32');
            EM_Clock.TimeSinceMidnightInMillisecondsFromExternalClock(i67) = fread(fid,1,'uint32');
            EM_Clock.OnePPSUse(i67)                                        = fread(fid,1,'uint8');
            EM_Clock.ETX(i67)                                              = fread(fid,1,'uint8');
            EM_Clock.CheckSum(i67)                                         = fread(fid,1,'uint16');
            
            % ETX check
            if EM_Clock.ETX(i67)~=3
                error('wrong ETX value (EM_Clock)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 68
            
            datagTypeText = 'DEPTH DATAGRAM (44H)';
            
            % counter for this type of datagram
            try i68=i68+1; catch, i68=1; end
            counter = i68;
            
            % parsing
            EM_Depth.NumberOfBytesInDatagram(i68)           = nbDatag;
            EM_Depth.STX(i68)                               = stxDatag;
            EM_Depth.TypeOfDatagram(i68)                    = datagTypeNumber;
            EM_Depth.EMModelNumber(i68)                     = emNumber;
            EM_Depth.Date(i68)                              = date;
            EM_Depth.TimeSinceMidnightInMilliseconds(i68)   = timeSinceMidnightInMilliseconds;
            EM_Depth.PingCounter(i68)                       = number;
            EM_Depth.SystemSerialNumber(i68)                = systemSerialNumber;
            
            EM_Depth.HeadingOfVessel(i68)                   = fread(fid,1,'uint16');
            EM_Depth.SoundSpeedAtTransducer(i68)            = fread(fid,1,'uint16');
            EM_Depth.TransmitTransducerDepth(i68)           = fread(fid,1,'uint16');
            EM_Depth.MaximumNumberOfBeamsPossible(i68)      = fread(fid,1,'uint8');
            EM_Depth.NumberOfValidBeams(i68)                = fread(fid,1,'uint8'); %N
            EM_Depth.ZResolution(i68)                       = fread(fid,1,'uint8');
            EM_Depth.XAndYResolution(i68)                   = fread(fid,1,'uint8');
            EM_Depth.SamplingRate(i68)                      = fread(fid,1,'uint16'); % OR: EM_Depth.DepthDifferenceBetweenSonarHeadsInTheEM3000D(i68) = fread(fid,1,'int16');
            % repeat cycle: N entries of 16 bits
            temp = ftell(fid);
            N = EM_Depth.NumberOfValidBeams(i68);
            EM_Depth.DepthZ{i68}                        = fread(fid,N,'int16',16-2); % OR 'uint16' for EM120 and EM300
            fseek(fid,temp+2,'bof'); % to next data type
            EM_Depth.AcrosstrackDistanceY{i68}          = fread(fid,N,'int16',16-2);
            fseek(fid,temp+4,'bof'); % to next data type
            EM_Depth.AlongtrackDistanceX{i68}           = fread(fid,N,'int16',16-2);
            fseek(fid,temp+6,'bof'); % to next data type
            EM_Depth.BeamDepressionAngle{i68}           = fread(fid,N,'int16',16-2);
            fseek(fid,temp+8,'bof'); % to next data type
            EM_Depth.BeamAzimuthAngle{i68}              = fread(fid,N,'uint16',16-2);
            fseek(fid,temp+10,'bof'); % to next data type
            EM_Depth.Range{i68}                         = fread(fid,N,'uint16',16-2);
            fseek(fid,temp+12,'bof'); % to next data type
            EM_Depth.QualityFactor{i68}                 = fread(fid,N,'uint8',16-1);
            fseek(fid,temp+13,'bof'); % to next data type
            EM_Depth.LengthOfDetectionWindow{i68}       = fread(fid,N,'uint8',16-1);
            fseek(fid,temp+14,'bof'); % to next data type
            EM_Depth.ReflectivityBS{i68}                = fread(fid,N,'int8',16-1);
            fseek(fid,temp+15,'bof'); % to next data type
            EM_Depth.BeamNumber{i68}                    = fread(fid,N,'uint8',16-1);
            fseek(fid,1-16,'cof'); % we need to come back after last jump
            EM_Depth.TransducerDepthOffsetMultiplier(i68) = fread(fid,1,'int8');
            EM_Depth.ETX(i68)                             = fread(fid,1,'uint8');
            EM_Depth.CheckSum(i68)                        = fread(fid,1,'uint16');
            
            % ETX check
            if EM_Depth.ETX(i68)~=3,
                error('wrong ETX value (EM_Depth)');
            end
            
            % confirm parsing
            parsed = 1;

        case 70

            datagTypeText = 'RAW RANGE AND BEAM ANGLE (F) (46H)';
            
            % counter for this type of datagram
            try i70=i70+1; catch, i70=1; end
            counter = i70;

            % parsing
            % ...to write...
            
        case 71
            
            datagTypeText = 'SURFACE SOUND SPEED (47H)';
            
            % counter for this type of datagram
            try i71=i71+1; catch, i71=1; end
            counter = i71;
            
            % parsing
            EM_SurfaceSoundSpeed.NumberOfBytesInDatagram(i71)           = nbDatag;
            EM_SurfaceSoundSpeed.STX(i71)                               = stxDatag;
            EM_SurfaceSoundSpeed.TypeOfDatagram(i71)                    = datagTypeNumber;
            EM_SurfaceSoundSpeed.EMModelNumber(i71)                     = emNumber;
            EM_SurfaceSoundSpeed.Date(i71)                              = date;
            EM_SurfaceSoundSpeed.TimeSinceMidnightInMilliseconds(i71)   = timeSinceMidnightInMilliseconds;
            EM_SurfaceSoundSpeed.SoundSpeedCounter(i71)                 = number;
            EM_SurfaceSoundSpeed.SystemSerialNumber(i71)                = systemSerialNumber;
            
            EM_SurfaceSoundSpeed.NumberOfEntries(i71)                   = fread(fid,1,'uint16'); %N
            % repeat cycle: N entries of 4 bits
            temp = ftell(fid);
            N = EM_SurfaceSoundSpeed.NumberOfEntries(i71);
            EM_SurfaceSoundSpeed.TimeInSecondsSinceRecordStart{i71} = fread(fid,N,'uint16',4-2);
            fseek(fid,temp+2,'bof'); % to next data type
            EM_SurfaceSoundSpeed.SoundSpeed{i71}                    = fread(fid,N,'uint16',4-2);
            fseek(fid,2-4,'cof'); % we need to come back after last jump
            EM_SurfaceSoundSpeed.Spare(i71)                             = fread(fid,1,'uint8');
            EM_SurfaceSoundSpeed.ETX(i71)                               = fread(fid,1,'uint8');
            EM_SurfaceSoundSpeed.CheckSum(i71)                          = fread(fid,1,'uint16');
            
            % ETX check
            if EM_SurfaceSoundSpeed.ETX(i71)~=3
                error('wrong ETX value (EM_SurfaceSoundSpeed)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 72
            
            datagTypeText = 'HEADING (48H)';
            
            % counter for this type of datagram
            try i72=i72+1; catch, i72=1; end
            counter = i72;
            
            % parsing
            % ...to write...
            
        case 73
            
            datagTypeText = 'INSTALLATION PARAMETERS - START (49H)';
            
            % counter for this type of datagram
            try i73=i73+1; catch, i73=1; end
            counter = i73;
            
            % parsing
            EM_InstallationStart.NumberOfBytesInDatagram(i73)         = nbDatag;
            EM_InstallationStart.STX(i73)                             = stxDatag;
            EM_InstallationStart.TypeOfDatagram(i73)                  = datagTypeNumber;
            EM_InstallationStart.EMModelNumber(i73)                   = emNumber;
            EM_InstallationStart.Date(i73)                            = date;
            EM_InstallationStart.TimeSinceMidnightInMilliseconds(i73) = timeSinceMidnightInMilliseconds;
            EM_InstallationStart.SurveyLineNumber(i73)                = number;
            EM_InstallationStart.SystemSerialNumber(i73)              = systemSerialNumber;
            
            EM_InstallationStart.SerialNumberOfSecondSonarHead(i73)   = fread(fid,1,'uint16');
            
            % 18 bytes of binary data already recorded and 3 more to come = 21.
            % but nbDatag will always be even thanks to SpareByte. so
            % nbDatag is 22 if there is no ASCII data and more if there is
            % ASCII data. read the rest as ASCII (including SpareByte) with
            % 1 byte for 1 character.
            EM_InstallationStart.ASCIIData{i73}                       = fscanf(fid, '%c', nbDatag-21);
            
            EM_InstallationStart.ETX(i73)                             = fread(fid,1,'uint8');
            EM_InstallationStart.CheckSum(i73)                        = fread(fid,1,'uint16');
            
            % ETX check
            if EM_InstallationStart.ETX(i73)~=3
                error('wrong ETX value (EM_InstallationStart)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 78
            
            datagTypeText = 'RAW RANGE AND ANGLE 78 (4EH)';
            
            % counter for this type of datagram
            try i78=i78+1; catch, i78=1; end
            counter = i78;
            
            % parsing
            EM_RawRangeAngle78.NumberOfBytesInDatagram(i78)           = nbDatag;
            EM_RawRangeAngle78.STX(i78)                               = stxDatag;
            EM_RawRangeAngle78.TypeOfDatagram(i78)                    = datagTypeNumber;
            EM_RawRangeAngle78.EMModelNumber(i78)                     = emNumber;
            EM_RawRangeAngle78.Date(i78)                              = date;
            EM_RawRangeAngle78.TimeSinceMidnightInMilliseconds(i78)   = timeSinceMidnightInMilliseconds;
            EM_RawRangeAngle78.PingCounter(i78)                       = number;
            EM_RawRangeAngle78.SystemSerialNumber(i78)                = systemSerialNumber;
            
            EM_RawRangeAngle78.SoundSpeedAtTransducer(i78)            = fread(fid,1,'uint16');
            EM_RawRangeAngle78.NumberOfTransmitSectors(i78)           = fread(fid,1,'uint16'); %Ntx
            EM_RawRangeAngle78.NumberOfReceiverBeamsInDatagram(i78)   = fread(fid,1,'uint16'); %Nrx
            EM_RawRangeAngle78.NumberOfValidDetections(i78)           = fread(fid,1,'uint16');
            EM_RawRangeAngle78.SamplingFrequencyInHz(i78)             = fread(fid,1,'float32');
            EM_RawRangeAngle78.Dscale(i78)                            = fread(fid,1,'uint32');
            % repeat cycle #1: Ntx entries of 24 bits
            temp = ftell(fid);
            C = 24;
            Ntx = EM_RawRangeAngle78.NumberOfTransmitSectors(i78);
            EM_RawRangeAngle78.TiltAngle{i78}                     = fread(fid,Ntx,'int16',C-2);
            fseek(fid,temp+2,'bof'); % to next data type
            EM_RawRangeAngle78.FocusRange{i78}                    = fread(fid,Ntx,'uint16',C-2);
            fseek(fid,temp+4,'bof'); % to next data type
            EM_RawRangeAngle78.SignalLength{i78}                  = fread(fid,Ntx,'float32',C-4);
            fseek(fid,temp+8,'bof'); % to next data type
            EM_RawRangeAngle78.SectorTransmitDelay{i78}           = fread(fid,Ntx,'float32',C-4);
            fseek(fid,temp+12,'bof'); % to next data type
            EM_RawRangeAngle78.CentreFrequency{i78}               = fread(fid,Ntx,'float32',C-4);
            fseek(fid,temp+16,'bof'); % to next data type
            EM_RawRangeAngle78.MeanAbsorptionCoeff{i78}           = fread(fid,Ntx,'uint16',C-2);
            fseek(fid,temp+18,'bof'); % to next data type
            EM_RawRangeAngle78.SignalWaveformIdentifier{i78}      = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,temp+19,'bof'); % to next data type
            EM_RawRangeAngle78.TransmitSectorNumberTxArrayIndex{i78} = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,temp+20,'bof'); % to next data type
            EM_RawRangeAngle78.SignalBandwidth{i78}               = fread(fid,Ntx,'float32',C-4);
            fseek(fid,4-C,'cof'); % we need to come back after last jump
            % repeat cycle #2: Nrx entries of 16 bits
            temp = ftell(fid);
            C = 16;
            Nrx = EM_RawRangeAngle78.NumberOfReceiverBeamsInDatagram(i78);
            EM_RawRangeAngle78.BeamPointingAngle{i78}             = fread(fid,Nrx,'int16',C-2);
            fseek(fid,temp+2,'bof'); % to next data type
            EM_RawRangeAngle78.TransmitSectorNumber{i78}          = fread(fid,Nrx,'uint8',C-1);
            fseek(fid,temp+3,'bof'); % to next data type
            EM_RawRangeAngle78.DetectionInfo{i78}                 = fread(fid,Nrx,'uint8',C-1);
            fseek(fid,temp+4,'bof'); % to next data type
            EM_RawRangeAngle78.DetectionWindowLength{i78}         = fread(fid,Nrx,'uint16',C-2);
            fseek(fid,temp+6,'bof'); % to next data type
            EM_RawRangeAngle78.QualityFactor{i78}                 = fread(fid,Nrx,'uint8',C-1);
            fseek(fid,temp+7,'bof'); % to next data type
            EM_RawRangeAngle78.Dcorr{i78}                         = fread(fid,Nrx,'int8',C-1);
            fseek(fid,temp+8,'bof'); % to next data type
            EM_RawRangeAngle78.TwoWayTravelTime{i78}              = fread(fid,Nrx,'float32',C-4);
            fseek(fid,temp+12,'bof'); % to next data type
            EM_RawRangeAngle78.ReflectivityBS{i78}                = fread(fid,Nrx,'int16',C-2);
            fseek(fid,temp+14,'bof'); % to next data type
            EM_RawRangeAngle78.RealTimeCleaningInfo{i78}          = fread(fid,Nrx,'int8',C-1);
            fseek(fid,temp+15,'bof'); % to next data type
            EM_RawRangeAngle78.Spare{i78}                         = fread(fid,Nrx,'uint8',C-1);
            fseek(fid,1-C,'cof'); % we need to come back after last jump
            EM_RawRangeAngle78.Spare2(i78)                            = fread(fid,1,'uint8');
            EM_RawRangeAngle78.ETX(i78)                               = fread(fid,1,'uint8');
            EM_RawRangeAngle78.CheckSum(i78)                          = fread(fid,1,'uint16');
            
            % ETX check
            if EM_RawRangeAngle78.ETX(i78)~=3,
                error('wrong ETX value (EM_RawRangeAngle78)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 79
            
            datagTypeText = 'QUALITY FACTOR DATAGRAM 79 (4FH)';
            
            % counter for this type of datagram
            try i79=i79+1; catch, i79=1; end
            counter = i79;
            
            % parsing
            % ...to write...
            
        case 80
            
            datagTypeText = 'POSITION (50H)';
            
            % counter for this type of datagram
            try i80=i80+1; catch, i80=1; end
            counter = i80;
            
            % parsing
            EM_Position.NumberOfBytesInDatagram(i80)         = nbDatag;
            EM_Position.STX(i80)                             = stxDatag;
            EM_Position.TypeOfDatagram(i80)                  = datagTypeNumber;
            EM_Position.EMModelNumber(i80)                   = emNumber;
            EM_Position.Date(i80)                            = date;
            EM_Position.TimeSinceMidnightInMilliseconds(i80) = timeSinceMidnightInMilliseconds;
            EM_Position.PositionCounter(i80)                 = number;
            EM_Position.SystemSerialNumber(i80)              = systemSerialNumber;
            
            EM_Position.Latitude(i80)                        = fread(fid,1,'int32');
            EM_Position.Longitude(i80)                       = fread(fid,1,'int32');
            EM_Position.MeasureOfPositionFixQuality(i80)     = fread(fid,1,'uint16');
            EM_Position.SpeedOfVesselOverGround(i80)         = fread(fid,1,'uint16');
            EM_Position.CourseOfVesselOverGround(i80)        = fread(fid,1,'uint16');
            EM_Position.HeadingOfVessel(i80)                 = fread(fid,1,'uint16');
            EM_Position.PositionSystemDescriptor(i80)        = fread(fid,1,'uint8');
            EM_Position.NumberOfBytesInInputDatagram(i80)    = fread(fid,1,'uint8');
            
            % next data size is variable. 34 bits of binary data already
            % recorded and 3 more to come = 37. read the rest as ASCII
            % (including SpareByte)
            EM_Position.PositionInputDatagramAsReceived{i80} = fscanf(fid, '%c', nbDatag-37);
            
            EM_Position.ETX(i80)                             = fread(fid,1,'uint8');
            EM_Position.CheckSum(i80)                        = fread(fid,1,'uint16');
            
            % ETX check
            if EM_Position.ETX(i80)~=3
                error('wrong ETX value (EM_Position)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 82
            
            datagTypeText = 'RUNTIME PARAMETERS (52H)';
            
            % counter for this type of datagram
            try i82=i82+1; catch, i82=1; end
            counter = i82;
            
            % parsing
            EM_Runtime.NumberOfBytesInDatagram(i82)                 = nbDatag;
            EM_Runtime.STX(i82)                                     = stxDatag;
            EM_Runtime.TypeOfDatagram(i82)                          = datagTypeNumber;
            EM_Runtime.EMModelNumber(i82)                           = emNumber;
            EM_Runtime.Date(i82)                                    = date;
            EM_Runtime.TimeSinceMidnightInMilliseconds(i82)         = timeSinceMidnightInMilliseconds;
            EM_Runtime.PingCounter(i82)                             = number;
            EM_Runtime.SystemSerialNumber(i82)                      = systemSerialNumber;
            
            EM_Runtime.OperatorStationStatus(i82)                   = fread(fid,1,'uint8');
            EM_Runtime.ProcessingUnitStatus(i82)                    = fread(fid,1,'uint8');
            EM_Runtime.BSPStatus(i82)                               = fread(fid,1,'uint8');
            EM_Runtime.SonarHeadStatus(i82)                         = fread(fid,1,'uint8');
            EM_Runtime.Mode(i82)                                    = fread(fid,1,'uint8');
            EM_Runtime.FilterIdentifier(i82)                        = fread(fid,1,'uint8');
            EM_Runtime.MinimumDepth(i82)                            = fread(fid,1,'uint16');
            EM_Runtime.MaximumDepth(i82)                            = fread(fid,1,'uint16');
            EM_Runtime.AbsorptionCoefficient(i82)                   = fread(fid,1,'uint16');
            EM_Runtime.TransmitPulseLength(i82)                     = fread(fid,1,'uint16');
            EM_Runtime.TransmitBeamwidth(i82)                       = fread(fid,1,'uint16');
            EM_Runtime.TransmitPowerReMaximum(i82)                  = fread(fid,1,'int8');
            EM_Runtime.ReceiveBeamwidth(i82)                        = fread(fid,1,'uint8');
            EM_Runtime.ReceiveBandwidth(i82)                        = fread(fid,1,'uint8');
            EM_Runtime.ReceiverFixedGainSetting(i82)                = fread(fid,1,'uint8'); % OR mode 2
            EM_Runtime.TVGLawCrossoverAngle(i82)                    = fread(fid,1,'uint8');
            EM_Runtime.SourceOfSoundSpeedAtTransducer(i82)          = fread(fid,1,'uint8');
            EM_Runtime.MaximumPortSwathWidth(i82)                   = fread(fid,1,'uint16');
            EM_Runtime.BeamSpacing(i82)                             = fread(fid,1,'uint8');
            EM_Runtime.MaximumPortCoverage(i82)                     = fread(fid,1,'uint8');
            EM_Runtime.YawAndPitchStabilizationMode(i82)            = fread(fid,1,'uint8');
            EM_Runtime.MaximumStarboardCoverage(i82)                = fread(fid,1,'uint8');
            EM_Runtime.MaximumStarboardSwathWidth(i82)              = fread(fid,1,'uint16');
            EM_Runtime.DurotongSpeed(i82)                           = fread(fid,1,'uint16'); % OR: EM_Runtime.TransmitAlongTilt(i82) = fread(fid,1,'int16');
            EM_Runtime.HiLoFrequencyAbsorptionCoefficientRatio(i82) = fread(fid,1,'uint8'); % OR filter identifier 2
            EM_Runtime.ETX(i82)                                     = fread(fid,1,'uint8');
            EM_Runtime.CheckSum(i82)                                = fread(fid,1,'uint16');
            
            % ETX check
            if EM_Runtime.ETX(i82)~=3,
                error('wrong ETX value (EM_Runtime)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 83
            
            datagTypeText = 'SEABED IMAGE DATAGRAM (53H)';
            
            % counter for this type of datagram
            try i83=i83+1; catch, i83=1; end
            counter = i83;
            
            % parsing
            EM_SeabedImage.NumberOfBytesInDatagram(i83)         = nbDatag;
            EM_SeabedImage.STX(i83)                             = stxDatag;
            EM_SeabedImage.TypeOfDatagram(i83)                  = datagTypeNumber;
            EM_SeabedImage.EMModelNumber(i83)                   = emNumber;
            EM_SeabedImage.Date(i83)                            = date;
            EM_SeabedImage.TimeSinceMidnightInMilliseconds(i83) = timeSinceMidnightInMilliseconds;
            EM_SeabedImage.PingCounter(i83)                     = number;
            EM_SeabedImage.SystemSerialNumber(i83)              = systemSerialNumber;
            
            EM_SeabedImage.MeanAbsorptionCoefficient(i83)       = fread(fid,1,'uint16'); % 'this field had earlier definition'
            EM_SeabedImage.PulseLength(i83)                     = fread(fid,1,'uint16'); % 'this field had earlier definition'
            EM_SeabedImage.RangeToNormalIncidence(i83)          = fread(fid,1,'uint16');
            EM_SeabedImage.StartRangeSampleOfTVGRamp(i83)       = fread(fid,1,'uint16');
            EM_SeabedImage.StopRangeSampleOfTVGRamp(i83)        = fread(fid,1,'uint16');
            EM_SeabedImage.NormalIncidenceBS(i83)               = fread(fid,1,'int8'); %BSN
            EM_SeabedImage.ObliqueBS(i83)                       = fread(fid,1,'int8'); %BSO
            EM_SeabedImage.TxBeamwidth(i83)                     = fread(fid,1,'uint16');
            EM_SeabedImage.TVGLawCrossoverAngle(i83)            = fread(fid,1,'uint8');
            EM_SeabedImage.NumberOfValidBeams(i83)              = fread(fid,1,'uint8'); %N
            % repeat cycle: N entries of 6 bits
            temp = ftell(fid);
            N = EM_SeabedImage.NumberOfValidBeams(i83);
            EM_SeabedImage.BeamIndexNumber{i83}             = fread(fid,N,'uint8',6-1);
            fseek(fid,temp+1,'bof'); % to next data type
            EM_SeabedImage.SortingDirection{i83}            = fread(fid,N,'int8',6-1);
            fseek(fid,temp+2,'bof'); % to next data type
            EM_SeabedImage.NumberOfSamplesPerBeam{i83}      = fread(fid,N,'uint16',6-2); %Ns
            fseek(fid,temp+4,'bof'); % to next data type
            EM_SeabedImage.CentreSampleNumber{i83}          = fread(fid,N,'uint16',6-2);
            fseek(fid,2-6,'cof'); % we need to come back after last jump
            Ns = [EM_SeabedImage.NumberOfSamplesPerBeam{i83}];
            for jj = 1:length(Ns)
                EM_SeabedImage.SampleAmplitudes(i83).beam{jj}   = fread(fid,Ns(jj),'int8');
            end
            % "spare byte if required to get even length (always 0 if used)"
            if floor(sum(Ns)/2) == sum(Ns)/2
                % even so far, since ETX is 1 byte, add a spare here
                EM_SeabedImage.Data.SpareByte(i83)              = fread(fid,1,'uint8');
            else
                % odd so far, since ETX is 1 bytes, no spare
                EM_SeabedImage.Data.SpareByte(i83) = NaN;
            end
            EM_SeabedImage.ETX(i83)                             = fread(fid,1,'uint8');
            EM_SeabedImage.CheckSum(i83)                        = fread(fid,1,'uint16');
            
            % ETX check
            if EM_SeabedImage.ETX(i83)~=3
                error('wrong ETX value (EM_SeabedImage)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 85
            
            datagTypeText = 'SOUND SPEED PROFILE (55H)';
            
            % counter for this type of datagram
            try i85=i85+1; catch, i85=1; end
            counter = i85;
            
            % parsing
            EM_SoundSpeedProfile.NumberOfBytesInDatagram(i85)                           = nbDatag;
            EM_SoundSpeedProfile.STX(i85)                                               = stxDatag;
            EM_SoundSpeedProfile.TypeOfDatagram(i85)                                    = datagTypeNumber;
            EM_SoundSpeedProfile.EMModelNumber(i85)                                     = emNumber;
            EM_SoundSpeedProfile.Date(i85)                                              = date;
            EM_SoundSpeedProfile.TimeSinceMidnightInMilliseconds(i85)                   = timeSinceMidnightInMilliseconds;
            EM_SoundSpeedProfile.ProfileCounter(i85)                                    = number;
            EM_SoundSpeedProfile.SystemSerialNumber(i85)                                = systemSerialNumber;
            
            EM_SoundSpeedProfile.DateWhenProfileWasMade(i85)                            = fread(fid,1,'uint32');
            EM_SoundSpeedProfile.TimeSinceMidnightInMillisecondsWhenProfileWasMade(i85) = fread(fid,1,'uint32');
            EM_SoundSpeedProfile.NumberOfEntries(i85)                                   = fread(fid,1,'uint16'); %N
            EM_SoundSpeedProfile.DepthResolution(i85)                                   = fread(fid,1,'uint16');
            % repeat cycle: N entries of 8 bits
            temp = ftell(fid);
            N = EM_SoundSpeedProfile.NumberOfEntries(i85);
            EM_SoundSpeedProfile.Depth{i85}                                         = fread(fid,N,'uint32',8-4);
            fseek(fid,temp+4,'bof'); % to next data type
            EM_SoundSpeedProfile.SoundSpeed{i85}                                    = fread(fid,N,'uint32',8-4);
            fseek(fid,4-8,'cof'); % we need to come back after last jump
            EM_SoundSpeedProfile.SpareByte(i85)                                         = fread(fid,1,'uint8');
            EM_SoundSpeedProfile.ETX(i85)                                               = fread(fid,1,'uint8');
            EM_SoundSpeedProfile.CheckSum(i85)                                          = fread(fid,1,'uint16');
            
            % ETX check
            if EM_SoundSpeedProfile.ETX(i85)~=3
                error('wrong ETX value (EM_SoundSpeedProfile)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 88
            
            datagTypeText = 'XYZ 88 (58H)';
            
            % counter for this type of datagram
            try i88=i88+1; catch, i88=1; end
            counter = i88;
            
            % parsing
            EM_XYZ88.NumberOfBytesInDatagram(i88)           = nbDatag;
            EM_XYZ88.STX(i88)                               = stxDatag;
            EM_XYZ88.TypeOfDatagram(i88)                    = datagTypeNumber;
            EM_XYZ88.EMModelNumber(i88)                     = emNumber;
            EM_XYZ88.Date(i88)                              = date;
            EM_XYZ88.TimeSinceMidnightInMilliseconds(i88)   = timeSinceMidnightInMilliseconds;
            EM_XYZ88.PingCounter(i88)                       = number;
            EM_XYZ88.SystemSerialNumber(i88)                = systemSerialNumber;
            
            EM_XYZ88.HeadingOfVessel(i88)                   = fread(fid,1,'uint16');
            EM_XYZ88.SoundSpeedAtTransducer(i88)            = fread(fid,1,'uint16');
            EM_XYZ88.TransmitTransducerDepth(i88)           = fread(fid,1,'float32');
            EM_XYZ88.NumberOfBeamsInDatagram(i88)           = fread(fid,1,'uint16');
            EM_XYZ88.NumberOfValidDetections(i88)           = fread(fid,1,'uint16');
            EM_XYZ88.SamplingFrequencyInHz(i88)             = fread(fid,1,'float32');
            EM_XYZ88.ScanningInfo(i88)                      = fread(fid,1,'uint8');
            EM_XYZ88.Spare1(i88)                            = fread(fid,1,'uint8');
            EM_XYZ88.Spare2(i88)                            = fread(fid,1,'uint8');
            EM_XYZ88.Spare3(i88)                            = fread(fid,1,'uint8');
            % repeat cycle: N entries of 20 bits
            temp = ftell(fid);
            C = 20;
            N = EM_XYZ88.NumberOfBeamsInDatagram(i88);
            EM_XYZ88.DepthZ{i88}                        = fread(fid,N,'float32',C-4);
            fseek(fid,temp+4,'bof'); % to next data type
            EM_XYZ88.AcrosstrackDistanceY{i88}          = fread(fid,N,'float32',C-4);
            fseek(fid,temp+8,'bof'); % to next data type
            EM_XYZ88.AlongtrackDistanceX{i88}           = fread(fid,N,'float32',C-4);
            fseek(fid,temp+12,'bof'); % to next data type
            EM_XYZ88.DetectionWindowLength{i88}         = fread(fid,N,'uint16',C-2);
            fseek(fid,temp+14,'bof'); % to next data type
            EM_XYZ88.QualityFactor{i88}                 = fread(fid,N,'uint8',C-1);
            fseek(fid,temp+15,'bof'); % to next data type
            EM_XYZ88.BeamIncidenceAngleAdjustment{i88}  = fread(fid,N,'int8',C-1);
            fseek(fid,temp+16,'bof'); % to next data type
            EM_XYZ88.DetectionInformation{i88}          = fread(fid,N,'uint8',C-1);
            fseek(fid,temp+17,'bof'); % to next data type
            EM_XYZ88.RealTimeCleaningInformation{i88}   = fread(fid,N,'int8',C-1);
            fseek(fid,temp+18,'bof'); % to next data type
            EM_XYZ88.ReflectivityBS{i88}                = fread(fid,N,'int16',C-2);
            fseek(fid,2-C,'cof'); % we need to come back after last jump
            EM_XYZ88.Spare4(i88)                            = fread(fid,1,'uint8');
            EM_XYZ88.ETX(i88)                               = fread(fid,1,'uint8');
            EM_XYZ88.CheckSum(i88)                          = fread(fid,1,'uint16');
            
            % ETX check
            if EM_XYZ88.ETX(i88)~=3,
                error('wrong ETX value (EM_XYZ88)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 89
            
            datagTypeText = 'SEABED IMAGE DATA 89 (59H)';
            
            % counter for this type of datagram
            try i89=i89+1; catch, i89=1; end
            counter = i89;
            
            % parsing
            EM_SeabedImage89.NumberOfBytesInDatagram(i89)         = nbDatag;
            EM_SeabedImage89.STX(i89)                             = stxDatag;
            EM_SeabedImage89.TypeOfDatagram(i89)                  = datagTypeNumber;
            EM_SeabedImage89.EMModelNumber(i89)                   = emNumber;
            EM_SeabedImage89.Date(i89)                            = date;
            EM_SeabedImage89.TimeSinceMidnightInMilliseconds(i89) = timeSinceMidnightInMilliseconds;
            EM_SeabedImage89.PingCounter(i89)                     = number;
            EM_SeabedImage89.SystemSerialNumber(i89)              = systemSerialNumber;
            
            EM_SeabedImage89.SamplingFrequencyInHz(i89)           = fread(fid,1,'float32');
            EM_SeabedImage89.RangeToNormalIncidence(i89)          = fread(fid,1,'uint16');
            EM_SeabedImage89.NormalIncidenceBS(i89)               = fread(fid,1,'int16'); %BSN
            EM_SeabedImage89.ObliqueBS(i89)                       = fread(fid,1,'int16'); %BSO
            EM_SeabedImage89.TxBeamwidthAlong(i89)                = fread(fid,1,'uint16');
            EM_SeabedImage89.TVGLawCrossoverAngle(i89)            = fread(fid,1,'uint16');
            EM_SeabedImage89.NumberOfValidBeams(i89)              = fread(fid,1,'uint16');
            % repeat cycle: N entries of 6 bits
            temp = ftell(fid);
            C = 6;
            N = EM_SeabedImage89.NumberOfValidBeams(i89);
            EM_SeabedImage89.SortingDirection{i89}            = fread(fid,N,'int8',C-1);
            fseek(fid,temp+1,'bof'); % to next data type
            EM_SeabedImage89.DetectionInfo{i89}               = fread(fid,N,'uint8',C-1);
            fseek(fid,temp+2,'bof'); % to next data type
            EM_SeabedImage89.NumberOfSamplesPerBeam{i89}      = fread(fid,N,'uint16',C-2); %Ns
            fseek(fid,temp+4,'bof'); % to next data type
            EM_SeabedImage89.CentreSampleNumber{i89}          = fread(fid,N,'uint16',C-2);
            fseek(fid,2-C,'cof'); % we need to come back after last jump
            Ns = [EM_SeabedImage89.NumberOfSamplesPerBeam{i89}];
            for jj = 1:length(Ns)
                EM_SeabedImage89.SampleAmplitudes(i89).beam{jj}   = fread(fid,Ns(jj),'int16');
            end
            EM_SeabedImage89.Spare(i89)                           = fread(fid,1,'uint8');
            EM_SeabedImage89.ETX(i89)                             = fread(fid,1,'uint8');
            EM_SeabedImage89.CheckSum(i89)                        = fread(fid,1,'uint16');
            
            % ETX check
            if EM_SeabedImage89.ETX(i89)~=3
                error('wrong ETX value (EM_SeabedImage89)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 102
            
            datagTypeText = 'RAW RANGE AND BEAM ANGLE (f) (66H)';
            
            % counter for this type of datagram
            try i102=i102+1; catch, i102=1; end
            counter = i102;
           
            % parsing
            % ...to write...
            
        case 104
            
            datagTypeText = 'DEPTH (PRESSURE) OR HEIGHT DATAGRAM (68H)';
            
            % counter for this type of datagram
            try i104=i104+1; catch, i104=1; end
            counter = i104;
            
            % parsing
            EM_Height.NumberOfBytesInDatagram(i104)         = nbDatag;
            EM_Height.STX(i104)                             = stxDatag;
            EM_Height.TypeOfDatagram(i104)                  = datagTypeNumber;
            EM_Height.EMModelNumber(i104)                   = emNumber;
            EM_Height.Date(i104)                            = date;
            EM_Height.TimeSinceMidnightInMilliseconds(i104) = timeSinceMidnightInMilliseconds;
            EM_Height.HeightCounter(i104)                   = number;
            EM_Height.SystemSerialNumber(i104)              = systemSerialNumber;
            
            EM_Height.Height(i104)                          = fread(fid,1,'int32');
            EM_Height.HeigthType(i104)                      = fread(fid,1,'uint8');
            EM_Height.ETX(i104)                             = fread(fid,1,'uint8');
            EM_Height.CheckSum(i104)                        = fread(fid,1,'uint16');
            
            % ETX check
            if EM_Height.ETX(i104)~=3
                error('wrong ETX value (EM_Height)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 105
            
            datagTypeText = 'INSTALLATION PARAMETERS -  STOP (69H)';
            
            % counter for this type of datagram
            try i105=i105+1; catch, i105=1; end
            counter = i105;
            
            % parsing
            EM_InstallationStop.NumberOfBytesInDatagram(i105)         = nbDatag;
            EM_InstallationStop.STX(i105)                             = stxDatag;
            EM_InstallationStop.TypeOfDatagram(i105)                  = datagTypeNumber;
            EM_InstallationStop.EMModelNumber(i105)                   = emNumber;
            EM_InstallationStop.Date(i105)                            = date;
            EM_InstallationStop.TimeSinceMidnightInMilliseconds(i105) = timeSinceMidnightInMilliseconds;
            EM_InstallationStop.SurveyLineNumber(i105)                = number;
            EM_InstallationStop.SystemSerialNumber(i105)              = systemSerialNumber;
            
            EM_InstallationStop.SerialNumberOfSecondSonarHead(i105)   = fread(fid,1,'uint16');
            
            % 18 bytes of binary data already recorded and 3 more to come = 21.
            % but nbDatag will always be even thanks to SpareByte. so
            % nbDatag is 22 if there is no ASCII data and more if there is
            % ASCII data. read the rest as ASCII (including SpareByte) with
            % 1 byte for 1 character.
            EM_InstallationStop.ASCIIData{i105}                       = fscanf(fid, '%c', nbDatag-21);
            
            EM_InstallationStop.ETX(i105)                             = fread(fid,1,'uint8');
            EM_InstallationStop.CheckSum(i105)                        = fread(fid,1,'uint16');
            
            % ETX check
            if EM_InstallationStop.ETX(i105)~=3
                error('wrong ETX value (EM_InstallationStop)');
            end
            
            % confirm parsing
            parsed = 1;

        case 107
            
            datagTypeText = 'WATER COLUMN DATAGRAM (6BH)';
            
            % counter for this type of datagram
            try i107=i107+1; catch, i107=1; end
            counter = i107;
            
            % parsing
            EM_WaterColumn.NumberOfBytesInDatagram(i107)           = nbDatag;
            EM_WaterColumn.STX(i107)                               = stxDatag;
            EM_WaterColumn.TypeOfDatagram(i107)                    = datagTypeNumber;
            EM_WaterColumn.EMModelNumber(i107)                     = emNumber;
            EM_WaterColumn.Date(i107)                              = date;
            EM_WaterColumn.TimeSinceMidnightInMilliseconds(i107)   = timeSinceMidnightInMilliseconds;
            EM_WaterColumn.PingCounter(i107)                       = number;
            EM_WaterColumn.SystemSerialNumber(i107)                = systemSerialNumber;
            
            EM_WaterColumn.NumberOfDatagrams(i107)                 = fread(fid,1,'uint16');
            EM_WaterColumn.DatagramNumbers(i107)                   = fread(fid,1,'uint16');
            EM_WaterColumn.NumberOfTransmitSectors(i107)           = fread(fid,1,'uint16'); %Ntx
            EM_WaterColumn.TotalNumberOfReceiveBeams(i107)         = fread(fid,1,'uint16');
            EM_WaterColumn.NumberOfBeamsInThisDatagram(i107)       = fread(fid,1,'uint16'); %Nrx
            EM_WaterColumn.SoundSpeed(i107)                        = fread(fid,1,'uint16'); %SS
            EM_WaterColumn.SamplingFrequency(i107)                 = fread(fid,1,'uint32'); %SF
            EM_WaterColumn.TXTimeHeave(i107)                       = fread(fid,1,'int16');
            EM_WaterColumn.TVGFunctionApplied(i107)                = fread(fid,1,'uint8'); %X
            EM_WaterColumn.TVGOffset(i107)                         = fread(fid,1,'int8'); %C
            EM_WaterColumn.ScanningInfo(i107)                      = fread(fid,1,'uint8');
            EM_WaterColumn.Spare1(i107)                            = fread(fid,1,'uint8');
            EM_WaterColumn.Spare2(i107)                            = fread(fid,1,'uint8');
            EM_WaterColumn.Spare3(i107)                            = fread(fid,1,'uint8');
            % repeat cycle #1: Ntx entries of 6 bits
            temp = ftell(fid);
            C = 6;
            Ntx = EM_WaterColumn.NumberOfTransmitSectors(i107);
            EM_WaterColumn.TiltAngle{i107}                     = fread(fid,Ntx,'int16',C-2);
            fseek(fid,temp+2,'bof'); % to next data type
            EM_WaterColumn.CenterFrequency{i107}               = fread(fid,Ntx,'uint16',C-2);
            fseek(fid,temp+4,'bof'); % to next data type
            EM_WaterColumn.TransmitSectorNumber{i107}          = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,temp+5,'bof'); % to next data type
            EM_WaterColumn.Spare{i107}                         = fread(fid,Ntx,'uint8',C-1);
            fseek(fid,1-C,'cof'); % we need to come back after last jump
            % repeat cycle #2: Nrx entries of a possibly variable number of bits. Using a for loop
            Nrx = EM_WaterColumn.NumberOfBeamsInThisDatagram(i107);
            Ns = nan(1,Nrx);
            for jj=1:Nrx
                EM_WaterColumn.BeamPointingAngle{i107}(jj)             = fread(fid,1,'int16');
                EM_WaterColumn.StartRangeSampleNumber{i107}(jj)        = fread(fid,1,'uint16');
                EM_WaterColumn.NumberOfSamples{i107}(jj)               = fread(fid,1,'uint16'); %Ns
                EM_WaterColumn.DetectedRangeInSamples{i107}(jj)        = fread(fid,1,'uint16'); %DR
                EM_WaterColumn.TransmitSectorNumber2{i107}(jj)         = fread(fid,1,'uint8');
                EM_WaterColumn.BeamNumber{i107}(jj)                    = fread(fid,1,'uint8');
                Ns(jj) = EM_WaterColumn.NumberOfSamples{i107}(jj);
                EM_WaterColumn.SampleAmplitude{i107}{jj}               = fread(fid,Ns(jj),'int8');
            end
            % "spare byte if required to get even length (always 0 if used)"
            if floor((Nrx*10+sum(Ns))/2) == (Nrx*10+sum(Ns))/2
                % even so far, since ETX is 1 byte, add a spare here
                EM_WaterColumn.Spare4(i107)                            = fread(fid,1,'uint8');
            else
                % odd so far, since ETX is 1 bytes, no spare
                EM_WaterColumn.Spare4(i107) = NaN;
            end
            EM_WaterColumn.ETX(i107)                               = fread(fid,1,'uint8');
            EM_WaterColumn.CheckSum(i107)                          = fread(fid,1,'uint16');
            
            % ETX check
            if EM_WaterColumn.ETX(i107)~=3,
                error('wrong ETX value (EM_WaterColumn)');
            end
            
            % confirm parsing
            parsed = 1;
            
        case 110
            
            datagTypeText = 'NETWORK ATTITUDE VELOCITY DATAGRAM 110 (6EH)';
            
            % counter for this type of datagram
            try i110=i110+1; catch, i110=1; end
            counter = i110;
            
            % parsing
            EM_NetworkAttitude.NumberOfBytesInDatagram(i110)                    = nbDatag;
            EM_NetworkAttitude.STX(i110)                                        = stxDatag;
            EM_NetworkAttitude.TypeOfDatagram(i110)                             = datagTypeNumber;
            EM_NetworkAttitude.EMModelNumber(i110)                              = emNumber;
            EM_NetworkAttitude.Date(i110)                                       = date;
            EM_NetworkAttitude.TimeSinceMidnightInMilliseconds(i110)            = timeSinceMidnightInMilliseconds;
            EM_NetworkAttitude.NetworkAttitudeCounter(i110)                     = number;
            EM_NetworkAttitude.SystemSerialNumber(i110)                         = systemSerialNumber;
            
            EM_NetworkAttitude.NumberOfEntries(i110)                            = fread(fid,1,'uint16'); %N
            EM_NetworkAttitude.SensorSystemDescriptor(i110)                     = fread(fid,1,'int8');
            EM_NetworkAttitude.Spare(i110)                                      = fread(fid,1,'uint8');
            % repeat cycle: N entries of a variable number of bits. Using a for loop
            N = EM_NetworkAttitude.NumberOfEntries(i110);
            Nx = nan(1,N);
            for jj=1:N
                EM_NetworkAttitude.TimeInMillisecondsSinceRecordStart{i110}(jj)     = fread(fid,1,'uint16');
                EM_NetworkAttitude.Roll{i110}(jj)                                   = fread(fid,1,'int16');
                EM_NetworkAttitude.Pitch{i110}(jj)                                  = fread(fid,1,'int16');
                EM_NetworkAttitude.Heave{i110}(jj)                                  = fread(fid,1,'int16');
                EM_NetworkAttitude.Heading{i110}(jj)                                = fread(fid,1,'uint16');
                EM_NetworkAttitude.NumberOfBytesInInputDatagrams{i110}(jj)          = fread(fid,1,'uint8'); %Nx
                Nx(jj) = EM_NetworkAttitude.NumberOfBytesInInputDatagrams{i110}(jj);
                EM_NetworkAttitude.NetworkAttitudeInputDatagramAsReceived{i110}{jj} = fread(fid,Nx(jj),'uint8');
            end
            % "spare byte if required to get even length (always 0 if used)"
            if floor((N*11+sum(Nx))/2) == (N*11+sum(Nx))/2
                % even so far, since ETX is 1 byte, add a spare here
                EM_NetworkAttitude.Spare2(i110)                                    = fread(fid,1,'uint8');
            else
                % odd so far, since ETX is 1 bytes, no spare
                EM_NetworkAttitude.Spare2(i110) = NaN;
            end
            EM_NetworkAttitude.ETX(i110)                                           = fread(fid,1,'uint8');
            EM_NetworkAttitude.CheckSum(i110)                                      = fread(fid,1,'uint16');
            
            % ETX check
            if EM_NetworkAttitude.ETX(i110)~=3
                error('wrong ETX value (EM_NetworkAttitude)');
            end
            
            % confirm parsing
            parsed = 1;
            
        otherwise
            
            % this datagTypeNumber is not recognized yet
            datagTypeText = {sprintf('UNKNOWN DATAGRAM (%sH)',dec2hex(datagTypeNumber))};
               
    end
    
    % write output ALLfileinfo
    if nargout
        kk = kk+1;
        ALLfileinfo.datagNumberInFile(kk,1) = kk;
        ALLfileinfo.datagPositionInFile(kk,1) = pif;
        ALLfileinfo.datagTypeNumber(kk,1) = datagTypeNumber;
        ALLfileinfo.datagTypeText{kk,1} = datagTypeText;
        ALLfileinfo.parsed(kk,1) = parsed;
        ALLfileinfo.counter(kk,1) = counter;
        ALLfileinfo.number(kk,1) = number;
        ALLfileinfo.size(kk,1) = nbDatag;
        ALLfileinfo.syncCounter(kk,1) = syncCounter;
        ALLfileinfo.emNumber(kk,1) = emNumber;
        ALLfileinfo.date(kk,1) = date;
        ALLfileinfo.timeSinceMidnightInMilliseconds(kk,1) = timeSinceMidnightInMilliseconds;
    end
    
    % reinitialize synccounter
    syncCounter = 0;
    
    % go to end of datagram
    fseek(fid,pif+4+nbDatag,-1);
    
end


%% saving data
fclose(fid);
save(MATfilename, '-regexp', 'EM\w*','-v7.3');

