function [XTFfileinfo] = CFF_convert_xtf_to_all(XTFfilename, ALLfilename, SVPfilename, InstallASCIIparam, EM_Runtime)
% function [XTFfileinfo] = CFF_convert_xtf_to_all(XTFfilename, ALLfilename, SVPfilename, InstallASCIIparam, EM_Runtime)
%
% DESCRIPTION
%
% code for converting EM3000 XTF files to SIMRAD ALL format.
%
% INPUT VARIABLES
%
% - XTFfilename (required): XTF file to convert.
%
% - ALLfilename (optional): output ALL file. Use empty string variable ''
% for default. As default, the ALL file is saved in same folder as input
% XTF file and bears the same name except for its extension. 
%
% - SVPfilename (optional): SVP dump file from EM3000 Controller, commonly
% named 'PuSvpU.txt'. Use empty string variable '' for default. As default,
% no Sound Speed Profile datagram is coded in the ALL file.
%
% - InstallASCIIparam (optional): ASCII parameters commonly found in Simrad
% Installation Parameters Start datagram. Content will be copied to the ALL
% file Installation Parameters Start and Stop datagrams. Use empty string
% variable '' for default. As default, ASCII data from datagrams obtained
% during DataDistrib tests on Tai Rangahau in Tairua (Jun-July 2009) is
% used.

% - EM_Runtime (optional): Simrad Runtime Parameters datagram, as created
% by function 'convall2mat', from which ASCII data will be copied to the
% ALL file Runtime Parameters datagram. Use empty array variable [] for
% default. As default, data from datagrams obtained during DataDistrib
% tests in Tairua (Jun-July 2009) will be used.
%
% OUTPUT VARIABLES
% 
% - XTFfileinfo (optional): structure for description of the contents of
% the XTF file. Fields are:
%   * XTFfilename
%   * filesize (in bytes)
%   * XTFheaderformat (endianness of XTF header, normally 'l')
%   * ALLdatagramsformat (endianness of ALL datagrams, normally 'b')
%   * XTFpackettypenumber (XTF packet type, in decimal)
%   * XTFpackettype (XTF packet type description)
%   * XTFpacketsize (in bytes)
%   * ALLdatagramtypenumber (SIMRAD datagram type in decimal, if relevant)
%   * ALLdatagramtype (SIMRAD datagram type description, if relevant)
%
% RESEARCH NOTES
%
% - The XTF file contains two simrad datagram types in their original form,
% they are copied directly in the ALL file: 
%       - SIMRAD 68 (44H, depth)
%       - SIMRAD 83 (53H, seabed image)
%
% - After inputing a SVP file to the EM3000 controller, it dumps all the
% information for a SIMRAD 85 (55H, sound speed profile) datagram in a text
% file. The dump file can be input in this function to add its content to
% the ALL file.
%
% - SIMRAD 80 (50H, position) and 65 (41H, attitude) datagrams are
% reconstructed from XTFATTITTUDEDATA and XTFPINGHEADER contents. Detail
% comments are included in the code about this procedure.
%
% - SIMRAD 73 (49H, installation parameters - start), 82 (52H, runtime
% parameters) and 105 (69H, installation parameters - stop) do not exist in
% XTF files, hence the need for importing them.
%
% - Our XTF files are written in 'little indian' but the SIMRAD datagrams
% within are written in 'big endian'. This function opens the XTF file in
% 'l', so it reads its 'l' TRITON content without specifying the format,
% but it reads its 'b' SIMRAD content by specifying the 'b' format.
%
% - This function creates a ALL file in 'b', so it writes any content
% without specifying the format.
%
% - output XTFfileinfo is growing inside loops and makes the function much
% more longer. A 20Mo XTF test file is converted in 530sec with this
% output, against 40sec without. Do not use if not required.
%
% REQUIRED IMPROVEMENTS
%
% - checksum are wrong
%
% NEW FEATURES
%
% - v0.4.1
%   - modified order of input variables ALL and SVP filenames, and allowed
%   to enter empty variables in order to have more flexibility in desired
%   input.
%   - reverted back to use ASCII datagram in input rather than the matlab
%   version "EM_InstallationStart".
% - v0.4
%   - improved comments and general code
%   - optional output information file
%   - survey line number default at 1
%   - default installation and runtime parameters are really from our
%   system now :)
%   - change format for optional input Installation Parameters ASCII data
%   - added optional input for Runtime parameters
% - v0.3.1:
%   - optional output ALL file name
%   - updated some parameters in runtime datagrams with luciano's EM3000
%   files
% - v0.3:
%   - comments improvements  
%   - POSITION time stamp issue found and solved
% - v0.2:
%   - soundspeed profiles supported
%   - fixed Date in POSITION and ATTITUDE datagrams
%   - ascii data in INSTALLATION datagrams supported
% - v0.1
%   - Now recording heave in attitude data packets (Hypack requirement).
%   Even though dvpt code showed that the value in Position datagrams are
%   probably better to use.
% 
%%%
% Alex Schimel, University of Waikato
% Version 1.0 (06-Jan-2011)
%%%

%% tests on input variables 

% if no input ALLfilename
if nargin<2 || isempty(ALLfilename)
    % use same directory as XTF file
    ALLfilename = [XTFfilename(1:end-3) 'all'];
end

%% opening XTF file and creating ALL file

[fid, message] = fopen(XTFfilename, 'r', 'l');
[fid2,message] = fopen(ALLfilename,'w', 'b');

% number of bytes in XTF file
temp = fread(fid,inf,'uint8');
filesize = length(temp);
clear temp
fseek(fid,0,-1);
    
%% create ouptut info file if required
if nargout
    XTFfileinfo.XTFfilename = XTFfilename;

    XTFfileinfo.filesize = filesize;

    % XTF byte ordering
    % this is default for UOW system, tests may be written to check other systems
    XTFfileinfo.XTFheaderformat = 'l';
    XTFfileinfo.ALLdatagramsformat = 'b';
end


%% info

% first of all, we need to write 3 important datagrams:
% 73 (49H): installation parameters - start
% 82 (52H): runtime parameters
% 85 (55H): sound speed profile
%
% but there is no useful data in the XTFFILEHEADER for these datagrams.
% However, the time information from the first DEPTH packet can be used. We
% need to extract it.

