function out_struct = CFF_read_EMdgmMRZ(fid, dgmVersion_warning_flag)
%CFF_READ_EMDGMMRZ  Read kmall structure #MRZ
%
%   #MRZ - Multibeam Raw Range and Depth datagram. The datagram also
%   contains seabed image data.
%
%   Datagram consists of several structs. The MRZ datagram replaces several
%   old datagrams: raw range (N 78), depth (XYZ 88), seabed image (Y 89)
%   datagram, quality factor (O 79) and runtime (R 52).
%
%   Depths points (x,y,z) are calculated in meters, georeferred to the
%   position of the vessel reference point at the time of the first
%   transmitted pulse of the ping. The depth point coordinates x and y are
%   in the surface coordinate system (SCS), and are also given as delta
%   latitude and delta longitude, referred to origo of the VCS/SCS, at the
%   time of the midpoint of the first transmitted pulse of the ping (equals
%   time used in the datagram header timestamp).
%   See Coordinate systems for introduction to spatial reference points and
%   coordinate systems. Reference points are also described in Reference
%   points and offsets. Explanation of the xyz reference points is also
%   illustrated in the figure below.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)

out_struct.header = CFF_read_EMdgmHeader(fid);

MRZ_VERSION = out_struct.header.dgmVersion;
if MRZ_VERSION>3 && dgmVersion_warning_flag
    % definitions in this function and subfunctions valid for MRZ_VERSION:
    % 0 (kmall format revision F, and presumably earlier ones?)
    % 1 (kmall format revision G)
    % 2 (kmall format revision H)
    % 3 (kmall format revision I)
    warning('#MRZ datagram version (%i) unsupported. Continue reading but there may be issues.',MRZ_VERSION);
end

out_struct.partition = CFF_read_EMdgmMpartition(fid);
out_struct.cmnPart   = CFF_read_EMdgmMbody(fid);
out_struct.pingInfo  = CFF_read_EMdgmMRZ_pingInfo(fid, MRZ_VERSION);

Ntx = out_struct.pingInfo.numTxSectors;
for iTx = 1:Ntx
    out_struct.sectorInfo(iTx) = CFF_read_EMdgmMRZ_txSectorInfo(fid, MRZ_VERSION);
end

out_struct.rxInfo = CFF_read_EMdgmMRZ_rxInfo(fid);

Ndc = out_struct.rxInfo.numExtraDetectionClasses;
for iD = 1:Ndc
    out_struct.extraDetClassInfo(iD) = CFF_read_EMdgmMRZ_extraDetClassInfo(fid);
end

Nrx = out_struct.rxInfo.numSoundingsMaxMain;
Nd  = out_struct.rxInfo.numExtraDetections;
% DEV NOTE: Normally, if following stricly the "struct" organization of
% kmall data, we would read ONE "sounding" struct per beam, using a for
% loop over all soundings. However, this was taking too much time because
% there are a lot of fields to read in that structure and a lot of beams
% per ping. So, just for this one, we're doing things differently. We're
% recording a SINGLE "sounding" struct, containing arrays for each
% soundings, which can be read efficiently because the total size is the
% same for all beams.
out_struct.sounding = CFF_read_EMdgmMRZ_sounding(fid, Nrx+Nd);

% Seabed image sample amplitude, in 0.1 dB. Actual number of seabed
% image samples (SIsample_desidB) to be found by summing parameter
% SInumSamples in struct EMdgmMRZ_sounding_def for all beams. Seabed
% image data are raw beam sample data taken from the RX beams. The data
% samples are selected based on the bottom detection ranges. First
% sample for each beam is the one with the lowest range. The centre
% sample from each beam is geo referenced (x, y, z data from the
% detections). The BS corrections applied at the centre sample are the
% same as used for reflectivity2_dB (struct EMdgmMRZ_sounding_def).
Ns = [out_struct.sounding.SInumSamples];
for iRx = 1:(Nrx+Nd)
    out_struct.SIsample_desidB{iRx} = fread(fid,Ns(iRx),'int16');
