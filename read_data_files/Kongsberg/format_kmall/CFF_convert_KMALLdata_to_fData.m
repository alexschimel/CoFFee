function fData = CFF_convert_KMALLdata_to_fData(KMALLdata,varargin)
%CFF_CONVERT_KMALLDATA_TO_FDATA  Convert kmall data to the CoFFee format
%
%   Converts Kongsberg EM series data FROM the KMALLdata format (read by
%   CFF_READ_KMALL) TO the CoFFee fData format used in processing.
%
%   FDATA = CFF_CONVERT_KMALLDATA_TO_FDATA(KMALLDATA) converts the contents
%   of KMALLDATA (as read by CFF_READ_KMALL) into FDATA (structure in the
%   fData format). KMALLDATA can be a single structure corresponding to a
%   single kmall or kmwcd file, or a 1x2 cell array of structures
%   corresponding to a kmall/kmwcd file pair. 
%   WARNING: This function cannot be used to convert KMALLdata structures 
%   from unpaired files. 
%   NOTE: For a pair of KMALLdata structures, these are converted in the
%   order they are in input, and that the first ones take precedence. Aka
%   if the second structure contains a type of datagram that is already in
%   the first, these will NOT be converted. This is to avoid doubling up
%   the data that may exist in duplicate in the pair of raw files. You need
%   to order the KMALLdata structures in input in order of desired
%   precedence. 
%
%   FDATA = CFF_CONVERT_KMALLDATA_TO_FDATA(KMALLDATA,DR_SUB,DB_SUB)
%   operates the conversion with a sub-sampling of the water-column data
%   (either WC or AP datagrams) in range and in beams. For example, to
%   sub-sample range by a factor of 10 and beams by a factor of 2, use:
%   FDATA = CFF_CONVERT_KMALLDATA_TO_FDATA(KMALLDATA,10,2).

%   DEV NOTE: In the kmall format, the lowest ping unit is not a ping but
%   a "swath" to accommodate dual-and multi-swath operating modes. For
%   example, in dual-swath mode, a single Tx transducer will transmit 2
%   pulses to create two along-swathes, and in kmall those two swathes are
%   recorded with the same ping counter because they were produced at about
%   the same time. However, to date the fData format is based on three
%   dimensions ping x beam x sample. To deal with this, we're creating new
%   "swath numbers" based on the original ping number and swath counter for
%   a ping. For example a ping #832 made up of four swathes counted 0-3
%   will have new "swath numbers" of 832.00, 832.01, 832.02, and 832.03. We
%   will maintain the current "ping" nomenclature in fData, but using those
%   new swath numbers. Note that if we have single-swath data, then the
%   swath number matches the ping number (832). Note that this is made more
%   complicated by the fact that an individual swathe can have its data on
%   multiple consecutive datagrams, as different "Rx fans" (i.e multiple Rx
%   heads) are recorded on separate datagrams.
%
%   DEV NOTE: a new "inspection" mode with alternating low/high frequency
%   trips up the code. To fix eventually when needed XXX2. There also seem
%   to be some issues with location of bottom on some dual head data. To
%   fix eventually XXX1.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% Input arguments management
p = inputParser;

% array of KMALLdata structures
addRequired(p,'KMALLdata',@(x) isstruct(x) || iscell(x));

% decimation factor in range and beam
addOptional(p,'dr_sub',1,@(x) isnumeric(x)&&x>0);
addOptional(p,'db_sub',1,@(x) isnumeric(x)&&x>0);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,KMALLdata,varargin{:})

% and get results
KMALLdata = p.Results.KMALLdata;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p;

% check inputs
if isstruct(KMALLdata)
    % just one KMALL structure. Convert to cell for next checks
    KMALLdata = {KMALLdata};
end
if iscell(KMALLdata) && numel(KMALLdata)==1
    % expecting a single KMALLdata structure.
    if ~isstruct(KMALLdata{1}) || ...
            ~isfield(KMALLdata{1}, 'KMALLfilename') || ...
            ~CFF_check_KMALLfilename(KMALLdata{1}.KMALLfilename)
        error('Invalid input');
    end
elseif iscell(KMALLdata) && numel(KMALLdata)==2
    % expecting two KMALLdata structures for a pair of matching files
    if ~isstruct(KMALLdata{1}) || ...
            ~isstruct(KMALLdata{2}) || ...
            ~isfield(KMALLdata{1}, 'KMALLfilename') || ...
            ~isfield(KMALLdata{2}, 'KMALLfilename') || ...
            ~CFF_check_KMALLfilename(KMALLdata{1}.KMALLfilename) || ...
            ~CFF_check_KMALLfilename(KMALLdata{2}.KMALLfilename)
        error('Invalid input');
    end
else
    error('Invalid input');
end


%% Prep

% start message
comms.start('Converting to fData format');

% initialize fData, with current version number
fData.MET_Fmt_version = CFF_get_current_fData_version();

% add source filename(s) (and save them for later parsing)
for iKS = 1:numel(KMALLdata)
    if isfield(KMALLdata{iKS},'EMdgmMWC')
        KMWCDfilename = KMALLdata{iKS}.KMALLfilename;
        fData.ALLfilename{iKS} = KMWCDfilename;
    elseif isfield(KMALLdata{iKS},'EMdgmMRZ')
        KMALLfilename = KMALLdata{iKS}.KMALLfilename;
        fData.ALLfilename{iKS} = KMALLfilename;
    end
end

% reformat input data to a single struct, with precedence (aka ignore
% fields in second structure if they already exist in first structure)
if numel(KMALLdata)==1
    KMALLdata = KMALLdata{1};
else
    fieldNames = fields(KMALLdata{2});
    for iFN = 1:numel(fieldNames)
        f = fieldNames{iFN};
        if ~isfield(KMALLdata{1},f)
            KMALLdata{1}.(f) = KMALLdata{2}.(f);
        end
    end
    KMALLdata = KMALLdata{1}; % delete 2nd struct here
    KMALLdata = rmfield(KMALLdata,'KMALLfilename'); % irrelevant in merge
    KMALLdata = rmfield(KMALLdata,'info'); % irrelevant in merge
end

% start progress
comms.progress(0,5);

% Now completing each "type" of fData fields (IP, Ru, X8, etc.) from the
% KMALL datagrams in the KMALLdata structure


