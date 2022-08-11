function KMALLdata = CFF_read_kmall_from_fileinfo(KMALLfilename,KMALLfileinfo,varargin)
%CFF_READ_KMALL_FROM_FILEINFO  Read contents of kmall file
%
%   Reads contents of one Kongsberg EM series binary data file in .kmall
%   format (.kmall or .kmwcd), using KMALLfileinfo to indicate which
%   datagrams to be parsed. 
%
%   KMALLdata = CFF_READ_KMALL_FROM_FILEINFO(KMALLfilename, KMALLfileinfo)
%   reads all datagrams in KMALLfilename for which KMALLfileinfo.parsed
%   equals 1, and store them in KMALLdata.
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021

global DEBUG;


%% HARD-CODED PARAMETERS

% This code was developped around the following kmall format revisions. To
% update if you verify it works with other revisions.
kmallRevSupported = 'F,H,I';


%% Input arguments management
p = inputParser;

% name of the .kmall or .kmwcd file
argName = 'KMALLfilename';
argCheck = @(x) CFF_check_KMALLfilename(x);
addRequired(p,argName,argCheck);

% fileinfo from CFF_KMALL_FILE_INFO containing indexes of datagrams to read
argName = 'KMALLfileinfo';
argCheck = @isstruct;
addRequired(p,argName,argCheck);

% ?? XXX3
argName = 'OutputFields';
argCheck = @iscell;
addParameter(p,argName,{},argCheck);

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,KMALLfilename,KMALLfileinfo,varargin{:});

% and get results
KMALLfilename = p.Results.KMALLfilename;
KMALLfileinfo = p.Results.KMALLfileinfo;
OutputFields = p.Results.OutputFields;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end


%% Prep

% start message
filename = CFF_file_name(KMALLfilename,1);
comms.start(sprintf('Reading datagrams in file %s',filename));

% store filename
KMALLdata.KMALLfilename = KMALLfilename;

% open file
[fid,~] = fopen(KMALLfilename, 'r');

% parse only datagrams indicated in KMALLfileinfo
datagToParse = find(KMALLfileinfo.parsed==1);
nDatagsToPars = numel(datagToParse);

% flag so kmall revision warning only goes off once
kmallRevWarningFlag = 0;

% start progress
comms.progress(0,nDatagsToPars);