end

end

function out_struct = CFF_read_EMdgmMRZ_pingInfo(fid, MRZ_VERSION)
% #MRZ - ping info. Information on vessel/system level, i.e. information
% common to all beams in the current ping.
%
% Verified correct for kmall format revisions F-I

% Number of bytes in current struct.
out_struct.numBytesInfoData = fread(fid,1,'uint16');

% Byte alignment.
out_struct.padding0 = fread(fid,1,'uint16');

% Ping rate. Filtered/averaged.
out_struct.pingRate_Hz = fread(fid,1,'float');

% 0 = Eqidistance
% 1 = Equiangle
% 2 = High density
out_struct.beamSpacing = fread(fid,1,'uint8');

% Depth mode. Describes setting of depth in K-Controller. Depth mode
% influences the PUs choice of pulse length and pulse type. If operator has
% manually chosen the depth mode to use, this is flagged by adding 100 to
% the mode index.
%
% Number 	Auto setting 	Number 	Manual setting
% 0         Very shallow 	100 	Very shallow
% 1         Shallow         101 	Shallow
% 2         Medium          102 	Medium
% 3         Deep            103 	Deep
% 4         Deeper          104 	Deeper
% 5         Very deep       105 	Very deep
% 6         Extra deep      106 	Extra deep
% 7         Extreme deep 	107 	Extreme deep
out_struct.depthMode = fread(fid,1,'uint8');

% For advanced use when depth mode is set manually. 0 = Sub depth mode is
% not used (when depth mode is auto).
out_struct.subDepthMode = fread(fid,1,'uint8');

% Achieved distance between swaths, in percent relative to required swath
% distance.
% 0 = function is not used
% 100 = achieved swath distance equals required swath distance.
out_struct.distanceBtwSwath = fread(fid,1,'uint8');

% Detection mode. Bottom detection algorithm used.
% 0 = normal
% 1 = waterway
% 2 = tracking
% 3 = minimum depth If system running in simulation mode
% detectionmode + 100 = simulator.
out_struct.detectionMode = fread(fid,1,'uint8');

% Pulse forms used for current swath.
% 0 = CW
% 1 = mix
% 2 = FM
out_struct.pulseForm = fread(fid,1,'uint8');

% Ping rate. Filtered/averaged.
out_struct.padding1 = fread(fid,1,'uint16');

% Ping frequency in hertz. E.g. for EM 2040: 200 000 Hz, 300 000 Hz, 400
% 000 Hz, 600 000 Hz or 700 000 Hz. If values is less than 100, it refers
% to a code defined in the table below.
% Value                 Frequency       Valid for EM model
% -1                    Not used        -
% 0                     40 - 100 kHz 	EM 712
% 1                     50 - 100 kHz 	EM 712
% 2                     70 - 100 kHz 	EM 712
% 3                     50 kHz          EM 712
% 4                     40 kHz          EM 712
% 180 000 - 400 000 	180 -400 kHz 	EM 2040C (10 kHz steps)
% 200 000               200 kHz         EM 2040, EM 2040P
% 300 000               300 kHz         EM 2040, EM 2040P
% 400 000               400 kHz         EM 2040, EM 2040P
% 600 000               600 kHz         EM 2040, EM 2040P
% 700 000               700 kHz         EM 2040, EM 2040P
out_struct.frequencyMode_Hz = fread(fid,1,'float');

% Lowest centre frequency of all sectors in this swath. Unit hertz. E.g.
% for EM 2040: 260 000 Hz.
out_struct.freqRangeLowLim_Hz = fread(fid,1,'float');

% Highest centre frequency of all sectors in this swath. Unit hertz. E.g.
% for EM 2040: 320 000 Hz.
out_struct.freqRangeHighLim_Hz = fread(fid,1,'float');

% Total signal length of the sector with longest tx pulse. Unit second.
out_struct.maxTotalTxPulseLength_sec = fread(fid,1,'float');

