function [fData,update_flag] = CFF_convert_ALLdata_to_fData(ALLdataGroup,varargin)
%CFF_CONVERT_ALLDATA_TO_FDATA  One-line description
%
%   Converts the Kongsberg EM series data files in ALLdata format
%   (containing the KONGSBERG datagrams) to the fData format used in
%   processing.
%
%   fData = CFF_CONVERT_ALLDATA_TO_FDATA(ALLdata) converts the contents of
%   one ALLdata structure to a structure in the fData format.
%
%   fData = CFF_CONVERT_ALLDATA_TO_FDATA({ALLdata;WCDdata}) converts two
%   ALLdata structures into one fData sructure. While many more structures
%   can thus be loaded, this is typically done because ALLdata structures
%   exist on a per-file basis and Kongsberg raw data often come in pairs of
%   files: one .all and one .wcd. Note that the ALLdata structures are
%   converted to fData in the order they are in input, and that the first
%   ones take precedence, aka in the example above, if WCDdata contains a
%   type of datagram that is already in ALLdata, they will NOT be
%   converted. 
%   This is to avoid doubling up. Order the ALLdata structures in input in
%   order of desired precedence. DO NOT use this feature to convert ALLdata
%   structures from different acquisition files. It will not work. Convert
%   each into its own fData structure.
%
%   fData = CFF_CONVERT_ALLDATA_TO_FDATA(ALLdata,10,2) operates the
%   conversion with sub-sampling in range and in beams. For example, to
%   sub-sample range by a factor of 10 and beams by a factor of 2, use
%   fData = CFF_CONVERT_ALLDATA_TO_FDATA(ALLdata,10,2). 
% 
%   [fData,update_flag] = CFF_CONVERT_ALLDATA_TO_FDATA(ALLdata,1,1,fData)
%   takes the result of a precedent conversion in input to allow
%   potentially saving time. The function will start by loading the result
%   of the precedent conversion, check that what you're trying to add to it
%   comes from the same raw data source, and add to fData only those types
%   of datagrams that may be missing. If fData has been modified, it will
%   return a update_flag=1. If the output is the same and no modification
%   occured, then it will return a update_flag=0. NOTE: If the decimation
%   factors in input are different to those used in the input fData, then
%   the data WILL be updated. This is actually the main use of this
%   feature...
%
%   *INPUT VARIABLES*
%   * |ALLdataGroup|: Required. ALLdata structure or cells of ALLdata
%   structures.
%   * |dr_sub|: Optional. Scalar for decimation in range. Default: 1 (no
%   decimation).
%   * |db_sub|: Optional. Scalar for decimation in beams. Default: 1 (no
%   decimation).
%   * |fData|: Optional. Existing fData structure to add to.
%
%   *OUTPUT VARIABLES*
%   * |fData|: structure for the storage of kongsberg EM series multibeam
%   data in a format more convenient for processing. The data is recorded
%   as fields coded "a_b_c" where "a" is a code indicating data origing,
%   "b" is a code indicating data dimensions, and "c" is the data name.
%     * a: code indicating data origin:
%         * IP: installation parameters
%         * Ru: Runtime Parameters
%         * De: depth datagram
%         * He: height datagram
%         * X8: XYZ88 datagram
%         * SI: seabed image datagram
%         * S8: seabed image data 89
%         * WC: watercolumn data
%         * Po: position datagram
%         * At: attitude datagram
%         * SS: sound speed profile datagram
%         * AP: "Amplitude and phase" water-column data
%     More codes for the 'a' part will be created if more datagrams are
%     parsed. Data derived from computations can be recorded back into
%     fData using 'X' for the "a" code.
%     * b: code indicating data dimensions (rows/columns)
%         * 1P: ping-like single-row-vector
%         * B1: beam-like single-column-vector
%         * BP: beam/ping array
%         * TP: transmit-sector/ping array
%         * SP: samples/ping array (note: samples are not sorted, this is
%         not equivalent to range!)
%         * 1D: datagram-like single-row-vector (for attitude or
%         position data)
%         * ED: entries-per-datagram/datagram array (for attitude or
%         position data)
%         * SBP: sample/beam/ping array (water-column data)
%     More codes for the 'b' part will be created if the storage of other
%     datagrams needs them. Data derived from computations can be recorded
%     back into fData using appropriate "b" codes such as:
%         * RP: range (choose distance, time or sample) / ping
%         * SP: swathe (meters) / ping
%         * LL: lat/long (WGS84)
%         * N1: northing-like single-column-vector
%         * 1E: easting-like single-row-vector
%         * NE: northing/easting
%         * NEH: northing/easting/height
%     * c: data type, obtained from the original variable name in the
%     Kongsberg datagram, or from the user's imagination for derived data
%     obtained from subsequent functions.
%   * |update_flag|: 1 if a fData was given in input and was modified with
%   this function
%
%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

%% input parsing

% init
p = inputParser;

% required
addRequired(p,'ALLdataGroup',@(x) isstruct(x) || iscell(x));

% optional
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'fData',{},@(x) isstruct(x) || iscell(x));

% parse
parse(p,ALLdataGroup,varargin{:})

% get results
ALLdataGroup = p.Results.ALLdataGroup;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
fData = p.Results.fData;
clear p;


%% pre-processing

if ~iscell(ALLdataGroup)
    ALLdataGroup = {ALLdataGroup};
end

% number of individual ALLdata structures in input ALLdataGroup
nStruct = length(ALLdataGroup);

% initialize fData if one not given in input
if isempty(fData)
    
    
    % initialize FABC structure by writing in the raw data filenames to be
    % added here
    fData.ALLfilename = cell(1,nStruct);
    for iF = 1:nStruct
        fData.ALLfilename{iF} = ALLdataGroup{iF}.ALLfilename;
    end
    
    % add the decimation factors given here in input
    fData.dr_sub = dr_sub;
    fData.db_sub = db_sub;
    
end


if ~isfield(fData,'MET_Fmt_version')&&~isempty(fData)
    %added a version for fData
    fData.MET_Fmt_version='0.0';
end

if ~strcmpi(ver,CFF_get_current_fData_version)
    f_reconvert = 1;
    update_mode = 0;
else
    f_reconvert = 0;
    update_mode = 1;
end

% initialize update_flag
update_flag = 0;



%% take one ALLdata structure at a time and add its contents to fData