%% fData.IP_ (installation parameters)
% DEV NOTES: Only value needed for processing (to date) is the "sonar
% heading offset". In installation parameters datagrams of .all files, we
% only had one field "S1H" per head. Here we have heading values for both
% the Tx and Rx antennae. So not sure which one we should take, or the
% difference between the two... but for now, take the value from Rx.
if isfield(KMALLdata,'EMdgmIIP')
    comms.step('Parsing Installation Parameters from #IIP datagrams');
    
    % get date and time-since-midnight-in-milleseconds from header
    header = [KMALLdata.EMdgmIIP.header];
    [fData.IP_1D_Date, fData.IP_1D_TimeSinceMidnightInMilliseconds] = CFF_kmall_time_to_all_time([header.time_sec],[header.time_nanosec]);
    
    % read ASCIIdata
    ASCIIdata = KMALLdata.EMdgmIIP(1).install_txt;
    
    % remove carriage returns, tabs and linefeed
    ASCIIdata = regexprep(ASCIIdata,char(9),'');
    ASCIIdata = regexprep(ASCIIdata,newline,'');
    ASCIIdata = regexprep(ASCIIdata,char(13),'');
    
    % read some fields and record value in old field for the software to
    % pick up
    try
        IP_ASCIIparameters.TRAI_RX1 = CFF_read_TRAI(ASCIIdata,'TRAI_RX1');
        IP_ASCIIparameters.S1H = IP_ASCIIparameters.TRAI_RX1.H;
    catch
        % at least in some EM2040C dual head data, I've found this field
        % missing and instead having TRAI_HD1
        IP_ASCIIparameters.TRAI_HD1 = CFF_read_TRAI(ASCIIdata,'TRAI_HD1');
        IP_ASCIIparameters.S1H = IP_ASCIIparameters.TRAI_HD1.H;
    end
    
    % HOTFIX for NIOZ - Alex 13 June 2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    IP_ASCIIparameters.S1H = 0;
    % end of HOTFIX %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % finally store in fData
    fData.IP_ASCIIparameters = IP_ASCIIparameters;
    
end

% progress message
comms.progress(1,5);


%% fData.Po_ (navigation data)
if isfield(KMALLdata,'EMdgmSPO')
    comms.step('Parsing navigation data from #SPO datagrams');
    
    % extract data
    % header = [KMALLdata.EMdgmSPO.header];
    cmnPart = [KMALLdata.EMdgmSPO.cmnPart];
    sensorData = [KMALLdata.EMdgmSPO.sensorData];
    
    % find all unique sensor systems
    sensorSystem = [cmnPart.sensorSystem];
    sensorSystemNumber = [sensorSystem.SensorSystemNumber];
    uniqueSensorSystems = unique(sensorSystemNumber);
    
    % init total number of entries recorded so far
    totN = 0;
    
    for ii = 1:numel(uniqueSensorSystems)
        
        systID = uniqueSensorSystems(ii);
        
        % extract all data for this system only
        indS = sensorSystemNumber == systID;
        thisSensorData = sensorData(indS);
        
        % get time vector from header, sort, and remove duplicates
        dt = CFF_kmall_time_to_datetime([thisSensorData.timeFromSensor_sec],[thisSensorData.timeFromSensor_nanosec]);
        [~,I] = sort(dt);
        iKeep = [true,diff(dt(I))~=0];
        indK = I(iKeep);
        if any(~iKeep)
            comms.info('Duplicate time entries in Position datagrams (#SPO). You might experience issues with navigation.');
        end
        thisSensorData = thisSensorData(indK);
        curN = numel(thisSensorData);
        
        % get time
        [fData.Po_1D_Date(totN+(1:curN)),fData.Po_1D_TimeSinceMidnightInMilliseconds(totN+(1:curN))] =  CFF_kmall_time_to_all_time([thisSensorData.timeFromSensor_sec],[thisSensorData.timeFromSensor_nanosec]);
        
        % get the rest
        fData.Po_1D_Latitude(totN+(1:curN))                    = [thisSensorData.correctedLat_deg]; % in decimal degrees
        fData.Po_1D_Longitude(totN+(1:curN))                   = [thisSensorData.correctedLong_deg]; % in decimal degrees
        fData.Po_1D_SpeedOfVesselOverGround(totN+(1:curN))     = [thisSensorData.speedOverGround_mPerSec]; % in m/s
        fData.Po_1D_HeadingOfVessel(totN+(1:curN))             = [thisSensorData.courseOverGround_deg]; % in degrees relative to north
        fData.Po_1D_MeasureOfPositionFixQuality(totN+(1:curN)) = [thisSensorData.posFixQuality_m];
        fData.Po_1D_PositionSystemDescriptor(totN+(1:curN))    = systID.*ones(1,curN);
        
        % update total number of entries recorded so far
        totN = totN+curN;
    end
    % DEV NOTE: entries are not sorted in time but in sensor-then-time.
    % Keeping it like this for now since CFF_compute_navigation_v2 only
    % uses the data from one sensor.
    
    % debug display
    dbug = 0;
    if dbug
        figure;
        clear ax
        dt = CFF_all_time_to_datetime(fData.Po_1D_Date,fData.Po_1D_TimeSinceMidnightInMilliseconds);
        unIDs = unique(fData.Po_1D_PositionSystemDescriptor);
        tiledlayout(4,1);
        ax(1) = nexttile;
        for ii = 1:numel(unIDs)
            ind = fData.Po_1D_PositionSystemDescriptor == unIDs(ii);
            plot(dt(ind), fData.Po_1D_Latitude(ind), '.-'); hold on
        end
        ylabel('latitude'); grid on; legend(string(unIDs))
        
        ax(2) = nexttile;
        for ii = 1:numel(unIDs)
            ind = fData.Po_1D_PositionSystemDescriptor == unIDs(ii);
            plot(dt(ind), fData.Po_1D_Longitude(ind), '.-'); hold on
        end
        ylabel('longitude'); grid on; legend(string(unIDs))
        
        ax(3) = nexttile;
        for ii = 1:numel(unIDs)
            ind = fData.Po_1D_PositionSystemDescriptor == unIDs(ii);
            plot(dt(ind), fData.Po_1D_HeadingOfVessel(ind), '.-'); hold on
        end
        ylabel('heading'); grid on; legend(string(unIDs))
        
        ax(4) = nexttile;
        for ii = 1:numel(unIDs)
            ind = fData.Po_1D_PositionSystemDescriptor == unIDs(ii);
            plot(dt(ind), fData.Po_1D_SpeedOfVesselOverGround(ind), '.-'); hold on
        end
        ylabel('speed'); grid on; legend(string(unIDs))
        
        linkaxes(ax,'x')
        
        figure;
        for ii = 1:numel(unIDs)
            ind = fData.Po_1D_PositionSystemDescriptor == unIDs(ii);
            plot(fData.Po_1D_Longitude(ind), fData.Po_1D_Latitude(ind), '.-'); hold on
        end
        xlabel('longitude'); ylabel('latitude'); grid on; legend(string(unIDs));
        
    end
    