% Effective signal length (-3dB envelope) of the sector with longest
% effective tx pulse. Unit second.
out_struct.maxEffTxPulseLength_sec = fread(fid,1,'float');

% Effective bandwidth (-3dB envelope) of the sector with highest bandwidth.
out_struct.maxEffTxBandWidth_Hz = fread(fid,1,'float');

% Average absorption coefficient, in dB/km, for vertical beam at current
% depth. Not currently in use.
out_struct.absCoeff_dBPerkm = fread(fid,1,'float');

% Port sector edge, used by beamformer, Coverage is refered to z of SCS..
% Unit degree.
out_struct.portSectorEdge_deg = fread(fid,1,'float');

% Starboard sector edge, used by beamformer. Coverage is referred to z of
% SCS. Unit degree.
out_struct.starbSectorEdge_deg = fread(fid,1,'float');

% Coverage achieved, corrected for raybending. Coverage is referred to z of
% SCS. Unit degree.
out_struct.portMeanCov_deg = fread(fid,1,'float');

% Coverage achieved, corrected for raybending. Coverage is referred to z of
% SCS. Unit degree.
out_struct.starbMeanCov_deg = fread(fid,1,'float');

% Coverage achieved, corrected for raybending. Coverage is referred to z of
% SCS. Unit meter.
out_struct.portMeanCov_m = fread(fid,1,'int16');

% Coverage achieved, corrected for raybending. Unit meter.
out_struct.starbMeanCov_m = fread(fid,1,'int16');

% Modes and stabilisation settings as chosen by operator. Each bit refers
% to one setting in K-Controller. Unless otherwise stated, default: 0 =
% off, 1 = on/auto.
% Bit 	Mode
% 1 	Pitch stabilisation
% 2 	Yaw stabilisation
% 3 	Sonar mode
% 4 	Angular coverage mode
% 5 	Sector mode
% 6 	Swath along position (0 = fixed, 1 = dynamic)
% 7-8 	Future use
out_struct.modeAndStabilisation = fread(fid,1,'uint8');

% Filter settings as chosen by operator. Refers to settings in runtime
% display of K-Controller. Each bit refers to one filter setting. 0 = off,
% 1 = on/auto.
% Bit 	Filter choice
% 1 	Slope filter
% 2 	Aeration filer
% 3 	Sector filter
% 4 	Interference filter
% 5 	Special amplitude detect
% 6-8 	Future use
out_struct.runtimeFilter1 = fread(fid,1,'uint8');

% Filter settings as chosen by operator. Refers to settings in runtime
% display of K-Controller. 4 bits used per filter.
% Bit       Filter choice           Setting
% 1-4       Range gate size         0 = small, 1 = normal, 2 = large
% 5-8       Spike filter strength 	0 = off, 1= weak, 2 = medium, 3 = strong
% 9-12      Penetration filter      0 = off, 1 = weak, 2 = medium, 3 = strong
% 13-16 	Phase ramp              0 = short, 1 = normal, 2 = long
out_struct.runtimeFilter2 = fread(fid,1,'uint16');

% Pipe tracking status. Describes how angle and range of top of pipe is
% determined.
% 0 = for future use
% 1 = PU uses guidance from SIS.
out_struct.pipeTrackingStatus = fread(fid,1,'uint32');

% Transmit array size used. Direction along ship. Unit degree.
out_struct.transmitArraySizeUsed_deg = fread(fid,1,'float');

% Receiver array size used. Direction across ship. Unit degree.
out_struct.receiveArraySizeUsed_deg = fread(fid,1,'float');

% Operator selected tx power level re maximum. Unit dB. E.g. 0 dB, -10 dB,
% -20 dB.
out_struct.transmitPower_dB = fread(fid,1,'float');

% For marine mammal protection. The parameters describes time remaining
% until max source level (SL) is achieved. Unit %.
out_struct.SLrampUpTimeRemaining = fread(fid,1,'uint16');

% Byte alignment.
out_struct.padding2 = fread(fid,1,'uint16');

