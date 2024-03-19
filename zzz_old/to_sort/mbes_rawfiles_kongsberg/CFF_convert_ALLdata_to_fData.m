function [fData,update_flag] = CFF_convert_ALLdata_to_fData(ALLdataGroup,varargin)
% CFF_convert_ALLdata_to_fData.m
%
% Converts the Kongsberg EM series data files in ALLdata format (containing
% the KONGSBERG datagrams) to the fData format used in processing.
%
% *USE*
%
% fData = CFF_convert_ALLdata_to_fData(ALLdata) converts the contents of
% one ALLdata structure to a structure in the fData format.
%
% fData = CFF_convert_ALLdata_to_fData({ALLdata;WCDdata}) converts two
% ALLdata structures into one fData sructure. While many more structures
% can thus be loaded, this is typically done because ALLdata structures
% exist on a per-file basis and Kongsberg raw data often come in pairs of
% files: one .all and one .wcd. Note that the ALLdata structures are
% converted to fData in the order they are in input, and that the first
% ones take precedence, aka in the example above, if WCDdata contains a
% type of datagram that is already in ALLdata, they will NOT be converted.
% This is to avoid doubling up. Order the ALLdata structures in input in
% order of desired precedence. DO NOT use this feature to convert ALLdata
% structures from different acquisition files. It will not work. Convert
% each into its own fData structure.
%
% fData = CFF_convert_ALLdata_to_fData(ALLdata,10,2) operates the
% conversion with sub-sampling in range and in beams. For example, to
% sub-sample range by a factor of 10 and beams by a factor of 2, use fData
% = CFF_convert_ALLdata_to_fData(ALLdata,10,2).
%
% [fData,update_flag] = CFF_convert_ALLdata_to_fData(ALLdata,1,1,fData);
% takes the result of a precedent conversion in input to allow potentially
% saving time. The function will start by loading the result of the
% precedent conversion, check that what you're trying to add to it comes
% from the same raw data source, and add to fData only those types of
% datagrams that may be missing. If fData has been modified, it will return
% a update_flag=1. If the output is the same and no modification occured,
% then it will return a update_flag=0. NOTE: If the decimation factors in
% input are different to those used in the input fData, then the data
% WILL be updated. This is actually the main use of this feature...
%
% *INPUT VARIABLES*
%
% * |ALLdataGroup|: Required. ALLdata structure or cells of ALLdata
% structures. 
% * |dr_sub|: Optional. Scalar for decimation in range. Default: 1 (no
% decimation). 
% * |db_sub|: Optional. Scalar for decimation in beams. Default: 1 (no
% decimation). 
% * |fData|: Optional. Existing fData structure to add to. 
%
% *OUTPUT VARIABLES*
%
% * |fData|: structure for the storage of kongsberg EM series multibeam
% data in a format more convenient for processing. The data is recorded as
% fields coded "a_b_c" where "a" is a code indicating data origing, "b" is
% a code indicating data dimensions, and "c" is the data name.
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
% * |update_flag|: 1 if a fData was given in input and was modified with
% this function
%
% *DEVELOPMENT NOTES*
%
% * only water column data can be subsampled, all other datagrams are
% converted in full. To be consistent, develop code to subsample all
% datagrams as desired in parameters. Add a subsampling in pings while
% you're at it.
% * Have not tested the loading of data from 'EM_Depth' and
% 'EM_SeabedImage' in the new format version (v2). Might need debugging.
% * Since v2, a few major changes including change in order of dimensions.
% * Based on CFF_convert_mat_to_fabc_v2
%
% *NEW FEATURES*
%
% * 2018-10-11: updated header before adding to Coffee v3
% * 2018-10-09: started adding runtime params
% * 2017-10-04: complete re-ordering of dimensions, no backward
% * 2017-09-28: updated header to new format, and updated contents, in
% preparation for revamping to handle large water-column data
% * 2014-04-28: Fixed watercolumn data parsing for when some
% datagrams are missing. height datagram supported
% * ????-??-??: Added support for XYZ88, seabed image 89 and WC
% * ????-??-??: Splitted seabed image samples per beam. Still not sorted
% * ????-??-??: Made all types of datagram optional
% * ????-??-??: Improved comments and general code
% * ????-??-??: Changed data origin codes to two letters
% * ????-??-??: Recording ASCII parameters as well
% * ????-??-??: Reading sound speed profile
%
% % *EXAMPLE*
%
% ALLfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.all';
% MATfilename = '0001_20140213_052736_Yolla.mat';
% info = CFF_all_file_info(ALLfilename);
% info.parsed(:)=1; % to save all the datagrams
% ALLdata = CFF_read_all_from_fileinfo(ALLfilename, info);
% fData = CFF_convert_ALLdata_to_fData(ALLdata);
%
%   Copyright 2007-2018 Alexandre Schimel
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
    
    update_mode = 0;
    
    % initialize FABC structure by writing in the raw data filenames to be
    % added here
    fData.ALLfilename = cell(1,nStruct);
    for iF = 1:nStruct
        fData.ALLfilename{iF} = ALLdataGroup{iF}.ALLfilename;
    end
    
    % add the decimation factors given here in input
    fData.dr_sub = dr_sub;
    fData.db_sub = db_sub;
    