%% Get the first DEPTH datagram time information

% set file position indicator at the end of XTFFILEHEADER if less than 6
% channels (the case for our EM3000)
fseek(fid,1024,'bof');

while 1
    
    point = ftell(fid); % beginning of the Triton Header
    dataType = fread(fid,[10,1],'uint8');
        % uint16 MagicNumber
        % uint8  HeaderType = dataType(3)
        % uint8  SerialPort
        % uint16 NumChansToFollow
        % uint16 Reserved1
        % uint16 Reserved2
    ndata = fread(fid,1,'uint32'); % NumBytesThisRecord
    
    if dataType(3) == 2
        % new XTFPINGHEADER
        fseek(fid,point+256,'bof'); % now in SIMRAD datagram
        NumberOfBytesInDatagram = fread(fid,1,'uint32','b');
        STX = fread(fid,1,'uint8','b');
        TypeOfDatagram = fread(fid,1,'uint8','b');
        if STX == 2 && TypeOfDatagram == 68 
            % ok this is a DEPTH datagram
            EMModelNumber = fread(fid,1,'uint16','b');
            LastDepthDate = fread(fid,1,'uint32','b');
            LastDepthTimeSinceMidnight = fread(fid,1,'uint32','b');
            PingCounter = fread(fid,1,'uint16','b');
            SystemSerialNumber = fread(fid,1,'uint16','b');
            break
        end
    end
    fseek(fid,point+ndata,-1);
end

% set file position indicator at the end of XTFFILEHEADER if less than 6
% channels (the case for our EM3000)
fseek(fid,1024,'bof');


%% write INSTALLATION PARAMETERS - START (73, 49H)

if nargin<4 || isempty(InstallASCIIparam)
    % using default values from DataDistrib tests in Tairua (Jun-July 2009)
    InstallASCIIparam = 'WLZ=-0.09,SMH=106,S1Z=0.79,S1X=4.71,S1Y=0.01,S1H=0.00,S1R=0.00,S1P=0.00,GO1=0.00,TSV=1.6.3 011217 ,RSV=,BSV=1.7.6 040222,PSV=3.0.7 031028,DSV=3.0.6 000404,DSD=0,DSO=0.000000,DSF=1.000000,DSH=NI,APS=0,P1M=1,P1T=1,P1Z=-2.88,P1X=2.13,P1Y=-0.94,P1D=0.00,P2M=0,P2T=0,P2Z=0.00,P2X=0.00,P2Y=0.00,P2D=0.00,P3M=0,P3T=0,P3Z=0.00,P3X=0.00,P3Y=0.00,P3D=0.00,P3S=1,MSZ=-0.77,MSX=3.51,MSY=0.01,MRP=RP,MSD=0,MSR=0.00,MSP=0.00,MSG=0.00,NSZ=0.00,NSX=0.00,NSY=0.00,NRP=HO,NSD=0,NSR=0.00,NSP=0.00,NSG=0.00,GCG=0.00,AHS=4,ARO=2,API=2,AHE=2,MAS=1.000,';
end

% This datagram is 21 bytes of binary data, InstallASCIIsize bytes of characters
% and one spare byte if the total is not even.
InstallASCIIsize = length(InstallASCIIparam);
DTGRMsize = 2.*ceil((InstallASCIIsize+21)./2);

% now write INSTALLATION PARAMETERS - START (73, 49H)
fwrite(fid2, DTGRMsize, 'uint32');                  % NumberOfBytesInDatagram
fwrite(fid2, 2, 'uint8');                           % STX
fwrite(fid2, 73, 'uint8');                          % TypeOfDatagram
fwrite(fid2, 3000, 'uint16');                       % EMModelNumber
fwrite(fid2, LastDepthDate, 'uint32');              % Date                              - from first depth packet
fwrite(fid2, LastDepthTimeSinceMidnight, 'uint32'); % TimeSinceMidnightInMilliseconds   - from first depth packet
fwrite(fid2, 1, 'uint16');                          % SurveyLineNumber
fwrite(fid2, SystemSerialNumber, 'uint16');         % SystemSerialNumber                - from first depth packet
fwrite(fid2, 0, 'uint16');                          % SerialNumberOfSecondSonarHead
fwrite(fid2, InstallASCIIparam, 'char');                   % ASCII parameters

%spare byte to add if no ASCII or even ASCII size:
if DTGRMsize~=InstallASCIIsize+21
    fwrite(fid2, 0, 'uint8');                       % Spare
end
fwrite(fid2, 3, 'uint8');                           % ETX
fwrite(fid2, DTGRMsize-4,'uint16');                 % checksum


%% write RUNTIME PARAMETERS (82, 52H)