% Yaw correction angle applied. Unit degree.
out_struct.yawAngle_deg = fread(fid,1,'float');

% Number of transmit sectors. Also called Ntx in documentation. Denotes how
% many times the struct EMdgmMRZ_txSectorInfo is repeated in the datagram.
out_struct.numTxSectors = fread(fid,1,'uint16');

% Number of bytes in the struct EMdgmMRZ_txSectorInfo, containing tx sector
% specific information. The struct is repeated numTxSectors times.
out_struct.numBytesPerTxSector = fread(fid,1,'uint16');

% Heading of vessel at time of midpoint of first tx pulse. From active
% heading sensor.
out_struct.headingVessel_deg = fread(fid,1,'float');

% At time of midpoint of first tx pulse. Value as used in depth
% calculations. Source of sound speed defined by user in K-Controller.
out_struct.soundSpeedAtTxDepth_mPerSec = fread(fid,1,'float');

% Tx transducer depth in meters below waterline, at time of midpoint of
% first tx pulse. For the tx array (head) used by this RX-fan. Use depth of
% TX1 to move depth point (XYZ) from water line to transducer (reference
% point of old datagram format).
out_struct.txTransducerDepth_m = fread(fid,1,'float');

% Distance between water line and vessel reference point in meters. At time
% of midpoint of first tx pulse. Measured in the surface coordinate system
% (SCS).See Coordinate systems 'Coordinate systems' for definition. Used
% this to move depth point (XYZ) from vessel reference point to waterline.
out_struct.z_waterLevelReRefPoint_m = fread(fid,1,'float');

% Distance between *.all reference point and *.kmall reference point
% (vessel refernece point) in meters, in the surface coordinate system, at
% time of midpoint of first tx pulse. Used this to move depth point (XYZ)
% from vessel reference point to the horisontal location (X,Y) of the
% active position sensor's reference point (old datagram format).
out_struct.x_kmallToall_m = fread(fid,1,'float');

% Distance between *.all reference point and *.kmall reference point
% (vessel refernece point) in meters, in the surface coordinate system, at
% time of midpoint of first tx pulse. Used this to move depth point (XYZ)
% from vessel reference point to the horisontal location (X,Y) of the
% active position sensor's reference point (old datagram format).
out_struct.y_kmallToall_m = fread(fid,1,'float');

% Method of position determination from position sensor data:
% 0 = last position received
% 1 = interpolated
% 2 = processed
out_struct.latLongInfo = fread(fid,1,'uint8');

% Status/quality for data from active position sensor. 0 = valid data, 1 =
% invalid data, 2 = reduced performance
out_struct.posSensorStatus = fread(fid,1,'uint8');

% Status/quality for data from active attitude sensor. 0 = valid data, 1 =
% invalid data, 2 = reduced performance
out_struct.attitudeSensorStatus = fread(fid,1,'uint8');

% Padding for byte alignment.
out_struct.padding3 = fread(fid,1,'uint8');

% Latitude (decimal degrees) of vessel reference point at time of midpoint
% of first tx pulse. Negative on southern hemisphere. Parameter is set to
% define UNAVAILABLE_LATITUDE if not available.
out_struct.latitude_deg = fread(fid,1,'double');

% Longitude (decimal degrees) of vessel reference point at time of midpoint
% of first tx pulse. Negative on western hemisphere. Parameter is set to
% define UNAVAILABLE_LONGITUDE if not available.
out_struct.longitude_deg = fread(fid,1,'double');

% Height of vessel reference point above the ellipsoid, derived from active
% GGA sensor. ellipsoidHeightReRefPoint_m is GGA height corrected for
% motion and installation offsets of the position sensor.
out_struct.ellipsoidHeightReRefPoint_m = fread(fid,1,'float');