for iF = 1:nStruct
    
    
    %% pre processing
    
    % get current structure
    ALLdata = ALLdataGroup{iF};
    
    % Make sure we don't update fData with datagrams from different
    % sources
    % XXX2 clean up that display later
    if ~ismember(ALLdata.ALLfilename,fData.ALLfilename)
        fprintf('Cannot add different files to this structure.\n')
        continue;
    end
    
    % open the original raw file in case we need to grab WC data from it
    fid_all = fopen(fData.ALLfilename{iF},'r',ALLdata.datagramsformat);
    
    % get folder for converted data
    wc_dir = CFF_converted_data_folder(fData.ALLfilename{iF});
    
    % now reading each type of datagram...
    
    %% EM_InstallationStart (v2 VERIFIED)
    
    if isfield(ALLdata,'EM_InstallationStart')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'IP_ASCIIparameters')
            
            if update_mode
                update_flag = 1;
            end
            
            % initialize struct
            IP_ASCIIparameters = struct;
            
            % read ASCIIdata
            ASCIIdata = char(ALLdata.EM_InstallationStart.ASCIIData(1));
            
            % remove carriage returns, tabs and linefeed
            ASCIIdata = regexprep(ASCIIdata,char(9),'');
            ASCIIdata = regexprep(ASCIIdata,newline,'');
            ASCIIdata = regexprep(ASCIIdata,char(13),'');
            
            % read individual fields
            if ~isempty(ASCIIdata)
                
                yo = strfind(ASCIIdata,',')';
                yo(:,1) = [1; yo(1:end-1)+1];        % beginning of ASCII field name
                yo(:,2) = strfind(ASCIIdata,'=')'-1; % end of ASCII field name
                yo(:,3) = strfind(ASCIIdata,'=')'+1; % beginning of ASCII field value
                yo(:,4) = strfind(ASCIIdata,',')'-1; % end of ASCII field value
                
                for ii = 1:size(yo,1)
                    
                    % get field string
                    field = ASCIIdata(yo(ii,1):yo(ii,2));
                    
                    % try turn value into numeric
                    value = str2double(ASCIIdata(yo(ii,3):yo(ii,4)));
                    if length(value)~=1
                        % looks like it cant. Keep as string
                        value = ASCIIdata(yo(ii,3):yo(ii,4));
                    end
                    
                    % store field/value
                    IP_ASCIIparameters.(field) = value;
                    
                end
                
            end
            
            % finally store in fData
            fData.IP_ASCIIparameters = IP_ASCIIparameters;
            
        end
        
    end
    
    
    %% EM_Runtime (v2 VERIFIED)
    
    if isfield(ALLdata,'EM_Runtime')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'Ru_1D_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            % NumberOfDatagrams  = length(ALLdata.EM_Runtime.TypeOfDatagram);
            % MaxNumberOfEntries = max(ALLdata.EM_Runtime.NumberOfEntries);
            
            fData.Ru_1D_Date                            = ALLdata.EM_Runtime.Date;
            fData.Ru_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Runtime.TimeSinceMidnightInMilliseconds;
            fData.Ru_1D_PingCounter                     = ALLdata.EM_Runtime.PingCounter;
            % the rest to code... XXX3
            fData.Ru_1D_TransmitPowerReMaximum          = ALLdata.EM_Runtime.TransmitPowerReMaximum;
            fData.Ru_1D_ReceiveBeamwidth                = ALLdata.EM_Runtime.ReceiveBeamwidth;
            % the rest to code... XXX3
            
        end
        
    end
    
    
    %% EM_SoundSpeedProfile (v2 VERIFIED)
    
    if isfield(ALLdata,'EM_SoundSpeedProfile')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'SS_1D_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            NumberOfDatagrams  = length(ALLdata.EM_SoundSpeedProfile.TypeOfDatagram);
            MaxNumberOfEntries = max(ALLdata.EM_SoundSpeedProfile.NumberOfEntries);
            
            fData.SS_1D_Date                                              = ALLdata.EM_SoundSpeedProfile.Date;
            fData.SS_1D_TimeSinceMidnightInMilliseconds                   = ALLdata.EM_SoundSpeedProfile.TimeSinceMidnightInMilliseconds;
            fData.SS_1D_ProfileCounter                                    = ALLdata.EM_SoundSpeedProfile.ProfileCounter;
            fData.SS_1D_DateWhenProfileWasMade                            = ALLdata.EM_SoundSpeedProfile.DateWhenProfileWasMade;
            fData.SS_1D_TimeSinceMidnightInMillisecondsWhenProfileWasMade = ALLdata.EM_SoundSpeedProfile.TimeSinceMidnightInMillisecondsWhenProfileWasMade;
            fData.SS_1D_NumberOfEntries                                   = ALLdata.EM_SoundSpeedProfile.NumberOfEntries;
            fData.SS_1D_DepthResolution                                   = ALLdata.EM_SoundSpeedProfile.DepthResolution;
            
            fData.SS_ED_Depth      = nan(MaxNumberOfEntries,NumberOfDatagrams);
            fData.SS_ED_SoundSpeed = nan(MaxNumberOfEntries,NumberOfDatagrams);
            
            for iD = 1:NumberOfDatagrams
                
                NumberOfEntries = ALLdata.EM_SoundSpeedProfile.NumberOfEntries(iD);
                
                fData.SS_ED_Depth(1:NumberOfEntries,iD)      = cell2mat(ALLdata.EM_SoundSpeedProfile.Depth(iD));
                fData.SS_ED_SoundSpeed(1:NumberOfEntries,iD) = cell2mat(ALLdata.EM_SoundSpeedProfile.SoundSpeed(iD));
                
            end
            
        end
        
    end
    
    %% EM_Attitude
    
    if isfield(ALLdata,'EM_Attitude')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'At_1D_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            NumberOfDatagrams  = length(ALLdata.EM_Attitude.TypeOfDatagram);
            MaxNumberOfEntries = max(ALLdata.EM_Attitude.NumberOfEntries);
            
            fData.At_1D_Date                            = ALLdata.EM_Attitude.Date;
            fData.At_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Attitude.TimeSinceMidnightInMilliseconds;
            fData.At_1D_AttitudeCounter                 = ALLdata.EM_Attitude.AttitudeCounter;
            fData.At_1D_NumberOfEntries                 = ALLdata.EM_Attitude.NumberOfEntries;
            
            fData.At_ED_TimeInMillisecondsSinceRecordStart = nan(MaxNumberOfEntries, NumberOfDatagrams);
            fData.At_ED_SensorStatus                       = nan(MaxNumberOfEntries, NumberOfDatagrams);
            fData.At_ED_Roll                               = nan(MaxNumberOfEntries, NumberOfDatagrams);
            fData.At_ED_Pitch                              = nan(MaxNumberOfEntries, NumberOfDatagrams);
            fData.At_ED_Heave                              = nan(MaxNumberOfEntries, NumberOfDatagrams);
            fData.At_ED_Heading                            = nan(MaxNumberOfEntries, NumberOfDatagrams);
            
            for iD = 1:NumberOfDatagrams
                
                NumberOfEntries = ALLdata.EM_Attitude.NumberOfEntries(iD);
                
                fData.At_ED_TimeInMillisecondsSinceRecordStart(1:NumberOfEntries, iD) = cell2mat(ALLdata.EM_Attitude.TimeInMillisecondsSinceRecordStart(iD));
                fData.At_ED_SensorStatus(1:NumberOfEntries, iD)                       = cell2mat(ALLdata.EM_Attitude.SensorStatus(iD));
                fData.At_ED_Roll(1:NumberOfEntries, iD)                               = cell2mat(ALLdata.EM_Attitude.Roll(iD));
                fData.At_ED_Pitch(1:NumberOfEntries, iD)                              = cell2mat(ALLdata.EM_Attitude.Pitch(iD));
                fData.At_ED_Heave(1:NumberOfEntries, iD)                              = cell2mat(ALLdata.EM_Attitude.Heave(iD));
                fData.At_ED_Heading(1:NumberOfEntries, iD)                            = cell2mat(ALLdata.EM_Attitude.Heading(iD));
                
            end
            
        end
        
    end
    
    
    %% EM_Height
    
    if isfield(ALLdata,'EM_Height')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'He_1D_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            % NumberOfDatagrams = length(ALLdata.EM_Height.TypeOfDatagram);
            
            fData.He_1D_Date                            = ALLdata.EM_Height.Date;
            fData.He_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Height.TimeSinceMidnightInMilliseconds;
            fData.He_1D_HeightCounter                   = ALLdata.EM_Height.HeightCounter;
            fData.He_1D_Height                          = ALLdata.EM_Height.Height/100;
            
        end
        
    end
    
    %% EM_Position (v2 verified)
    
    if isfield(ALLdata,'EM_Position')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'Po_1D_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            % NumberOfDatagrams = length(ALLdata.EM_Position.TypeOfDatagram);
            
            fData.Po_1D_Date                            = ALLdata.EM_Position.Date;
            fData.Po_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Position.TimeSinceMidnightInMilliseconds;  % in ms
            fData.Po_1D_PositionCounter                 = ALLdata.EM_Position.PositionCounter;
            fData.Po_1D_Latitude                        = ALLdata.EM_Position.Latitude./20000000; % now in decimal degrees
            fData.Po_1D_Longitude                       = ALLdata.EM_Position.Longitude./10000000; % now in decimal degrees
            fData.Po_1D_SpeedOfVesselOverGround         = ALLdata.EM_Position.SpeedOfVesselOverGround./100;  % now in m/s
            fData.Po_1D_HeadingOfVessel                 = ALLdata.EM_Position.HeadingOfVessel./100;  % now in degrees relative to north
            fData.Po_1D_MeasureOfPositionFixQuality     = ALLdata.EM_Position.MeasureOfPositionFixQuality./100;  % in meters
            fData.Po_1D_PositionSystemDescriptor        = ALLdata.EM_Position.PositionSystemDescriptor;  % indicator if there are several GPS sources
            
        end
        
    end
    
    
    %% EM_Depth
    
    if isfield(ALLdata,'EM_Depth')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'De_1P_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            NumberOfPings    = length(ALLdata.EM_Depth.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(cellfun(@(x) max(x),ALLdata.EM_Depth.BeamNumber)); % maximum beam number in file
            
            fData.De_1P_Date                            = ALLdata.EM_Depth.Date;
            fData.De_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_Depth.TimeSinceMidnightInMilliseconds;
            fData.De_1P_PingCounter                     = ALLdata.EM_Depth.PingCounter;
            fData.De_1P_HeadingOfVessel                 = ALLdata.EM_Depth.HeadingOfVessel;
            fData.De_1P_SoundSpeedAtTransducer          = ALLdata.EM_Depth.SoundSpeedAtTransducer*0.1;
            fData.De_1P_TransmitTransducerDepth         = ALLdata.EM_Depth.TransmitTransducerDepth + 65536.*ALLdata.EM_Depth.TransducerDepthOffsetMultiplier;
            fData.De_1P_MaximumNumberOfBeamsPossible    = ALLdata.EM_Depth.MaximumNumberOfBeamsPossible;
            fData.De_1P_NumberOfValidBeams              = ALLdata.EM_Depth.NumberOfValidBeams;
            fData.De_1P_ZResolution                     = ALLdata.EM_Depth.ZResolution;
            fData.De_1P_XAndYResolution                 = ALLdata.EM_Depth.XAndYResolution;
            fData.De_1P_SamplingRate                    = ALLdata.EM_Depth.SamplingRate;
            
            % initialize
            fData.De_BP_DepthZ                  = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_BP_AcrosstrackDistanceY    = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_BP_AlongtrackDistanceX     = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_BP_BeamDepressionAngle     = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_BP_BeamAzimuthAngle        = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_BP_Range                   = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_BP_QualityFactor           = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_BP_LengthOfDetectionWindow = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_BP_ReflectivityBS          = nan(MaxNumberOfBeams,NumberOfPings);
            fData.De_B1_BeamNumber              = (1:MaxNumberOfBeams)';
            
            for iP = 1:NumberOfPings
                
                BeamNumber = cell2mat(ALLdata.EM_Depth.BeamNumber(iP));
                
                fData.De_BP_DepthZ(BeamNumber,iP)                  = cell2mat(ALLdata.EM_Depth.DepthZ(iP));
                fData.De_BP_AcrosstrackDistanceY(BeamNumber,iP)    = cell2mat(ALLdata.EM_Depth.AcrosstrackDistanceY(iP));
                fData.De_BP_AlongtrackDistanceX(BeamNumber,iP)     = cell2mat(ALLdata.EM_Depth.AlongtrackDistanceX(iP));
                fData.De_BP_BeamDepressionAngle(BeamNumber,iP)     = cell2mat(ALLdata.EM_Depth.BeamDepressionAngle(iP));
                fData.De_BP_BeamAzimuthAngle(BeamNumber,iP)        = cell2mat(ALLdata.EM_Depth.BeamAzimuthAngle(iP));
                fData.De_BP_Range(BeamNumber,iP)                   = cell2mat(ALLdata.EM_Depth.Range(iP));
                fData.De_BP_QualityFactor(BeamNumber,iP)           = cell2mat(ALLdata.EM_Depth.QualityFactor(iP));
                fData.De_BP_LengthOfDetectionWindow(BeamNumber,iP) = cell2mat(ALLdata.EM_Depth.LengthOfDetectionWindow(iP));
                fData.De_BP_ReflectivityBS(BeamNumber,iP)          = cell2mat(ALLdata.EM_Depth.ReflectivityBS(iP));
                
            end
            
        end
        
    end
    
    
    %% EM_XYZ88
    
    if isfield(ALLdata,'EM_XYZ88')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'X8_1P_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            NumberOfPings    = length(ALLdata.EM_XYZ88.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(ALLdata.EM_XYZ88.NumberOfBeamsInDatagram); % maximum beam number in file
            
            fData.X8_1P_Date                            = ALLdata.EM_XYZ88.Date;
            fData.X8_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_XYZ88.TimeSinceMidnightInMilliseconds;
            fData.X8_1P_PingCounter                     = ALLdata.EM_XYZ88.PingCounter;
            fData.X8_1P_HeadingOfVessel                 = ALLdata.EM_XYZ88.HeadingOfVessel;
            fData.X8_1P_SoundSpeedAtTransducer          = ALLdata.EM_XYZ88.SoundSpeedAtTransducer*0.1;
            fData.X8_1P_TransmitTransducerDepth         = ALLdata.EM_XYZ88.TransmitTransducerDepth;
            fData.X8_1P_NumberOfBeamsInDatagram         = ALLdata.EM_XYZ88.NumberOfBeamsInDatagram;
            fData.X8_1P_NumberOfValidDetections         = ALLdata.EM_XYZ88.NumberOfValidDetections;
            fData.X8_1P_SamplingFrequencyInHz           = ALLdata.EM_XYZ88.SamplingFrequencyInHz;
            
            % initialize
            fData.X8_BP_DepthZ                       = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_BP_AcrosstrackDistanceY         = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_BP_AlongtrackDistanceX          = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_BP_DetectionWindowLength        = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_BP_QualityFactor                = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_BP_BeamIncidenceAngleAdjustment = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_BP_DetectionInformation         = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_BP_RealTimeCleaningInformation  = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_BP_ReflectivityBS               = nan(MaxNumberOfBeams,NumberOfPings);
            fData.X8_B1_BeamNumber                   = (1:MaxNumberOfBeams)';
            
            for iP = 1:NumberOfPings
                N=numel(cell2mat(ALLdata.EM_XYZ88.DepthZ(iP)));
                fData.X8_BP_DepthZ(1:N,iP)                       = cell2mat(ALLdata.EM_XYZ88.DepthZ(iP));
                fData.X8_BP_AcrosstrackDistanceY(1:N,iP)         = cell2mat(ALLdata.EM_XYZ88.AcrosstrackDistanceY(iP));
                fData.X8_BP_AlongtrackDistanceX(1:N,iP)          = cell2mat(ALLdata.EM_XYZ88.AlongtrackDistanceX(iP));
                fData.X8_BP_DetectionWindowLength(1:N,iP)        = cell2mat(ALLdata.EM_XYZ88.DetectionWindowLength(iP));
                fData.X8_BP_QualityFactor(1:N,iP)                = cell2mat(ALLdata.EM_XYZ88.QualityFactor(iP));
                fData.X8_BP_BeamIncidenceAngleAdjustment(1:N,iP) = cell2mat(ALLdata.EM_XYZ88.BeamIncidenceAngleAdjustment(iP));
                fData.X8_BP_DetectionInformation(1:N,iP)         = cell2mat(ALLdata.EM_XYZ88.DetectionInformation(iP));
                fData.X8_BP_RealTimeCleaningInformation(1:N,iP)  = cell2mat(ALLdata.EM_XYZ88.RealTimeCleaningInformation(iP));
                fData.X8_BP_ReflectivityBS(1:N,iP)               = cell2mat(ALLdata.EM_XYZ88.ReflectivityBS(iP));
                
            end
            
        end
        
    end
    
    
    %% EM_SeabedImage
    
    if isfield(ALLdata,'EM_SeabedImage')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'SI_1P_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            NumberOfPings      = length(ALLdata.EM_SeabedImage.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams   = max(cellfun(@(x) max(x),ALLdata.EM_SeabedImage.BeamIndexNumber))+1; % maximum beam number (beam index number +1), in file
            MaxNumberOfSamples = max(cellfun(@(x) max(x),ALLdata.EM_SeabedImage.NumberOfSamplesPerBeam));
            
            fData.SI_1P_Date                            = ALLdata.EM_SeabedImage.Date;
            fData.SI_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_SeabedImage.TimeSinceMidnightInMilliseconds;
            fData.SI_1P_PingCounter                     = ALLdata.EM_SeabedImage.PingCounter;
            fData.SI_1P_MeanAbsorptionCoefficient       = ALLdata.EM_SeabedImage.MeanAbsorptionCoefficient;
            fData.SI_1P_PulseLength                     = ALLdata.EM_SeabedImage.PulseLength;
            fData.SI_1P_RangeToNormalIncidence          = ALLdata.EM_SeabedImage.RangeToNormalIncidence;
            fData.SI_1P_StartRangeSampleOfTVGRamp       = ALLdata.EM_SeabedImage.StartRangeSampleOfTVGRamp;
            fData.SI_1P_StopRangeSampleOfTVGRamp        = ALLdata.EM_SeabedImage.StopRangeSampleOfTVGRamp;
            fData.SI_1P_NormalIncidenceBS               = ALLdata.EM_SeabedImage.NormalIncidenceBS;
            fData.SI_1P_ObliqueBS                       = ALLdata.EM_SeabedImage.ObliqueBS;
            fData.SI_1P_TxBeamwidth                     = ALLdata.EM_SeabedImage.TxBeamwidth;
            fData.SI_1P_TVGLawCrossoverAngle            = ALLdata.EM_SeabedImage.TVGLawCrossoverAngle;
            fData.SI_1P_NumberOfValidBeams              = ALLdata.EM_SeabedImage.NumberOfValidBeams;
            
            % initialize
            fData.SI_BP_SortingDirection       = nan(MaxNumberOfBeams,NumberOfPings);
            fData.SI_BP_NumberOfSamplesPerBeam = nan(MaxNumberOfBeams,NumberOfPings);
            fData.SI_BP_CentreSampleNumber     = nan(MaxNumberOfBeams,NumberOfPings);
            fData.SI_B1_BeamNumber             = (1:MaxNumberOfBeams)';
            fData.SI_SBP_SampleAmplitudes      = cell(NumberOfPings,1); % saving as sparse
            
            for iP = 1:NumberOfPings
                
                % Get data from datagram
                BeamNumber             = cell2mat(ALLdata.EM_SeabedImage.BeamIndexNumber(iP))+1;
                NumberOfSamplesPerBeam = cell2mat(ALLdata.EM_SeabedImage.NumberOfSamplesPerBeam(iP));
                Samples                = cell2mat(ALLdata.EM_SeabedImage.SampleAmplitudes(iP).beam(:));
                
                % from number of samples per beam, get indices of first and last
                % sample for each beam in the Samples data vector
                iFirst = [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
                iLast  = iFirst+NumberOfSamplesPerBeam-1;
                
                % store
                fData.SI_BP_SortingDirection(BeamNumber,iP)       = cell2mat(ALLdata.EM_SeabedImage.SortingDirection(iP));
                fData.SI_BP_NumberOfSamplesPerBeam(BeamNumber,iP) = NumberOfSamplesPerBeam;
                fData.SI_BP_CentreSampleNumber(BeamNumber,iP)     = cell2mat(ALLdata.EM_SeabedImage.CentreSampleNumber(iP));
                
                % initialize the beams/sample array (use zero instead of NaN to
                % allow turning it to sparse
                temp = zeros(MaxNumberOfSamples,length(BeamNumber));
                
                % fill in
                for iB = 1:length(BeamNumber)
                    temp(1:NumberOfSamplesPerBeam(iB),BeamNumber(iB)) = Samples(iFirst(iB):iLast(iB));
                end
                
                % and save the sparse version
                fData.SI_SBP_SampleAmplitudes(iP,1) = {sparse(temp)}; % to use full matrices, fData.SI_SBP_SampleAmplitudes(:,:,iP) = temp;
                
            end
            
        end
        
    end
    
    
    %% EM_SeabedImage89
    
    if isfield(ALLdata,'EM_SeabedImage89')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'S8_1P_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            NumberOfPings      = length(ALLdata.EM_SeabedImage89.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams   = max(ALLdata.EM_SeabedImage89.NumberOfValidBeams);
            MaxNumberOfSamples = max(cellfun(@(x) max(x),ALLdata.EM_SeabedImage89.NumberOfSamplesPerBeam));
            
            fData.S8_1P_Date                            = ALLdata.EM_SeabedImage89.Date;
            fData.S8_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_SeabedImage89.TimeSinceMidnightInMilliseconds;
            fData.S8_1P_PingCounter                     = ALLdata.EM_SeabedImage89.PingCounter;
            fData.S8_1P_SamplingFrequencyInHz           = ALLdata.EM_SeabedImage89.SamplingFrequencyInHz;
            fData.S8_1P_RangeToNormalIncidence          = ALLdata.EM_SeabedImage89.RangeToNormalIncidence;
            fData.S8_1P_NormalIncidenceBS               = ALLdata.EM_SeabedImage89.NormalIncidenceBS;
            fData.S8_1P_ObliqueBS                       = ALLdata.EM_SeabedImage89.ObliqueBS;
            fData.S8_1P_TxBeamwidthAlong                = ALLdata.EM_SeabedImage89.TxBeamwidthAlong;
            fData.S8_1P_TVGLawCrossoverAngle            = ALLdata.EM_SeabedImage89.TVGLawCrossoverAngle;
            fData.S8_1P_NumberOfValidBeams              = ALLdata.EM_SeabedImage89.NumberOfValidBeams;
            
            % initialize
            fData.S8_BP_SortingDirection       = nan(MaxNumberOfBeams,NumberOfPings);
            fData.S8_BP_DetectionInfo          = nan(MaxNumberOfBeams,NumberOfPings);
            fData.S8_BP_NumberOfSamplesPerBeam = nan(MaxNumberOfBeams,NumberOfPings);
            fData.S8_BP_CentreSampleNumber     = nan(MaxNumberOfBeams,NumberOfPings);
            fData.S8_B1_BeamNumber             = (1:MaxNumberOfBeams)';
            fData.S8_SBP_SampleAmplitudes      = cell(NumberOfPings,1);
            
            % in this more recent datagram, all beams are in. No beamnumber anymore
            BeamNumber = fData.S8_B1_BeamNumber;
            
            for iP = 1:NumberOfPings
                
                % Get data from datagram
                NumberOfSamplesPerBeam = cell2mat(ALLdata.EM_SeabedImage89.NumberOfSamplesPerBeam(iP));
                Samples                = cell2mat(ALLdata.EM_SeabedImage89.SampleAmplitudes(iP).beam(:));
                
                % from number of samples per beam, get indices of first and last
                % sample for each beam in the Samples data vector
                iFirst = [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
                iLast  = iFirst+NumberOfSamplesPerBeam-1;
                
                % store
                fData.S8_BP_SortingDirection(BeamNumber,iP)       = cell2mat(ALLdata.EM_SeabedImage89.SortingDirection(iP));
                fData.S8_BP_NumberOfSamplesPerBeam(BeamNumber,iP) = NumberOfSamplesPerBeam;
                fData.S8_BP_CentreSampleNumber(BeamNumber,iP)     = cell2mat(ALLdata.EM_SeabedImage89.CentreSampleNumber(iP));
                
                % initialize the beams/sample array (use zero instead of NaN to
                % allow turning it to sparse
                temp = zeros(MaxNumberOfSamples,length(BeamNumber));
                
                % and fill in
                for iB = 1:length(BeamNumber)
                    temp(1:NumberOfSamplesPerBeam(iB),BeamNumber(iB)) = Samples(iFirst(iB):iLast(iB));
                end
                
                % and save the sparse version
                fData.S8_SBP_SampleAmplitudes(iP,1) = {sparse(temp)}; % to use full matrices, fData.S8_SBP_SampleAmplitudes(:,:,iP) = temp;
                
            end
            
        end
        
    end
    
    
    %% EM_WaterColumn (v2 verified)
    
    if isfield(ALLdata,'EM_WaterColumn')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'WC_1P_Date') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
            
            if update_mode
                update_flag = 1;
            end
            
            % get the number of heads
            headNumber = unique(ALLdata.EM_WaterColumn.SystemSerialNumber,'stable');
            
            % get the list of pings and the index of first datagram for
            % each ping
            if length(headNumber) == 1
                % if only one head...
                [pingCounters, iFirstDatagram] = unique(ALLdata.EM_WaterColumn.PingCounter,'stable');
            else
                % in case there's more than one head, we're going to only
                % keep pings for which we have data for all heads
                
                % pings for first head
                pingCounters = unique(ALLdata.EM_WaterColumn.PingCounter(ALLdata.EM_WaterColumn.SystemSerialNumber==headNumber(1)),'stable');
                
                % for each other head, get ping numbers and only keep
                % intersection
                for iH = 2:length(headNumber)
                    pingCountersOtherHead = unique(ALLdata.EM_WaterColumn.PingCounter(ALLdata.EM_WaterColumn.SystemSerialNumber==headNumber(iH)),'stable');
                    pingCounters = intersect(pingCounters, pingCountersOtherHead);
                end
                
                % get the index of first datagram for each ping and each
                % head
                for iH = 1:length(headNumber)
                    
                    iFirstDatagram(:,iH) = arrayfun(@(x) find(ALLdata.EM_WaterColumn.SystemSerialNumber==headNumber(iH) & ALLdata.EM_WaterColumn.PingCounter==x, 1),pingCounters);
                    
                    % % originally we would require datagram number 1, but
                    % % it turns out it doesn't always exist. Keep this
                    % % code here for now, but the replacement above to
                    % % just find the first datagram for each ping seems to
                    % % work fine.
                    % iFirstDatagram(:,iH) = find( ALLdata.EM_WaterColumn.SystemSerialNumber == headNumber(iH) & ...
                    %     ismember(ALLdata.EM_WaterColumn.PingCounter,pingCounters) & ...
                    %     ALLdata.EM_WaterColumn.DatagramNumbers == 1);
                end
            end
            
            % save ping numbers
            fData.WC_1P_PingCounter = pingCounters;
            
            % for the following fields, take value from first datagram in
            % first head
            fData.WC_1P_Date                            = ALLdata.EM_WaterColumn.Date(iFirstDatagram(:,1));
            fData.WC_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_WaterColumn.TimeSinceMidnightInMilliseconds(iFirstDatagram(:,1));
            fData.WC_1P_SoundSpeed                      = ALLdata.EM_WaterColumn.SoundSpeed(iFirstDatagram(:,1))*0.1;
            fData.WC_1P_OriginalSamplingFrequencyHz     = ALLdata.EM_WaterColumn.SamplingFrequency(iFirstDatagram(:,1)).*0.01; % in Hz
            fData.WC_1P_SamplingFrequencyHz             = (ALLdata.EM_WaterColumn.SamplingFrequency(iFirstDatagram(:,1)).*0.01)./dr_sub; % in Hz
            fData.WC_1P_TXTimeHeave                     = ALLdata.EM_WaterColumn.TXTimeHeave(iFirstDatagram(:,1));
            fData.WC_1P_TVGFunctionApplied              = ALLdata.EM_WaterColumn.TVGFunctionApplied(iFirstDatagram(:,1));
            fData.WC_1P_TVGOffset                       = ALLdata.EM_WaterColumn.TVGOffset(iFirstDatagram(:,1));
            fData.WC_1P_ScanningInfo                    = ALLdata.EM_WaterColumn.ScanningInfo(iFirstDatagram(:,1));
            
            % test for inconsistencies between heads and raise a warning if
            % one is detected
            if length(headNumber) > 1
                fields = {'SoundSpeed','SamplingFrequency','TXTimeHeave','TVGFunctionApplied','TVGOffset','ScanningInfo'};
                for iFi = 1:length(fields)
                    if any(any(ALLdata.EM_WaterColumn.(fields{iFi})(iFirstDatagram(:,1))'.*ones(1,length(headNumber))~=ALLdata.EM_WaterColumn.(fields{iFi})(iFirstDatagram)))
                        warning('System has more than one head and "%s" data are inconsistent between heads for at least one ping. Using information from first head anyway.',fields{iFi});
                    end
                end
            end
            
            % for the other fields, sum the numbers from heads
            if length(headNumber) > 1
                fData.WC_1P_NumberOfDatagrams                  = sum(ALLdata.EM_WaterColumn.NumberOfDatagrams(iFirstDatagram),2)';
                fData.WC_1P_NumberOfTransmitSectors            = sum(ALLdata.EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram),2)';
                fData.WC_1P_OriginalTotalNumberOfReceiveBeams  = sum(ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram),2)';
                fData.WC_1P_TotalNumberOfReceiveBeams          = sum(ceil(ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram)/db_sub),2)'; % each head is decimated in beam individually
            else
                fData.WC_1P_NumberOfDatagrams                  = ALLdata.EM_WaterColumn.NumberOfDatagrams(iFirstDatagram);
                fData.WC_1P_NumberOfTransmitSectors            = ALLdata.EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram);
                fData.WC_1P_OriginalTotalNumberOfReceiveBeams  = ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram);
                fData.WC_1P_TotalNumberOfReceiveBeams          = ceil(ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram)/db_sub); % each head is decimated in beam individually
            end
            
            % get number of pings, maximum number of transmit sectors,
            % maximum number of receive beams and maximum number of samples
            % in any given ping to use as the output data dimensions
            nPings              = length(pingCounters);
            maxNTransmitSectors = max(fData.WC_1P_NumberOfTransmitSectors);
            maxNBeams           = max(fData.WC_1P_OriginalTotalNumberOfReceiveBeams);
            maxNBeams_sub       = max(fData.WC_1P_TotalNumberOfReceiveBeams); % number of beams to extract (decimated)
            maxNSamples         = max(cellfun(@(x) max(x), ALLdata.EM_WaterColumn.NumberOfSamples(ismember(ALLdata.EM_WaterColumn.PingCounter,pingCounters))));
            maxNSamples_sub     = ceil(maxNSamples/dr_sub); % number of samples to extract (decimated)
            
            %Samples=cellfun(@plus,ALLdata.EM_WaterColumn.StartRangeSampleNumber,ALLdata.EM_WaterColumn.NumberOfSamples,'un',0);
            [maxNSamples_groups,ping_group_start,ping_group_end] = CFF_group_pings(ALLdata.EM_WaterColumn.NumberOfSamples,pingCounters,ALLdata.EM_WaterColumn.PingCounter);
            maxNSamples_groups=maxNSamples_groups/dr_sub;
            
            % path to binary file for WC data
            file_binary=cell(1,numel(maxNSamples_groups));
            fileID=-ones(1,numel(maxNSamples_groups));
            
            for uig=1:numel(ping_group_start)
                file_binary{uig} = fullfile(wc_dir,sprintf('WC_SBP_SampleAmplitudes_%.0f_%.0f.dat',ping_group_start(uig),ping_group_end(uig)));
                if ~exist(file_binary{uig},'file') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
                    fileID(uig) = fopen(file_binary{uig},'w+');
                    % if we're not here, it means the file already exists and
                    % already contain the data at the proper sampling. So we
                    % just need to store the metadata and link to it as
                    % memmapfile.
                end
            end
            
            % initialize data per transmit sector and ping
            fData.WC_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
            fData.WC_TP_CenterFrequency      = nan(maxNTransmitSectors,nPings);
            fData.WC_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
            fData.WC_TP_SystemSerialNumber   = nan(maxNTransmitSectors,nPings);
            
            % initialize data per decimated beam and ping
            fData.WC_BP_BeamPointingAngle      = nan(maxNBeams_sub,nPings)/100;
            fData.WC_BP_StartRangeSampleNumber = nan(maxNBeams_sub,nPings);
            fData.WC_BP_NumberOfSamples        = nan(maxNBeams_sub,nPings);
            fData.WC_BP_DetectedRangeInSamples = zeros(maxNBeams_sub,nPings);
            fData.WC_BP_TransmitSectorNumber   = nan(maxNBeams_sub,nPings);
            fData.WC_BP_BeamNumber             = nan(maxNBeams_sub,nPings);
            fData.WC_BP_SystemSerialNumber     = nan(maxNBeams_sub,nPings);
            
            
            ig=1;
            % now get data for each ping
            %             fp=figure();
            %             ax=axes(fp);
            for iP = 1:nPings
                
                % ping number (ex: 50455)
                pingCounter = fData.WC_1P_PingCounter(1,iP);
                if pingCounter-fData.WC_1P_PingCounter(1,1)+1>ping_group_end(ig)
                    ig=ig+1;
                end
                % initialize the water column data matrix for that ping.
                % Original data are in "int8" format, the NaN equivalent
                % will be -128
                if fileID(ig) >= 0
                    SB_temp = zeros(maxNSamples_groups(ig),maxNBeams_sub,'int8') - 128;
                end
                
                % intialize number of sectors and beams recorded so far for
                % that ping (needed for multiple heads)
                nTxSectTot = 0;
                nBeamTot = 0;
                
                for iH = 1:length(headNumber)
                    
                    headSSN = headNumber(iH);
                    
                    % index of the datagrams making up this ping/head in ALLdata.EM_Watercolumn (ex: 58-59-61-64)
                    iDatagrams  = find( ALLdata.EM_WaterColumn.PingCounter == pingCounter & ...
                        ALLdata.EM_WaterColumn.SystemSerialNumber == headSSN);
                    
                    % actual number of datagrams available (ex: 4)
                    nDatagrams  = length(iDatagrams);
                    
                    % some datagrams may be missing. Need to detect and adjust.
                    % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
                    datagramOrder     = ALLdata.EM_WaterColumn.DatagramNumbers(iDatagrams);
                    [~,IX]            = sort(datagramOrder);
                    iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in ALLdata.EM_Watercolumn, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
                    nBeamsPerDatagram = ALLdata.EM_WaterColumn.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
                    
                    % number of transmit sectors to record
                    nTxSect = ALLdata.EM_WaterColumn.NumberOfTransmitSectors(iDatagrams(1));
                    
                    % indices of those sectors in output structure
                    iTxSectDest = nTxSectTot + (1:nTxSect);
                    
                    % recording data per transmit sector
                    fData.WC_TP_TiltAngle(iTxSectDest,iP)            = ALLdata.EM_WaterColumn.TiltAngle{iDatagrams(1)};
                    fData.WC_TP_CenterFrequency(iTxSectDest,iP)      = ALLdata.EM_WaterColumn.CenterFrequency{iDatagrams(1)};
                    fData.WC_TP_TransmitSectorNumber(iTxSectDest,iP) = ALLdata.EM_WaterColumn.TransmitSectorNumber{iDatagrams(1)};
                    fData.WC_TP_SystemSerialNumber(iTxSectDest,iP)   = headSSN;
                    
                    % updating total number of sectors recorded so far
                    nTxSectTot = nTxSectTot + nTxSect;
                    
                    % and then read the data in each datagram
                    for iD = 1:nDatagrams
                        
                        % indices of desired beams in this head/datagram
                        if iD == 1
                            % if first datagram, start with first beam
                            iBeamStart = 1;
                        else
                            % if not first datagram, continue the
                            % decimation where we left it
                            nBeamsLastDatag = nBeamsPerDatagram(iD-1);
                            lastRecBeam  = iBeamSource(end);
                            iBeamStart = db_sub - (nBeamsLastDatag-lastRecBeam);
                        end
                        iBeamSource = iBeamStart:db_sub:nBeamsPerDatagram(iD);
                        
                        % number of beams to record
                        nBeam = length(iBeamSource);
                        
                        % indices of those beams in output structure
                        iBeamDest = nBeamTot + (1:nBeam);
                        
                        fData.WC_BP_BeamPointingAngle(iBeamDest,iP)      = ALLdata.EM_WaterColumn.BeamPointingAngle{iDatagrams(iD)}(iBeamSource)/100;
                        fData.WC_BP_StartRangeSampleNumber(iBeamDest,iP) = round(ALLdata.EM_WaterColumn.StartRangeSampleNumber{iDatagrams(iD)}(iBeamSource)./dr_sub);
                        fData.WC_BP_NumberOfSamples(iBeamDest,iP)        = round(ALLdata.EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(iBeamSource)./dr_sub);
                        fData.WC_BP_DetectedRangeInSamples(iBeamDest,iP) = round(ALLdata.EM_WaterColumn.DetectedRangeInSamples{iDatagrams(iD)}(iBeamSource)./dr_sub);
                        fData.WC_BP_TransmitSectorNumber(iBeamDest,iP)   = ALLdata.EM_WaterColumn.TransmitSectorNumber2{iDatagrams(iD)}(iBeamSource);
                        fData.WC_BP_BeamNumber(iBeamDest,iP)             = ALLdata.EM_WaterColumn.BeamNumber{iDatagrams(iD)}(iBeamSource);
                        fData.WC_BP_SystemSerialNumber(iBeamDest,iP)     = headSSN;
                        
                        % now getting watercolumn data (beams x samples)
                        if fileID(ig) >= 0
                            
                            for iB = 1:nBeam
                                
                                % actual number of samples in that beam
                                nSamp = ALLdata.EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(iBeamSource(iB));
                                
                                % number of samples we're going to record
                                nSamp_sub = ceil(nSamp/dr_sub);
                                
                                % read the data in original file and record
                                % water column data are recorded in "int8
                                % (-128 to 127) with -128 being the NaN
                                % value, and with a resolution of 0.5dB,
                                % aka it needs to be multiplied by a factor
                                % of 1/2 to retrieve the appropriate value,
                                % aka an int8 record of -41 is actually
                                % -20.5dB
                                pos = ALLdata.EM_WaterColumn.SampleAmplitudePosition{iDatagrams(iD)}(iBeamSource(iB));
                                fseek(fid_all,pos,'bof');
                                SB_temp(1:nSamp_sub,nBeamTot+iB) = fread(fid_all,nSamp_sub,'int8',dr_sub-1);
                                
                            end
                            
                        end
                        
                        % updating total number of beams recorded so far
                        nBeamTot = nBeamTot + nBeam;
                        
                    end
                    
                end
                
                % store data on binary file
                if fileID(ig) >= 0
                    fwrite(fileID(ig),SB_temp,'int8');
                    %                     imagesc(ax,SB_temp);
                    %                     drawnow;
                end
                
            end
            
            fData.WC_n_start=ping_group_start;
            fData.WC_n_end=ping_group_end;
            fData.WC_n_maxNSamples=maxNSamples_groups;
            
            % close binary data file
            fData.WC_SBP_SampleAmplitudes=cell(1,numel(fileID));
            for ig =1:numel(fileID)
                if fileID(ig) >= 0
                    fclose(fileID(ig));
                end
                % and link to it through memmapfile
                % remember data is in int8 format
                
                fData.WC_SBP_SampleAmplitudes{ig} = memmapfile(file_binary{ig},'Format',{'int8' [maxNSamples_groups(ig) maxNBeams_sub fData.WC_n_end(ig)-fData.WC_n_start(ig)+1] 'val'},'repeat',1,'writable',true);
            end
            
            % save info about data format for later access and conversion
            % to dB
            fData.WC_1_SampleAmplitudes_Class = 'int8';
            fData.WC_1_SampleAmplitudes_Nanval = -128;
            fData.WC_1_SampleAmplitudes_Factor = 1/2;
            
        end
    end
    
    
    %% EM_AmpPhase
    
    if isfield(ALLdata,'EM_AmpPhase')
        
        % only convert these datagrams if this type doesn't already exist in output
        if f_reconvert || ~isfield(fData,'AP_1P_Date') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
            
            if update_mode
                update_flag = 1;
            end
            
            % get indices of first datagram for each ping
            [pingCounters,iFirstDatagram] = unique(ALLdata.EM_AmpPhase.PingCounter,'stable');
            
            % get data dimensions
            nPings              = length(pingCounters); % total number of pings in file
            maxNBeams           = max(ALLdata.EM_AmpPhase.TotalNumberOfReceiveBeams); % maximum number of beams for a ping in file
            maxNTransmitSectors = max(ALLdata.EM_AmpPhase.NumberOfTransmitSectors); % maximum number of transmit sectors for a ping in file
            maxNSamples         = max(cellfun(@(x) max(x),ALLdata.EM_AmpPhase.NumberOfSamples)); % max number of samples for a beam in file
            
            % decimating beams and samples
            maxNBeams_sub       = ceil(maxNBeams/db_sub); % number of beams to extract
            maxNSamples_sub     = ceil(maxNSamples/dr_sub); % number of samples to extract
            
            % read data per ping from first datagram of each ping
            fData.AP_1P_Date                            = ALLdata.EM_AmpPhase.Date(iFirstDatagram);
            fData.AP_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_AmpPhase.TimeSinceMidnightInMilliseconds(iFirstDatagram);
            fData.AP_1P_PingCounter                     = ALLdata.EM_AmpPhase.PingCounter(iFirstDatagram);
            fData.AP_1P_NumberOfDatagrams               = ALLdata.EM_AmpPhase.NumberOfDatagrams(iFirstDatagram);
            fData.AP_1P_NumberOfTransmitSectors         = ALLdata.EM_AmpPhase.NumberOfTransmitSectors(iFirstDatagram);
            fData.AP_1P_TotalNumberOfReceiveBeams       = ALLdata.EM_AmpPhase.TotalNumberOfReceiveBeams(iFirstDatagram);
            fData.AP_1P_SoundSpeed                      = ALLdata.EM_AmpPhase.SoundSpeed(iFirstDatagram)*0.1;
            fData.AP_1P_SamplingFrequencyHz             = (ALLdata.EM_AmpPhase.SamplingFrequency(iFirstDatagram).*0.01)./dr_sub; % in Hz
            fData.AP_1P_TXTimeHeave                     = ALLdata.EM_AmpPhase.TXTimeHeave(iFirstDatagram);
            fData.AP_1P_TVGFunctionApplied              = ALLdata.EM_AmpPhase.TVGFunctionApplied(iFirstDatagram);
            fData.AP_1P_TVGOffset                       = ALLdata.EM_AmpPhase.TVGOffset(iFirstDatagram);
            fData.AP_1P_ScanningInfo                    = ALLdata.EM_AmpPhase.ScanningInfo(iFirstDatagram);
            
            % initialize data per transmit sector and ping
            fData.AP_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
            fData.AP_TP_CenterFrequency      = nan(maxNTransmitSectors,nPings);
            fData.AP_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
            
            % initialize data per decimated beam and ping
            fData.AP_BP_BeamPointingAngle      = nan(maxNBeams_sub,nPings);
            fData.AP_BP_StartRangeSampleNumber = nan(maxNBeams_sub,nPings);
            fData.AP_BP_NumberOfSamples        = nan(maxNBeams_sub,nPings);
            fData.AP_BP_DetectedRangeInSamples = zeros(maxNBeams_sub,nPings);
            fData.AP_BP_TransmitSectorNumber   = nan(maxNBeams_sub,nPings);
            fData.AP_BP_BeamNumber             = nan(maxNBeams_sub,nPings);
            
            %Samples=cellfun(@plus,ALLdata.EM_AmpPhase.StartRangeSampleNumber,ALLdata.EM_AmpPhase.NumberOfSamples,'un',0);
            [maxNSamples_groups,ping_group_start,ping_group_end]=CFF_group_pings(ALLdata.EM_AmpPhase.NumberOfSamples,pingCounters,ALLdata.EM_AmpPhase.PingCounter);
            
            
            % path to binary file for WC data
            file_amp_binary=cell(1,numel(maxNSamples_groups));
            file_phase_binary=cell(1,numel(maxNSamples_groups));
            file_amp_id=-ones(1,numel(maxNSamples_groups));
            file_phase_id=-ones(1,numel(maxNSamples_groups));
            
            for uig=1:numel(ping_group_start)
                file_amp_binary{uig} = fullfile(wc_dir,sprintf('AP_SBP_SampleAmplitudes_%.0f_%.0f.dat',ping_group_start(uig),ping_group_end(uig)));
                file_phase_binary{uig} = fullfile(wc_dir,sprintf('AP_SBP_SamplePhase_%.0f_%.0f.dat',ping_group_start(uig),ping_group_end(uig)));
                
                if exist(file_amp_binary{uig},'file')==0 || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
                    file_amp_id(uig) = fopen(file_amp_binary{uig},'w+');
                else
                    file_amp_id(uig) = -1;
                end
                
                % repeat for phase file
                if exist(file_phase_binary{uig},'file')==0 || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
                    file_phase_id(uig) = fopen(file_phase_binary{uig},'w+');
                else
                    file_phase_id(uig) = -1;
                end
            end
            
            
            ig=1;
            disp_wc=0;
            if disp_wc
                f = figure();
                ax_mag = axes(f,'outerposition',[0 0.5 1 0.5]);
                ax_phase = axes(f,'outerposition',[0 0 1 0.5]);
            end
            % now get data for each ping
            for iP = 1:nPings
                
                if iP>ping_group_end(ig)
                    ig=ig+1;
                end
                
                % find datagrams composing this ping
                pingCounter = fData.AP_1P_PingCounter(1,iP); % ping number (ex: 50455)
                % nDatagrams  = fData.AP_1P_NumberOfDatagrams(1,iP); % theoretical number of datagrams for this ping (ex: 7)
                iDatagrams  = find(ALLdata.EM_AmpPhase.PingCounter==pingCounter); % index of the datagrams making up this ping in ALLdata.EM_AmpPhase (ex: 58-59-61-64)
                nDatagrams  = length(iDatagrams); % actual number of datagrams available (ex: 4)
                
                % some datagrams may be missing, like in the example. Detect and adjust...
                datagramOrder     = ALLdata.EM_AmpPhase.DatagramNumbers(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
                [~,IX]            = sort(datagramOrder);
                iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in ALLdata.EM_AmpPhase, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
                nBeamsPerDatagram = ALLdata.EM_AmpPhase.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
                
                % assuming transmit sectors data are not split between several datagrams, get that data from the first datagram.
                nTransmitSectors = fData.AP_1P_NumberOfTransmitSectors(1,iP); % number of transmit sectors in this ping
                fData.AP_TP_TiltAngle(1:nTransmitSectors,iP)            = ALLdata.EM_AmpPhase.TiltAngle{iDatagrams(1)};
                fData.AP_TP_CenterFrequency(1:nTransmitSectors,iP)      = ALLdata.EM_AmpPhase.CenterFrequency{iDatagrams(1)};
                fData.AP_TP_TransmitSectorNumber(1:nTransmitSectors,iP) = ALLdata.EM_AmpPhase.TransmitSectorNumber{iDatagrams(1)};
                
                % initialize the water column data matrix for that ping.
                
                if file_amp_id(ig) >= 0 || file_phase_id(ig) >= 0
                    SB2_temp = zeros(maxNSamples_groups(ig),maxNBeams_sub,'int16')-intmin('int16');
                    Ph_temp = zeros(maxNSamples_groups(ig),maxNBeams_sub,'int16');
                end
                
                % and then read the data in each datagram
                for iD = 1:nDatagrams
                    
                    % index of beams in output structure for this datagram
                    [iBeams,idx_beams] = unique(ceil((sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD)))/db_sub));
                    % old approach
                    % iBeams = sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD));
                    % idx_beams = (1:numel(iBeams));
                    
                    % ping x beam data
                    fData.AP_BP_BeamPointingAngle(iBeams,iP)      = ALLdata.EM_AmpPhase.BeamPointingAngle{iDatagrams(iD)}(idx_beams)/100;
                    fData.AP_BP_StartRangeSampleNumber(iBeams,iP) = round(ALLdata.EM_AmpPhase.StartRangeSampleNumber{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.AP_BP_NumberOfSamples(iBeams,iP)        = round(ALLdata.EM_AmpPhase.NumberOfSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.AP_BP_DetectedRangeInSamples(iBeams,iP) = round(ALLdata.EM_AmpPhase.DetectedRangeInSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.AP_BP_TransmitSectorNumber(iBeams,iP)   = ALLdata.EM_AmpPhase.TransmitSectorNumber2{iDatagrams(iD)}(idx_beams);
                    fData.AP_BP_BeamNumber(iBeams,iP)             = ALLdata.EM_AmpPhase.BeamNumber{iDatagrams(iD)}(idx_beams);
                    
                    % now getting watercolumn data (beams x samples)
                    if file_amp_id(ig) >= 0 || file_phase_id(ig) >= 0
                        
                        for iB = 1:numel(iBeams)
                            
                            % actual number of samples in that beam
                            Ns = ALLdata.EM_AmpPhase.NumberOfSamples{iDatagrams(iD)}(idx_beams(iB));
                            
                            % number of samples we're going to record:
                            Ns_sub = ceil(Ns/dr_sub);
                            
                            % get the data:
                            if Ns_sub > 0
                                
                                fseek(fid_all,ALLdata.EM_AmpPhase.SamplePhaseAmplitudePosition{iDatagrams(iD)}(idx_beams(iB)),'bof');
                                tmp = fread(fid_all,Ns_sub,'uint16',2);
                                SB2_temp((1:(Ns_sub)),iBeams(iB)) = int16(20*log10(single(tmp)*0.0001)*200); % what is this transformation? XXX2
                                
                                fseek(fid_all,ALLdata.EM_AmpPhase.SamplePhaseAmplitudePosition{iDatagrams(iD)}(idx_beams(iB))+2,'bof');
                                tmp = fread(fid_all,Ns_sub,'int16',2);
                                Ph_temp((1:(Ns_sub)),iBeams(iB)) = int16(-0.0001*single(tmp)*30/pi*180); % what is this transformation? XXX2
                                
                            end
                        end
                    end
                end
                
                % store amp data on binary file
                if file_amp_id(ig) >= 0
                    fwrite(file_amp_id(ig),SB2_temp,'int16');
                end
                
                % store phase data on binary file
                if file_phase_id(ig)>=0
                    fwrite(file_phase_id(ig),Ph_temp,'int16');
                end
                if disp_wc
                    imagesc(ax_mag,single(SB2_temp)/200);
                    hold(ax_mag,'on');plot(ax_mag,fData.AP_BP_DetectedRangeInSamples(:,iP));
                    hold(ax_mag,'off');
                    caxis(ax_mag,[-100 -20]);
                    imagesc(ax_phase,single(Ph_temp)/30);
                    hold(ax_phase,'on');plot(ax_phase,fData.AP_BP_DetectedRangeInSamples(:,iP));
                    hold(ax_phase,'off');
                    drawnow;
                end
                
            end
            
            fData.AP_SBP_SampleAmplitudes=cell(1,numel(maxNSamples_groups));
            fData.AP_SBP_SamplePhase=cell(1,numel(maxNSamples_groups));
            
            fData.AP_n_start=ping_group_start;
            fData.AP_n_end=ping_group_end;
            fData.AP_n_maxNSamples=maxNSamples_groups;
            
            for ig=1:numel(maxNSamples_groups)
                % close binary data file
                if file_amp_id(ig) >= 0
                    fclose(file_amp_id(ig));
                end
                
                % close binary data file
                if file_phase_id(ig) >= 0
                    fclose(file_phase_id(ig));
                end
                
                % and link to them through memmapfile
                fData.AP_SBP_SampleAmplitudes{ig} = memmapfile(file_amp_binary{ig},'Format',{'int16' [maxNSamples_groups(ig) maxNBeams fData.AP_n_end(ig)-fData.AP_n_start(ig)+1] 'val'},'repeat',1,'writable',true);
                fData.AP_SBP_SamplePhase{ig}      = memmapfile(file_phase_binary{ig},'Format',{'int16' [maxNSamples_groups(ig) maxNBeams fData.AP_n_end(ig)-fData.AP_n_start(ig)+1] 'val'},'repeat',1,'writable',true);
            end
            % save info about data format for later access
            fData.AP_1_SampleAmplitudes_Class  = 'int16';
            fData.AP_1_SampleAmplitudes_Nanval = intmin('int16');
            fData.AP_1_SampleAmplitudes_Factor = 1/200;
            fData.AP_1_SamplePhase_Class  = 'int16';
            fData.AP_1_SamplePhase_Nanval = 200;
            fData.AP_1_SamplePhase_Factor = 1/30;
            
        end
        
    end
    
    % close the original raw file
    fclose(fid_all);
    fData.MET_Fmt_version=CFF_get_current_fData_version();
end