if nargin>4 && ~isempty(EM_Runtime)
    
    fwrite(fid2, 52, 'uint32');                                                 %NumberOfBytesInDatagram 
    fwrite(fid2, 2, 'uint8');                                                   %STX                  
    fwrite(fid2, 82, 'uint8');                                                  %TypeOfDatagram            
    fwrite(fid2, 3000, 'uint16');                                               %EMModelNumber                   
    fwrite(fid2, LastDepthDate, 'uint32');                                      %Date                            - from first depth packet
    fwrite(fid2, LastDepthTimeSinceMidnight, 'uint32');                         %TimeSinceMidnightInMilliseconds - from first depth packet
    fwrite(fid2, PingCounter, 'uint16');                                        %PingCounter                     - from first depth packet
    fwrite(fid2, SystemSerialNumber, 'uint16');                                 %SystemSerialNumber              - from first depth packet
    if sum(diff(EM_Runtime.OperatorStationStatus) == 0) ~= length(EM_Runtime.OperatorStationStatus)-1, warning('The ''OperatorStationStatus'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.OperatorStationStatus(1), 'uint8');                 % 0 means no error
    if sum(diff(EM_Runtime.ProcessingUnitStatus) == 0) ~= length(EM_Runtime.ProcessingUnitStatus)-1, warning('The ''ProcessingUnitStatus'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.ProcessingUnitStatus(1), 'uint8');                  % 0 means no error
    if sum(diff(EM_Runtime.BSPStatus) == 0) ~= length(EM_Runtime.BSPStatus)-1, warning('The ''BSPStatus'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.BSPStatus(1), 'uint8');                             % 0 means no error
    if sum(diff(EM_Runtime.SonarHeadStatus) == 0) ~= length(EM_Runtime.SonarHeadStatus)-1, warning('The ''SonarHeadStatus'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.SonarHeadStatus(1), 'uint8');                       % 0 means no error
    if sum(diff(EM_Runtime.Mode) == 0) ~= length(EM_Runtime.Mode)-1, warning('The ''Mode'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.Mode(1), 'uint8');                      
    if sum(diff(EM_Runtime.FilterIdentifier) == 0) ~= length(EM_Runtime.FilterIdentifier)-1, warning('The ''FilterIdentifier'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.FilterIdentifier(1), 'uint8');             
    if sum(diff(EM_Runtime.MinimumDepth) == 0) ~= length(EM_Runtime.MinimumDepth)-1, warning('The ''MinimumDepth'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.MinimumDepth(1), 'uint16');                                         
    if sum(diff(EM_Runtime.MaximumDepth) == 0) ~= length(EM_Runtime.MaximumDepth)-1, warning('The ''MaximumDepth'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.MaximumDepth(1), 'uint16');
    if sum(diff(EM_Runtime.AbsorptionCoefficient) == 0) ~= length(EM_Runtime.AbsorptionCoefficient)-1, warning('The ''AbsorptionCoefficient'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.AbsorptionCoefficient(1), 'uint16');
    if sum(diff(EM_Runtime.TransmitPulseLength) == 0) ~= length(EM_Runtime.TransmitPulseLength)-1, warning('The ''TransmitPulseLength'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.TransmitPulseLength(1), 'uint16');
    if sum(diff(EM_Runtime.TransmitBeamwidth) == 0) ~= length(EM_Runtime.TransmitBeamwidth)-1, warning('The ''TransmitBeamwidth'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.TransmitBeamwidth(1), 'uint16');
    if sum(diff(EM_Runtime.TransmitPowerReMaximum) == 0) ~= length(EM_Runtime.TransmitPowerReMaximum)-1, warning('The ''TransmitPowerReMaximum'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.TransmitPowerReMaximum(1), 'int8');
    if sum(diff(EM_Runtime.ReceiveBeamwidth) == 0) ~= length(EM_Runtime.ReceiveBeamwidth)-1, warning('The ''ReceiveBeamwidth'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.ReceiveBeamwidth(1), 'uint8');
    if sum(diff(EM_Runtime.ReceiveBandwidth) == 0) ~= length(EM_Runtime.ReceiveBandwidth)-1, warning('The ''ReceiveBandwidth'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.ReceiveBandwidth(1), 'uint8');
    if sum(diff(EM_Runtime.ReceiverFixedGainSetting) == 0) ~= length(EM_Runtime.ReceiverFixedGainSetting)-1, warning('The ''ReceiverFixedGainSetting'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.ReceiverFixedGainSetting(1), 'uint8');
    if sum(diff(EM_Runtime.TVGLawCrossoverAngle) == 0) ~= length(EM_Runtime.TVGLawCrossoverAngle)-1, warning('The ''TVGLawCrossoverAngle'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.TVGLawCrossoverAngle(1), 'uint8');
    if sum(diff(EM_Runtime.SourceOfSoundSpeedAtTransducer) == 0) ~= length(EM_Runtime.SourceOfSoundSpeedAtTransducer)-1, warning('The ''SourceOfSoundSpeedAtTransducer'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.SourceOfSoundSpeedAtTransducer(1), 'uint8');          % 1 means "manually entered by operator" 
    if sum(diff(EM_Runtime.MaximumPortSwathWidth) == 0) ~= length(EM_Runtime.MaximumPortSwathWidth)-1, warning('The ''MaximumPortSwathWidth'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.MaximumPortSwathWidth(1), 'uint16');
    if sum(diff(EM_Runtime.BeamSpacing) == 0) ~= length(EM_Runtime.BeamSpacing)-1, warning('The ''BeamSpacing'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.BeamSpacing(1), 'uint8');
    if sum(diff(EM_Runtime.MaximumPortCoverage) == 0) ~= length(EM_Runtime.MaximumPortCoverage)-1, warning('The ''MaximumPortCoverage'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.MaximumPortCoverage(1), 'uint8');
    if sum(diff(EM_Runtime.YawAndPitchStabilizationMode) == 0) ~= length(EM_Runtime.YawAndPitchStabilizationMode)-1, warning('The ''YawAndPitchStabilizationMode'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.YawAndPitchStabilizationMode(1), 'uint8');
    if sum(diff(EM_Runtime.MaximumStarboardCoverage) == 0) ~= length(EM_Runtime.MaximumStarboardCoverage)-1, warning('The ''MaximumStarboardCoverage'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.MaximumStarboardCoverage(1), 'uint8');
    if sum(diff(EM_Runtime.MaximumStarboardSwathWidth) == 0) ~= length(EM_Runtime.MaximumStarboardSwathWidth)-1, warning('The ''MaximumStarboardSwathWidth'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.MaximumStarboardSwathWidth(1), 'uint16');
    if sum(diff(EM_Runtime.DurotongSpeed) == 0) ~= length(EM_Runtime.DurotongSpeed)-1, warning('The ''DurotongSpeed'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.DurotongSpeed(1), 'uint16');
    if sum(diff(EM_Runtime.HiLoFrequencyAbsorptionCoefficientRatio) == 0) ~= length(EM_Runtime.HiLoFrequencyAbsorptionCoefficientRatio)-1, warning('The ''HiLoFrequencyAbsorptionCoefficientRatio'' fields in input Runtime Parameters datagrams are not all identical. Only the value from the first datagram was conserved.'); end
    fwrite(fid2, EM_Runtime.HiLoFrequencyAbsorptionCoefficientRatio(1), 'uint8');
    fwrite(fid2, 3, 'uint8');                                                     %ETX                        
    fwrite(fid2, 52-4, 'uint16');                                                 %CheckSum      
    