if MRZ_VERSION > 0
    
    % Backscatter offset set in the installation menu
    out_struct.bsCorrectionOffset_dB = fread(fid,1,'float');
    
    % Beam intensity data corrected as seabed image data (Lambert and
    % normal incidence corrections)
    out_struct.lambertsLawApplied = fread(fid,1,'uint8');
    
    % Ice window installed
    out_struct.iceWindow = fread(fid,1,'uint8');
    
    if MRZ_VERSION == 1
        % Padding for byte alignment.
        out_struct.padding4 = fread(fid,1,'uint16');
    else
        % Sets status for active modes.
        % Bit 	Modes                   Setting
        % 1 	EM MultiFrequency Mode 	0 = not active, 1 = active
        % 2-16 	Not in use              NA
        out_struct.activeModes = fread(fid,1,'uint16');
    end

end

end

function out_struct = CFF_read_EMdgmMRZ_txSectorInfo(fid, MRZ_VERSION)
% #MRZ - sector information.
%
% Information specific to each transmitting sector. sectorInfo is repeated
% numTxSectors (Ntx)- times in datagram.
%
% Verified correct for kmall format revisions F-I

% TX sector index number, used in the sounding section. Starts at 0.
out_struct.txSectorNumb = fread(fid,1,'uint8');

% TX array number. Single TX, txArrNumber = 0.
out_struct.txArrNumber = fread(fid,1,'uint8');

% Default = 0. E.g. for EM2040, the transmitted pulse consists of three
% sectors, each transmitted from separate txSubArrays. Orientation and
% numbers are relative the array coordinate system. Sub array installation
% offsets can be found in the installation datagram, #IIP.
% 0 = Port subarray
% 1 = middle subarray
% 2 = starboard subarray
out_struct.txSubArray = fread(fid,1,'uint8');

% Byte alignment.
out_struct.padding0 = fread(fid,1,'uint8');

% Transmit delay of the current sector/subarray. Delay is the time from the
% midpoint of the current transmission to midpoint of the first transmitted
% pulse of the ping, i.e. relative to the time used in the datagram header.
out_struct.sectorTransmitDelay_sec = fread(fid,1,'float');

% Along ship steering angle of the TX beam (main lobe of transmitted
% pulse), angle referred to transducer array coordinate system. Unit
% degree. See Coordinate systems 'Coordinate systems'
out_struct.tiltAngleReTx_deg = fread(fid,1,'float');

% Actual SL = txNominalSourceLevel_dB + highVoltageLevel_dB. Unit dB re 1
% microPascal.
out_struct.txNominalSourceLevel_dB = fread(fid,1,'float');

% 0 = no focusing applied.
out_struct.txFocusRange_m = fread(fid,1,'float');

% Centre frequency. Unit hertz.
out_struct.centreFreq_Hz = fread(fid,1,'float');

% FM mode: effective bandwidth
% CW mode: 1/(effective TX pulse length)
out_struct.signalBandWidth_Hz = fread(fid,1,'float');

% Also called pulse length. Unit second.
out_struct.totalSignalLength_sec = fread(fid,1,'float');

% Transmit pulse is shaded in time (tapering). Amplitude shading in %.
% cos2- function used for shading the TX pulse in time.
out_struct.pulseShading = fread(fid,1,'uint8');

% Transmit signal wave form.
% 0 = CW
% 1 = FM upsweep
% 2 = FM downsweep.
out_struct.signalWaveForm = fread(fid,1,'uint8');

% Byte alignment.
out_struct.padding1 = fread(fid,1,'uint16');

if MRZ_VERSION > 0
    
    % 20 log(Measured high voltage power level at TX pulse / Nominal high
    % voltage power level). This parameter will also include the effect of user
    % selected transmit power reduction (transmitPower_dB) and mammal
    % protection. Actual SL = txNominalSourceLevel_dB + highVoltageLevel_dB.
    % Unit dB.
    out_struct.highVoltageLevel_dB = fread(fid,1,'float');
    
    % Backscatter correction added in sector tracking mode. Unit dB.
    out_struct.sectorTrackingCorr_dB = fread(fid,1,'float');
    
    % Signal length used for backscatter footprint calculation. This
    % compensates for the TX pulse tapering and the RX filter bandwidths. Unit
    % second.
    out_struct.effectiveSignalLength_sec = fread(fid,1,'float');
    