end

% progress message
comms.progress(2,5);

%% fData.X8_ ("pear beam" data - bathymetry and backscatter )
% DEV NOTE: See function doc string about "swathes". Note we don't decimate
% beam data here as we do for water-column data 
if isfield(KMALLdata,'EMdgmMRZ')
    comms.step('Parsing X8 fields from #MRZ datagrams');
    
    % remove duplicate datagrams
    [EMdgmMRZ, nDup] = CFF_remove_duplicate_KMALL_datagrams(KMALLdata.EMdgmMRZ);
    if nDup
        infoStr = sprintf('Found and discarded %i duplicate datagrams',nDup);
        comms.info(infoStr);
    end
    
    % extract data
    header   = [EMdgmMRZ.header];
    cmnPart  = [EMdgmMRZ.cmnPart];
    pingInfo = [EMdgmMRZ.pingInfo];
    rxInfo   = [EMdgmMRZ.rxInfo];
    sounding = [EMdgmMRZ.sounding];
    % CFF_get_kmall_TxRx_info(cmnPart) % evaluate to get info for debugging
    
    % number of datagrams
    % nDatag = numel(cmnPart);
    
    % number of pings
    dtg_pingCnt = [cmnPart.pingCnt]; % actual ping number for each datagram
    dtg_swathAlongPosition = [cmnPart.swathAlongPosition]; % alongship index for the location of the swath in multi swath mode. Index 0 is the aftmost swath.
    dtg_swathCnt = dtg_pingCnt + 0.01.*dtg_swathAlongPosition; % "new ping number" for each datagram
    [swath_counter, iFirstDatagram, iC] = unique(dtg_swathCnt,'stable'); % list of swath numbers
    nSwaths = numel(swath_counter); % total number of swaths in file
    
    % number of beams
    dtg_nBeams = [rxInfo.numSoundingsMaxMain]; % number of beams per datagram ("main soundings" only. Ignoring "extra detections")
    nBeams = arrayfun(@(idx) sum(dtg_nBeams(iC==idx)), 1:nSwaths); % total number of beams per swath
    maxnBeams = nanmax(nBeams); % maximum number of "beams per swath" in the file
    
    % date and time
    [dtg_date,dtg_TSMIM] = CFF_kmall_time_to_all_time([header.time_sec],[header.time_nanosec]);
    fData.X8_1P_Date = dtg_date(iFirstDatagram); % date per swath
    fData.X8_1P_TimeSinceMidnightInMilliseconds = dtg_TSMIM(iFirstDatagram); % time per swath
    
    % record data per ping
    fData.X8_1P_PingCounter             = swath_counter;
    fData.X8_1P_HeadingOfVessel         = NaN; % unused (for now)
    fData.X8_1P_SoundSpeedAtTransducer  = NaN; % unused (for now)
    fData.X8_1P_TransmitTransducerDepth = [pingInfo(iFirstDatagram).txTransducerDepth_m]; % unused (for now)
    fData.X8_1P_NumberOfBeamsInDatagram = NaN; % unused (for now)
    fData.X8_1P_NumberOfValidDetections = NaN; % unused (for now)
    fData.X8_1P_SamplingFrequencyInHz   = NaN; % unused (for now)
    
    % initialize data per beam and ping
    fData.X8_BP_DepthZ                       = nan(maxnBeams,nSwaths);
    fData.X8_BP_AcrosstrackDistanceY         = nan(maxnBeams,nSwaths);
    fData.X8_BP_AlongtrackDistanceX          = nan(maxnBeams,nSwaths);
    fData.X8_BP_DetectionWindowLength        = NaN; % unused (for now)
    fData.X8_BP_QualityFactor                = NaN; % unused (for now)
    fData.X8_BP_BeamIncidenceAngleAdjustment = NaN; % unused (for now)
    fData.X8_BP_RealTimeCleaningInformation  = NaN; % unused (for now)
    fData.X8_BP_ReflectivityBS               = nan(maxnBeams,nSwaths);
    fData.X8_B1_BeamNumber                   = (1:maxnBeams)';
    
    % init a temp array to store detectionMethod before decoding it
    tempDetectMethod = nan(maxnBeams,nSwaths);
    
    % record data per beam and ping
    for iS = 1:nSwaths
        dtg_iS = find(iC==iS); % indices of datagrams for that swath
        nB_tot = 0; % initialize total number of beams recorded so far for that swath
        for iD = 1:numel(dtg_iS)
            SD = sounding(dtg_iS(iD)); % soundings data for that datagram
            nB = dtg_nBeams(dtg_iS(iD)); % number of actual beams in this datagram (ignoring "extra detections")
            iB_dst = nB_tot + (1:nB); % indices of beams in output arrays
            fData.X8_BP_DepthZ(iB_dst,iS)               = SD.z_reRefPoint_m(1:nB);
            fData.X8_BP_AcrosstrackDistanceY(iB_dst,iS) = SD.y_reRefPoint_m(1:nB);
            fData.X8_BP_AlongtrackDistanceX(iB_dst,iS)  = SD.x_reRefPoint_m(1:nB);
            fData.X8_BP_ReflectivityBS(iB_dst,iS)       = SD.reflectivity1_dB(1:nB);
            tempDetectMethod(iB_dst,iS)                 = SD.detectionMethod(1:nB);
            nB_tot = nB_tot + nB; % update total number of beams recorded so far for this swath
        end
    end
    
    % Note the coordinate system for (x,y,z) is different in the .all and
    % .kmall formats so some transformation is necessary since processing
    % code will expect (x,y,z) in the .all coordinate system.
    %
    % * In the .all format, the coordinate system is the "Vessel Coordinate
    % System, where x is forward, y is starboard and z is downward" and the
    % origin is the centre of the array face.
    %
    % * In the .kmall format, the coordinate system is the "Surface
    % Coordinate System (SCS)" where: 
    %   * Origo of the SCS is the vessel reference point at the time of
    %   transmission. The SCS is defined according to the right hand rule.
    %   * x-axis pointing forward along the horizontal projection of the
    %   vessel main axis. 
    %   * y-axis pointing horizontally to starboard, orthogonal to the
    %   horizontal projection of the vessel main axis.
    %   * z-axis pointing down along the g-vector.
    % To move SCS into the waterline, use reference point height corrected
    % for roll and pitch at the time of transmission. 
    %
    % Looks like the coordinate system is the same, but the origin
    % is different. So the transformation is simply offsets.
    
    % for x and y, the kmall data conveniently includes the offsets:
    fData.X8_BP_AlongtrackDistanceX  = fData.X8_BP_AlongtrackDistanceX +  [pingInfo(iFirstDatagram).x_kmallToall_m];
    fData.X8_BP_AcrosstrackDistanceY = fData.X8_BP_AcrosstrackDistanceY + [pingInfo(iFirstDatagram).y_kmallToall_m];
    
    % for z, the kmall data includes the distance of the ref point to the
    % water line, and the distance of the water line to the sonar face:
    WLreRP = [pingInfo(iFirstDatagram).z_waterLevelReRefPoint_m];
    TTD = [pingInfo(iFirstDatagram).txTransducerDepth_m];
    
    % debug graph
    dbug = 0;
    if dbug
        figure;
        tiledlayout(3,1)
        ax(1) = nexttile; plot(WLreRP); ylabel('WLreRP'); grid on
        ax(2) = nexttile; plot(TTD); ylabel('TTD'); grid on
        ax(3) = nexttile;
        plot(fData.X8_BP_DepthZ(200,:)); % to vessel ref point
        hold on
        plot(fData.X8_BP_DepthZ(200,:) - WLreRP); % to waterline
        plot(fData.X8_BP_DepthZ(200,:) - WLreRP - TTD); % to sonar face
        ylabel('depth middle beam'); grid on
        legend({'to vessel ref point (orig)','% to waterline','to sonar face (.all)'})
        linkaxes(ax,'x')
    end
    
    fData.X8_BP_DepthZ = fData.X8_BP_DepthZ - WLreRP - TTD;
    
    % debug graph
    dbug = 0;
    if dbug
        f = figure();
        ax_z = axes(f,'outerposition',[0 0.66 1 0.3]);
        imagesc(ax_z, -fData.X8_BP_DepthZ);
        colorbar(ax_z); grid on; title(ax_z, 'bathy'); colormap(ax_z,'jet');
        ax_y = axes(f,'outerposition',[0 0.33 1 0.3]);
        imagesc(ax_y, fData.X8_BP_AcrosstrackDistanceY);
        colorbar(ax_y); grid on; title(ax_y, 'across-track distance');
        ax_bs = axes(f,'outerposition',[0 0 1 0.3]);
        imagesc(ax_bs, fData.X8_BP_ReflectivityBS);
        caxis(ax_bs, [prctile(fData.X8_BP_ReflectivityBS(:),1), prctile(fData.X8_BP_ReflectivityBS(:),99)]);
        colorbar(ax_bs); grid on; title(ax_bs, 'BS (scaled 1-99th percentile)'); colormap(ax_bs,'gray');
        linkaxes([ax_z,ax_y,ax_bs]);
        drawnow;
        
        figure;
        tiledlayout(2,1)
        clear ax
        ax(1) = nexttile; imagesc(-fData.X8_BP_DepthZ); colorbar; grid on; title('bathy'); colormap(ax(1),'jet');
        ax(2) = nexttile; imagesc(fData.X8_BP_ReflectivityBS); colorbar; grid on; title('backscatter (beam average'); colormap(ax(2),'gray');
        linkaxes(ax);
        
        figure;
        iP  = 304
        yyaxis left
        plot(fData.X8_BP_ReflectivityBS(:,iP),'.-'); ylabel('BS')
        yyaxis right
        plot(fData.X8_BP_DepthZ(:,iP),'.-'); ylabel('bathy')
        xlabel('beam #')
    end
    
    % decode detectMethod
    fData.X8_BP_DetectionValidity = categorical(tempDetectMethod,[0,1,2],{'invalid','valid','valid'});
    fData.X8_BP_DetectionInfo     = categorical(tempDetectMethod,[0,1,2],{'invalid','amplitude','phase'});
    
    % debug graph
    dbug = 0;
    if dbug
        figure; tiledlayout(2,1);
        ax3(1) = nexttile; image(double(fData.X8_BP_DetectionValidity)); CFF_add_cat_array_legend(fData.X8_BP_DetectionValidity); title('Detection validity');
        ax3(2) = nexttile; image(double(fData.X8_BP_DetectionInfo)); CFF_add_cat_array_legend(fData.X8_BP_DetectionInfo); title('Detection info');
        linkaxes(ax3);
    end
    
