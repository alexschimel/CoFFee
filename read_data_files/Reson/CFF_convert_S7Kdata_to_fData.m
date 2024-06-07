function fData = CFF_convert_S7Kdata_to_fData(S7Kdata,varargin)
%CFF_CONVERT_S7KDATA_TO_FDATA  Convert s7k data to the CoFFee format
%
%   Converts Multibeam data FROM the S7Kdata format (e.g. Teledyne, Norbit)
%   TO the CoFFee fData format used in processing.
%
%   IMPORTANT NOTE: THE FDATA FORMAT WAS NOT DESIGNED TO BE A GENERIC
%   FORMAT BUT A MATLAB VERSION OF THE KONGSBERG *.ALL FORMAT. AS A RESULT,
%   CONVERSION FROM S7K TO FDATA IS NOT OPTIMAL AND REQUIRES SOME TWEAKS.
%   ALSO, WE ONLY POPULATE THE FDATA FIELDS THAT ARE ABSOLUTELY NECESSARY
%   FOR WATER-COLUMN DISPLAY. YOU MIGHT EXPERIENCE ISSUES TRYING TO DO
%   ANYTHING ELSE WITH THAT FDATA. CHECK CFF_CONVERT_ALLDATA_TO_FDATA TO
%   GET AN IDEA OF WHAT ALL THOSE FIELDS ACTUALLY ARE.
%
%   FDATA = CFF_CONVERT_S7KDATA_TO_FDATA(S7KDATA) converts the contents of
%   the S7KDATA structure to a structure in the fData format.
%
%   FDATA = CFF_CONVERT_S7KDATA_TO_FDATA(S7KDATA,DR_SUB,DB_SUB) operates
%   the conversion with a sub-sampling of the water-column data in range
%   and in beams. For example, to sub-sample range by a factor of 10 and
%   beams by a factor of 2, use:
%   FDATA = CFF_CONVERT_S7KDATA_TO_FDATA(S7KDATA,10,2).
%
%   See also CFF_CONVERT_RAW_FILES, CFF_READ_S7K,
%   CFF_CONVERT_ALLDATA_TO_FDATA 

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% Input arguments management
p = inputParser;

% array of S7Kdata structures
addRequired(p,'S7Kdata',@(x) isstruct(x) || iscell(x));

% decimation factor in range and beam
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,S7Kdata,varargin{:})

% and get results
S7Kdata = p.Results.S7Kdata;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p;

if iscell(S7Kdata)
    S7Kdata = S7Kdata{1};
end

% check it's from Teledyne-Reson and that source file exist
has_S7Kfilename = isfield(S7Kdata, 'S7Kfilename');
if ~has_S7Kfilename || ~CFF_check_S7Kfilename(S7Kdata.S7Kfilename)
    error('Invalid input');
end


%% Prep

% start message
comms.start('Converting to fData format');

% initialize fData, with current version number
fData.MET_Fmt_version = CFF_get_current_fData_version();

% add source filename
S7Kfilename = S7Kdata.S7Kfilename;
fData.ALLfilename{1} = S7Kfilename;

% start progress
comms.progress(0,6);

% now populating fields where we can


%% Settings

comms.step('Converting Settings'); 

% sonar heading offset in degrees
% to check where we can find it... In the meantime, leave it at zero
fData.IP_ASCIIparameters.S1H = 0;

if isfield(S7Kdata,'R7000_SonarSettings')
    fData.Ru_1D_Date                            = S7Kdata.R7000_SonarSettings.Date;
    fData.Ru_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R7000_SonarSettings.TimeSinceMidnightInMilliseconds;
    fData.Ru_1D_PingCounter                     = S7Kdata.R7000_SonarSettings.PingNumber;
    fData.Ru_1D_TransmitPowerReMaximum          = pow2db(S7Kdata.R7000_SonarSettings.PowerSelection);
    fData.Ru_1D_ReceiveBeamwidth                = S7Kdata.R7000_SonarSettings.ReceiveBeamWidthRad/pi*180;
end

comms.progress(1,6);

%% Navigation

comms.step('Converting Navigation data'); 

if isfield(S7Kdata,'R1015_Navigation')
    fData.Po_1D_Date                            = S7Kdata.R1015_Navigation.Date;
    fData.Po_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1015_Navigation.TimeSinceMidnightInMilliseconds;
    fData.Po_1D_PositionCounter                 = 1:numel(S7Kdata.R1015_Navigation.Date);    % dummy values
    fData.Po_1D_Latitude                        = S7Kdata.R1015_Navigation.Latitude/pi*180; % now in deg
    fData.Po_1D_Longitude                       = S7Kdata.R1015_Navigation.Longitude/pi*180; % now in deg
    fData.Po_1D_SpeedOfVesselOverGround         = S7Kdata.R1015_Navigation.SpeedOverGround;
    fData.Po_1D_HeadingOfVessel                 = S7Kdata.R1015_Navigation.Heading/pi*180; % now in deg
    fData.Po_1D_MeasureOfPositionFixQuality     = ones(size(S7Kdata.R1003_Position.Date)); % dummy values
    fData.Po_1D_PositionSystemDescriptor        = ones(size(S7Kdata.R1015_Navigation.Date)); % dummy values