end

end

function out_struct = CFF_read_EMdgmMRZ_rxInfo(fid)
% #MRZ - receiver specific information.
%
% Information specific to the receiver unit used in this swath.
%
% Verified correct for kmall format revisions F-I

% Bytes in current struct.
out_struct.numBytesRxInfo = fread(fid,1,'uint16');

% Maximum number of main soundings (bottom soundings) in this datagram,
% extra detections (soundings in water column) excluded. Also referred to
% as Nrx. Denotes how many bottom points (or loops) given in the struct
% EMdgmMRZ_sounding_def.
out_struct.numSoundingsMaxMain = fread(fid,1,'uint16');

% Number of main soundings of valid quality. Extra detections not included.
out_struct.numSoundingsValidMain = fread(fid,1,'uint16');

% Bytes per loop of sounding (per depth point), i.e. bytes per loops of the
% struct EMdgmMRZ_sounding_def.
out_struct.numBytesPerSounding = fread(fid,1,'uint16');

% Sample frequency divided by water column decimation factor. Unit hertz.
out_struct.WCSampleRate = fread(fid,1,'float');

% Sample frequency divided by seabed image decimation factor. Unit hertz.
out_struct.seabedImageSampleRate = fread(fid,1,'float');

% Backscatter level, normal incidence. Unit dB
out_struct.BSnormal_dB = fread(fid,1,'float');

% Backscatter level, oblique incidence. Unit dB
out_struct.BSoblique_dB = fread(fid,1,'float');

% extraDetectionAlarmFlag = sum of alarm flags. Range 0-10.
out_struct.extraDetectionAlarmFlag = fread(fid,1,'uint16');

% Sum of extradetection from all classes. Also refered to as Nd.
out_struct.numExtraDetections = fread(fid,1,'uint16');

% Range 0-10.
out_struct.numExtraDetectionClasses = fread(fid,1,'uint16');

% Number of bytes in the struct EMdgmMRZ_extraDetClassInfo_def.
out_struct.numBytesPerClass = fread(fid,1,'uint16');

end

function out_struct = CFF_read_EMdgmMRZ_extraDetClassInfo(fid)
% #MRZ - Extra detection class information.
%
% To be entered in loop numExtraDetectionClasses - times.
%
% Verified correct for kmall format revisions F-I

% Number of extra detection in this class.
out_struct.numExtraDetInClass = fread(fid,1,'uint16');

% Byte alignment.
out_struct.padding = fread(fid,1,'int8');

% 0 = no alarm
% 1 = alarm.
out_struct.alarmFlag = fread(fid,1,'uint8');

end

function out_struct = CFF_read_EMdgmMRZ_sounding(fid, N)
% #MRZ - Data for each sounding, e.g. XYZ, reflectivity, two way travel
% time etc.
%
% Also contains information necessary to read seabed image following this
% datablock (number of samples in SI etc.). To be entered in loop
% (numSoundingsMaxMain + numExtraDetections) times.
%
% Verified correct for kmall format revisions F-I

structSize = 120;
data = fread(fid,N.*structSize,'uint8=>uint8');
data = reshape(data, [structSize,N]);

% Sounding index. Cross reference for seabed image. Valid range: 0 to
% (numSoundingsMaxMain+numExtraDetections)-1, i.e. 0 - (Nrx+Nd)-1.
out_struct.soundingIndex = typecast(reshape(data(1:2,:),1,[]),'uint16');

% Transmitting sector number. Valid range: 0-(Ntx-1), where Ntx is
% numTxSectors.
out_struct.txSectorNumb = data(3,:);


%% Detection info

% Bottom detection type. Normal bottom detection, extra detection, or
% rejected.
% 0 = normal detection
% 1 = extra detection
% 2 = rejected detection
% In case 2, the estimated range has been used to fill in amplitude samples
% in the seabed image datagram.
out_struct.detectionType = data(4,:);