end

% progress message
comms.progress(3,5);

%% fData.WC_ (water-column data)
% DEV NOTE: ...
if isfield(KMALLdata,'EMdgmMWC')
    comms.step('Parsing water-column data from #MWC datagrams');
    
    % remove duplicate datagrams
    [EMdgmMWC, nDup] = CFF_remove_duplicate_KMALL_datagrams(KMALLdata.EMdgmMWC);
    if nDup
        infoStr = sprintf('Found and discarded %i duplicate datagrams',nDup);
        comms.info(infoStr);
    end
    
    % extract data
    header = [EMdgmMWC.header];
    cmnPart = [EMdgmMWC.cmnPart];
    rxInfo  = [EMdgmMWC.rxInfo];
    % CFF_get_kmall_TxRx_info(cmnPart) % evaluate to get info for debugging
    
    % number of datagrams
    nDatag = numel(EMdgmMWC);
    
    % number of pings
    dtg_pingCnt = [cmnPart.pingCnt]; % actual ping number for each datagram
    dtg_swathAlongPosition = [cmnPart.swathAlongPosition]; % alongship index for the location of the swath in multi swath mode. Index 0 is the aftmost swath.
    dtg_swathCnt = dtg_pingCnt + 0.01.*dtg_swathAlongPosition; % "new ping number" for each datagram
    [swath_counter, iFirstDatagram, iC] = unique(dtg_swathCnt,'stable'); % list of swath numbers
    nSwaths = numel(swath_counter); % total number of swaths in file
    
    % number of beams
    dtg_nBeams = [rxInfo.numBeams]; % number of beams per datagram
    nBeams = arrayfun(@(idx) sum(dtg_nBeams(iC==idx)), 1:nSwaths); % total number of beams per swath
    maxnBeams = nanmax(nBeams); % maximum number of "beams per swath" in the file
    maxnBeams_sub = ceil(maxnBeams/db_sub); % maximum number of beams TO READ per swath
    
    % number of samples
    dtg_nSamples = arrayfun(@(idx) [EMdgmMWC(idx).beamData_p(:).numSampleData], 1:nDatag, 'UniformOutput', false); % number of samples per ping per datagram
    [maxnSamples_groups, ping_group_start, ping_group_end] = CFF_group_pings(dtg_nSamples, swath_counter, dtg_swathCnt); % making groups of pings to limit size of memmaped files
    maxnSamples_groups = ceil(maxnSamples_groups/dr_sub); % maximum number of samples TO READ, per group.
    
    % add the WCD decimation factors given here in input
    fData.dr_sub = dr_sub;
    fData.db_sub = db_sub;
    
    % data per ping
    % here taken from first datagram. Ideally, check consistency between
    % datagrams for a given ping
    [dtg_date,dtg_TSMIM] = CFF_kmall_time_to_all_time([header.time_sec],[header.time_nanosec]);
    fData.WC_1P_Date = dtg_date(iFirstDatagram); % date per swath
    fData.WC_1P_TimeSinceMidnightInMilliseconds = dtg_TSMIM(iFirstDatagram); % time per swath
    fData.WC_1P_PingCounter               = swath_counter;
    fData.WC_1P_NumberOfDatagrams         = NaN; % unused (for now)
    fData.WC_1P_NumberOfTransmitSectors   = NaN; % unused (for now)
    fData.WC_1P_TotalNumberOfReceiveBeams = NaN; % unused (for now)
    fData.WC_1P_SoundSpeed                = [rxInfo(iFirstDatagram).soundVelocity_mPerSec];
    fData.WC_1P_SamplingFrequencyHz       = [rxInfo(iFirstDatagram).sampleFreq_Hz];
    fData.WC_1P_TXTimeHeave               = NaN; % unused (for now)
    fData.WC_1P_TVGFunctionApplied        = [rxInfo(iFirstDatagram).TVGfunctionApplied];
    fData.WC_1P_TVGOffset                 = [rxInfo(iFirstDatagram).TVGoffset_dB];
    fData.WC_1P_ScanningInfo              = NaN; % unused (for now)
    
    % data per transmit sector and ping
    fData.WC_TP_TiltAngle            = NaN; % unused (for now)
    fData.WC_TP_CenterFrequency      = NaN; % unused (for now)
    fData.WC_TP_TransmitSectorNumber = NaN; % unused (for now)
    
    % initialize data per (decimated) beam and ping
    fData.WC_BP_BeamPointingAngle      = nan(maxnBeams_sub,nSwaths);
    fData.WC_BP_StartRangeSampleNumber = nan(maxnBeams_sub,nSwaths);
    fData.WC_BP_NumberOfSamples        = nan(maxnBeams_sub,nSwaths);
    fData.WC_BP_DetectedRangeInSamples = zeros(maxnBeams_sub,nSwaths);
    fData.WC_BP_TransmitSectorNumber   = NaN; % unused (for now)
    fData.WC_BP_BeamNumber             = NaN; % unused (for now)
    fData.WC_BP_SystemSerialNumber     = NaN; % unused (for now)
    
    % The actual water-column data will not be saved in fData but in binary
    % files. Get the output directory to store those files
    wc_dir = CFF_converted_data_folder(KMWCDfilename);
    
    % Clean up that folder first before adding anything to it
    CFF_clean_delete_fdata(wc_dir);
    
    % DEV NOTE: Info format for raw WC data and storage
    % In these raw datagrams, you have both amplitude and phase.
    %
    % Amplitude samples are recorded exactly as in the .all format, that is
    % in "int8" (signed integers from -128 to 127) with -128 being the NaN
    % value. Raw values needs to be multiplied by a factor of 1/2 to
    % retrieve the true value, aka real values go from -127/2 = -63.5 dB to
    % 127/2 = 63.5 dB in increments of 0.5 dB
    % For storage, we keep the same format in order to save disk space.
    %
    % Phase might or might not be recorded, and depending on the value of
    % the flag may be recorded in 'int8' with a factor of 180./128, or in
    % 'int16' with a factor of 0.01.
    %
    % For storage, we keep the same format in order to save disk space.
    
    % initialize data-holding binary files for Amplitude
    fData = CFF_init_memmapfiles(fData, ...
        'field', 'WC_SBP_SampleAmplitudes', ...
        'wc_dir', wc_dir, ...
        'Class', 'int8', ...
        'Factor', 1./2, ...
        'Nanval', intmin('int8'), ...
        'Offset', 0, ...
        'MaxSamples', maxnSamples_groups, ...
        'MaxBeams', maxnBeams_sub, ...
        'ping_group_start', ping_group_start, ...
        'ping_group_end', ping_group_end);
    
    % was phase recorded
    dtg_phaseFlag = [rxInfo.phaseFlag];
    if all(dtg_phaseFlag==0)
        phaseFlag = 0;
    elseif all(dtg_phaseFlag==1)
        phaseFlag = 1;
    elseif all(dtg_phaseFlag==2)
        phaseFlag = 2;
    else
        % hopefully this error should never occur. Otherwise it's fixable
        % but have to change the code a bit. 
        error('phase flag is inconsistent across ping records in this file.')
    end
    
    % record phase data, if available
    if phaseFlag
        
        % two different formats for raw phase, depending on the value of
        % the flag. Keep the same for storage 
        if phaseFlag==1
            phaseFormat = 'int8';
            phaseFactor = 180./128;
        else
            phaseFormat = 'int16';
            phaseFactor = 0.01;
        end
        phaseNanValue = intmin(phaseFormat);
        
        % initialize data-holding binary files for Phase
        fData = CFF_init_memmapfiles(fData, ...
            'field', 'WC_SBP_SamplePhase', ...
            'wc_dir', wc_dir, ...
            'Class', phaseFormat, ...
            'Factor', phaseFactor, ...
            'Nanval', phaseNanValue, ...
            'Offset', 0, ...
            'MaxSamples', maxnSamples_groups, ...
            'MaxBeams', maxnBeams_sub, ...
            'ping_group_start', ping_group_start, ...
            'ping_group_end', ping_group_end);
        
    end
    
    % Also the samples data were not recorded, only their location in the
    % source file, so we need to fopen the source file to grab the data.
    fid = fopen(KMWCDfilename,'r','l');
    
    % debug graph
    debugDisp = 0;
    if debugDisp
        f = figure();
        if ~phaseFlag
            ax_mag = axes(f,'outerposition',[0 0 1 1]);
            title('WCD amplitude');
        else
            ax_mag = axes(f,'outerposition',[0 0.5 1 0.5]);
            title('WCD amplitude');
            ax_phase = axes(f,'outerposition',[0 0 1 0.5]);
            title('WCD phase');
        end
    end
    
    % initialize ping group number
    iG = 1;
    
    % now get data for each swath...
    for iS = 1:nSwaths
        
        % ping group number is the index of the memmaped file in which that
        % swath's data will be saved. 
        if iS > ping_group_end(iG)
            iG = iG+1;
        end
        
        % (re-)initialize amplitude and phase arrays for that swath
        Mag_tmp = intmin('int8').*ones(maxnSamples_groups(iG),maxnBeams_sub,'int8');
        if phaseFlag
            Ph_tmp = phaseNanValue.*ones(maxnSamples_groups(iG),maxnBeams_sub,phaseFormat);
        end
        
        % data for one swath can be spread over several datagrams,
        % typically when using dual Rx systems, so we're going to loop over
        % all datagrams to grab this swath's entire data 
        dtg_iS = find(iC==iS); % indices of datagrams for that swath
        nB_tot = 0; % initialize total number of beams recorded so far for that swath
        iB_src_start = 1; % index of first beam to read in a datagram, start with 1 and to be updated later
        
        % in each datagram...
        for iD = 1:numel(dtg_iS)
            
            % beamData_p for this datagram
            BD = EMdgmMWC(dtg_iS(iD)).beamData_p;
            
            % important variables for data to grab
            nRx = numel(BD.beamPointAngReVertical_deg); % total number of beams in this datagram
            iB_src = iB_src_start:db_sub:nRx; % indices of beams to read in this datagram
            nB = numel(iB_src); % number of beams to record from this datagram
            iB_dst = nB_tot + (1:nB); % indices of those beams in output arrays
            
            % data per beam
            fData.WC_BP_BeamPointingAngle(iB_dst,iS)      = BD.beamPointAngReVertical_deg(iB_src);
            fData.WC_BP_StartRangeSampleNumber(iB_dst,iS) = BD.startRangeSampleNum(iB_src);
            fData.WC_BP_NumberOfSamples(iB_dst,iS)        = BD.numSampleData(iB_src);
            fData.WC_BP_DetectedRangeInSamples(iB_dst,iS) = BD.detectedRangeInSamplesHighResolution(iB_src);
            
            % in each beam...
            for iB = 1:nB
                
                % data size
                sR = BD.startRangeSampleNum(iB_src(iB)); % start range sample number
                nS = BD.numSampleData(iB_src(iB)); % number of samples in this beam
                
                % continue only if data is valid
                if ~isnan(sR) && ~isnan(nS)
                    % number of samples we're going to record
                    nS_sub = ceil(nS/dr_sub); 
                    
                    % get to start of amplitude block
                    dpif = BD.sampleDataPositionInFile(iB_src(iB));
                    fseek(fid,dpif,-1);
                    
                    % amplitude block is nS records of 1 byte each.
                    Mag_tmp(sR+1:sR+nS_sub,iB_dst(iB)) = fread(fid, nS_sub, 'int8=>int8',dr_sub-1); % read with decimation
                    
                    if phaseFlag
                        % go to start of phase block
                        fseek(fid,dpif+nS,-1);
                        
                        if phaseFlag == 1
                            % phase block is nS records of 1 byte each.
                            Ph_tmp(sR+1:sR+nS_sub,iB_dst(iB)) = fread(fid, nS_sub, 'int8=>int8',dr_sub-1); % read with decimation
                        else
                            % phase block is nS records of 2 bytes each. XXX1
                            % case not tested yet. Find suitable data files
                            Ph_tmp(sR+1:sR+nS_sub,iB_dst(iB)) = fread(fid, nS_sub, 'int16=>int16',2*dr_sub-2); % read with decimation
                        end
                    end
                end
                
            end
            
            % update variables before reading next datagram, if necessary
            nB_tot = nB_tot + nB; % total number of beams recorded so far for this swath
            iB_src_start = iB_src(end) - nRx + db_sub; % index of first beam to read in next datagram
            
        end
        
        % debug graph
        if debugDisp
            % display amplitude
            imagesc(ax_mag,double(Mag_tmp)./2);
            colorbar(ax_mag)
            title(ax_mag, sprintf('Ping %i/%i, WCD amplitude',iS,nSwaths));
            % display phase
            if phaseFlag
                imagesc(ax_phase,double(Ph_tmp).*phaseFactor);
                colorbar(ax_phase)
                title(ax_phase, 'WCD phase');
            end
            drawnow;
        end
        
        % finished reading this swath's WC data. Store the data in the
        % appropriate binary file, at the appropriate ping, through the
        % memory mapping    
        fData.WC_SBP_SampleAmplitudes{iG}.Data.val(:,:,iS-ping_group_start(iG)+1) = Mag_tmp;
        if phaseFlag
            fData.WC_SBP_SamplePhase{iG}.Data.val(:,:,iS-ping_group_start(iG)+1) = Ph_tmp;
        end
        
    end
    
    % close the original raw file
    fclose(fid);
    