else
    
    % using default values from DataDistrib tests in Tairua (Jun-July 2009)
    
    fwrite(fid2, 52, 'uint32');                         %NumberOfBytesInDatagram 
    fwrite(fid2, 2, 'uint8');                           %STX                  
    fwrite(fid2, 82, 'uint8');                          %TypeOfDatagram            
    fwrite(fid2, 3000, 'uint16');                       %EMModelNumber                   
    fwrite(fid2, LastDepthDate, 'uint32');              %Date                                    - from first depth packet
    fwrite(fid2, LastDepthTimeSinceMidnight, 'uint32'); %TimeSinceMidnightInMilliseconds         - from first depth packet
    fwrite(fid2, PingCounter, 'uint16');                %PingCounter                             - from first depth packet
    fwrite(fid2, SystemSerialNumber, 'uint16');         %SystemSerialNumber                      - from first depth packet
    fwrite(fid2, 0, 'uint8');                           %OperatorStationStatus                   - 0 means no error
    fwrite(fid2, 0, 'uint8');                           %ProcessingUnitStatus                    - 0 means no error
    fwrite(fid2, 0, 'uint8');                           %BSPStatus                               - 0 means no error
    fwrite(fid2, 0, 'uint8');                           %SonarHeadStatus                         - 0 means no error
    fwrite(fid2, 1, 'uint8');                           %Mode
    fwrite(fid2, 14, 'uint8');                          %FilterIdentifier
    fwrite(fid2, 0, 'uint16');                          %MinimumDepth                            
    fwrite(fid2, 150, 'uint16');                        %MaximumDepth
    fwrite(fid2, 6000, 'uint16');                       %AbsorptionCoefficient
    fwrite(fid2, 150, 'uint16');                        %TransmitPulseLength
    fwrite(fid2, 15, 'uint16');                         %TransmitBeamwidth
    fwrite(fid2, 0, 'int8');                            %TransmitPowerReMaximum
    fwrite(fid2, 15, 'uint8');                          %ReceiveBeamwidth
    fwrite(fid2, 160, 'uint8');                         %ReceiveBandwidth
    fwrite(fid2, 30, 'uint8');                          %ReceiverFixedGainSetting
    fwrite(fid2, 15, 'uint8');                          %TVGLawCrossoverAngle
    fwrite(fid2, 2, 'uint8');                           %SourceOfSoundSpeedAtTransducer          - 1 means "manually entered by operator" 
    fwrite(fid2, 150, 'uint16');                        %MaximumPortSwathWidth
    fwrite(fid2, 0, 'uint8');                           %BeamSpacing
    fwrite(fid2, 65, 'uint8');                          %MaximumPortCoverage
    fwrite(fid2, 128, 'uint8');                         %YawAndPitchStabilizationMode
    fwrite(fid2, 65, 'uint8');                          %MaximumStarboardCoverage
    fwrite(fid2, 150, 'uint16');                        %MaximumStarboardSwathWidth
    fwrite(fid2, 0, 'uint16');                          %DurotongSpeed
    fwrite(fid2, 255, 'uint8');                         %HiLoFrequencyAbsorptionCoefficientRatio
    fwrite(fid2, 3, 'uint8');                           %ETX
    fwrite(fid2, 52-4, 'uint16');                       %CheckSum
    
end

%% write SOUND SPEED PROFILE (85, 55H)

if nargin>2 && ~isempty(SVPfilename)
    
    % read SVP data
    [fid4, message] = fopen(SVPfilename, 'r', 'l');
    SVPHeader = textscan(fid4,'%s %s',11, 'Delimiter', '=', 'HeaderLines', 1);
    SVPHeader = [SVPHeader{1,1} SVPHeader{1,2}];
    SVPData = textscan(fid4,'%u32 %u32','HeaderLines',3);
    SVPData = [SVPData{1,1} SVPData{1,2}];
    fclose(fid4);
    N = uint16(str2num(cell2mat(SVPHeader(10,2)))); % NumberOfEntries (N)  

    % write SOUND SPEED PROFILE (85, 55H)
    fwrite(fid2, 32+N.*8, 'uint32');                                    % NumberOfBytesInDatagram
    fwrite(fid2, 2, 'uint8');                                           % STX
    fwrite(fid2, 85, 'uint8');                                          % TypeOfDatagram
    fwrite(fid2, 3000, 'uint16');                                       % EMModelNumber
    fwrite(fid2, uint32(str2num(cell2mat(SVPHeader(4,2)))), 'uint32');  % Date                                              - from SVP file header
    fwrite(fid2, uint32(str2num(cell2mat(SVPHeader(5,2)))), 'uint32');  % TimeSinceMidnightInMilliseconds                   - from SVP file header
    fwrite(fid2, uint16(str2num(cell2mat(SVPHeader(6,2)))), 'uint16');  % ProfileCounter                                    - from SVP file header
    fwrite(fid2, uint16(str2num(cell2mat(SVPHeader(7,2)))), 'uint16');  % SystemSerialNumber                                - from SVP file header
    fwrite(fid2, uint32(str2num(cell2mat(SVPHeader(8,2)))), 'uint32');  % DateWhenProfileWasMade                            - from SVP file header
    fwrite(fid2, uint32(str2num(cell2mat(SVPHeader(9,2)))), 'uint32');  % TimeSinceMidnightInMillisecondsWhenProfileWasMade - from SVP file header
    fwrite(fid2, N, 'uint16');                                          % NumberOfEntries (N)                               - from SVP file header
    fwrite(fid2, uint16(str2num(cell2mat(SVPHeader(11,2)))), 'uint16'); % DepthResolution                                   - from SVP file header
    % repeat cycle: N entries of 8 bits
        fseek(fid2,-8+4,'cof'); % we need to come back before first jump
        temp = ftell(fid2);
        fwrite(fid2, SVPData(:,1), 'uint32', 8-4);                      % Depth (in cm)
        fseek(fid2,temp+4,'bof'); % to next data type
        fwrite(fid2, SVPData(:,2), 'uint32',8-4);                       % SoundSpeed (in dm/s)
    fwrite(fid2, 0, 'uint8');                                           % Spare                                             - always required
    fwrite(fid2, 3, 'uint8');                                           % ETX
    fwrite(fid2, 32+N.*8-4,'uint16');                                   % CheckSum