% Method for determining bottom detection, e.g. amplitude or phase.
% 0 = no valid detection
% 1 = amplitude detection
% 2 = phase detection
% 3-15 for future use.
out_struct.detectionMethod = data(5,:);

% For Kongsberg use.
% out_struct.rejectionInfo1 = data(6,:);

% For Kongsberg use.
% out_struct.rejectionInfo2 = data(7,:);

% For Kongsberg use.
% out_struct.postProcessingInfo = data(8,:);

% Only used by extra detections. Detection class based on detected range.
% Detection class 1 to 7 corresponds to value 0 to 6. If the value is
% between 100 and 106, the class is disabled by the operator. If the value
% is 107, the detections are outside the treshhold limits.
out_struct.detectionClass = data(9,:);

% Detection confidence level.
out_struct.detectionConfidenceLevel = data(10,:);

% Byte alignment.
% out_struct.padding = typecast(reshape(data(11:12,:),1,[]),'uint16');

% Unit %. rangeFactor = 100 if main detection.
out_struct.rangeFactor = typecast(reshape(data(13:16,:),1,[]),'single');

% Estimated standard deviation as % of the detected depth. Quality Factor
% (QF) is calculated from IFREMER Quality Factor (IFQ):
% QF=Est(dz)/z=100*10^-IQF
out_struct.qualityFactor = typecast(reshape(data(17:20,:),1,[]),'single');

% Vertical uncertainty, based on quality factor (QF, qualityFactor).
out_struct.detectionUncertaintyVer_m = typecast(reshape(data(21:24,:),1,[]),'single');

% Horizontal uncertainty, based on quality factor (QF, qualityFactor).
out_struct.detectionUncertaintyHor_m = typecast(reshape(data(25:28,:),1,[]),'single');

% Detection window length. Unit second. Sample data range used in final
% detection.
out_struct.detectionWindowLength_sec = typecast(reshape(data(29:32,:),1,[]),'single');

% Measured echo length. Unit second.
out_struct.echoLength_sec = typecast(reshape(data(33:36,:),1,[]),'single');


%% Water column parameters

% Water column beam number. Info for plotting soundings together with water
% column data.
out_struct.WCBeamNumb = typecast(reshape(data(37:38,:),1,[]),'uint16');

% Water column range. Range of bottom detection, in samples.
out_struct.WCrange_samples = typecast(reshape(data(39:40,:),1,[]),'uint16');

% Water column nominal beam angle across. Re vertical.
out_struct.WCNomBeamAngleAcross_deg = typecast(reshape(data(41:44,:),1,[]),'single');


%% Reflectivity data (backscatter (BS) data)

% Mean absorption coefficient, alfa. Used for TVG calculations. Value as
% used. Unit dB/km.
out_struct.meanAbsCoeff_dBPerkm = typecast(reshape(data(45:48,:),1,[]),'single');

% Beam intensity, using the traditional KM special TVG.
out_struct.reflectivity1_dB = typecast(reshape(data(49:52,:),1,[]),'single');

% Beam intensity (BS), using TVG = X log(R) + 2 alpha R. X (operator
% selected) is common to all beams in datagram. Alpha (variabel
% meanAbsCoeff_dBPerkm) is given for each beam (current struct).
% BS = EL - SL - M + TVG + BScorr,
% where EL= detected echo level (not recorded in datagram), and the rest of
% the parameters are found below.
out_struct.reflectivity2_dB = typecast(reshape(data(53:56,:),1,[]),'single');

% Receiver sensitivity (M), in dB, compensated for RX beampattern at actual
% transmit frequency at current vessel attitude.
out_struct.receiverSensitivityApplied_dB = typecast(reshape(data(57:60,:),1,[]),'single');