%% Reading datagrams
for iDatag = datagToParse'
    
    % A full kmall datagram is organized as a sequence of:
    % * GH - General Header EMdgmHeader (20 bytes, at least for Rev H)
    % * DB - Datagram Body (variable size)
    % * DS - Datagram size (uint32, aka 4 bytes)
    %
    % The General Header was read and stored in fileinfo. Here we read the
    % datagram body only
    %
    % Relevant info from the general header
    dgm_type_code = KMALLfileinfo.dgm_type_code{iDatag}(2:end);
    dgm_start_pif = KMALLfileinfo.dgm_start_pif(iDatag);
    
    % Go to start of dgm
    fseek(fid, dgm_start_pif, -1);
    
    % set/reset the parsed switch
    parsed = 0;
    
    % set/reset the datagram version warning flag
    dtg_warn_flag = 0;
    
    switch dgm_type_code
        
        
        %% --------- INSTALLATION AND RUNTIME DATAGRAMS (I..) -------------
        
        case 'IIP'
            % '#IIP - Installation parameters and sensor setup'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iIIP=iIIP+1; catch, iIIP=1; dtg_warn_flag = 1; end
             
            KMALLdata.EMdgmIIP(iIIP) = CFF_read_EMdgmIIP(fid, dtg_warn_flag);
            
            % extract and check kmall revision
            kmallRev = CFF_get_kmall_revision(KMALLdata.EMdgmIIP(iIIP));
            if ~ismember(kmallRev, kmallRevSupported) && ~kmallRevWarningFlag
                errStr = sprintf('This file''s kmall format revision (%s) is different to that used to develop the raw data reading code (%s). Data will be read anyway, but there may be issues',kmallRev,kmallRevSupported);
                comms.error(errStr);
                kmallRevWarningFlag = 1;
            end
            
            parsed = 1;
            
        case 'IOP'
            % '#IOP - Runtime parameters as chosen by operator'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iIOP=iIOP+1; catch, iIOP=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmIOP(iIOP) = CFF_read_EMdgmIOP(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'IBE'
            % '#IBE - Built in test (BIST) error report'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iIBE=iIBE+1; catch, iIBE=1; dtg_warn_flag = 1; end
            
            % to do maybe one day... XXX3
            % KMALLdata.EMdgmIBE(iIBE) = CFF_read_EMdgmIBE(fid, dtg_warn_flag);
            
            parsed = 0;
            
        case 'IBR'
            % '#IBR - Built in test (BIST) reply'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iIBR=iIBR+1; catch, iIBR=1; dtg_warn_flag = 1; end
            
            % to do maybe one day... XXX3
            % KMALLdata.EMdgmIBR(iIBR) = CFF_read_EMdgmIBR(fid, dtg_warn_flag);
            
            parsed = 0;
            
        case 'IBS' 
            % '#IBS - Built in test (BIST) short reply'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iIBS=iIBS+1; catch, iIBS=1; dtg_warn_flag = 1; end
            
            % to do maybe one day... XXX3
            % KMALLdata.EMdgmIBS(iIBS) = CFF_read_EMdgmIBS(fid, dtg_warn_flag);
            
            parsed = 0;
            
          
        %% ------------------ MULTIBEAM DATAGRAMS (M..) -------------------
      
        case 'MRZ'
            % '#MRZ - Multibeam (M) raw range (R) and depth(Z) datagram'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iMRZ=iMRZ+1; catch, iMRZ=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmMRZ(iMRZ) = CFF_read_EMdgmMRZ(fid, dtg_warn_flag);
            
            parsed = 1;
            
            if DEBUG
                
                % create or grab and clear figure
                try
                    figure(f_MRZ);
                    clf
                catch
                    f_MRZ = figure();
                end
                
                num_beams = KMALLdata.EMdgmMRZ(iMRZ).rxInfo.numSoundingsMaxMain ...
                    +  KMALLdata.EMdgmMRZ(iMRZ).rxInfo.numExtraDetections;
                
                % detection info
                subplot(221);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.qualityFactor]);
                hold on
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.detectionUncertaintyVer_m]);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.detectionUncertaintyHor_m]);
                xlabel('beam number')
                legend('Ifremer quality fact.', 'Vert. uncert. (m)', 'Horz. uncert. (m)');
                title(sprintf('%s\n#MRZ datagram #%i contents\nDetection info', CFF_file_name(KMALLdata.KMALLfilename,1),iMRZ),'Interpreter','none');
                grid on
                xlim([1 num_beams])
                
                % reflectivity data
                subplot(222);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.reflectivity1_dB]);
                hold on
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.reflectivity2_dB]);
                xlabel('beam number')
                legend('Refl. 1 (dB)', 'Refl. 2 (dB)');
                title('Reflectivity data')
                grid on
                xlim([1 num_beams])
                
                % range and angle
                subplot(223);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.beamAngleReRx_deg], ...
                    [KMALLdata.EMdgmMRZ(iMRZ).sounding.twoWayTravelTime_sec],'.');
                xlabel('beam angle re. Rx (deg)')
                ylabel('two-way travel time (s)')
                set(gca, 'YDir','reverse');
                title('Range and angle')
                grid on
                
                % georeferenced depth points
                subplot(224);
                plot([KMALLdata.EMdgmMRZ(iMRZ).sounding.y_reRefPoint_m], ...
                    [KMALLdata.EMdgmMRZ(iMRZ).sounding.z_reRefPoint_m],'.');
                xlabel('Horz. dist y (m)')
                ylabel('Vert. dist z (m)')
                set(gca, 'YDir','reverse')
                title('Georeferenced depth points')
                axis equal
                grid on
                
                drawnow;
            end
            
        case 'MWC'
            % '#MWC - Multibeam (M) water (W) column (C) datagram'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iMWC=iMWC+1; catch, iMWC=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmMWC(iMWC) = CFF_read_EMdgmMWC(fid, dtg_warn_flag);
            
            parsed = 1;
            
            if DEBUG
                
                % save pif
                pif_save = ftell(fid);
                
                % get water-column amplitude for this ping (and phase if it
                % exists)
                max_samples = max([KMALLdata.EMdgmMWC(iMWC).beamData_p.startRangeSampleNum] ...
                    + [KMALLdata.EMdgmMWC(iMWC).beamData_p.numSampleData]);
                nBeams = KMALLdata.EMdgmMWC(iMWC).rxInfo.numBeams;
                Mag_tmp = nan(max_samples, nBeams);
                Ph_tmp = nan(max_samples, nBeams);
                phaseFlag = KMALLdata.EMdgmMWC(iMWC).rxInfo.phaseFlag;
                for iB = 1:nBeams
                    dpif = KMALLdata.EMdgmMWC(iMWC).beamData_p.sampleDataPositionInFile(iB);
                    fseek(fid,dpif,-1);
                    sR = KMALLdata.EMdgmMWC(iMWC).beamData_p.startRangeSampleNum(iB);
                    nS = KMALLdata.EMdgmMWC(iMWC).beamData_p.numSampleData(iB);
                    if phaseFlag == 0
                        % Only nS records of amplitude of 1 byte
                        Mag_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',0);
                    elseif phaseFlag == 1
                        % nS records of amplitude of 1 byte alternated with nS
                        % records of phase of 1 byte
                        Mag_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',1);
                        fseek(fid,dpif+1,-1); % rewind to after the first amplitude record
                        Ph_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',1);
                    else
                        % XXX1 this case was not tested yet. Find data for it
                        % nS records of amplitude of 1 byte alternated with nS
                        % records of phase of 2 bytes
                        Mag_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int8=>int8',2);
                        fseek(fid,dpif+1,-1); % rewind to after the first amplitude record
                        Ph_tmp(sR+1:sR+nS,iB) = fread(fid, nS, 'int16=>int16',1);
                    end
                end
                
                % reset pif
                fseek(fid, pif_save,-1);
                
                % create or grab and clear figure
                try
                    figure(f_MWC);
                    clf
                catch
                    f_MWC = figure();
                end
               
                % plot
                if ~phaseFlag
                    % amplitude only
                    imagesc(Mag_tmp);
                    xlabel('beam number');
                    ylabel('sample number');
                    grid on; colorbar
                    title(sprintf('%s\n#MWC datagram #%i contents\nAmplitude only', CFF_file_name(KMALLdata.KMALLfilename,1), iMWC),'Interpreter','none');
                else
                    % amplitude
                    subplot(121); imagesc(Mag_tmp);
                    xlabel('beam number');
                    ylabel('sample number');
                    grid on; colorbar
                    title(sprintf('%s\n#MWC datagram #%i contents\nAmplitude', CFF_file_name(KMALLdata.KMALLfilename,1), iMWC),'Interpreter','none');
                    % phase
                    subplot(121); imagesc(Ph_tmp);
                    xlabel('beam number');
                    ylabel('sample number');
                    grid on; colorbar
                    title('Phase');
                end
                drawnow;
               
            end
            

        %% ------------------- SENSOR DATAGRAMS (S..) ---------------------

        case 'SPO'
            % '#SPO - Sensor (S) data for position (PO)'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iSPO=iSPO+1; catch, iSPO=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmSPO(iSPO) = CFF_read_EMdgmSPO(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'SKM'
            % '#SKM - Sensor (S) KM binary sensor format'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iSKM=iSKM+1; catch, iSKM=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmSKM(iSKM) = CFF_read_EMdgmSKM(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'SVP'
            % '#SVP - Sensor (S) data from sound velocity (V) profile (P) or CTD'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iSVP=iSVP+1; catch, iSVP=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmSVP(iSVP) = CFF_read_EMdgmSVP(fid, dtg_warn_flag);
            
            parsed = 1;
            
            if DEBUG
                depth    = [KMALLdata.EMdgmSVP(iSVP).sensorData.depth_m];
                velocity = [KMALLdata.EMdgmSVP(iSVP).sensorData.soundVelocity_mPerSec];
                temp     = [KMALLdata.EMdgmSVP(iSVP).sensorData.temp_C];
                salinity = [KMALLdata.EMdgmSVP(iSVP).sensorData.salinity];
                
                % create or grab and clear figure
                try
                    figure(f_SVP);
                    clf
                catch
                    f_SVP = figure();
                end
                
                % plot
                subplot(131); plot(velocity,-depth,'.-');
                ylabel('depth (m)'); xlabel('sound velocity (m/s)'); grid on
                subplot(132); plot(temp,-depth,'.-');
                ylabel('depth (m)'); xlabel('temperature (C)'); grid on
                title(sprintf('%s\n#SVP datagram #%i contents', CFF_file_name(KMALLdata.KMALLfilename,1), iSVP),'Interpreter','none');
                subplot(133); plot(salinity,-depth,'.-');
                ylabel('depth (m)'); xlabel('salinity'); grid on
                drawnow;
            end
            
        case 'SVT'
            % '#SVT - Sensor (S) data for sound velocity (V) at transducer (T)'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iSVT=iSVT+1; catch, iSVT=1; dtg_warn_flag = 1; end
            
            % to do maybe one day... XXX3
            % KMALLdata.EMdgmSVT(iSVT) = CFF_read_EMdgmSVT(fid, dtg_warn_flag);
            
            parsed = 0;
            
        case 'SCL'
            % '#SCL - Sensor (S) data from clock (CL)'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iSCL=iSCL+1; catch, iSCL=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmSCL(iSCL) = CFF_read_EMdgmSCL(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'SDE'
            % '#SDE - Sensor (S) data from depth (DE) sensor'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iSDE=iSDE+1; catch, iSDE=1; dtg_warn_flag = 1; end
            
            % to do maybe one day... XXX3
            % KMALLdata.EMdgmSDE(iSDE) = CFF_read_EMdgmSDE(fid, dtg_warn_flag);
            
            parsed = 0;
            
        case 'SHI'
            % '#SHI - Sensor (S) data for height (HI)'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iSHI=iSHI+1; catch, iSHI=1; dtg_warn_flag = 1; end
            
            % in progress...
            % KMALLdata.EMdgmSHI(iSHI) = CFF_read_EMdgmSHI(fid, dtg_warn_flag);
            
            parsed = 0;
            
            
        %% --------------- COMPATIBILITY DATAGRAMS (C..) ------------------
                    
        case 'CPO'
            % '#CPO - Compatibility (C) data for position (PO)'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iCPO=iCPO+1; catch, iCPO=1; dtg_warn_flag = 1; end
            
            KMALLdata.EMdgmCPO(iCPO) = CFF_read_EMdgmCPO(fid, dtg_warn_flag);
            
            parsed = 1;
            
        case 'CHE'
            % '#CHE - Compatibility (C) data for heave (HE)'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iCHE=iCHE+1; catch, iCHE=1; dtg_warn_flag = 1; end
           
            KMALLdata.EMdgmCHE(iCHE) = CFF_read_EMdgmCHE(fid, dtg_warn_flag);
            
            parsed = 1;
            
 
        %% --------------------- FILE DATAGRAMS (F..) ---------------------
                                           
        case '#FCF - Backscatter calibration (C) file (F) datagram'
            % 'YYY'
            if ~( isempty(OutputFields) || any(strcmp(dgm_type_code,OutputFields)) )
                continue;
            end
            try iFCF=iFCF+1; catch, iFCF=1; dtg_warn_flag = 1; end
            
            % to do maybe one day... XXX3
            % KMALLdata.EMdgmFCF(iFCF) = CFF_read_EMdgmFCF(fid, dtg_warn_flag);
            
            parsed = 0;
            
        otherwise
            % dgm_type_code not recognized. Skip.
            
            parsed = 0;
            
    end
    
    % modify parsed status in info
    KMALLfileinfo.parsed(iDatag,1) = parsed;
    
    % communicate progress
    comms.progress(iDatag,nDatagsToPars);
    
end


%% finalise

% close fid
fclose(fid);

% add info to parsed data
KMALLdata.info = KMALLfileinfo;

% end message
comms.finish('Done');

end