else
    
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
    % XXX clean up that display later
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
        if ~isfield(fData,'IP_ASCIIparameters')
            
            if update_mode
                update_flag = 1;
            end
            
            % initialize struct
            IP_ASCIIparameters = struct;
            
            % read ASCIIdata
            ASCIIdata = char(ALLdata.EM_InstallationStart.ASCIIData(1));
            
            % remove carriage returns, tabs and linefeed
            ASCIIdata = regexprep(ASCIIdata,char(9),'');
            ASCIIdata = regexprep(ASCIIdata,char(10),'');
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
        if ~isfield(fData,'Ru_1D_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            % NumberOfDatagrams  = length(ALLdata.EM_Runtime.TypeOfDatagram);
            % MaxNumberOfEntries = max(ALLdata.EM_Runtime.NumberOfEntries);
            
            fData.Ru_1D_Date                            = ALLdata.EM_Runtime.Date;
            fData.Ru_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Runtime.TimeSinceMidnightInMilliseconds;
            fData.Ru_1D_PingCounter                     = ALLdata.EM_Runtime.PingCounter;
            % the rest to code... XXX
            fData.Ru_1D_ReceiveBeamwidth                = ALLdata.EM_Runtime.ReceiveBeamwidth;
            % the rest to code... XXX
            
        end
        
    end

    
    %% EM_SoundSpeedProfile (v2 VERIFIED)
    
    if isfield(ALLdata,'EM_SoundSpeedProfile')
        
        % only convert these datagrams if this type doesn't already exist in output
        if ~isfield(fData,'SS_1D_Date')
            
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
        if ~isfield(fData,'At_1D_Date')
            
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
        if ~isfield(fData,'He_1D_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            % NumberOfDatagrams = length(ALLdata.EM_Height.TypeOfDatagram);
            
            fData.He_1D_Date                            = ALLdata.EM_Height.Date;
            fData.He_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Height.TimeSinceMidnightInMilliseconds;
            fData.He_1D_HeightCounter                   = ALLdata.EM_Height.HeightCounter;
            fData.He_1D_Height                          = ALLdata.EM_Height.Height;
            
        end
        
    end
    
    %% EM_Position (v2 verified)
    
    if isfield(ALLdata,'EM_Position')
        
        % only convert these datagrams if this type doesn't already exist in output
        if ~isfield(fData,'Po_1D_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            % NumberOfDatagrams = length(ALLdata.EM_Position.TypeOfDatagram);
            
            fData.Po_1D_Date                            = ALLdata.EM_Position.Date;
            fData.Po_1D_TimeSinceMidnightInMilliseconds = ALLdata.EM_Position.TimeSinceMidnightInMilliseconds;
            fData.Po_1D_PositionCounter                 = ALLdata.EM_Position.PositionCounter;
            fData.Po_1D_Latitude                        = ALLdata.EM_Position.Latitude;
            fData.Po_1D_Longitude                       = ALLdata.EM_Position.Longitude;
            fData.Po_1D_SpeedOfVesselOverGround         = ALLdata.EM_Position.SpeedOfVesselOverGround;
            fData.Po_1D_HeadingOfVessel                 = ALLdata.EM_Position.HeadingOfVessel;
            
        end
        
    end
    
    
    %% EM_Depth
    
    if isfield(ALLdata,'EM_Depth')
        
        % only convert these datagrams if this type doesn't already exist in output
        if ~isfield(fData,'De_1P_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            NumberOfPings    = length(ALLdata.EM_Depth.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(cellfun(@(x) max(x),ALLdata.EM_Depth.BeamNumber)); % maximum beam number in file
            
            fData.De_1P_Date                            = ALLdata.EM_Depth.Date;
            fData.De_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_Depth.TimeSinceMidnightInMilliseconds;
            fData.De_1P_PingCounter                     = ALLdata.EM_Depth.PingCounter;
            fData.De_1P_HeadingOfVessel                 = ALLdata.EM_Depth.HeadingOfVessel;
            fData.De_1P_SoundSpeedAtTransducer          = ALLdata.EM_Depth.SoundSpeedAtTransducer;
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
            fData.De_BP_BeamNumber              = nan(MaxNumberOfBeams,NumberOfPings);
            
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
                fData.De_BP_BeamNumber(BeamNumber,iP)              = cell2mat(ALLdata.EM_Depth.BeamNumber(iP));
            end
            
        end
        
    end
    
    
    %% EM_XYZ88
    
    if isfield(ALLdata,'EM_XYZ88')
        
        % only convert these datagrams if this type doesn't already exist in output
        if ~isfield(fData,'X8_1P_Date')
            
            if update_mode
                update_flag = 1;
            end
            
            NumberOfPings    = length(ALLdata.EM_XYZ88.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(ALLdata.EM_XYZ88.NumberOfBeamsInDatagram); % maximum beam number in file
            
            fData.X8_1P_Date                            = ALLdata.EM_XYZ88.Date;
            fData.X8_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_XYZ88.TimeSinceMidnightInMilliseconds;
            fData.X8_1P_PingCounter                     = ALLdata.EM_XYZ88.PingCounter;
            fData.X8_1P_HeadingOfVessel                 = ALLdata.EM_XYZ88.HeadingOfVessel;
            fData.X8_1P_SoundSpeedAtTransducer          = ALLdata.EM_XYZ88.SoundSpeedAtTransducer;
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
                
                fData.X8_BP_DepthZ(1:MaxNumberOfBeams,iP)                       = cell2mat(ALLdata.EM_XYZ88.DepthZ(iP));
                fData.X8_BP_AcrosstrackDistanceY(1:MaxNumberOfBeams,iP)         = cell2mat(ALLdata.EM_XYZ88.AcrosstrackDistanceY(iP));
                fData.X8_BP_AlongtrackDistanceX(1:MaxNumberOfBeams,iP)          = cell2mat(ALLdata.EM_XYZ88.AlongtrackDistanceX(iP));
                fData.X8_BP_DetectionWindowLength(1:MaxNumberOfBeams,iP)        = cell2mat(ALLdata.EM_XYZ88.DetectionWindowLength(iP));
                fData.X8_BP_QualityFactor(1:MaxNumberOfBeams,iP)                = cell2mat(ALLdata.EM_XYZ88.QualityFactor(iP));
                fData.X8_BP_BeamIncidenceAngleAdjustment(1:MaxNumberOfBeams,iP) = cell2mat(ALLdata.EM_XYZ88.BeamIncidenceAngleAdjustment(iP));
                fData.X8_BP_DetectionInformation(1:MaxNumberOfBeams,iP)         = cell2mat(ALLdata.EM_XYZ88.DetectionInformation(iP));
                fData.X8_BP_RealTimeCleaningInformation(1:MaxNumberOfBeams,iP)  = cell2mat(ALLdata.EM_XYZ88.RealTimeCleaningInformation(iP));
                fData.X8_BP_ReflectivityBS(1:MaxNumberOfBeams,iP)               = cell2mat(ALLdata.EM_XYZ88.ReflectivityBS(iP));
                
            end
            
        end
        
    end
    
    
    %% EM_SeabedImage
    
    if isfield(ALLdata,'EM_SeabedImage')
        
        % only convert these datagrams if this type doesn't already exist in output
        if ~isfield(fData,'SI_1P_Date')
            
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
        if ~isfield(fData,'S8_1P_Date')
            
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
                fData.S8_BP_DetectionInfo(BeamNumber,iP)          = cell2mat(ALLdata.EM_SeabedImage89.DetectionInfo(iP));
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
        if ~isfield(fData,'WC_1P_Date') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
            
            if update_mode
                update_flag = 1;
            end
            
            % get indices of first datagram for each ping
            [pingCounters,iFirstDatagram] = unique(ALLdata.EM_WaterColumn.PingCounter,'stable');
            
            % get data dimensions
            nPings              = length(pingCounters); % total number of pings in file
            maxNBeams           = max(ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams); % maximum number of beams for a ping in file
            maxNTransmitSectors = max(ALLdata.EM_WaterColumn.NumberOfTransmitSectors); % maximum number of transmit sectors for a ping in file
            maxNSamples         = max(cellfun(@(x) max(x),ALLdata.EM_WaterColumn.NumberOfSamples)); % max number of samples for a beam in file
            
            % decimating beams and samples
            maxNBeams_sub       = ceil(maxNBeams/db_sub); % number of beams to extract
            maxNSamples_sub     = ceil(maxNSamples/dr_sub); % number of samples to extract
            
            % read data per ping from first datagram of each ping
            fData.WC_1P_Date                            = ALLdata.EM_WaterColumn.Date(iFirstDatagram);
            fData.WC_1P_TimeSinceMidnightInMilliseconds = ALLdata.EM_WaterColumn.TimeSinceMidnightInMilliseconds(iFirstDatagram);
            fData.WC_1P_PingCounter                     = ALLdata.EM_WaterColumn.PingCounter(iFirstDatagram);
            fData.WC_1P_NumberOfDatagrams               = ALLdata.EM_WaterColumn.NumberOfDatagrams(iFirstDatagram);
            fData.WC_1P_NumberOfTransmitSectors         = ALLdata.EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram);
            fData.WC_1P_TotalNumberOfReceiveBeams       = ALLdata.EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram);
            fData.WC_1P_SoundSpeed                      = ALLdata.EM_WaterColumn.SoundSpeed(iFirstDatagram);
            fData.WC_1P_SamplingFrequencyHz             = (ALLdata.EM_WaterColumn.SamplingFrequency(iFirstDatagram).*0.01)./dr_sub; % in Hz
            fData.WC_1P_TXTimeHeave                     = ALLdata.EM_WaterColumn.TXTimeHeave(iFirstDatagram);
            fData.WC_1P_TVGFunctionApplied              = ALLdata.EM_WaterColumn.TVGFunctionApplied(iFirstDatagram);
            fData.WC_1P_TVGOffset                       = ALLdata.EM_WaterColumn.TVGOffset(iFirstDatagram);
            fData.WC_1P_ScanningInfo                    = ALLdata.EM_WaterColumn.ScanningInfo(iFirstDatagram);
            
            % initialize data per transmit sector and ping
            fData.WC_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
            fData.WC_TP_CenterFrequency      = nan(maxNTransmitSectors,nPings);
            fData.WC_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
            
            % initialize data per decimated beam and ping
            fData.WC_BP_BeamPointingAngle      = nan(maxNBeams_sub,nPings);
            fData.WC_BP_StartRangeSampleNumber = nan(maxNBeams_sub,nPings);
            fData.WC_BP_NumberOfSamples        = nan(maxNBeams_sub,nPings);
            fData.WC_BP_DetectedRangeInSamples = zeros(maxNBeams_sub,nPings);
            fData.WC_BP_TransmitSectorNumber   = nan(maxNBeams_sub,nPings);
            fData.WC_BP_BeamNumber             = nan(maxNBeams_sub,nPings);
            
            % path to binary file for WC data
            file_binary = fullfile(wc_dir,'WC_SBP_SampleAmplitudes.dat');
            
            % if file does not exist or we're re-sampling it, create a new
            % one ready for writing
            if ~exist(file_binary,'file') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
                fileID = fopen(file_binary,'w+');
            else
                % if we're here, it means the file already exists and
                % already contain the data at the proper sampling. So we
                % just need to store the metadata and link to it as
                % memmapfile.
                fileID = -1;
            end
            
            % now get data for each ping
            for iP = 1:nPings
                
                % find datagrams composing this ping
                pingCounter = fData.WC_1P_PingCounter(1,iP); % ping number (ex: 50455)
                % nDatagrams  = fData.WC_1P_NumberOfDatagrams(1,iP); % theoretical number of datagrams for this ping (ex: 7)
                iDatagrams  = find(ALLdata.EM_WaterColumn.PingCounter==pingCounter); % index of the datagrams making up this ping in ALLdata.EM_Watercolumn (ex: 58-59-61-64)
                nDatagrams  = length(iDatagrams); % actual number of datagrams available (ex: 4)
                
                % some datagrams may be missing, like in the example. Detect and adjust...
                datagramOrder     = ALLdata.EM_WaterColumn.DatagramNumbers(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
                [~,IX]            = sort(datagramOrder);
                iDatagrams        = iDatagrams(IX); % index of the datagrams making up this ping in ALLdata.EM_Watercolumn, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
                nBeamsPerDatagram = ALLdata.EM_WaterColumn.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
                
                % assuming transmit sectors data are not split between several datagrams, get that data from the first datagram.
                nTransmitSectors = fData.WC_1P_NumberOfTransmitSectors(1,iP); % number of transmit sectors in this ping
                fData.WC_TP_TiltAngle(1:nTransmitSectors,iP)            = ALLdata.EM_WaterColumn.TiltAngle{iDatagrams(1)};
                fData.WC_TP_CenterFrequency(1:nTransmitSectors,iP)      = ALLdata.EM_WaterColumn.CenterFrequency{iDatagrams(1)};
                fData.WC_TP_TransmitSectorNumber(1:nTransmitSectors,iP) = ALLdata.EM_WaterColumn.TransmitSectorNumber{iDatagrams(1)};
                
                % initialize the water column data matrix for that ping.
                % original data are in "int8" format, the NaN equivalent
                % will be -128
                if fileID >= 0
                    SB_temp = zeros(maxNSamples_sub,maxNBeams_sub,'int8') - 128;
                end
                
                % and then read the data in each datagram
                for iD = 1:nDatagrams
                    
                    % index of beams in output structure for this datagram
                    [iBeams,idx_beams] = unique(ceil((sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD)))/db_sub));
                    % old approach:
                    % iBeams = sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD));
                    % idx_beams = (1:numel(iBeams));
                    
                    % ping x beam data
                    fData.WC_BP_BeamPointingAngle(iBeams,iP)      = ALLdata.EM_WaterColumn.BeamPointingAngle{iDatagrams(iD)}(idx_beams);
                    fData.WC_BP_StartRangeSampleNumber(iBeams,iP) = round(ALLdata.EM_WaterColumn.StartRangeSampleNumber{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.WC_BP_NumberOfSamples(iBeams,iP)        = round(ALLdata.EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.WC_BP_DetectedRangeInSamples(iBeams,iP) = round(ALLdata.EM_WaterColumn.DetectedRangeInSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.WC_BP_TransmitSectorNumber(iBeams,iP)   = ALLdata.EM_WaterColumn.TransmitSectorNumber2{iDatagrams(iD)}(idx_beams);
                    fData.WC_BP_BeamNumber(iBeams,iP)             = ALLdata.EM_WaterColumn.BeamNumber{iDatagrams(iD)}(idx_beams);
                    
                    % now getting watercolumn data (beams x samples)
                    if fileID >= 0
                        
                        for iB = 1:numel(iBeams)
                            
                            % actual number of samples in that beam
                            Ns = ALLdata.EM_WaterColumn.NumberOfSamples{iDatagrams(iD)}(idx_beams(iB));
                            
                            % number of samples we're going to record:
                            Ns_sub = ceil(Ns/dr_sub);
                            
                            % get the data:
                            fseek(fid_all,ALLdata.EM_WaterColumn.SampleAmplitudePosition{iDatagrams(iD)}(idx_beams(iB)),'bof');
                            SB_temp(1:Ns_sub,iBeams(iB)) = fread(fid_all,Ns_sub,'int8',dr_sub-1);
                            
                            % Note: the original method was to grab the
                            % data that had been recorded in the ALLdata
                            % structure, aka:
                            % SB_temp(1:Ns_sub,iBeams(iB)) = ALLdata.EM_WaterColumn.SampleAmplitude{iDatagrams(iD)}{idx_beams(iB)}(1:dr_sub:Ns_sub*dr_sub)';
                            
                        end
                        
                    end
                end
                
                % store data on binary file
                if fileID >= 0
                    fwrite(fileID,SB_temp,'int8');
                end
                
            end
            
            % close binary data file
            if fileID >= 0
                fclose(fileID);
            end
            
            % and link to it through memmapfile
            fData.WC_SBP_SampleAmplitudes = memmapfile(file_binary,'Format',{'int8' [maxNSamples_sub maxNBeams_sub nPings] 'val'},'repeat',1,'writable',true);
            
            % save info about data format for later access
            fData.WC_1_SampleAmplitudes_Class = 'int8';
            fData.WC_1_SampleAmplitudes_Nanval = -128;
            fData.WC_1_SampleAmplitudes_Factor = 1/2;
            
        end
    end
    
    
    %% EM_AmpPhase
    
    if isfield(ALLdata,'EM_AmpPhase')
        
        % only convert these datagrams if this type doesn't already exist in output
        if ~isfield(fData,'AP_1P_Date') || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
            
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
            fData.AP_1P_SoundSpeed                      = ALLdata.EM_AmpPhase.SoundSpeed(iFirstDatagram);
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
            
            % path to binary file for WC data
            file_amp_binary   = fullfile(wc_dir,'AP_SBP_SampleAmplitudes.dat');
            file_phase_binary = fullfile(wc_dir,'AP_SBP_SamplePhase.dat');
            
            % if file does not exist or we're re-sampling it, create a new
            % one ready for writing
            if exist(file_amp_binary,'file')==0 || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
                file_amp_id = fopen(file_amp_binary,'w+');
            else
                % if we're here, it means the file already exists and
                % already contain the data at the proper sampling. So we
                % just need to store the metadata and link to it as
                % memmapfile.
                file_amp_id = -1;
            end
            
            % repeat for phase file
            if exist(file_phase_binary,'file')==0 || fData.dr_sub~=dr_sub || fData.db_sub~=db_sub
                file_phase_id = fopen(file_phase_binary,'w+');
            else
                file_phase_id = -1;
            end
            
            % now get data for each ping
            for iP = 1:nPings
                
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
                if file_amp_id >= 0 || file_phase_id >= 0
                    SB2_temp = zeros(maxNSamples_sub,maxNBeams_sub,'int16') - 2^15;
                    Ph_temp = zeros(maxNSamples_sub,maxNBeams_sub,'int16');
                end
                
                % and then read the data in each datagram
                for iD = 1:nDatagrams
                    
                    % index of beams in output structure for this datagram
                    [iBeams,idx_beams] = unique(ceil((sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD)))/db_sub));
                    % old approach
                    % iBeams = sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD));
                    % idx_beams = (1:numel(iBeams));
                    
                    % ping x beam data
                    fData.AP_BP_BeamPointingAngle(iBeams,iP)      = ALLdata.EM_AmpPhase.BeamPointingAngle{iDatagrams(iD)}(idx_beams);
                    fData.AP_BP_StartRangeSampleNumber(iBeams,iP) = round(ALLdata.EM_AmpPhase.StartRangeSampleNumber{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.AP_BP_NumberOfSamples(iBeams,iP)        = round(ALLdata.EM_AmpPhase.NumberOfSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.AP_BP_DetectedRangeInSamples(iBeams,iP) = round(ALLdata.EM_AmpPhase.DetectedRangeInSamples{iDatagrams(iD)}(idx_beams)./dr_sub);
                    fData.AP_BP_TransmitSectorNumber(iBeams,iP)   = ALLdata.EM_AmpPhase.TransmitSectorNumber2{iDatagrams(iD)}(idx_beams);
                    fData.AP_BP_BeamNumber(iBeams,iP)             = ALLdata.EM_AmpPhase.BeamNumber{iDatagrams(iD)}(idx_beams);
                    
                    % now getting watercolumn data (beams x samples)
                    if file_amp_id >= 0 || file_phase_id >= 0
                        
                        for iB = 1:numel(iBeams)
                            
                            % actual number of samples in that beam
                            Ns = ALLdata.EM_AmpPhase.NumberOfSamples{iDatagrams(iD)}(idx_beams(iB));
                            
                            % number of samples we're going to record:
                            Ns_sub = ceil(Ns/dr_sub);
                            
                            % get the data:
                            if Ns_sub > 0
                                
                                fseek(fid_all,ALLdata.EM_AmpPhase.SamplePhaseAmplitudePosition{iDatagrams(iD)}(idx_beams(iB)),'bof');
                                tmp = fread(fid_all,Ns_sub,'uint16',2);
                                SB2_temp(1:Ns_sub,iBeams(iB)) = int16(20*log10(single(tmp)*0.0001)*40); % what is this transformation? XXX
                                
                                fseek(fid_all,ALLdata.EM_AmpPhase.SamplePhaseAmplitudePosition{iDatagrams(iD)}(idx_beams(iB))+1,'bof');
                                tmp = fread(fid_all,Ns_sub,'int16',2);
                                Ph_temp(1:Ns_sub,iBeams(iB)) = -0.0001*single(tmp)*30/pi*180; % what is this transformation? XXX
                                
                            end
                        end
                    end
                end
                
                % store amp data on binary file
                if file_amp_id >= 0
                    fwrite(file_amp_id,SB2_temp,'int16');
                end
                
                % store phase data on binary file
                if file_phase_id>=0
                    fwrite(file_phase_id,Ph_temp,'int16');
                end
                
            end
            
            % close binary data file
            if file_amp_id >= 0
                fclose(file_amp_id);
            end
            
            % close binary data file
            if file_phase_id >= 0
                fclose(file_phase_id);
            end
            
            % and link to them through memmapfile
            fData.AP_SBP_SampleAmplitudes = memmapfile(file_amp_binary,'Format',{'int16' [maxNSamples_sub maxNBeams_sub nPings] 'val'},'repeat',1,'writable',true);
            fData.AP_SBP_SamplePhase      = memmapfile(file_phase_binary,'Format',{'int16' [maxNSamples_sub maxNBeams_sub nPings] 'val'},'repeat',1,'writable',true);
            
            % save info about data format for later access
            fData.AP_1_SampleAmplitudes_Class  = 'int16';
            fData.AP_1_SampleAmplitudes_Nanval = int16(-inf);
            fData.AP_1_SampleAmplitudes_Factor = 1/40;
            fData.AP_1_SamplePhase_Class  = 'int16';
            fData.AP_1_SamplePhase_Nanval = 0;
            fData.AP_1_SamplePhase_Factor = 1/30;
            
        end
        
    end
    
    % close the original raw file
    fclose(fid_all);
    
end
