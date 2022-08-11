%% CFF_convert_mat_to_fabc.m
%
% Converts the Kongsberg EM series data files in MAT format (containing the
% KONGSBERG datagrams) to the FABC format for use in processing.
%
%% Help
% 
% *USE*
%
% ...
%
% *INPUT VARIABLES*
%
% * |MATfilename|: MAT file to convert either as a string of a single file,
% or cell of strings for several files to parse together.
%
% *OUTPUT VARIABLES*
%
% * |FABCdata|: structure for the storage of data in a format easier
% to use than the EM datagrams. The structure is arranged as f.a_b_c,
% where:
%     * f: 'FABCdata'
%     * a: code indicating data origin:
%         * IP: installation parameters
%         * De: depth datagram
%         * He: height datagram
%         * X8: XYZ88 datagram
%         * SI: seabed image datagram
%         * S8: seabed image data 89
%         * WC: watercolumn data
%         * Po: position datagram
%         * At: attitude datagram
%         * SS: sound speed profile datagram
%     More codes for the 'a' part will be created if more datagrams are
%     parsed. As further codes work with the data contained in FABC
%     structure, these derived data can be recorded back into the FABC,
%     with the 'a' code set to 'X'.
%     * b: code indicating data dimensions (rows/columns)
%         * P1: ping-like single-column-vector
%         * 1B: beam-like single-row-vecor
%         * PB: ping/beam array
%         * PT: ping/transmit sector array
%         * PS: ping/samples array (note: samples are not sorted, this is
%         not equivalent to range!) 
%         * D1: datagram-like single-column-vector (for attitude or
%         position data) 
%         * DE: datagram/entries-per-datagram array (for attitude or
%         position data) 
%         * PBS: ping/beam/sample array (water-column data)
%     More codes for the 'b' part will be created if the storage of other
%     datagrams needs them. As subsequent functions work with the data
%     contained in FABC structure to generate derived data, these derived
%     data can be recorded with other dimensions types. They are not listed
%     fully here but they may include:
%         * RP: range (choose distance, time or sample) / ping
%         * SP: swathe (meters) / ping
%         * LL: lat long (WGS84)
%         * EN: easting northing
%     * c: data type, obtained from the original variable name in the
%     Kongsberg datagram, or from the user's imagination for derived data
%     obtained from subsequent functions. 
%
% *RESEARCH NOTES*
%
% * FOR NOW, PARSING DIFFERENT FILES DO NOT APPEND DATA TO EXISTING
% FIELDS. ONLY NEW DATAGRAMS ARE COPIED. So if file 1 has Depth datagrams,
% and file 2 has depth and watercolumn datagrams, the function will save
% all datagrams in file 1 first (aka, Depth), and then IGNORE THE DEPTH
% DATAGRAMS IN THE SECOND FILE, only recording the water-column one. This
% is because I could not be bothered having to test for redundant dagrams
% in both files. In theory, this code is to use on a single file only, with
% the option to load several files being only used to load data from a .raw
% file and its corresponding .wcd file.
%
% *NEW FEATURES*
%
% * 2017-09-28: updated header to new format, and updated contents, in
% preparation for revamping to handle large water-column data (Alex
% Schimel).
% * 2014-04-28: v1.1.1. fixed watercolumn data parsing for when some
% datagrams are missing. height datagram supported (Alex Schimel).
% - v1.1:
%   - added support for XYZ88, seabed image 89 and WC
%   - splitted seabed image samples per beam. Still not sorted
% - v1.0:
%   - NA
% - v0.4.2:
%   - made all types of datagram optional
% - v0.4:
%   - improved comments and general code
%   - changed data origin codes to two letters
%   - recording ASCII parameters as well
% - v0.3.1:
%   - reading sound speed profile
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel,Deakin University, NIWA

%% Function
function [FABCdata] = CFF_convert_mat_to_fabc(MATfilename)

% turn MATfilename to cell if string
if ischar(MATfilename)
    MATfilename = {MATfilename};
end

% write MATfilename to FABC
FABCdata.MET_MATfilename = MATfilename;
nFiles = length(MATfilename);