end


%% info

% Some recurring datagrams in EM3000 files:
%
% 102 (66H): raw range and beam angle (f)
%       -> this one doesn't exist in XTF files
%
% 68 (44H): depth
% 83 (53H): seabed image
%       -> these two exist as SIMRAD datagrams in the XTF files. We just
%       have to extract and copy them.
%
% 67 (43H): clock
%       -> various time values exist in XTF but none was identified to be
%       related to some external clock.
%
% 65 (41H): attitude
%       -> We've seen that some of the XTFATTITUDEDATA packets in a XTF
%       file were written using input SIMRAD ATTITUDE datagrams. We've seen
%       that ISIS extracted all the cycle of data from ATTITUDE and write
%       as many XTFATTITUDEDATA packets as needed. So the idea is
%       to compile all these XTFATTITUDEDATA back into a single ATTITUDE.
%       The difficulty here is to be sure to find which of the
%       XTFATTITUDEDATA packets were made from a ATTITUDE datagram and not
%       POSITION
%
% 104 (68H): depth (pressure) or height
%       -> this datagram is reserved to systems that can derive altitude
%       data from GPS systems. I have found this type of data nowhere in my
%       XTF files.
%
% 80 (50H): position
%       -> We've seen that POSITION datagrams data were used by ISIS to
%       create ONE XTFATTITUDEDATA packet and complete the following 
%       XTFPINGHEADER packets until new POSITION is received. The created
%       XTFATTITUDEDATA packet does not contain all information (only time
%       and heading) so we can't use it to re-create the POSITION datagram.
%       However, the following XTFPINGHEADER packet has (almost) all needed
%       data to recreate the latest POSITION datagram for each depth or
%       seabedimage datagram. Therefore we extract position data from those
%       PINGHEADERS.
%       Note 1: because of the procedure described before, consecutive
%       XTFPINGHEADERS can have the same position data if it has not been
%       updated. In order to avoid writing repetitive data, we add a test
%       of time update before writing
%       Note 2: Some of the rest of the data the POSITION datagram usually
%       contains is lost. 
%       Note 3: In the ALL files we've been provided, we have one POSITION
%       datagram every 5 or 6 couples of DEPTH / SEABEDIMAGE datagrams,
%       whereas our XTF files have much denser navigation information. It
%       would be good to check and compare GPS input rate and ping rate. !!!
%
% 49 (31H): PU status output
%       -> this datagram is only used for acquisition monitoring. It is
%       not useful to create some here.
%
% 71 (47H): surface sound speed
%       -> we don't have an instrument measuring soundspeed at surface in
%       real-time. We use the same value from the profile. our XTF files
%       don't contain this information anyway.


%% Reading XTF packets and writing ALL datagrams

% inititalize depthtoken:
depthtoken = 0;

% inititalize u32jump:
u32jump = 0;

% intitializing XTFpackets counter (used only if XTFfileinfo has been called)
kk = 0;

while 1
    
    point = ftell(fid); % beginning of the Triton Header
    dataType = fread(fid,[10,1],'uint8');
        if isempty(dataType), break; end % file finished, leave the loop
        % uint16 MagicNumber
        % uint8  HeaderType = dataType(3)
        % uint8  SerialPort
        % uint16 NumChansToFollow
        % uint16 Reserved1
        % uint16 Reserved2
    ndata = fread(fid,1,'uint32'); % NumBytesThisRecord

    switch dataType(3)

        case 3
            % new XTFATTITUDEDATA packet

            if nargout
                % file information
                kk = kk +1;
                XTFfileinfo.XTFpackettypenumber(kk) = dataType(3);
                XTFfileinfo.XTFpackettype(kk,1) = {'XTFATTITUDEDATA'};
                XTFfileinfo.XTFpacketsize(kk) = ndata;
                XTFfileinfo.ALLdatagramtypenumber(kk) = NaN;
                XTFfileinfo.ALLdatagramtype(kk,1) = {'N/A'};
            end
            
            % we first need to check if this packet contains ATTITUDE
            % data (to save) or POSITION (to discard). If it is
            % ATTITUDE, many more should follow. So let's save its data
            % for the moment and not write it yet 

            if ~exist('ATTITUDE','var'), ii=1; else ii=size(ATTITUDE,2)+1; end % datapacket counter

            % read and save data
            fseek(fid,point+30,'bof');
                ATTITUDE(ii).Pitch = fread(fid,1,'float32');    % unit? assumed to be degrees
                ATTITUDE(ii).Roll = fread(fid,1,'float32');     % unit? assumed to be degrees
                ATTITUDE(ii).Heave = fread(fid,1,'float32');    % unit? assumed to be meters. a note in XTF format description about Heave sign being reversed??? we keep the current sign for the moment !!!
                ATTITUDE(ii).Yaw = fread(fid,1,'float32');      % unit? assumed to be degrees
                ATTITUDE(ii).TimeTag = fread(fid,1,'uint32');
                ATTITUDE(ii).Heading = fread(fid,1,'float32');  % in degrees
            
            
        case 2
            % new XTFPINGHEADER packet

            if nargout
                % file information
                kk = kk +1;
                XTFfileinfo.XTFpackettypenumber(kk) = dataType(3);
                XTFfileinfo.XTFpackettype(kk,1) = {'XTFPINGHEADER'};
                XTFfileinfo.XTFpacketsize(kk) = ndata;
            end
                
            % Let's start by seeing if we just finished reading some
            % XTFATTITUDEDATA packets in series

            if ( exist('ATTITUDE','var') && size(ATTITUDE,2)>9 )

                % yes, we just saved at least 10 packets. ATTITUDE data
                % usually comes in ~100 packets. This test is here to
                % eliminate the cases when several POSITION datagrams
                % created a few packets in a row

                % find the ATTITUDE data within
                % this operation is difficult. How to be entierly sure
                % to make the difference between XTFATTITUDEDATA
                % packets that came from ATTITUDE datagrams and from
                % POSITION datagrams ? The solution below is based on
                % the time increments. it seems to work fine enough for
                % our files.

                % index for which time is less than next value but no more than 3* the normal time step 
                yo = [-inf diff([ATTITUDE(:).TimeTag]) inf];
                index2a = (yo > 0) & (yo < 3.*median(yo));
                index2a(1) = []; % eliminate inf

                % index for which time is less than previous value but no more than 3* the normal time step 
                yo = [0 yo];
                index2b = (yo > 0) & (yo < 3.*median(yo));
                index2b(1) = []; % eliminate introduced value
                index2b(end) = []; % eliminate inf

                index2 = find( index2a | index2b ); % index for which time is good compared to at least one of its neighbour

                index = index2; % use only index2 for the moment