elseif isfield(S7Kdata,'R1003_Position')
    fData.Po_1D_Date                            = S7Kdata.R1003_Position.Date;
    fData.Po_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1003_Position.TimeSinceMidnightInMilliseconds;
    fData.Po_1D_PositionCounter                 = 1:numel(S7Kdata.R1003_Position.Date);    % dummy values
    fData.Po_1D_MeasureOfPositionFixQuality     = ones(size(S7Kdata.R1003_Position.Date)); % dummy values
    fData.Po_1D_PositionSystemDescriptor        = S7Kdata.R1003_Position.PositioningMethod;
    
    if  S7Kdata.R1003_Position.PositionTypeFlag(1) == 0
        % geographic coordinates (lat/long) in rad
        fData.Po_1D_Latitude  = S7Kdata.R1003_Position.LatitudeOrNorthing/pi*180; % now in deg
        fData.Po_1D_Longitude = S7Kdata.R1003_Position.LongitudeOrEasting/pi*180; % now in deg
        
        % calculating speed of vessel and heading based on lat/long
        nb_pt = numel(fData.Po_1D_Latitude);
        [dist_in_deg,head] = distance([fData.Po_1D_Latitude(1:nb_pt-1)' fData.Po_1D_Longitude(1:nb_pt-1)'],[fData.Po_1D_Latitude(2:nb_pt)' fData.Po_1D_Longitude(2:nb_pt)']);
        d_dist = deg2km(dist_in_deg');
        t = datenum(cellfun(@num2str,num2cell(fData.Po_1D_Date),'un',0),'yyyymmdd')'*24*60*60+fData.Po_1D_TimeSinceMidnightInMilliseconds/1e3;
        s = d_dist*1000./diff(t);
        fData.Po_1D_SpeedOfVesselOverGround = [s(1) s];
        fData.Po_1D_HeadingOfVessel         = [head(1) head'];
        
    else
        % grid coordinates (easting/northing) in meters
        % Code here conversion back to geographic coordinates if we
        % ever come across this case.
    end
end

comms.progress(2,6);


%% Height

comms.step('Converting Height data'); 

if isfield(S7Kdata,'R1015_Navigation')
    fData.He_1D_Date                            = S7Kdata.R1015_Navigation.Date;
    fData.He_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1015_Navigation.TimeSinceMidnightInMilliseconds;
    fData.He_1D_HeightCounter                   = 1:numel(S7Kdata.R1015_Navigation.Date);
    fData.He_1D_Height                          = S7Kdata.R1015_Navigation.VesselHeight;
elseif isfield(S7Kdata,'R1003_Position')
    fData.He_1D_Date                            = S7Kdata.R1003_Position.Date;
    fData.He_1D_TimeSinceMidnightInMilliseconds = S7Kdata.R1003_Position.TimeSinceMidnightInMilliseconds;
    fData.He_1D_HeightCounter                   = 1:numel(S7Kdata.R1003_Position.Date);
    fData.He_1D_Height                          = S7Kdata.R1003_Position.Height;
end

comms.progress(3,6);


%% seafloor data (bathy, BS) fields

comms.step('Converting Seafloor data (bathy, BS)'); 

if isfield(S7Kdata,'R7027_RawDetectionData')
    
    % number of pings
    nPings = numel(S7Kdata.R7027_RawDetectionData.PingNumber);
    
    % number of beams
    % +1 because beam numbers in this field start at 0
    maxnBeams = nanmax(cellfun(@nanmax,S7Kdata.R7027_RawDetectionData.BeamDescriptor)) + 1;
    
    % date and time
    fData.X8_1P_Date                            = S7Kdata.R7027_RawDetectionData.Date;
    fData.X8_1P_TimeSinceMidnightInMilliseconds = S7Kdata.R7027_RawDetectionData.TimeSinceMidnightInMilliseconds;
    
    % record data per ping
    fData.X8_1P_PingCounter              = S7Kdata.R7027_RawDetectionData.PingNumber;
    fData.X8_1P_HeadingOfVessel          = NaN; % unused anyway
    fData.X8_1P_SoundSpeedAtTransducer   = NaN; % unused anyway
    fData.X8_1P_TransmitTransducerDepth  = NaN; % unused anyway
    fData.X8_1P_NumberOfBeamsInDatagram  = NaN; % unused anyway
    fData.X8_1P_NumberOfValidDetections  = NaN; % unused anyway
    fData.X8_1P_SamplingFrequencyInHz    = NaN; % unused anyway
    
    % initialize data per beam and ping
    fData.X8_BP_DepthZ                       = nan(maxnBeams,nPings);
    fData.X8_BP_AcrosstrackDistanceY         = nan(maxnBeams,nPings);
    fData.X8_BP_AlongtrackDistanceX          = NaN; % unused anyway
    fData.X8_BP_DetectionWindowLength        = NaN; % unused anyway
    fData.X8_BP_QualityFactor                = NaN; % unused anyway
    fData.X8_BP_BeamIncidenceAngleAdjustment = NaN; % unused anyway
    fData.X8_BP_DetectionInformation         = NaN; % unused anyway
    fData.X8_BP_RealTimeCleaningInformation  = NaN; % unused anyway
    fData.X8_BP_ReflectivityBS               = nan(maxnBeams,nPings);
    fData.X8_B1_BeamNumber                   = (1:maxnBeams)';
    
    % record data per beam and ping
    for iP = 1:nPings
        iBeam = S7Kdata.R7027_RawDetectionData.BeamDescriptor{iP}+1; % +1 because beam numbers in this field start at 0
        fData.X8_BP_DepthZ(iBeam,iP)               = S7Kdata.R7027_RawDetectionData.Depth{iP};
        fData.X8_BP_AcrosstrackDistanceY(iBeam,iP) = S7Kdata.R7027_RawDetectionData.AcrossTrackDistance{iP};
        fData.X8_BP_ReflectivityBS(iBeam,iP)       = S7Kdata.R7027_RawDetectionData.Intensity{iP};
    end
    
    % transform intensity to dB
    % DEV NOTE: no idea where Yoann got this formula
    fData.X8_BP_ReflectivityBS = 20*log10(fData.X8_BP_ReflectivityBS/65535);
    
    % debug graph
    debugDisp = 0;
    if debugDisp
        f = figure();
        ax_z = axes(f,'outerposition',[0 0.66 1 0.3]);
        imagesc(ax_z, -fData.X8_BP_DepthZ);
        colorbar(ax_z); grid on; title(ax_z, 'bathy'); colormap(ax_z,'jet');
        ax_y = axes(f,'outerposition',[0 0.33 1 0.3]);
        imagesc(ax_y, fData.X8_BP_AcrosstrackDistanceY);
        colorbar(ax_y); grid on; title(ax_y, 'across-track distance');
        ax_bs = axes(f,'outerposition',[0 0 1 0.3]);
        imagesc(ax_bs, fData.X8_BP_ReflectivityBS);
        caxis(ax_bs, [prctile(fData.X8_BP_ReflectivityBS(:),5), prctile(fData.X8_BP_ReflectivityBS(:),95)]);
        colorbar(ax_bs); grid on; title(ax_bs, 'BS (scaled 5-95th percentile)'); colormap(ax_bs,'gray');
        drawnow;
    end
    
end

comms.progress(4,6);


%% water-column data (amplitude, phase) from 7018 records

comms.step('Converting Water-column data (amplitude, phase)'); 

if all(isfield(S7Kdata,{'R7018_BeamformedData','R7000_SonarSettings','R7004_BeamGeometry', 'R7027_RawDetectionData'}))
    
    % I came across one file where not all pings are recorded, also with
    % different records having different pings. Since we here combine data
    % from different records, we first need to limit the recording to pings
    % that are present in all records. To make it more complicated,
    % R7004_BeamGeometry does not have a pingNumber field.
    R7018pings = S7Kdata.R7018_BeamformedData.PingNumber;
    R7000pings = S7Kdata.R7000_SonarSettings.PingNumber;
    R7027pings = S7Kdata.R7027_RawDetectionData.PingNumber;
    pingNumber = intersect(R7018pings,intersect(R7000pings,R7027pings));
    [~,ipR7018] = ismember(pingNumber,R7018pings);
    [~,ipR7000] = ismember(pingNumber,R7000pings);
    [~,ipR7027] = ismember(pingNumber,R7027pings);
    
    % for R7004_BeamGeometry, we will have to assume its contents are the
    % same as one of the other record types
    if numel(S7Kdata.R7004_BeamGeometry.SonarID) == numel(R7000pings)
        ipR7004 = ipR7000;
    elseif numel(S7Kdata.R7004_BeamGeometry.SonarID) == numel(R7027pings)
        ipR7004 = ipR7027;
    elseif numel(S7Kdata.R7004_BeamGeometry.SonarID) == numel(R7018pings)
        ipR7004 = ipR7018;
    else
        error('cannot proceed...')
    end
    
    % number of pings
    nPings = numel(pingNumber);
    
    % number of beams
    dtg_nBeams = S7Kdata.R7018_BeamformedData.N(ipR7018); % number of beams per ping
    maxnBeams = nanmax(dtg_nBeams); % max number of beams in file
    maxnBeams_sub = ceil(maxnBeams/db_sub); % maximum number of beams TO READ per ping
        
    % number of samples
    dtg_nSamples = S7Kdata.R7018_BeamformedData.S(ipR7018); % number of samples per ping
    [maxnSamples_groups,ping_group_start,ping_group_end] = CFF_group_pings(dtg_nSamples, pingNumber); % making groups of pings to limit size of memmaped files
    maxnSamples_groups = ceil(maxnSamples_groups/dr_sub); % maximum number of samples TO READ, per group.
    
    % add the WCD decimation factors given here in input
    fData.dr_sub = dr_sub;
    fData.db_sub = db_sub;
   
    % data per ping
    fData.AP_1P_Date                            = S7Kdata.R7018_BeamformedData.Date(ipR7018);
    fData.AP_1P_TimeSinceMidnightInMilliseconds = S7Kdata.R7018_BeamformedData.TimeSinceMidnightInMilliseconds(ipR7018);
    fData.AP_1P_PingCounter                     = pingNumber;
    fData.AP_1P_NumberOfDatagrams               = NaN; % unused anyway
    fData.AP_1P_NumberOfTransmitSectors         = NaN; % unused anyway
    fData.AP_1P_TotalNumberOfReceiveBeams       = NaN; % unused anyway
    fData.AP_1P_SoundSpeed                      = S7Kdata.R7000_SonarSettings.SoundVelocity(ipR7000);
    fData.AP_1P_SamplingFrequencyHz             = S7Kdata.R7000_SonarSettings.SampleRate(ipR7000); % in Hz
    fData.AP_1P_TXTimeHeave                     = NaN; % unused anyway
    fData.AP_1P_TVGFunctionApplied              = nan(size(pingNumber)); % dummy values. to find XXX1
    fData.AP_1P_TVGOffset                       = zeros(size(pingNumber)); % dummy values. to find XXX1
    fData.AP_1P_ScanningInfo                    = NaN; % unused anyway
    
    % initialize data per transmit sector and ping
    fData.AP_TP_TiltAngle            = NaN; % unused anyway
    fData.AP_TP_CenterFrequency      = NaN; % unused anyway
    fData.AP_TP_TransmitSectorNumber = NaN; % unused anyway
    
    % initialize data per (decimated) beam and ping
    fData.AP_BP_BeamPointingAngle      = nan(maxnBeams_sub,nPings);
    fData.AP_BP_StartRangeSampleNumber = nan(maxnBeams_sub,nPings);
    fData.AP_BP_NumberOfSamples        = nan(maxnBeams_sub,nPings);
    fData.AP_BP_DetectedRangeInSamples = zeros(maxnBeams_sub,nPings);
    fData.AP_BP_TransmitSectorNumber   = NaN; % unused anyway
    fData.AP_BP_BeamNumber             = NaN; % unused anyway
    fData.AP_BP_SystemSerialNumber     = NaN; % unused anyway
    
    % The actual water-column data will not be saved in fData but in binary
    % files. Get the output directory to store those files
    wc_dir = CFF_converted_data_folder(S7Kfilename);
    
    % Clean up that folder first before adding anything to it
    CFF_clean_delete_fdata(wc_dir);
    
    % DEV NOTE: Info format for raw WC data and storage
    % In these raw datagrams, there are both amplitude and phase.
    %
    % Amplitude samples are in uint16. I don't have doc describing more
    % than that but looking at Yoann code, they appear to be in natural
    % values, scaled by intmax('uint16'). NaN value is likely
    % intmin('uint16'). We need to convert those to dB so we can't reuse 
    % that format. Here we will store the data as int16 with a factor of
    % 1/200.
    %
    % Phase samples are in radians, format int16, scaled by 10430, in order
    % to fit between -pi and pi. We're going to store them as they are, in
    % int16, but adjusting the factor so they are in degrees.
    
    % initialize data-holding binary files
    fData = CFF_init_memmapfiles(fData, ...
        'field', 'AP_SBP_SampleAmplitudes', ...
        'wc_dir', wc_dir, ...
        'Class', 'int16', ...
        'Factor', 1/200, ...
        'Nanval', intmin('int16'), ...
        'Offset', 0, ...
        'MaxSamples', maxnSamples_groups, ...
        'MaxBeams', maxnBeams_sub, ...
        'ping_group_start', ping_group_start, ...
        'ping_group_end', ping_group_end);
    
    fData = CFF_init_memmapfiles(fData, ...
        'field', 'AP_SBP_SamplePhase', ...
        'wc_dir', wc_dir, ...
        'Class', 'int16', ...
        'Factor', (180/pi)/10430, ...
        'Nanval', 200, ...
        'Offset', 0, ...
        'MaxSamples', maxnSamples_groups, ...
        'MaxBeams', maxnBeams_sub, ...
        'ping_group_start', ping_group_start, ...
        'ping_group_end', ping_group_end);
    
    % Also the samples data were not recorded, only their location in the
    % source file, so we need to fopen the source file to grab the data.
    fid = fopen(S7Kfilename,'r','l');
    
    % debug graph
    debugDisp = 0;
    if debugDisp
        f = figure();
        ax_mag = axes(f,'outerposition',[0 0.5 1 0.5]);
        title('WCD amplitude');
        ax_phase = axes(f,'outerposition',[0 0 1 0.5]);
        title('WCD phase');
    end
    
    % initialize ping group number
    iG = 1;
    
    % now get data for each ping
    for iP = 1:nPings
        
        % ping group number is the index of the memmaped file in which that
        % swath's data will be saved.
        if iP > ping_group_end(iG)
            iG = iG+1;
        end
        
        % data per beam
        nBeamsInR7004 = S7Kdata.R7004_BeamGeometry.N(ipR7004(iP));
        fData.AP_BP_BeamPointingAngle(1:nBeamsInR7004,iP)       = rad2deg(S7Kdata.R7004_BeamGeometry.BeamHorizontalDirectionAngleRad{ipR7004(iP)});
        fData.AP_BP_StartRangeSampleNumber(1:dtg_nBeams(iP),iP) = zeros(dtg_nBeams(iP),1);
        fData.AP_BP_NumberOfSamples(1:dtg_nBeams(iP),iP)        = dtg_nSamples(iP).*ones(dtg_nBeams(iP),1);
        beamsInR7027 = S7Kdata.R7027_RawDetectionData.BeamDescriptor{ipR7027(iP)}+1;
        fData.AP_BP_DetectedRangeInSamples(beamsInR7027,iP) = S7Kdata.R7027_RawDetectionData.DetectionPoint{ipR7027(iP)};
        
        % initialize the water column data matrix for that ping.
        pingMag = intmin('int16').*ones(maxnSamples_groups(iG),maxnBeams_sub,'int16');
        pingPh  = 200.*ones(maxnSamples_groups(iG),maxnBeams_sub,'int16');
        
        % read amplitude in original format and decode
        fseek(fid,S7Kdata.R7018_BeamformedData.BeamformedDataPos(ipR7018(iP)),'bof');
        Mag_tmp = (fread(fid,[dtg_nBeams(iP) dtg_nSamples(iP)],'uint16',2))';
        Mag_tmp(Mag_tmp==double(intmin('uint16'))) = NaN;
        Mag_tmp = 20*log10(Mag_tmp/double(intmax('uint16'))); % now in dB

        % re-encode Magnitude for storage
        Mag_tmp2 = int16(Mag_tmp*200);
        Mag_tmp2(isnan(Mag_tmp)) = intmin('int16');
        
        % read phase in original format
        fseek(fid,S7Kdata.R7018_BeamformedData.BeamformedDataPos(ipR7018(iP))+2,'bof');
        Ph_tmp = (fread(fid,[dtg_nBeams(iP) dtg_nSamples(iP)],'int16=>int16',2))';

        % debug graph
        if debugDisp
            % display amplitude
            imagesc(ax_mag,Mag_tmp);
            colorbar(ax_mag)
            title(ax_mag, sprintf('Ping %i/%i, WCD amplitude',iP,nPings));
            % display phase
            imagesc(ax_phase,double(Ph_tmp).*((180/pi)/10430));
            colorbar(ax_phase)
            title(ax_phase, 'WCD phase');
            drawnow;
        end
        
        % store Magnitude and Phase
        pingMag(1:size(Mag_tmp2,1),:) = Mag_tmp2;
        pingPh(1:size(Ph_tmp,1),:) = Ph_tmp;
        
        % Store the data in the appropriate binary file, at the appropriate
        % ping, through the memory mapping
        fData.AP_SBP_SampleAmplitudes{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = pingMag;
        fData.AP_SBP_SamplePhase{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = pingPh;

    end
    
    % close the original raw file
    fclose(fid);
    
end

comms.progress(5,6);


%% water-column data (amplitude, phase) from 7042 records

comms.step('Converting Water-column data (amplitude, phase)'); 

if all(isfield(S7Kdata,{'R7042_CompressedWaterColumnData','R7000_SonarSettings','R7004_BeamGeometry','R7027_RawDetectionData'}))
        
    % I came across one file where not all pings are recorded, also with
    % different records having different pings. Since we here combine data
    % from different records, we first need to limit the recording to pings
    % that are present in all records. To make it more complicated,
    % R7004_BeamGeometry does not have a pingNumber field.
    R7042pings = S7Kdata.R7042_CompressedWaterColumnData.PingNumber;
    R7000pings = S7Kdata.R7000_SonarSettings.PingNumber;
    R7027pings = S7Kdata.R7027_RawDetectionData.PingNumber;
    pingNumber = intersect(R7042pings,intersect(R7000pings,R7027pings));
    [~,ipR7042] = ismember(pingNumber,R7042pings);
    [~,ipR7000] = ismember(pingNumber,R7000pings);
    [~,ipR7027] = ismember(pingNumber,R7027pings);
    
    % for R7004_BeamGeometry, we will have to assume its contents are the
    % same as one of the other record types
    if numel(S7Kdata.R7004_BeamGeometry.SonarID) == numel(R7000pings)
        ipR7004 = ipR7000;
    elseif numel(S7Kdata.R7004_BeamGeometry.SonarID) == numel(R7027pings)
        ipR7004 = ipR7027;
    elseif numel(S7Kdata.R7004_BeamGeometry.SonarID) == numel(R7042pings)
        ipR7004 = ipR7042;
    else
        error('cannot proceed...')
    end
    
    % number of pings
    nPings = numel(pingNumber);
    
    % number of Tx sectors
    maxNTransmitSectors = 1;
    
    % number of beams
    nBeams = cellfun(@numel,S7Kdata.R7042_CompressedWaterColumnData.BeamNumber(ipR7042)); % number of beams per ping
    maxnBeams = nanmax(nBeams); % maximum number of beams in file
    
    % number of samples
    % maxNSamples = nanmax(S7Kdata.R7042_CompressedWaterColumnData.FirstSample(ipR7042)+cellfun(@nanmax,S7Kdata.R7042_CompressedWaterColumnData.NumberOfSamples(ipR7042)));
    dtg_nSamples = S7Kdata.R7042_CompressedWaterColumnData.NumberOfSamples(ipR7042); % number of samples per datagram and beam
    [maxNSamples_groups, ping_group_start, ping_group_end] = CFF_group_pings(dtg_nSamples,pingNumber,pingNumber); % making groups of pings to limit size of memmaped files
    
    % add the WCD decimation factors given here in input
    fData.dr_sub = dr_sub;
    fData.db_sub = db_sub;
    
    % data per ping
    fData.AP_1P_Date                            = S7Kdata.R7042_CompressedWaterColumnData.Date(ipR7042);
    fData.AP_1P_TimeSinceMidnightInMilliseconds = S7Kdata.R7042_CompressedWaterColumnData.TimeSinceMidnightInMilliseconds(ipR7042);
    fData.AP_1P_PingCounter                     = pingNumber;
    fData.AP_1P_NumberOfDatagrams               = ones(size(pingNumber));
    fData.AP_1P_NumberOfTransmitSectors         = ones(size(pingNumber));
    fData.AP_1P_TotalNumberOfReceiveBeams       = cellfun(@numel,S7Kdata.R7042_CompressedWaterColumnData.BeamNumber(ipR7042));
    fData.AP_1P_SoundSpeed                      = S7Kdata.R7000_SonarSettings.SoundVelocity(ipR7000);
    fData.AP_1P_SamplingFrequencyHz             = S7Kdata.R7042_CompressedWaterColumnData.SampleRate(ipR7042); % in Hz
    fData.AP_1P_TXTimeHeave                     = nan(ones(size(pingNumber)));
    fData.AP_1P_TVGFunctionApplied              = nan(size(pingNumber));
    fData.AP_1P_TVGOffset                       = zeros(size(pingNumber));
    fData.AP_1P_ScanningInfo                    = nan(size(pingNumber));
    
    % initialize data per transmit sector and ping
    fData.AP_TP_TiltAngle            = nan(maxNTransmitSectors,nPings);
    fData.AP_TP_CenterFrequency      = S7Kdata.R7000_SonarSettings.Frequency(ipR7000);
    fData.AP_TP_TransmitSectorNumber = nan(maxNTransmitSectors,nPings);
    
    % initialize data per (decimated) beam and ping
    fData.AP_BP_BeamPointingAngle      = nan(maxnBeams,nPings);
    fData.AP_BP_StartRangeSampleNumber = nan(maxnBeams,nPings);
    fData.AP_BP_NumberOfSamples        = nan(maxnBeams,nPings);
    fData.AP_BP_DetectedRangeInSamples = zeros(maxnBeams,nPings);
    fData.AP_BP_TransmitSectorNumber   = nan(maxnBeams,nPings);
    fData.AP_BP_BeamNumber             = nan(maxnBeams,nPings);
    
    % flags indicating what data are available
    [flags,sample_size,mag_fmt,phase_fmt] = CFF_get_R7042_flags(S7Kdata.R7042_CompressedWaterColumnData.Flags(1));
    
    % The actual water-column data will not be saved in fData but in binary
    % files. Get the output directory to store those files
    wc_dir = CFF_converted_data_folder(S7Kfilename);
    
    % Clean up that folder first before adding anything to it
    CFF_clean_delete_fdata(wc_dir);
    
    % amplitude format
    switch mag_fmt
        case 'int8'
            mag_file_fmt = 'int8';
            mag_fact = 1;
        case {'uint16', 'float32'}
            mag_file_fmt = 'int16';
            mag_fact = 1/200;
    end
    
    % initialize data-holding binary files for Amplitude
    fData = CFF_init_memmapfiles(fData,...
        'field', 'AP_SBP_SampleAmplitudes', ...
        'wc_dir', wc_dir, ...
        'Class', mag_file_fmt, ...
        'Factor', mag_fact, ...
        'Nanval', intmin(mag_file_fmt), ...
        'Offset', 0, ...
        'MaxSamples', maxNSamples_groups, ...
        'MaxBeams', maxnBeams, ...
        'ping_group_start', ping_group_start, ...
        'ping_group_end', ping_group_end);
    
    % do the same for phase if it's available
    if ~flags.magnitudeOnly
        
        % phase format
        switch phase_fmt
            case 'int8'
                phase_fact = 360/256;
            case 'int16'
                phase_fact = 180/pi/10430;
        end
        
        % initialize data-holding binary files for Phase
        fData = CFF_init_memmapfiles(fData, ...
            'field', 'AP_SBP_SamplePhase', ...
            'wc_dir', wc_dir, ...
            'Class', phase_fmt, ...
            'Factor', phase_fact, ...
            'Nanval', 200, ...
            'Offset', 0, ...
            'MaxSamples', maxNSamples_groups, ...
            'MaxBeams', maxnBeams, ...
            'ping_group_start', ping_group_start, ...
            'ping_group_end', ping_group_end);
        
    end
    
    % Also the samples data were not recorded, only their location in the
    % source file, so we need to fopen the source file to grab the data. 
    fid = fopen(S7Kfilename,'r','l');
    
    % correct sampling frequency record
    if flags.downsamplingType > 0
        fData.AP_1P_SamplingFrequencyHz = fData.AP_1P_SamplingFrequencyHz./flags.downsamplingDivisor;
    end
    
    % initialize ping group counter, to use to specify which memmapfile
    % to fill. We start in the first.
    iG = 1;
    
    % debug graph
    disp_wc = 0;
    if disp_wc
        f = figure();
        if flags.magnitudeOnly
            ax_mag = axes(f,'outerposition',[0 0 1 1]);
        else
            ax_mag = axes(f,'outerposition',[0 0.5 1 0.5]);
            ax_phase = axes(f,'outerposition',[0 0 1 0.5]);
        end
    end
    
    % now get data for each ping
    for iP = 1:nPings
        
        % ping group number is the index of the memmaped file in which that
        % swath's data will be saved.
        if iP > ping_group_end(iG)
            iG = iG+1;
        end
        
        % data per Tx sector
        nTransmitSectors = fData.AP_1P_NumberOfTransmitSectors(1,iP); % number of transmit sectors in this ping
        fData.AP_TP_TiltAngle(1:nTransmitSectors,iP)            = zeros(nTransmitSectors,1);
        fData.AP_TP_CenterFrequency(1:nTransmitSectors,iP)      = S7Kdata.R7000_SonarSettings.Frequency(ipR7000(iP))*ones(nTransmitSectors,1);
        fData.AP_TP_TransmitSectorNumber(1:nTransmitSectors,iP) = 1:nTransmitSectors;
        
        % data per beam
        iBeam = S7Kdata.R7042_CompressedWaterColumnData.BeamNumber{ipR7042(iP)}+1; % beam numbers in this ping
        fData.AP_BP_BeamPointingAngle(iBeam,iP)      = S7Kdata.R7004_BeamGeometry.BeamHorizontalDirectionAngleRad{ipR7004(iP)}/pi*180;
        fData.AP_BP_StartRangeSampleNumber(iBeam,iP) = round(S7Kdata.R7042_CompressedWaterColumnData.FirstSample(ipR7042(iP)));
        fData.AP_BP_NumberOfSamples(iBeam,iP)        = round(S7Kdata.R7042_CompressedWaterColumnData.NumberOfSamples{ipR7042(iP)});
        fData.AP_BP_DetectedRangeInSamples(S7Kdata.R7027_RawDetectionData.BeamDescriptor{ipR7027(iP)}+1,iP) = round(S7Kdata.R7027_RawDetectionData.DetectionPoint{ipR7027(iP)}/flags.downsamplingDivisor);
        fData.AP_BP_TransmitSectorNumber(iBeam,iP)   = 1;
        fData.AP_BP_BeamNumber(iBeam,iP)             = S7Kdata.R7004_BeamGeometry.N(ipR7004(iP));
        
        % initialize amplitude and phase matrices
        Mag_tmp = ones(maxNSamples_groups(iG),maxnBeams,mag_fmt)*eval([mag_fmt '(-inf)']);
        if ~flags.magnitudeOnly
            Ph_tmp = zeros(maxNSamples_groups(iG),maxnBeams,phase_fmt);
        end
        
        % number of samples for each beam in this ping
        nSamples = S7Kdata.R7042_CompressedWaterColumnData.NumberOfSamples{ipR7042(iP)};
        
        % got to start of data in raw file, from here
        pos = ftell(fid);
        fseek(fid,S7Kdata.R7042_CompressedWaterColumnData.SampleStartPositionInFile{ipR7042(iP)}(1)-pos,'cof');
        
        % read the ping's data as int8, between the start position for the
        % first beam's data and the end position of the last beam's data 
        pos_start_ping = S7Kdata.R7042_CompressedWaterColumnData.SampleStartPositionInFile{ipR7042(iP)}(1);
        pos_end_ping = S7Kdata.R7042_CompressedWaterColumnData.SampleStartPositionInFile{ipR7042(iP)}(end)+nSamples(end)*sample_size;
        DataSamples_tot = fread(fid,pos_end_ping-pos_start_ping+1,'int8=>int8');
        
        % index of first sample
        % DEV NOTE --------------------------------------------------------
        % Here we used to save the samples with any start sample
        % offset, aka:
        % start_sample = S7Kdata.R7042_CompressedWaterColumnData.FirstSample(ipR7042(iP))+1;
        % so it could be used when recording the data a few lines down,
        % such as:
        % Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = DataSamples_tmp;
        %
        % Now I removed it because it caused errors. The errors are due to
        % the fact that Mag_tmp are initialized without considering the
        % start sample number. It turns out this error never happened
        % before because all WCD from R7042 records test previously did NOT
        % have a start sample offset. Now, saving data with the offset is
        % something we did not do with ALL or KMALL data, so why did we
        % code it here. Anyway, for now I don't want to change the code in
        % case there was a good reason for doing things this way. So just
        % saving start_sample = 1 to override this approach:
        start_sample = S7Kdata.R7042_CompressedWaterColumnData.FirstSample(ipR7042(iP))+1;
        start_sample = 1;
        % -----------------------------------------------------------------
        
        % read beam by beam
        for jj = 1:S7Kdata.R7004_BeamGeometry.N(ipR7004(iP))  % from R7004??? XXX1
            
            % get data for that beam
            idx_pp = S7Kdata.R7042_CompressedWaterColumnData.SampleStartPositionInFile{ipR7042(iP)}(jj):(S7Kdata.R7042_CompressedWaterColumnData.SampleStartPositionInFile{ipR7042(iP)}(jj)+nSamples(jj)*sample_size-1);
            idx_pp = idx_pp-pos_start_ping+1;
            DataSamples_tmp = DataSamples_tot(idx_pp);
            
            if flags.magnitudeOnly
                % data are amplitude only
                switch mag_fmt
                    % read amplitude data
                    case 'int8'
                        Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = DataSamples_tmp;
                    case 'uint16'
                        Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = typecast(DataSamples_tmp,mag_fmt);
                    case 'float32'
                        Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = 10*log10(typecast(DataSamples_tmp,mag_fmt));
                    otherwise
                        warning('WC compression flag issue');
                end
            else
                % data are amplitude AND phase
                switch mag_fmt
                    % read amplitude data
                    case 'int8'
                        Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = DataSamples_tmp(1:2:end,:);
                    case 'uint16'
                        idx_tot = rem(1:numel(DataSamples_tmp),4);
                        idx_mag = idx_tot==1 | idx_tot==2;
                        Mag_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = typecast(DataSamples_tmp(idx_mag,:),mag_fmt);
                    otherwise
                        warning('WC compression flag issue');
                end
                switch phase_fmt
                    % read phase data
                    case'int8'
                        Ph_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = DataSamples_tmp(2:2:end,:);
                    case 'int16'
                        idx_tot = rem(1:numel(DataSamples_tmp),4);
                        idx_phase = idx_tot==3 | idx_tot==0;
                        Ph_tmp((start_sample:start_sample+nSamples(jj)-1),jj) = typecast(DataSamples_tmp(idx_phase,:),phase_fmt);
                    otherwise
                        warning('WC compression flag issue');
                end
            end
            
        end
        
        % debug graph
        if disp_wc
            % display amplitude
            switch mag_fmt
                case 'int8'
                    imagesc(ax_mag,double(Mag_tmp)-128);
                case 'uint16'
                    imagesc(ax_mag,10*log10(double(Mag_tmp)/double(intmax('int16'))));
            end
            caxis(ax_mag,[-100 -20]);
            colorbar
            title(sprintf('ping %i/%i',iP,nPings));
            % display phase
            if ~flags.magnitudeOnly
                imagesc(ax_phase,Ph_tmp*phase_fact);
                colorbar
            end
            drawnow;
        end
        
        % reformat amplitude data for storing
        switch mag_fmt
            case 'int8'
                Mag_tmp = Mag_tmp - int8(128);
            case 'uint16'
                idx0 = Mag_tmp==0;
                Mag_tmp = (10*log10(double(Mag_tmp)/double(intmax('uint16')))/mag_fact);
                Mag_tmp(idx0) = -inf;
                Mag_tmp = int16(Mag_tmp);
            case 'float32'
                Mag_tmp = int16(Mag_tmp/mag_fact);
        end
        
        % finished reading this ping's WC data. Store the data in the
        % appropriate binary file, at the appropriate ping, through the
        % memory mapping
        fData.AP_SBP_SampleAmplitudes{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = Mag_tmp;
        
        if ~flags.magnitudeOnly
            fData.AP_SBP_SamplePhase{iG}.Data.val(:,:,iP-ping_group_start(iG)+1) = Ph_tmp;
        end
        
    end
    
    % close the original raw file
    fclose(fid);
    
end

comms.progress(6,6);


%% finalise

% end message
comms.finish('Done');