end

% progress message
comms.progress(4,5);


%% fData.Ru_ (runtime parameters)
% DEV NOTE: A bit complicated as SOME runtime parameters are in #IOP
% datagrams (the "user set" parameters, which we want to log to track
% undesirable change in parameters, i.e. for Iskaffe), and SOME runtime
% parameters are in #MRZ datagrams (the parameters for processing, such as
% the receive beamwidth, needed for echo footprint computation, and the
% transmit power re. maximum, needed for BS level correction).
%
% To make matters worse, the #IOP and #MRZ datagrams are not in sync, aka
% their time stamps are not strictly comparable. See email from Torgrim (24
% Jul 2023):
%  Hi
%  The MRZ and IIP/IOP are not in sync.
%  At start of logging (pinging started already) it will log incoming data
%  to file and send a request to the PU for Installation and Runtime
%  datagrams, then these datagrams are put to the start of the file. The
%  IIP is valid as this cannot change while pinging, but the Runtime can in
%  theory be different. 
%  During the line, the Runtime datagram is sent as a response to incoming
%  data and not actually when it is used, so depending on pingrate it might
%  be 0-2 pings delayed in MRZ compared to IOP. And it is time not sequence
%  in file. 
%  To be sure of pulse length/frequency etc you must see in the MRZ
%  datagram.
%
%  The implications are that:
%  1. The first #IOP datagram at the beggining of the file applies already
%  to the very first #MRZ, even if its time predates this first #IOP
%  datagram.
%  2. Any change in runtime parameters during file recording will be logged
%  first in #MRZ data and then later as a new #IOP datagram. We would need
%  to match parameter change instead of time. Not ideal.
if isfield(KMALLdata,'EMdgmIOP') && isfield(KMALLdata,'EMdgmMRZ')
    comms.step('Parsing runtime parameters from #IOP and #MRZ datagrams');
    
    % first, read the info from #MRZ
    clear RuParFromMRZ
    % read time info
    RuParFromMRZ.time = CFF_getKM(KMALLdata,'EMdgmMRZ',[],'header',[],'time_sec') ...
        + CFF_getKM(KMALLdata,'EMdgmMRZ',[],'header',[],'time_nanosec').*10^-9;
    % read parameters
    parFieldnamesIn = {'receiveArraySizeUsed_deg','transmitPower_dB'};
    parFieldnamesOut = {'ReceiveBeamwidth','TransmitPowerReMaximum'};
    for iP = 1:numel(parFieldnamesIn)
        RuParFromMRZ.(parFieldnamesOut{iP}) = CFF_getKM(KMALLdata,'EMdgmMRZ',[],'pingInfo',[],parFieldnamesIn{iP});
    end
    % sort by time
    [~,I] = sort(RuParFromMRZ.time);
    fnames = fieldnames(RuParFromMRZ);
    for ifn = 1:numel(fnames)
        val = RuParFromMRZ.(fnames{ifn});
        RuParFromMRZ.(fnames{ifn}) = val(I);
    end
    % remove datagrams where no changes occur
    if numel(RuParFromMRZ.time)>1
        fnames = setdiff(fnames,'time');
        iNoChange = nan(numel(fnames),numel(RuParFromMRZ.time)); % matrix of indices where no change occured, per field
        for ifn = 1:numel(fnames)
            iNoChange(ifn,:) = [false,RuParFromMRZ.(fnames{ifn})(2:end)==RuParFromMRZ.(fnames{ifn})(1:end-1)];
        end
        iToRemove = all(iNoChange,1);
        RuParFromMRZ.time(iToRemove) = [];
        for ifn = 1:numel(fnames)
            RuParFromMRZ.(fnames{ifn})(iToRemove) = [];
        end
    end
    
    % second, read the info from #IOP
    clear RuParFromIOP
    % read parameters
    RuParFromIOP = CFF_decode_IOP(KMALLdata.EMdgmIOP);
    % read time info
    RuParFromIOP.time = CFF_getKM(KMALLdata,'EMdgmIOP',[],'header',[],'time_sec') ...
        + CFF_getKM(KMALLdata,'EMdgmIOP',[],'header',[],'time_nanosec').*10^-9;
    % sort by time
    [~,I] = sort(RuParFromIOP.time);
    fnames = fieldnames(RuParFromIOP);
    for ifn = 1:numel(fnames)
        val = RuParFromIOP.(fnames{ifn});
        RuParFromIOP.(fnames{ifn}) = val(I);
    end
    % remove datagrams where no change occured (except time)
    if numel(RuParFromIOP.time)>1
        fnames = setdiff(fnames,'time');
        iNoChange = nan(numel(fnames),numel(RuParFromIOP.time)); % matrix of indices where no change occured, per field
        for ifn = 1:numel(fnames)
            iNoChange(ifn,:) = [false,RuParFromIOP.(fnames{ifn})(2:end)==RuParFromIOP.(fnames{ifn})(1:end-1)];
        end
        iToRemove = all(iNoChange,1);
        RuParFromIOP.time(iToRemove) = [];
        for ifn = 1:numel(fnames)
            RuParFromIOP.(fnames{ifn})(iToRemove) = [];
        end
    end
    % set first #IOP time to zero as it applies from first ping onwards
    RuParFromIOP.time(1) = 0;
    
    % third, merge them
    clear RuParBoth
    % stack them to start
    RuParBoth.time = [RuParFromIOP.time, RuParFromMRZ.time];
    fnames = setdiff(fieldnames(RuParFromIOP),'time');
    for ifn = 1:numel(fnames)
        RuParBoth.(fnames{ifn}) = [RuParFromIOP.(fnames{ifn}), repmat(categorical({''}),size(RuParFromMRZ.time))];
    end
    fnames = setdiff(fieldnames(RuParFromMRZ),'time');
    for ifn = 1:numel(fnames)
        RuParBoth.(fnames{ifn}) = [nan(size(RuParFromIOP.time)), RuParFromMRZ.(fnames{ifn})];
    end
    % sort by time
    [~,I] = sort(RuParBoth.time);
    fnames = fieldnames(RuParBoth);
    for ifn = 1:numel(fnames)
        val = RuParBoth.(fnames{ifn});
        RuParBoth.(fnames{ifn}) = val(I);
    end
    % datagram by datagram, if a field is undefined/nan, copy last value
    nD = numel(RuParBoth.time);
    fnames = setdiff(fieldnames(RuParBoth),'time');
    for ifn = 1:numel(fnames)
        if iscategorical(RuParBoth.(fnames{ifn}))
            for iD = 2:nD
                if isundefined(RuParBoth.(fnames{ifn})(iD))
                    RuParBoth.(fnames{ifn})(iD) = RuParBoth.(fnames{ifn})(iD-1);
                end
            end
        elseif isnumeric(RuParBoth.(fnames{ifn}))
            for iD = 2:nD
                if isnan(RuParBoth.(fnames{ifn})(iD))
                    RuParBoth.(fnames{ifn})(iD) = RuParBoth.(fnames{ifn})(iD-1);
                end
            end
        end
    end
    % remove the first entry, corresponding to time "zero", since all the
    % values are copied to the next one anyway 
    fnames = fieldnames(RuParBoth);
    for ifn = 1:numel(fnames)
        RuParBoth.(fnames{ifn})(1) = [];
    end
    
    % finally, save back in fData
    % date and time
    dt = datetime(RuParBoth.time,'ConvertFrom','posixtime');
    fData.Ru_1D_Date = convertTo(dt,'yyyymmdd');
    fData.Ru_1D_TimeSinceMidnightInMilliseconds = milliseconds(timeofday(dt));
    % match ping counter - for each Ru datagram time, find index of swathe
    % in X8_ which time immediately follows 
    RuDatetime =  CFF_all_time_to_datetime(fData.Ru_1D_Date,fData.Ru_1D_TimeSinceMidnightInMilliseconds);
    X8Datetime =  CFF_all_time_to_datetime(fData.X8_1P_Date,fData.X8_1P_TimeSinceMidnightInMilliseconds);
    timeVecDiff = RuDatetime-X8Datetime';
    timeVecDiff(timeVecDiff>0) = NaN;
    [~,iSw] = max(timeVecDiff,[],1,'omitnan');
    fData.Ru_1D_PingCounter = fData.X8_1P_PingCounter(iSw);
    % add all parameters
    fnames = setdiff(fieldnames(RuParBoth),'time');
    for ifn = 1:numel(fnames)
        newField = ['Ru_1D_' fnames{ifn}];
        fData.(newField) = RuParBoth.(fnames{ifn});
    end
    