% loop through all files and aggregate the datagrams contents
for iF = 1:nFiles
    
    % clear previous datagrams
    clear -regexp EM\w*
    
    % OPENING MAT FILE
    file = MATfilename{iF};
    load(file)
    
    % EM_Attitude
    if exist('EM_Attitude')
        
        if ~isfield(FABCdata, 'At_D1_Date')
            
            NumberOfDatagrams = length(EM_Attitude.TypeOfDatagram);
            MaxNumberOfEntries = max(EM_Attitude.NumberOfEntries);
            
            FABCdata.At_D1_Date = EM_Attitude.Date';
            FABCdata.At_D1_TimeSinceMidnightInMilliseconds = EM_Attitude.TimeSinceMidnightInMilliseconds';
            FABCdata.At_D1_AttitudeCounter = EM_Attitude.AttitudeCounter';
            FABCdata.At_D1_NumberOfEntries = EM_Attitude.NumberOfEntries';
            
            FABCdata.At_DE_TimeInMillisecondsSinceRecordStart = nan(NumberOfDatagrams, MaxNumberOfEntries);
            FABCdata.At_DE_SensorStatus = nan(NumberOfDatagrams, MaxNumberOfEntries);
            FABCdata.At_DE_Roll = nan(NumberOfDatagrams, MaxNumberOfEntries);
            FABCdata.At_DE_Pitch = nan(NumberOfDatagrams, MaxNumberOfEntries);
            FABCdata.At_DE_Heave = nan(NumberOfDatagrams, MaxNumberOfEntries);
            FABCdata.At_DE_Heading = nan(NumberOfDatagrams, MaxNumberOfEntries);
            
            for iD=1:NumberOfDatagrams
                
                NumberOfEntries = EM_Attitude.NumberOfEntries(iD);
                
                FABCdata.At_DE_TimeInMillisecondsSinceRecordStart(iD,1:NumberOfEntries) = cell2mat(EM_Attitude.TimeInMillisecondsSinceRecordStart(iD));
                FABCdata.At_DE_SensorStatus(iD,1:NumberOfEntries) = cell2mat(EM_Attitude.SensorStatus(iD));
                FABCdata.At_DE_Roll(iD,1:NumberOfEntries) = cell2mat(EM_Attitude.Roll(iD));
                FABCdata.At_DE_Pitch(iD,1:NumberOfEntries) = cell2mat(EM_Attitude.Pitch(iD));
                FABCdata.At_DE_Heave(iD,1:NumberOfEntries) = cell2mat(EM_Attitude.Heave(iD));
                FABCdata.At_DE_Heading(iD,1:NumberOfEntries) = cell2mat(EM_Attitude.Heading(iD));
                
            end
            
        end
        
    end
    
    % EM_Depth
    if exist('EM_Depth')
        
        if ~isfield(FABCdata, 'De_P1_Date')
            
            NumberOfPings = length(EM_Depth.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(cellfun(@(x) max(x),EM_Depth.BeamNumber)); % maximum beam number in file
            
            FABCdata.De_P1_Date = EM_Depth.Date';
            FABCdata.De_P1_TimeSinceMidnightInMilliseconds = EM_Depth.TimeSinceMidnightInMilliseconds';
            FABCdata.De_P1_PingCounter = EM_Depth.PingCounter';
            FABCdata.De_P1_HeadingOfVessel = EM_Depth.HeadingOfVessel';
            FABCdata.De_P1_SoundSpeedAtTransducer = EM_Depth.SoundSpeedAtTransducer';
            FABCdata.De_P1_TransmitTransducerDepth = EM_Depth.TransmitTransducerDepth' + 65536.*EM_Depth.TransducerDepthOffsetMultiplier';
            FABCdata.De_P1_MaximumNumberOfBeamsPossible = EM_Depth.MaximumNumberOfBeamsPossible';
            FABCdata.De_P1_NumberOfValidBeams = EM_Depth.NumberOfValidBeams';
            FABCdata.De_P1_ZResolution = EM_Depth.ZResolution';
            FABCdata.De_P1_XAndYResolution = EM_Depth.XAndYResolution';
            FABCdata.De_P1_SamplingRate = EM_Depth.SamplingRate';
            
            % initialize
            FABCdata.De_PB_DepthZ = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_PB_AcrosstrackDistanceY = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_PB_AlongtrackDistanceX = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_PB_BeamDepressionAngle = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_PB_BeamAzimuthAngle = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_PB_Range = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_PB_QualityFactor = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_PB_LengthOfDetectionWindow = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_PB_ReflectivityBS = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.De_1B_BeamNumber = 1:MaxNumberOfBeams;
            
            for iP = 1:NumberOfPings
                
                BeamNumber = cell2mat(EM_Depth.BeamNumber(iP));
                
                FABCdata.De_PB_DepthZ(iP,BeamNumber) = cell2mat(EM_Depth.DepthZ(iP));
                FABCdata.De_PB_AcrosstrackDistanceY(iP,BeamNumber) = cell2mat(EM_Depth.AcrosstrackDistanceY(iP));
                FABCdata.De_PB_AlongtrackDistanceX(iP,BeamNumber) = cell2mat(EM_Depth.AlongtrackDistanceX(iP));
                FABCdata.De_PB_BeamDepressionAngle(iP,BeamNumber) = cell2mat(EM_Depth.BeamDepressionAngle(iP));
                FABCdata.De_PB_BeamAzimuthAngle(iP,BeamNumber) = cell2mat(EM_Depth.BeamAzimuthAngle(iP));
                FABCdata.De_PB_Range(iP,BeamNumber) = cell2mat(EM_Depth.Range(iP));
                FABCdata.De_PB_QualityFactor(iP,BeamNumber) = cell2mat(EM_Depth.QualityFactor(iP));
                FABCdata.De_PB_LengthOfDetectionWindow(iP,BeamNumber) = cell2mat(EM_Depth.LengthOfDetectionWindow(iP));
                FABCdata.De_PB_ReflectivityBS(iP,BeamNumber) = cell2mat(EM_Depth.ReflectivityBS(iP));
                
            end
            
        end
        
    end
    
    % EM_Height
    if exist('EM_Height')
        
        if ~isfield(FABCdata, 'He_P1_Date')
            
            NumberOfDatagrams = length(EM_Height.TypeOfDatagram);
            
            FABCdata.He_D1_Date = EM_Height.Date';
            FABCdata.He_D1_TimeSinceMidnightInMilliseconds = EM_Height.TimeSinceMidnightInMilliseconds';
            FABCdata.He_D1_HeightCounter = EM_Height.HeightCounter';
            FABCdata.He_D1_Height = EM_Height.Height';
            
        end
        
    end
    
    % EM_InstallationStart
    if exist('EM_InstallationStart')
        
        if ~isfield(FABCdata, 'IP_ASCIIparameters')
            
            ASCIIdata = char(EM_InstallationStart.ASCIIData(1));
            % remove carriage returns, tabs and linefeed
            ASCIIdata = regexprep(ASCIIdata,char(9),'');
            ASCIIdata = regexprep(ASCIIdata,char(10),'');
            ASCIIdata = regexprep(ASCIIdata,char(13),'');
            
            if ~isempty(ASCIIdata)
                
                yo = strfind(ASCIIdata,',')';
                yo(:,1) = [1; yo(1:end-1)+1];        % beginning of ASCII field name
                yo(:,2) = strfind(ASCIIdata,'=')'-1; % end of ASCII field name
                yo(:,3) = strfind(ASCIIdata,'=')'+1; % beginning of ASCII field value
                yo(:,4) = strfind(ASCIIdata,',')'-1; % end of ASCII field value
                
                for ii = 1:size(yo,1)
                    if ii==10
                        ii;
                    end
                    if size(str2num(ASCIIdata(yo(ii,3):yo(ii,4)))) == [1,1]
                        % if value seems to be a unique number
                        eval(['FABCdata.IP_ASCIIparameters.' ASCIIdata(yo(ii,1):yo(ii,2)) ' = ' ASCIIdata(yo(ii,3):yo(ii,4)) ';']);
                    else
                        eval(['FABCdata.IP_ASCIIparameters.' ASCIIdata(yo(ii,1):yo(ii,2)) ' = ''' ASCIIdata(yo(ii,3):yo(ii,4)) ''';']);
                    end
                end
                
            else
                
                FABCdata.IP_ASCIIparameters = [];
                
            end
            
        end
        
    end
    
    % EM_Position
    if exist('EM_Position')
        
        if ~isfield(FABCdata, 'Po_D1_Date')
            
            NumberOfDatagrams = length(EM_Position.TypeOfDatagram);
            
            FABCdata.Po_D1_Date = EM_Position.Date';
            FABCdata.Po_D1_TimeSinceMidnightInMilliseconds = EM_Position.TimeSinceMidnightInMilliseconds';
            FABCdata.Po_D1_PositionCounter = EM_Position.PositionCounter';
            FABCdata.Po_D1_Latitude = EM_Position.Latitude';
            FABCdata.Po_D1_Longitude = EM_Position.Longitude';
            FABCdata.Po_D1_SpeedOfVesselOverGround = EM_Position.SpeedOfVesselOverGround';
            FABCdata.Po_D1_HeadingOfVessel = EM_Position.HeadingOfVessel';
            
        end
        
    end
    
    % EM_SeabedImage
    if exist('EM_SeabedImage')
        
        if ~isfield(FABCdata, 'SI_P1_Date')
            
            NumberOfPings = length(EM_SeabedImage.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(cellfun(@(x) max(x),EM_SeabedImage.BeamIndexNumber))+1; % maximum beam number (beam index number +1), in file
            MaxNumberOfSamples = max(cellfun(@(x) max(x),EM_SeabedImage.NumberOfSamplesPerBeam));
            
            FABCdata.SI_P1_Date = EM_SeabedImage.Date';
            FABCdata.SI_P1_TimeSinceMidnightInMilliseconds = EM_SeabedImage.TimeSinceMidnightInMilliseconds';
            FABCdata.SI_P1_PingCounter = EM_SeabedImage.PingCounter';
            FABCdata.SI_P1_MeanAbsorptionCoefficient = EM_SeabedImage.MeanAbsorptionCoefficient';
            FABCdata.SI_P1_PulseLength = EM_SeabedImage.PulseLength';
            FABCdata.SI_P1_RangeToNormalIncidence = EM_SeabedImage.RangeToNormalIncidence';
            FABCdata.SI_P1_StartRangeSampleOfTVGRamp = EM_SeabedImage.StartRangeSampleOfTVGRamp';
            FABCdata.SI_P1_StopRangeSampleOfTVGRamp = EM_SeabedImage.StopRangeSampleOfTVGRamp';
            FABCdata.SI_P1_NormalIncidenceBS = EM_SeabedImage.NormalIncidenceBS';
            FABCdata.SI_P1_ObliqueBS = EM_SeabedImage.ObliqueBS';
            FABCdata.SI_P1_TxBeamwidth = EM_SeabedImage.TxBeamwidth';
            FABCdata.SI_P1_TVGLawCrossoverAngle = EM_SeabedImage.TVGLawCrossoverAngle';
            FABCdata.SI_P1_NumberOfValidBeams = EM_SeabedImage.NumberOfValidBeams';
            
            % initialize
            FABCdata.SI_PB_SortingDirection = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.SI_PB_NumberOfSamplesPerBeam = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.SI_PB_CentreSampleNumber = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.SI_1B_BeamNumber = 1:MaxNumberOfBeams;
            FABCdata.SI_PBS_SampleAmplitudes = cell(NumberOfPings,1);
            
            for iP = 1:NumberOfPings
                
                % Get data from datagram
                BeamNumber = cell2mat(EM_SeabedImage.BeamIndexNumber(iP))+1;
                NumberOfSamplesPerBeam = cell2mat(EM_SeabedImage.NumberOfSamplesPerBeam(iP));
                Samples = cell2mat(EM_SeabedImage.SampleAmplitudes(iP).beam(:));
                
                % from number of samples per beam, get indices of first and last
                % sample for each beam in the Samples data vector
                iFirst =  [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
                iLast = iFirst+NumberOfSamplesPerBeam-1;
                
                % store
                FABCdata.SI_PB_SortingDirection(iP,BeamNumber) = cell2mat(EM_SeabedImage.SortingDirection(iP));
                FABCdata.SI_PB_NumberOfSamplesPerBeam(iP,BeamNumber) = NumberOfSamplesPerBeam;
                FABCdata.SI_PB_CentreSampleNumber(iP,BeamNumber) = cell2mat(EM_SeabedImage.CentreSampleNumber(iP));
                
                % initialize the beams/sample array (use zero instead of NaN to
                % allow turning it to sparse
                temp = zeros(length(BeamNumber),MaxNumberOfSamples);
                
                % fill in
                for iB = 1:length(BeamNumber)
                    temp(BeamNumber(iB),1:NumberOfSamplesPerBeam(iB)) = Samples(iFirst(iB):iLast(iB));
                end
                
                % and save the sparse version
                FABCdata.SI_PBS_SampleAmplitudes{iP} = sparse(temp);
                
            end
            
        end
        
    end
    
    % EM_SeabedImage89
    if exist('EM_SeabedImage89')
        
        if ~isfield(FABCdata, 'S8_P1_Date')
            
            NumberOfPings = length(EM_SeabedImage89.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(EM_SeabedImage89.NumberOfValidBeams);
            MaxNumberOfSamples = max(cellfun(@(x) max(x),EM_SeabedImage89.NumberOfSamplesPerBeam));
            
            FABCdata.S8_P1_Date = EM_SeabedImage89.Date';
            FABCdata.S8_P1_TimeSinceMidnightInMilliseconds = EM_SeabedImage89.TimeSinceMidnightInMilliseconds';
            FABCdata.S8_P1_PingCounter = EM_SeabedImage89.PingCounter';
            FABCdata.S8_P1_SamplingFrequencyInHz = EM_SeabedImage89.SamplingFrequencyInHz';
            FABCdata.S8_P1_RangeToNormalIncidence = EM_SeabedImage89.RangeToNormalIncidence';
            FABCdata.S8_P1_NormalIncidenceBS = EM_SeabedImage89.NormalIncidenceBS';
            FABCdata.S8_P1_ObliqueBS = EM_SeabedImage89.ObliqueBS';
            FABCdata.S8_P1_TxBeamwidthAlong = EM_SeabedImage89.TxBeamwidthAlong';
            FABCdata.S8_P1_TVGLawCrossoverAngle = EM_SeabedImage89.TVGLawCrossoverAngle';
            FABCdata.S8_P1_NumberOfValidBeams = EM_SeabedImage89.NumberOfValidBeams';
            
            % initialize
            FABCdata.S8_PB_SortingDirection = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.S8_PB_DetectionInfo = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.S8_PB_NumberOfSamplesPerBeam = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.S8_PB_CentreSampleNumber = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.S8_1B_BeamNumber = 1:MaxNumberOfBeams;
            FABCdata.S8_PBS_SampleAmplitudes = cell(NumberOfPings,1);
            
            % in this more recent datagram, all beams are in. No beamnumber anymore
            BeamNumber = FABCdata.S8_1B_BeamNumber;
            
            for iP = 1:NumberOfPings
                
                % Get data from datagram
                NumberOfSamplesPerBeam = cell2mat(EM_SeabedImage89.NumberOfSamplesPerBeam(iP));
                Samples = cell2mat(EM_SeabedImage89.SampleAmplitudes(iP).beam(:));
                
                % from number of samples per beam, get indices of first and last
                % sample for each beam in the Samples data vector
                iFirst =  [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
                iLast = iFirst+NumberOfSamplesPerBeam-1;
                
                % store
                FABCdata.S8_PB_SortingDirection(iP,BeamNumber) = cell2mat(EM_SeabedImage89.SortingDirection(iP));
                FABCdata.S8_PB_NumberOfSamplesPerBeam(iP,BeamNumber) = NumberOfSamplesPerBeam;
                FABCdata.S8_PB_CentreSampleNumber(iP,BeamNumber) = cell2mat(EM_SeabedImage89.CentreSampleNumber(iP));
                
                % initialize the beams/sample array (use zero instead of NaN to
                % allow turning it to sparse
                temp = zeros(length(BeamNumber),MaxNumberOfSamples);
                
                % and fill in
                for iB = 1:length(BeamNumber)
                    temp(BeamNumber(iB),1:NumberOfSamplesPerBeam(iB)) = Samples(iFirst(iB):iLast(iB));
                end
                
                % and save the sparse version
                FABCdata.S8_PBS_SampleAmplitudes{iP} = sparse(temp);
                
            end
            
        end
        
    end
    
    % EM_SoundSpeedProfile
    if exist('EM_SoundSpeedProfile')
        
        if ~isfield(FABCdata, 'SS_D1_Date')
            
            NumberOfDatagrams = length(EM_SoundSpeedProfile.TypeOfDatagram);
            MaxNumberOfEntries = max(EM_SoundSpeedProfile.NumberOfEntries);
            
            FABCdata.SS_D1_Date = EM_SoundSpeedProfile.Date';
            FABCdata.SS_D1_TimeSinceMidnightInMilliseconds = EM_SoundSpeedProfile.TimeSinceMidnightInMilliseconds';
            FABCdata.SS_D1_ProfileCounter = EM_SoundSpeedProfile.ProfileCounter';
            FABCdata.SS_D1_DateWhenProfileWasMade = EM_SoundSpeedProfile.DateWhenProfileWasMade';
            FABCdata.SS_D1_TimeSinceMidnightInMillisecondsWhenProfileWasMade = EM_SoundSpeedProfile.TimeSinceMidnightInMillisecondsWhenProfileWasMade';
            FABCdata.SS_D1_NumberOfEntries = EM_SoundSpeedProfile.NumberOfEntries';
            FABCdata.SS_D1_DepthResolution = EM_SoundSpeedProfile.DepthResolution';
            
            FABCdata.SS_DE_Depth = nan(NumberOfDatagrams, MaxNumberOfEntries);
            FABCdata.SS_DE_SoundSpeed = nan(NumberOfDatagrams, MaxNumberOfEntries);
            
            for iD=1:NumberOfDatagrams
                
                NumberOfEntries = EM_SoundSpeedProfile.NumberOfEntries(iD);
                FABCdata.SS_DE_Depth(iD,1:NumberOfEntries) = cell2mat(EM_SoundSpeedProfile.Depth(iD));
                FABCdata.SS_DE_SoundSpeed(iD,1:NumberOfEntries) = cell2mat(EM_SoundSpeedProfile.SoundSpeed(iD));
                
            end
            
        end
        
    end
    
    % EM_WaterColumn
    if exist('EM_WaterColumn')
        
        if ~isfield(FABCdata, 'WC_P1_Date')
            
            % get indices of first datagram for each ping
            [pingCounters,iFirstDatagram] = unique(EM_WaterColumn.PingCounter);
            
            nPings = length(pingCounters); % total number of pings in file
            maxNBeams = max(EM_WaterColumn.TotalNumberOfReceiveBeams); % maximum number of beams for a ping in file
            maxNTransmitSectors = max(EM_WaterColumn.NumberOfTransmitSectors); % maximum number of transmit sectors for a ping in file
            maxNSamples = max(cellfun(@(x) max(x),EM_WaterColumn.NumberOfSamples)); % max number of samples for a beam in file
            
            FABCdata.WC_P1_Date = EM_WaterColumn.Date(iFirstDatagram)';
            FABCdata.WC_P1_TimeSinceMidnightInMilliseconds = EM_WaterColumn.TimeSinceMidnightInMilliseconds(iFirstDatagram)';
            FABCdata.WC_P1_PingCounter = EM_WaterColumn.PingCounter(iFirstDatagram)';
            FABCdata.WC_P1_NumberOfDatagrams = EM_WaterColumn.NumberOfDatagrams(iFirstDatagram)';
            FABCdata.WC_P1_NumberOfTransmitSectors = EM_WaterColumn.NumberOfTransmitSectors(iFirstDatagram)';
            FABCdata.WC_P1_TotalNumberOfReceiveBeams = EM_WaterColumn.TotalNumberOfReceiveBeams(iFirstDatagram)';
            FABCdata.WC_P1_SoundSpeed = EM_WaterColumn.SoundSpeed(iFirstDatagram)';
            FABCdata.WC_P1_SamplingFrequency = EM_WaterColumn.SamplingFrequency(iFirstDatagram)';
            FABCdata.WC_P1_TXTimeHeave = EM_WaterColumn.TXTimeHeave(iFirstDatagram)';
            FABCdata.WC_P1_TVGFunctionApplied = EM_WaterColumn.TVGFunctionApplied(iFirstDatagram)';
            FABCdata.WC_P1_TVGOffset = EM_WaterColumn.TVGOffset(iFirstDatagram)';
            FABCdata.WC_P1_ScanningInfo = EM_WaterColumn.ScanningInfo(iFirstDatagram)';
            
            % initialize data per transmit sector:
            FABCdata.WC_PT_TiltAngle = nan(nPings,maxNTransmitSectors);
            FABCdata.WC_PT_CenterFrequency = nan(nPings,maxNTransmitSectors);
            FABCdata.WC_PT_TransmitSectorNumber = nan(nPings,maxNTransmitSectors);
            
            % initialize data per beam
            FABCdata.WC_PB_BeamPointingAngle = nan(nPings,maxNBeams);
            FABCdata.WC_PB_StartRangeSampleNumber = nan(nPings,maxNBeams);
            FABCdata.WC_PB_NumberOfSamples = nan(nPings,maxNBeams);
            FABCdata.WC_PB_DetectedRangeInSamples = zeros(nPings,maxNBeams);
            FABCdata.WC_PB_TransmitSectorNumber = nan(nPings,maxNBeams);
            FABCdata.WC_PB_BeamNumber = nan(nPings,maxNBeams);
            
            % initialize samples
            FABCdata.WC_PBS_SampleAmplitudes = nan(nPings,maxNBeams,maxNSamples); % as full?
            % FABCdata.WC_PBS_SampleAmplitudes = cell(nPings,1); % or as sparse?
            
            for iP = 1:nPings
                
                % find datagrams composing this ping
                pingCounter = FABCdata.WC_P1_PingCounter(iP); % ping number (ex: 50455)
                nDatagrams  = FABCdata.WC_P1_NumberOfDatagrams(iP); % theoretical number of datagrams for this ping (ex: 7)
                iDatagrams = find(EM_WaterColumn.PingCounter==pingCounter); % index of the datagrams making up this ping in EM_Watercolumn (ex: 58-59-61-64)
                nDatagrams = length(iDatagrams); % actual number of datagrams available (ex: 4)
                
                % some datagrams may be missing, like in the example. Detect and adjust...
                datagramOrder = EM_WaterColumn.DatagramNumbers(iDatagrams); % order of the datagrams (ex: 4-3-6-2, the missing one is 1st, 5th and 7th)
                [B,IX] = sort(datagramOrder);
                iDatagrams = iDatagrams(IX); % index of the datagrams making up this ping in EM_Watercolumn, but in the right order (ex: 64-59-58-61, missing datagrams are still missing)
                nBeamsPerDatagram = EM_WaterColumn.NumberOfBeamsInThisDatagram(iDatagrams); % number of beams in each datagram making up this ping (ex: 56-61-53-28)
                
                % assuming transmit sectors data are not split between several
                % datagrams, get that data from the first datagram.
                nTransmitSectors = FABCdata.WC_P1_NumberOfTransmitSectors(iP); % number of transmit sectors in this ping
                FABCdata.WC_PT_TiltAngle(iP,1:nTransmitSectors) = EM_WaterColumn.TiltAngle{iDatagrams(1)};
                FABCdata.WC_PT_CenterFrequency(iP,1:nTransmitSectors) = EM_WaterColumn.CenterFrequency{iDatagrams(1)};
                FABCdata.WC_PT_TransmitSectorNumber(iP,1:nTransmitSectors) = EM_WaterColumn.TransmitSectorNumber{iDatagrams(1)};
                
                BS_temp = nan(maxNBeams,maxNSamples); % store as full matrices. To use sparse, BS_temp = zero(maxNBeams,maxNSamples);
                for iD = 1:nDatagrams
                    
                    % index of beams in output structure for this datagram
                    iBeams = sum(nBeamsPerDatagram(1:iD-1)) + (1:nBeamsPerDatagram(iD));
                    
                    % ping x beam data
                    FABCdata.WC_PB_BeamPointingAngle(iP,iBeams) = EM_WaterColumn.BeamPointingAngle{iDatagrams(iD)};
                    FABCdata.WC_PB_StartRangeSampleNumber(iP,iBeams) = EM_WaterColumn.StartRangeSampleNumber{iDatagrams(iD)};
                    FABCdata.WC_PB_NumberOfSamples(iP,iBeams) = EM_WaterColumn.NumberOfSamples{iDatagrams(iD)};
                    FABCdata.WC_PB_DetectedRangeInSamples(iP,iBeams) = EM_WaterColumn.DetectedRangeInSamples{iDatagrams(iD)};
                    FABCdata.WC_PB_TransmitSectorNumber(iP,iBeams) = EM_WaterColumn.TransmitSectorNumber2{iDatagrams(iD)};
                    % formerly
                    % FABCdata.WC_PB_TransmitSectorNumber(iP,iBeams) =
                    % EM_WaterColumn.TransmitSectorNumber{iDatagrams(iD)};
                    % (without the two, but was crashing for NIWA data.
                    % Makes more sense with the 2.
                    FABCdata.WC_PB_BeamNumber(iP,iBeams) = EM_WaterColumn.BeamNumber{iDatagrams(iD)};
                    
                    % ping x samples data
                    for iB = 1:nBeamsPerDatagram(iD)
                        Ns = FABCdata.WC_PB_NumberOfSamples(iP,iBeams(iB));
                        BS_temp(iBeams(iB),1:Ns) = EM_WaterColumn.SampleAmplitude{iDatagrams(iD)}{iB}';
                    end
                    
                end
                
                FABCdata.WC_PBS_SampleAmplitudes(iP,:,:) = BS_temp; % store as full matrices. To use sparse, FABCdata.WC_PBS_SampleAmplitudes{iP} = sparse(BS_temp);
                
            end
            
        end
        
    end
    
    % EM_XYZ88
    if exist('EM_XYZ88')
        
        if ~isfield(FABCdata, 'X8_P1_Date')
            
            NumberOfPings = length(EM_XYZ88.TypeOfDatagram); % total number of pings in file
            MaxNumberOfBeams = max(EM_XYZ88.NumberOfBeamsInDatagram); % maximum beam number in file
            
            FABCdata.X8_P1_Date = EM_XYZ88.Date';
            FABCdata.X8_P1_TimeSinceMidnightInMilliseconds = EM_XYZ88.TimeSinceMidnightInMilliseconds';
            FABCdata.X8_P1_PingCounter = EM_XYZ88.PingCounter';
            FABCdata.X8_P1_HeadingOfVessel = EM_XYZ88.HeadingOfVessel';
            FABCdata.X8_P1_SoundSpeedAtTransducer = EM_XYZ88.SoundSpeedAtTransducer';
            FABCdata.X8_P1_TransmitTransducerDepth = EM_XYZ88.TransmitTransducerDepth';
            FABCdata.X8_P1_NumberOfBeamsInDatagram = EM_XYZ88.NumberOfBeamsInDatagram';
            FABCdata.X8_P1_NumberOfValidDetections = EM_XYZ88.NumberOfValidDetections';
            FABCdata.X8_P1_SamplingFrequencyInHz = EM_XYZ88.SamplingFrequencyInHz';
            
            % initialize
            FABCdata.X8_PB_DepthZ = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_PB_AcrosstrackDistanceY = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_PB_AlongtrackDistanceX = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_PB_DetectionWindowLength = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_PB_QualityFactor = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_PB_BeamIncidenceAngleAdjustment = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_PB_DetectionInformation = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_PB_RealTimeCleaningInformation = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_PB_ReflectivityBS = nan(NumberOfPings,MaxNumberOfBeams);
            FABCdata.X8_1B_BeamNumber = 1:MaxNumberOfBeams;
            
            for iP = 1:NumberOfPings
                
                FABCdata.X8_PB_DepthZ(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.DepthZ(iP));
                FABCdata.X8_PB_AcrosstrackDistanceY(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.AcrosstrackDistanceY(iP));
                FABCdata.X8_PB_AlongtrackDistanceX(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.AlongtrackDistanceX(iP));
                FABCdata.X8_PB_DetectionWindowLength(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.DetectionWindowLength(iP));
                FABCdata.X8_PB_QualityFactor(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.QualityFactor(iP));
                FABCdata.X8_PB_BeamIncidenceAngleAdjustment(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.BeamIncidenceAngleAdjustment(iP));
                FABCdata.X8_PB_DetectionInformation(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.DetectionInformation(iP));
                FABCdata.X8_PB_RealTimeCleaningInformation(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.RealTimeCleaningInformation(iP));
                FABCdata.X8_PB_ReflectivityBS(iP,1:MaxNumberOfBeams) = cell2mat(EM_XYZ88.ReflectivityBS(iP));
                
            end
            
        end
        
    end
    
    % other types of datagrams not supported yet.
    
end


% OLD CODE TO POSITION SEABED IMAGE SAMPLES RELATIVE TO BOTTOM DETECTION
% SAMPLES
% % if seabed image datagrams:
% if exist('EM_SeabedImage')
%
%     NumberOfPings = length(EM_SeabedImage.TypeOfDatagram); % total number of pings in file
%     NumberOfBeams = max(cellfun(@(x) max(x),EM_SeabedImage.BeamIndexNumber))+1; % maximum beam number (beam index number +1), in file
%
%     FABCdata.SI_P1_Date = EM_SeabedImage.Date';
%     FABCdata.SI_P1_TimeSinceMidnightInMilliseconds = EM_SeabedImage.TimeSinceMidnightInMilliseconds';
%     FABCdata.SI_P1_PingCounter = EM_SeabedImage.PingCounter';
%     FABCdata.SI_P1_MeanAbsorptionCoefficient = EM_SeabedImage.MeanAbsorptionCoefficient';
%     FABCdata.SI_P1_PulseLength = EM_SeabedImage.PulseLength';
%     FABCdata.SI_P1_RangeToNormalIncidence = EM_SeabedImage.RangeToNormalIncidence';
%     FABCdata.SI_P1_StartRangeSampleOfTVGRamp = EM_SeabedImage.StartRangeSampleOfTVGRamp';
%     FABCdata.SI_P1_StopRangeSampleOfTVGRamp = EM_SeabedImage.StopRangeSampleOfTVGRamp';
%     FABCdata.SI_P1_NormalIncidenceBS = EM_SeabedImage.NormalIncidenceBS';
%     FABCdata.SI_P1_ObliqueBS = EM_SeabedImage.ObliqueBS';
%     FABCdata.SI_P1_TxBeamwidth = EM_SeabedImage.TxBeamwidth';
%     FABCdata.SI_P1_TVGLawCrossoverAngle = EM_SeabedImage.TVGLawCrossoverAngle';
%     FABCdata.SI_P1_NumberOfValidBeams = EM_SeabedImage.NumberOfValidBeams';
%
%     % initialize
%     FABCdata.SI_PB_SortingDirection = nan(NumberOfPings,NumberOfBeams);
%     FABCdata.SI_PB_NumberOfSamplesPerBeam = nan(NumberOfPings,NumberOfBeams);
%     FABCdata.SI_PB_CentreSampleNumber = nan(NumberOfPings,NumberOfBeams);
%     FABCdata.SI_1B_BeamNumber = 1:NumberOfBeams;
%     FABCdata.SI_PBS_SampleAmplitudes = cell(NumberOfPings,1);
%
%     for iP = 1:NumberOfPings
%
%         % Get data from datagram
%         BeamNumber = cell2mat(EM_SeabedImage.BeamIndexNumber(iP))+1;
%         SortingDirection = cell2mat(EM_SeabedImage.SortingDirection(iP));
%         NumberOfSamplesPerBeam = cell2mat(EM_SeabedImage.NumberOfSamplesPerBeam(iP));
%         CentreSampleNumber = cell2mat(EM_SeabedImage.CentreSampleNumber(iP));
%         Samples = cell2mat(EM_SeabedImage.SampleAmplitudes(iP).beam(:));
%
%         % Get bottom sample number from Depth datagram
%         % depth datagram says "OWTT = range / sampling rate / 4"
%         % since OWTT = bottomsample# / (2 * sampling rate), then bottomsample# = "range"/2
%         % problem, this means bottom sample number as a 0.5 resolution
%         % (???)
%         BottomSample = ceil( FABCdata.De_PB_Range(iP,BeamNumber)' ./ 2 );
%
%         % from BottomSample and CentreSampleNumber, deduce numbers of first
%         % and last of recorded samples.
%         firstSampleNumber = 1 - CentreSampleNumber + BottomSample;
%         lastSampleNumber  = NumberOfSamplesPerBeam - CentreSampleNumber + BottomSample;
%
%         % min, max and total sample range for this ping.
%         minSampleNumber = min(firstSampleNumber);
%         maxSampleNumber = max(lastSampleNumber);
%         NumberOfSamples = maxSampleNumber-minSampleNumber+1;
%
%         % from number of samples per beam, get indices of first and last
%         % sample for each beam in the Samples data vector
%         iFirst =  [1;cumsum(NumberOfSamplesPerBeam(1:end-1))+1];
%         iLast = iFirst+NumberOfSamplesPerBeam-1;
%
%         % initialize the beams/sample array (use zero instead of NaN to
%         % allow turning it to sparse
%         temp = zeros(length(BeamNumber),NumberOfSamples);
%
%         % and fill in
%         for iB = 1:length(BeamNumber)
%             temp(iB,firstSampleNumber(iB)-minSampleNumber+1:lastSampleNumber(iB)-minSampleNumber+1) = Samples(iFirst(iB):iLast(iB));
%         end
%
%         % store
%         FABCdata.SI_PB_SortingDirection(iP,BeamNumber) = SortingDirection;
%         FABCdata.SI_PB_NumberOfSamplesPerBeam(iP,BeamNumber) = NumberOfSamplesPerBeam;
%         FABCdata.SI_PB_CentreSampleNumber(iP,BeamNumber) = CentreSampleNumber;
%
%         % store additional stuff:
%         FABCdata.SI_PB_BottomSample(iP,BeamNumber) = BottomSample; % from Depth datagram, see above for calculation
%         FABCdata.SI_PB_firstSampleNumber(iP,BeamNumber) = firstSampleNumber; % firstSampleNumber = 1 - CentreSampleNumber + BottomSample;
%         FABCdata.SI_PB_lastSampleNumber(iP,BeamNumber) = lastSampleNumber; % lastSampleNumber  = NumberOfSamplesPerBeam - CentreSampleNumber + BottomSample;
%
%         % and the data:
%         FABCdata.SI_PBS_SampleAmplitudes{iP} = sparse(temp);
%
%     end
%
% end