%                     % plot for checking out the detection. breakpoint at clf 
%                     figure(99);
%                     clf
%                     subplot(211); grid on; hold on
%                     plot([ATTITUDE(:).Heading],'.-')
%                     plot(index,[ATTITUDE(index).Heading],'ro-')
%                     subplot(212); grid on; hold on
%                     plot([ATTITUDE(:).TimeTag],'.-')
%                     plot(index,[ATTITUDE(index).TimeTag],'ro-')

                % keep only the good packets
                ATTITUDE = ATTITUDE(index);

                % now we need to guess ATTITUDE date (original data is
                % missing) from the last DEPTH date. We compare the
                % ATTITUDE time to the last DEPTH time. If similar,
                % then date is the same, if very different, then we
                % have a date jump and we need to compensate for it.
                TimeTest =  ATTITUDE(1).TimeTag - LastDepthTimeSinceMidnight;
                if TimeTest > 43000000
                    NewAttitudeDate = LastDepthDate-1; % ATTITUDE time is very large compared to DEPTH time. Means ATTITUDE is one day behind DEPTH
                elseif TimeTest < -43000000
                    NewAttitudeDate = LastDepthDate+1; % ATTITUDE time is very small compared to DEPTH time. Means ATTITUDE is one day ahead DEPTH
                else
                    NewAttitudeDate = LastDepthDate;   % ATTITUDE time is very similar to DEPTH time. Means ATTITUDE is same day as DEPTH
                end


                % write ATTITUDE (65, 41H)
                fwrite(fid2, 22+size(ATTITUDE,2).*12, 'uint32');                                % NumberOfBytesInDatagram
                fwrite(fid2, 2, 'uint8');                                                       % STX
                fwrite(fid2, 65, 'uint8');                                                      % TypeOfDatagram
                fwrite(fid2, 3000, 'uint16');                                                   % EMModelNumber
                fwrite(fid2, NewAttitudeDate, 'uint32');                                        % Date                               - data unavailable. We guess the date from last depth packet (see test before)
                fwrite(fid2, ATTITUDE(1).TimeTag, 'uint32');                                    % TimeSinceMidnightInMilliseconds    - ok, should be original data
                fwrite(fid2, 0, 'uint16');                                                      % AttitudeCounter                    - ? data unavailable
                fwrite(fid2, SystemSerialNumber, 'uint16');                                     % SystemSerialNumber                 - ? from first depth packet
                fwrite(fid2, size(ATTITUDE,2), 'uint16');                                       % NumberOfEntries
                % repeat cycle: N entries of 12 bits
                    fseek(fid2,-12+2,'cof'); % we need to come back before first jump
                    temp = ftell(fid2);
                    fwrite(fid2, [ATTITUDE(:).TimeTag]-ATTITUDE(1).TimeTag, 'uint16', 12-2);    % TimeInMillisecondsSinceRecordStart
                    fseek(fid2,temp+2,'bof'); % to next data type
                    fwrite(fid2, ones(1,size(ATTITUDE,2)), 'uint16',12-2);                      % SensorStatus
                    fseek(fid2,temp+4,'bof'); % to next data type
                    fwrite(fid2, round([ATTITUDE(:).Roll].*100), 'int16',12-2);                 % Roll                               - in 0.01 degrees
                    fseek(fid2,temp+6,'bof'); % to next data type
                    fwrite(fid2, round([ATTITUDE(:).Pitch].*100), 'int16',12-2);                % Pitch                              - in 0.01 degrees
                    fseek(fid2,temp+8,'bof'); % to next data type
                    fwrite(fid2, round([ATTITUDE(:).Heave].*100), 'int16',12-2);                % Heave                              - in 0.01 m
                    fseek(fid2,temp+10,'bof'); % to next data type
                    fwrite(fid2, round([ATTITUDE(:).Heading].*100), 'uint16',12-2);             % Heading                            - in 0.01 degrees
                fwrite(fid2, 1, 'uint8');                                                       % SensorSystemDescriptor             - ? copied from Erik's example file
                fwrite(fid2, 3, 'uint8');                                                       % ETX
                fwrite(fid2, 22+size(ATTITUDE,2).*12-4,'uint16');                               % checksum

                % reset ATTITUDE structure
                clear ATTITUDE

            else
                % no, we recorded no XTFATTITUDEDATA or less than 10 packets,
                % which means it contains POSITION data that we can
                % discard. Let's just reset the ATTITUDE structure.
                clear ATTITUDE
            end

            % now, back to our current packet. XTFPINGHEADER contains
            % some data to code a POSITION datagram. Read it.
            fseek(fid,point+120,'bof');
                POS_ShipSpeed = fread(fid,1,'float32');         % speed
                POS_ShipGyro = fread(fid,1,'float32');          % heading
            fseek(fid,point+160,'bof');
                POS_SensorYcoordinate = fread(fid,1,'double');  % latitude
                POS_SensorXcoordinate = fread(fid,1,'double');  % longitude
            fseek(fid,point+232,'bof');
                POS_NavFixMilliseconds = fread(fid,1,'uint32'); % time

            % if this is the first POSITION data we have, record it:
            if ~exist('LASTPOS_NavFixMilliseconds','var')

                % Like ATTITUDE, we have no original data for POSITION date
                % (the date in XTFPINGHEADER is PING date). We use same
                % process to guess POSITION date
                TimeTest =  POS_NavFixMilliseconds - LastDepthTimeSinceMidnight;
                if TimeTest > 43000000
                    NewPositionDate = LastDepthDate-1; % POSITION time is very large compared to DEPTH time. Means POSITION is one day behind DEPTH
                elseif TimeTest < -43000000
                    NewPositionDate = LastDepthDate+1; % POSITION time is very small compared to DEPTH time. Means POSITION is one day ahead DEPTH
                else
                    NewPositionDate = LastDepthDate;   % POSITION time is very similar to DEPTH time. Means POSITION is same day as DEPTH
                end

                % write POSITION (80, 50H)
                fwrite(fid2, 38, 'uint32');                                     % NumberOfBytesInDatagram 
                fwrite(fid2, 2, 'uint8');                                       % STX 
                fwrite(fid2, 80, 'uint8');                                      % TypeOfDatagram 
                fwrite(fid2, 3000, 'uint16');                                   % EMModelNumber 
                fwrite(fid2, NewPositionDate, 'uint32');                        % Date                            - data unavailable. We guess the date from last depth packet (see test before)
                fwrite(fid2, POS_NavFixMilliseconds, 'uint32');                 % TimeSinceMidnightInMilliseconds - ok, should be original data
                fwrite(fid2, 0, 'uint16');                                      % PositionCounter                 - ? data unavailable
                fwrite(fid2, SystemSerialNumber, 'uint16');                     % SystemSerialNumber              - from first depth packet 
                fwrite(fid2, round(POS_SensorYcoordinate.*20000000), 'int32');  % Latitude
                fwrite(fid2, round(POS_SensorXcoordinate.*10000000), 'int32');  % Longitude
                fwrite(fid2, 15, 'uint16');                                     % MesureOfPositionFixQuality      - ? copied from Erik's example file
                fwrite(fid2, round(POS_ShipSpeed.*51.44444444444), 'uint16');   % SpeedOfVesselOverGround         - ShipSpeed in knots to be changed into cm./s. NOTE: this value in Erik's example file is weird !!!
                fwrite(fid2, round(POS_ShipGyro.*100), 'uint16');               % CourseOfVesselOverGround        - NOTE: this value in Erik's example file is weird !!!
                fwrite(fid2, round(POS_ShipGyro.*100), 'uint16');               % HeadingOfVessel                 - NOTE: this value in Erik's example file is good. NOTE: there is a second heading value in the XTFPINGHEADER, named SensorHeading, but we've seen ShipGyro is very probably the value recorded from a POSITION datagram
                fwrite(fid2, 193, 'uint8');                                     % PositionSystemDescriptor        - ? copied from Erik's example file
                fwrite(fid2, 0, 'uint8');                                       % NumberOfBytesInInputDatagram    - there is no input datagram following
                fwrite(fid2, 0, 'uint8');                                       % SpareByte                       - ok we need one in all cases because no datagram
                fwrite(fid2, 3, 'uint8');                                       % ETX 
                fwrite(fid2, 38-4,'uint16');                                    % checksum 

                % keep the original and corrected last values in memory
                LASTNEWPOS_NavFixMilliseconds = POS_NavFixMilliseconds;
                LASTPOS_NavFixMilliseconds = POS_NavFixMilliseconds;

            else       
                % we've recorded a previous POSITION datagram. Use it
                % to apply important correction to
                % POS_NavFixMilliseconds in case there is a date change 
                % within the file.

                if (POS_NavFixMilliseconds - LASTPOS_NavFixMilliseconds)<-(2.^32)./2
                    % a uint32 reset just happened, increase counter
                    u32jump = u32jump+1;
                end

                % now compensate for it (and previous jumps too)
                NEWPOS_NavFixMilliseconds = POS_NavFixMilliseconds + u32jump.*(2.^32);

                % now compensate for extra day jump
                temp = (NEWPOS_NavFixMilliseconds - LASTNEWPOS_NavFixMilliseconds)./86400000;
                NEWPOS_NavFixMilliseconds = NEWPOS_NavFixMilliseconds - floor(temp).*86400000;

                if NEWPOS_NavFixMilliseconds>=86400000
                    % finally, come back into the [0;86400000]
                    % range
                    NEWPOS_NavFixMilliseconds = NEWPOS_NavFixMilliseconds - 86400000;
                end

                % now record only if we don't have this data already
                if (NEWPOS_NavFixMilliseconds ~= LASTNEWPOS_NavFixMilliseconds)

                    % guess POSITION date
                    TimeTest =  NEWPOS_NavFixMilliseconds - LastDepthTimeSinceMidnight;
                    if TimeTest > 43000000
                        NewPositionDate = LastDepthDate-1; % POSITION time is very large compared to DEPTH time. Means POSITION is one day behind DEPTH
                    elseif TimeTest < -43000000
                        NewPositionDate = LastDepthDate+1; % POSITION time is very small compared to DEPTH time. Means POSITION is one day ahead DEPTH
                    else
                        NewPositionDate = LastDepthDate;   % POSITION time is very similar to DEPTH time. Means POSITION is same day as DEPTH
                    end

                    % write POSITION (80, 50H)
                    fwrite(fid2, 38, 'uint32');                                     % NumberOfBytesInDatagram 
                    fwrite(fid2, 2, 'uint8');                                       % STX 
                    fwrite(fid2, 80, 'uint8');                                      % TypeOfDatagram 
                    fwrite(fid2, 3000, 'uint16');                                   % EMModelNumber 
                    fwrite(fid2, NewPositionDate, 'uint32');                        % Date                            - data unavailable. We guess the date from last depth packet (see test before)
                    fwrite(fid2, NEWPOS_NavFixMilliseconds, 'uint32');              % TimeSinceMidnightInMilliseconds - ok, should be original data
                    fwrite(fid2, 0, 'uint16');                                      % PositionCounter                 - ? data unavailable
                    fwrite(fid2, SystemSerialNumber, 'uint16');                     % SystemSerialNumber              - from first depth packet 
                    fwrite(fid2, round(POS_SensorYcoordinate.*20000000), 'int32');  % Latitude
                    fwrite(fid2, round(POS_SensorXcoordinate.*10000000), 'int32');  % Longitude
                    fwrite(fid2, 15, 'uint16');                                     % MesureOfPositionFixQuality      - ? copied from Erik's example file
                    fwrite(fid2, round(POS_ShipSpeed.*51.44444444444), 'uint16');   % SpeedOfVesselOverGround         - ShipSpeed in knots to be changed into cm./s. NOTE: this value in Erik's example file is weird !!!
                    fwrite(fid2, round(POS_ShipGyro.*100), 'uint16');               % CourseOfVesselOverGround        - NOTE: this value in Erik's example file is weird !!!
                    fwrite(fid2, round(POS_ShipGyro.*100), 'uint16');               % HeadingOfVessel                 - NOTE: this value in Erik's example file is good. NOTE: there is a second heading value in the XTFPINGHEADER, named SensorHeading, but we've seen ShipGyro is very probably the value recorded from a POSITION datagram
                    fwrite(fid2, 193, 'uint8');                                     % PositionSystemDescriptor        - ? copied from Erik's example file
                    fwrite(fid2, 0, 'uint8');                                       % NumberOfBytesInInputDatagram    - there is no input datagram following
                    fwrite(fid2, 0, 'uint8');                                       % SpareByte                       - ok we need one in all cases because no datagram
                    fwrite(fid2, 3, 'uint8');                                       % ETX 
                    fwrite(fid2, 38-4,'uint16');                                    % checksum 

                end

                % keep the original and corrected last values in
                % memory for correction of next datagram
                LASTNEWPOS_NavFixMilliseconds = NEWPOS_NavFixMilliseconds;
                LASTPOS_NavFixMilliseconds = POS_NavFixMilliseconds;

            end

            fseek(fid,point+256,'bof'); % now in SIMRAD datagram
            NumberOfBytesInDatagram = fread(fid,1,'uint32','b');
            STX = fread(fid,1,'uint8','b');
            TypeOfDatagram = fread(fid,1,'uint8','b');                

            if TypeOfDatagram == 68

                if nargout
                    % file information
                    XTFfileinfo.ALLdatagramtypenumber(kk) = TypeOfDatagram;
                    XTFfileinfo.ALLdatagramtype(kk,1) = {'DEPTH (44H)'};
                end
            
                % saving some data for STOP datagram at end of file
                LastDepthEMModelNumber = fread(fid,1,'uint16','b');     % EMModelNumber
                LastDepthDate = fread(fid,1,'uint32','b');              % Date
                LastDepthTimeSinceMidnight = fread(fid,1,'uint32','b'); % TimeSinceMidnightInMilliseconds

                % write DEPTH (68,44H)
                fseek(fid,point+256,'bof');
                A = fread(fid,NumberOfBytesInDatagram+4);
                fwrite(fid2,A);
                depthtoken = 1; % ok, we have one DEPTH datagram written

            elseif (TypeOfDatagram == 83 && depthtoken == 1 ) % write only if one DEPTH datagram has already been written

                if nargout
                    % file information
                    XTFfileinfo.ALLdatagramtypenumber(kk) = TypeOfDatagram;
                    XTFfileinfo.ALLdatagramtype(kk,1) = {'SEABED IMAGE (53H)'};
                end
                
                % write SEABED IMAGE (83,53H)
                fseek(fid,point+256,'bof');
                A = fread(fid,NumberOfBytesInDatagram+4);
                fwrite(fid2,A);    

            elseif (TypeOfDatagram == 83 && depthtoken == 0 )

                if nargout
                    % file information
                    XTFfileinfo.ALLdatagramtypenumber(kk) = TypeOfDatagram;
                    XTFfileinfo.ALLdatagramtype(kk,1) = {'SEABED IMAGE (53H)'};
                end
                
                % do nothing, just loop

            else
                
                if nargout
                    % file information
                    XTFfileinfo.ALLdatagramtypenumber(kk) = TypeOfDatagram;
                    XTFfileinfo.ALLdatagramtype(kk,1) = {'UNKNOWN'};
                end

            end

        otherwise

            if nargout
                % file information
                kk = kk +1;
                XTFfileinfo.XTFpackettypenumber(kk) = dataType(3);
                XTFfileinfo.XTFpackettype(kk,1) = {'UNKNOWN'};
                XTFfileinfo.XTFpacketsize(kk) = ndata;
                XTFfileinfo.ALLdatagramtypenumber(kk) = NaN;
                XTFfileinfo.ALLdatagramtype(kk,1) = {'N/A'};
            end

    end

    fseek(fid,point+ndata,-1); % go to next TRITON packet