end

%% end message
comms.progress(5,5);
comms.finish('Done');

end




% DEV NOTE: I have found occurences of duplicate MRZ datagrams in some test
% files. Not sure how common it is, but if doing nothing, the conversion
% code ends up duplicating the data too.
% Instead of modifying the code everywhere to be always considering the
% possibility of duplicates, it's easier to look for them at the start and
% remove them before parsing.
% In the examples I found, it would be sufficient to check for the set
% unicity of the cmnPart fields pingCnt, rxFanIndex, and
% swathAlongPosition. But the range of cases covered by the kmall format
% can be complicated (including systems with dual Rx heads and dual Tx
% heads in multi-swath mode!!! see documentation of EMdgmMbody_def) so to
% be entierely safe, we will instead use ALL the fields of cmnPart in a
% test for set unicity.
function [outEMstruct,nDuplicates] = CFF_remove_duplicate_KMALL_datagrams(inEMstruct)

nDuplicates = 0;

if isfield(inEMstruct, 'cmnPart')
    
    % fidn duplicates
    cmnPartTable = struct2table([inEMstruct.cmnPart]);
    [~, ia, ~] = unique(cmnPartTable,'rows', 'stable');
    idxDuplicates = ~ismember(1:size(cmnPartTable,1), ia);
    
    % remove duplicates
    outEMstruct = inEMstruct(~idxDuplicates);
    nDuplicates = sum(idxDuplicates);
    
