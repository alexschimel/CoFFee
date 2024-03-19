function out_struct = CFF_read_EMdgmMWC(fid, dgmVersion_warning_flag)
%CFF_READ_EMDGMMWC  Read kmall structure #MWC
%
%   #MWC - Multibeam Water Column Datagram. Entire datagram containing
%   several sub structs.
%
%   Verified correct for kmall format revisions F-I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

pifStartOfDatagram = ftell(fid);
out_struct.header = CFF_read_EMdgmHeader(fid);
pifEndOfDatagram = pifStartOfDatagram + out_struct.header.numBytesDgm + 4;

MWC_VERSION = out_struct.header.dgmVersion;
if MWC_VERSION>2 && dgmVersion_warning_flag
    % definitions in this function and subfunctions valid for MWC_VERSION:
    % 0 (kmall format revision F, and presumably earlier ones?)
    % 1 (kmall format revision G-H)
    % 2 (kmall format revision I)
    warning('#MWC datagram version (%i) unsupported. Continue reading but there may be issues.',MWC_VERSION);
end

out_struct.partition = CFF_read_EMdgmMpartition(fid);
out_struct.cmnPart   = CFF_read_EMdgmMbody(fid);
out_struct.txInfo    = CFF_read_EMdgmMWCtxInfo(fid);

Ntx = out_struct.txInfo.numTxSectors;
for iTx = 1:Ntx
    out_struct.sectorData(iTx) = CFF_read_EMdgmMWCtxSectorData(fid);
end

out_struct.rxInfo = CFF_read_EMdgmMWCrxInfo(fid);

% Pointer to beam related information. Struct defines information about
% data for a beam. Beam information is followed by sample amplitudes in
% 0.5 dB resolution . Amplitude array is followed by phase information
% if phaseFlag >0. These data defined by struct
% EMdgmMWCrxBeamPhase1_def (int8_t) or struct EMdgmMWCrxBeamPhase2_def
% (int16_t) if indicated in the field phaseFlag in struct
% EMdgmMWCrxInfo_def.
% Lenght of data block for each beam depends on the operators choise of
% phase information (see table).
% phaseFlag 	Beam block size
% 0             numBytesPerBeamEntry + numSampleData* size(sampleAmplitude05dB_p)
% 1             numBytesPerBeamEntry + numSampleData* size(sampleAmplitude05dB_p) + numSampleData* size(EMdgmMWCrxBeamPhase1_def)
% 2             numBytesPerBeamEntry + numSampleData* size(sampleAmplitude05dB_p) + numSampleData* size(EMdgmMWCrxBeamPhase2_def)
phaseFlag = out_struct.rxInfo.phaseFlag;
Nrx = out_struct.rxInfo.numBeams;
out_struct.beamData_p = CFF_read_EMdgmMWCrxBeamData(fid, phaseFlag, Nrx, MWC_VERSION, pifEndOfDatagram);

end


function out_struct = CFF_read_EMdgmMWCtxInfo(fid)
% #MWC - data block 1: transmit sectors, general info for all sectors
%
% Verified correct for kmall format revisions F-I

% Number of bytes in current struct.
out_struct.numBytesTxInfo = fread(fid,1,'uint16');

% Number of transmitting sectors (Ntx). Denotes the number of times the
% struct EMdgmMWCtxSectorData is repeated in the datagram.
out_struct.numTxSectors = fread(fid,1,'uint16');

% Number of bytes in EMdgmMWCtxSectorData.
out_struct.numBytesPerTxSector = fread(fid,1,'uint16');

% Byte alignment.
out_struct.padding = fread(fid,1,'int16');

% Heave at vessel reference point, at time of ping, i.e. at midpoint of
% first tx pulse in rxfan.
out_struct.heave_m = fread(fid,1,'float');

end


function out_struct = CFF_read_EMdgmMWCtxSectorData(fid)
% #MWC - data block 1: transmit sector data, loop for all i = numTxSectors.
%
% Verified correct for kmall format revisions F-I

% Along ship steering angle of the TX beam (main lobe of transmitted
% pulse), angle referred to transducer face. Angle as used by beamformer
% (includes stabilisation). Unit degree.
out_struct.tiltAngleReTx_deg = fread(fid,1,'float');

% Centre frequency of current sector. Unit hertz.
out_struct.centreFreq_Hz = fread(fid,1,'float');

% Corrected for frequency, sound velocity and tilt angle. Unit degree.
out_struct.txBeamWidthAlong_deg = fread(fid,1,'float');

% Transmitting sector number.
out_struct.txSectorNum = fread(fid,1,'uint16');

% Byte alignment.
out_struct.padding = fread(fid,1,'int16');

end


function out_struct = CFF_read_EMdgmMWCrxInfo(fid)
% #MWC - data block 2: receiver, general info
%
% Verified correct for kmall format revisions F-I

% Number of bytes in current struct.
out_struct.numBytesRxInfo = fread(fid,1,'uint16');

% Number of beams in this datagram (Nrx).
out_struct.numBeams = fread(fid,1,'uint16');

% Bytes in EMdgmMWCrxBeamData struct, excluding sample amplitudes (which
% have varying lengths)
out_struct.numBytesPerBeamEntry = fread(fid,1,'uint8');

% 0 = off
% 1 = low resolution
% 2 = high resolution
out_struct.phaseFlag = fread(fid,1,'uint8');