% Source level (SL) applied (dB):
% SL = SLnom + SLcorr
% where SLnom = Nominal maximum SL, recorded per TX sector (variabel
% txNominalSourceLevel_dB in struct EMdgmMRZ_txSectorInfo_def) and SLcorr =
% SL correction relative to nominal TX power based on measured high voltage
% power level and any use of digital power control. SL is corrected for TX
% beampattern along and across at actual transmit frequency at current
% vessel attitude.
out_struct.sourceLevelApplied_dB = typecast(reshape(data(61:64,:),1,[]),'single');

% Backscatter (BScorr) calibration offset applied (default = 0 dB).
out_struct.BScalibration_dB = typecast(reshape(data(65:68,:),1,[]),'single');

% Time Varying Gain (TVG) used when correcting reflectivity.
out_struct.TVG_dB = typecast(reshape(data(69:72,:),1,[]),'single');


%% Range and angle data

% Angle relative to the RX transducer array, except for ME70, where the
% angles are relative to the horizontal plane.
out_struct.beamAngleReRx_deg = typecast(reshape(data(73:76,:),1,[]),'single');

% Applied beam pointing angle correction.
out_struct.beamAngleCorrection_deg = typecast(reshape(data(77:80,:),1,[]),'single');

% Two way travel time (also called range). Unit second.
out_struct.twoWayTravelTime_sec = typecast(reshape(data(81:84,:),1,[]),'single');

% Applied two way travel time correction. Unit second.
out_struct.twoWayTravelTimeCorrection_sec = typecast(reshape(data(85:88,:),1,[]),'single');


%% Georeferenced depth points

% Distance from vessel reference point at time of first tx pulse in ping,
% to depth point. Measured in the surface coordinate system (SCS), see
% Coordinate systems for definition. Unit decimal degrees.
out_struct.deltaLatitude_deg = typecast(reshape(data(89:92,:),1,[]),'single');

% Distance from vessel reference point at time of first tx pulse in ping,
% to depth point. Measured in the surface coordinate system (SCS), see
% Coordinate systems for definition. Unit decimal degree.
out_struct.deltaLongitude_deg = typecast(reshape(data(93:96,:),1,[]),'single');

% Vertical distance z. Distance from vessel reference point at time of
% first tx pulse in ping, to depth point. Measured in the surface
% coordinate system (SCS), see Coordinate systems for definition.
out_struct.z_reRefPoint_m = typecast(reshape(data(97:100,:),1,[]),'single');

% Horizontal distance y. Distance from vessel reference point at time of
% first tx pulse in ping, to depth point. Measured in the surface
% coordinate system (SCS), see Coordinate systems for definition.
out_struct.y_reRefPoint_m = typecast(reshape(data(101:104,:),1,[]),'single');

% Horizontal distance x. Distance from vessel reference point at time of
% first tx pulse in ping, to depth point. Measured in the surface
% coordinate system (SCS), see Coordinate systems for definition.
out_struct.x_reRefPoint_m = typecast(reshape(data(105:108,:),1,[]),'single');

% Beam incidence angle adjustment (IBA) unit degree.
out_struct.beamIncAngleAdj_deg = typecast(reshape(data(109:112,:),1,[]),'single');

% For future use.
out_struct.realTimeCleanInfo = typecast(reshape(data(113:114,:),1,[]),'uint16');


%% Seabed image

% Seabed image start range, in sample number from transducer. Valid only
% for the current beam.
out_struct.SIstartRange_samples = typecast(reshape(data(115:116,:),1,[]),'uint16');

% Seabed image. Number of the centre seabed image sample for the current
% beam.
out_struct.SIcentreSample = typecast(reshape(data(117:118,:),1,[]),'uint16');

% Seabed image. Number of range samples from the current beam, used to form
% the seabed image.
out_struct.SInumSamples = typecast(reshape(data(119:120,:),1,[]),'uint16');


%% change out_struct organization
% from one struct with array fields to array of structs with
% single-variable fields, like all other stuctures in this format
% for field = fieldnames(out_struct)'
%     for ii = 1:N
%         out_struct_2(ii).(field{1}) = out_struct.(field{1})(ii);
%     end
% end
% out_struct = out_struct_2;



end