else
    outEMstruct = inEMstruct;
end

end


%%
function out_struct = CFF_read_TRAI(ASCIIdata, TRAI_code)

out_struct = struct;

[iS,iE] = regexp(ASCIIdata,[TRAI_code ':.+?,']);

if isempty(iS)
    % no match, exit
    return
end

TRAI_TX1_ASCII = ASCIIdata(iS+9:iE-1);

yo(:,1) = [1; strfind(TRAI_TX1_ASCII,';')'+1]; % beginning of ASCII field name
yo(:,2) = strfind(TRAI_TX1_ASCII,'=')'-1; % end of ASCII field name
yo(:,3) = strfind(TRAI_TX1_ASCII,'=')'+1; % beginning of ASCII field value
yo(:,4) = [strfind(TRAI_TX1_ASCII,';')'-1;length(TRAI_TX1_ASCII)]; % end of ASCII field value

for ii = 1:size(yo,1)
    
    % get field string
    field = TRAI_TX1_ASCII(yo(ii,1):yo(ii,2));
    
    % try turn value into numeric
    value = str2double(TRAI_TX1_ASCII(yo(ii,3):yo(ii,4)));
    if length(value)~=1
        % looks like it cant. Keep as string
        value = TRAI_TX1_ASCII(yo(ii,3):yo(ii,4));
    end
    
    % store field/value
    out_struct.(field) = value;
    
end

end


%%
function str = CFF_get_kmall_TxRx_info(cmnPart)

% Single or Dual Tx
iTx = unique([cmnPart.txTransducerInd]);
if numel(iTx)==1 && iTx==0
    str = 'Single Tx, ';
elseif numel(iTx)==2 && all(iTx==[0,1])
    str = 'Dual Tx, ';
else
    str = '??? Tx, ';
end

% Single or Dual Rx
iRx = unique([cmnPart.numRxTransducers]);
iRx2 = unique([cmnPart.rxTransducerInd]);
if numel(iRx)==1 && iRx==1
    % should be single
    if numel(iRx2)==1 && iRx2==0
        % confirmed
        str = [str, 'Single Rx, '];
    else
        % unconfirmed
        str = [str, '??? Rx, '];
    end
elseif numel(iRx)==1 && iRx==2
    % should be dual
    if numel(iRx2)==2 && all(iRx2==[0,1])
        % confirmed
        str = [str, 'Dual Rx, '];
    else
        % unconfirmed
        str = [str, '??? Rx, '];
    end
else
    str = [str, '??? Rx, '];
end

% Single or Multi Swath
iSw = unique([cmnPart.swathsPerPing]);
iSw2 = unique([cmnPart.swathAlongPosition]);
if numel(iSw)==1 && iSw==1
    % should be single
    if numel(iSw2)==1 && iSw2==0
        % confirmed
        str = [str, 'Single Swath.'];
    else
        % unconfirmed
        str = [str, '??? Swath.'];
    end
elseif numel(iSw)==1 && iSw==2
    % should be dual
    if numel(iSw2)==2 && all(iSw2==[0,1])
        % confirmed
        str = [str, 'Dual Swath.'];
    else
        % unconfirmed
        str = [str, '??? Swath.'];
    end
elseif numel(iSw)==1 && iSw>2
    % should be multi (more than 2)
    if numel(iSw2)==iSw && all(iSw2==[0:iSw-1])
        % confirmed
        str = [str, sprintf('Multi Swath (%i).',iSw)];
    else
        % unconfirmed
        str = [str, '??? Swath.'];
    end
else
    str = [str, '??? Swath.'];
end

end