% Time Varying Gain function applied (X). X log R + 2 Alpha R + OFS + C,
% where X and C is documented in #MWC datagram. OFS is gain offset to
% compensate for TX source level, receiver sensitivity etc.
out_struct.TVGfunctionApplied = fread(fid,1,'uint8');

% Time Varying Gain offset used (OFS), unit dB. X log R + 2 Alpha R + OFS +
% C, where X and C is documented in #MWC datagram. OFS is gain offset to
% compensate for TX source level, receiver sensitivity etc.
out_struct.TVGoffset_dB = fread(fid,1,'int8');

% The sample rate is normally decimated to be approximately the same as the
% bandwidth of the transmitted pulse. Unit hertz.
out_struct.sampleFreq_Hz = fread(fid,1,'float');

% Sound speed at transducer, unit m/s.
out_struct.soundVelocity_mPerSec = fread(fid,1,'float');

end


function out_struct = CFF_read_EMdgmMWCrxBeamData(fid, phaseFlag, Nrx, MWC_VERSION, pifEndOfDatagram)
% #MWC - data block 2: receiver, specific info for each beam.
%
% Verified correct for kmall format revisions F-I

% initialize output array
out_struct = struct(...
    'beamPointAngReVertical_deg',nan(1,Nrx),...
    'startRangeSampleNum',nan(1,Nrx),...
    'detectedRangeInSamples',nan(1,Nrx),...
    'beamTxSectorNum',nan(1,Nrx),...
    'numSampleData',nan(1,Nrx),...
    'detectedRangeInSamplesHighResolution',nan(1,Nrx),...
    'sampleDataPositionInFile',nan(1,Nrx));

for iRx = 1:Nrx
    
    out_struct.beamPointAngReVertical_deg(iRx) = fread(fid,1,'float');
    
    out_struct.startRangeSampleNum(iRx) = fread(fid,1,'uint16');
    
    % Two way range in samples. Approximation to calculated distance from
    % tx to bottom detection [meters] = soundVelocity_mPerSec *
    % detectedRangeInSamples / (sampleFreq_Hz * 2). The detected range is
    % set to zero when the beam has no bottom detection. Replaced by
    % detectedRangeInSamplesHighResolution for higher precision.
    out_struct.detectedRangeInSamples(iRx) = fread(fid,1,'uint16');
    
    out_struct.beamTxSectorNum(iRx) = fread(fid,1,'uint16');
    
    % Number of sample data for current beam. Also denoted Ns.
    out_struct.numSampleData(iRx) = fread(fid,1,'uint16');
    
    if MWC_VERSION >= 1
        % The same information as in detectedRangeInSamples with higher
        % resolution. Two way range in samples. Approximation to calculated
        % distance from tx to bottom detection [meters] = soundVelocity_mPerSec
        % * detectedRangeInSamples / (sampleFreq_Hz * 2). The detected range is
        % set to zero when the beam has no bottom detection.
        out_struct.detectedRangeInSamplesHighResolution(iRx) = fread(fid,1,'float');
    end
    
    % ------------------ OPTION 1: ACTUALLY READ DATA ---------------------
    %
    % % Pointer to start of array with Water Column data. Lenght of array =
    % % numSampleData. Sample amplitudes in 0.5 dB resolution. Size of
    % % array is numSampleData * int8_t. Amplitude array is followed by
    % % phase information if phaseFlag >0. Use (numSampleData * int8_t) to
    % % jump to next beam, or to start of phase info for this beam, if
    % % phase flag > 0.
    % out_struct.sampleAmplitude05dB_p = fread(fid,Ns,'int8');
    %
    % switch phaseFlag
    %     % #MWC - Beam sample phase info, specific for each beam and water
    %     % column sample. numBeams * numSampleData = (Nrx * Ns) entries.
    %     case 1
    %         % Only added to datagram if phaseFlag = 1. Total size of
    %         % phase block is numSampleData * int8_t.
    %
    %         % Rx beam phase in 180/128 degree resolution.
    %         out_struct.rxBeamPhase = fread(fid,Ns,'int8');
    %
    %     case 2
    %         % Only added to datagram if phaseFlag = 2. Total size of
    %         % phase block is numSampleData * int16_t.
    %
    %         % Rx beam phase in 0.01 degree resolution.
    %         out_struct.rxBeamPhase = fread(fid,Ns,'int16');
    %
    % end
    %
    % ------------------ END OF OPTION 1 ----------------------------------
    
    
    % ------------------ OPTION 2: SAVING POSITION IN FILE ----------------
    % instead of reading file as above, we save the position in file for
    % later reading.
    pif = ftell(fid);
    out_struct.sampleDataPositionInFile(iRx) = pif;
    
    % we still need to fast-forward to the end of the data section so that
    % reading can continue from there in the next loop iteration. 
    % BUT we first have a quick check gainst corruption, namely we check that 
    % the expected data block will not offshot the expected datagram size.
    Ns = out_struct.numSampleData(iRx);
    dataBlockSizeInBytes = Ns.*(1+phaseFlag);
    if pifEndOfDatagram-(pif+dataBlockSizeInBytes) >= 0
        fseek(fid,dataBlockSizeInBytes,0);
    else
        % datagram is corrupted. Exit here or we will run into errors at some
        % point in this loop
        return
    end
    % ------------------ END OF OPTION 2 ----------------------------------
    
end

end