end


%% INSTALLATION PARAMETERS - STOP (105, 69H)

% use InstallASCIIparam, ASCII size, DTGRMsize from the
% datagram INSTALLATION PARAMETERS - START (73,49H) 

fwrite(fid2, DTGRMsize, 'uint32');                  % NbOfBytesInDatagram
fwrite(fid2, 2, 'uint8');                           % STX
fwrite(fid2, 105, 'uint8');                         % TypeOfDatagram
fwrite(fid2, 3000, 'uint16');                       % EMmodel
fwrite(fid2, LastDepthDate, 'uint32');              % Date                              - from last depth packet
fwrite(fid2, LastDepthTimeSinceMidnight, 'uint32'); % TimeSinceMidnightInMilliseconds   - from last depth packet
fwrite(fid2, 1, 'uint16');                          % SurveyLineNumber
fwrite(fid2, SystemSerialNumber, 'uint16');         % SystemSerialNumber                - from first depth packet
fwrite(fid2, 0, 'uint16');                          % SecondSerialNumber
fwrite(fid2, InstallASCIIparam, 'char');                   % ASCII parameters

%spare byte to add if no ASCII or even ASCII size:
if DTGRMsize~=InstallASCIIsize+21
    fwrite(fid2, 0, 'uint8');                       % Spare
end

fwrite(fid2, 3, 'uint8');                           % ETX
fwrite(fid2, DTGRMsize-4,'uint16');                 % Checksum


%% CLOSE ALL file
fclose(fid2);

