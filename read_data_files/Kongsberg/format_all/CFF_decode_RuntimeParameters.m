function out = CFF_decode_RuntimeParameters(EM_Runtime)
%CFF_DECODE_RUNTIMEPARAMETERS  Read the encoded fields of Runtime Param.
%
%   Info taken from  KONGSBERG. 2022. Kongsberg EM Series Multibeam echo
%   sounders - EM datagram formats. Document 850-160692/X (pp. 133).

%   See also CFF_READ_ALL_FROM_FILEINFO, CFF_CONVERT_ALLDATA_TO_FDATA.

%   Copyright 2021-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


% A lot is dependent on EM number (model)
emNumber = unique(EM_Runtime.EMModelNumber);
if numel(emNumber)>1
    error(['Cannot deal with multiple EM model numbers in a single ' ... 
        'EM_Runtime struct. In fact there is no reason why this ' ... 
        'should ever happen. Investigate this.']);
end

% The documentation does not mention the EM 712 but expecting the codes to 
% be exactly the same as for EM 710.
if emNumber==712
    emNumber = 710;
end

% init output
out = struct();


%% "Operator Station status"
% to decode properly XXX
out.OperatorStationStatus = EM_Runtime.OperatorStationStatus;


%% "Processing Unit status (CPU)"
% to decode properly XXX
out.ProcessingUnitStatus = EM_Runtime.ProcessingUnitStatus;


%% "BSP status"
% to decode properly XXX
out.BSPStatus = EM_Runtime.BSPStatus;


%% "Sonar Head or Transceiver status"
% to decode properly XXX
out.SonarHeadStatus = EM_Runtime.SonarHeadStatus;


%% "Mode"
data = EM_Runtime.Mode;
sz = size(data);
encodedData = dec2bin(reshape(data,[],1), 8);

% Ping mode
switch emNumber
    
    case 3000
        
        codeTable = {...
            0, 'Nearfield (4º)';... % xxxx 0000 - Nearfield (4º)
            1, 'Normal (1.5º)';...  % xxxx 0001 - Normal (1.5º)
            2, 'Target detect'...   % xxxx 0010 - Target detect
            };
        codes = bin2dec(encodedData(:,5:8));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.PingMode = reshape(categorical(codeTable(idx,2)),sz);
        
    case 3002
        
        codeTable = {...
            0, 'Wide Tx beamwidth (4°)';...    % xxxx 0000 - Wide Tx beamwidth (4°)
            1, 'Normal Tx beamwidth (1.5°)'... % xxxx 0001 - Normal Tx beamwidth (1.5°)
            };
        
        codes = bin2dec(encodedData(:,5:8));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.PingMode = reshape(categorical(codeTable(idx,2)),sz);
        
    case {2000, 710, 1002, 300, 302, 120, 122}
        
        codeTable = {...
            0, 'Very Shallow';... % xxxx 0000 - Very Shallow
            1, 'Shallow';...      % xxxx 0001 - Shallow
            2, 'Medium';...       % xxxx 0010 - Medium
            3, 'Deep';...         % xxxx 0011 - Deep
            4, 'Very deep';...    % xxxx 0100 - Very deep
            5, 'Extra deep'...    % xxxx 0101 - Extra deep
            };
        codes = bin2dec(encodedData(:,5:8));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.PingMode = reshape(categorical(codeTable(idx,2)),sz);
        
    case 2040
        
        codeTable = {...
            0, '200 kHz';... % xxxx 0000 - 200 kHz
            1, '300 kHz';... % xxxx 0001 - 300 kHz
            2, '400 kHz'...  % xxxx 0010 - 400 kHz
            };
        codes = bin2dec(encodedData(:,5:8));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.PingMode = reshape(categorical(codeTable(idx,2)),sz);
        
end

% TX pulse form
switch emNumber
    
    case {2040, 710, 302, 122}
        
        codeTable = {...
            0, 'CW';...    % xx00 xxxx - CW
            1, 'Mixed';... % xx01 xxxx - Mixed
            2, 'FM'...     % xx10 xxxx - FM
            };
        codes = bin2dec(encodedData(:,3:4));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.TxPulseForm = reshape(categorical(codeTable(idx,2)),sz);
        
    case 2045
        
        codeTable = {...
            0, 'CW';... % xx0x xxxx - CW
            1, 'FM'...  % xx1x xxxx - FM
            };
        codes = bin2dec(encodedData(:,3));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.TxPulseForm = reshape(categorical(codeTable(idx,2)),sz);
        
end

% Frequency
switch emNumber
    case 2045
        % Frequency (EM2040C)
        % Frequency = 180 kHz + 10 kHz * parameter
        % Examples:
        %  xxx0 0000 - 180 kHz
        %  xxx0 0001 - 190 kHz
        %  xxx1 0110 - 400 kHz
        
        parameter = bin2dec(encodedData(:,4:end));
        out.FrequencyKHz = 180 + 10.*parameter;
        
end

% Dual Swath mode
switch emNumber
    case {2040, 710, 302, 122}
        
        codeTable = {...
            0, 'Dual swath = Off';...     % 00xx xxxx - Dual swath = Off
            1, 'Dual swath = Fixed';...   % 01xx xxxx - Dual swath = Fixed
            2, 'Dual swath = Dynamic'...  % 10xx xxxx - Dual swath = Dynamic
            };
        codes = bin2dec(encodedData(:,1:2));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.DualSwathMode = reshape(categorical(codeTable(idx,2)),sz);
        
end


%% "Filter Identifier"
% to decode properly XXX
out.FilterIdentifier = EM_Runtime.FilterIdentifier;


%% "Minimum depth in m"
out.MinimumDepth = EM_Runtime.MinimumDepth;


%% "Maximum depth in m"
out.MaximumDepth = EM_Runtime.MaximumDepth;


%% "Absorption coefficient in 0.01 dB/km"
out.AbsorptionCoefficient = EM_Runtime.AbsorptionCoefficient.*0.01; % now in dB/km


%% "Transmit pulse length in μs"
out.TransmitPulseLength = EM_Runtime.TransmitPulseLength.*1e-6; % now in seconds


%% "Transmit beamwidth in 0.1 degrees"
out.TransmitBeamwidth = EM_Runtime.TransmitBeamwidth.*0.1; % now in degrees


%% "Transmit power re maximum in dB"
out.TransmitPowerReMaximum = EM_Runtime.TransmitPowerReMaximum;


%% "Receive beamwidth in 0.1 degrees"
out.ReceiveBeamwidth = EM_Runtime.ReceiveBeamwidth.*0.1; % now in degrees


%% "Receive bandwidth in 50 Hz resolution"
out.ReceiveBandwidth = EM_Runtime.ReceiveBandwidth.*50; % now in Hz


%% "Mode 2 or Receiver fixed gain setting in dB"
data = EM_Runtime.ReceiverFixedGainSetting;
sz = size(data);
encodedData = dec2bin(reshape(data,[],1), 8);

% RXarray use (EM2040)
switch emNumber
    case 2040
        
        codeTable = {...
            0, 'Off (RX inactive)';...       % xxxx xx00 - Off (RX inactive)
            1, 'RX 1 (port) active';...      % xxxx xx01 - RX 1 (port) active
            2, 'RX 2 (starboard) active';... % xxxx xx10 - RX 2 (starboard) active
            3, 'Both RX units active'...     % xxxx xx11 - Both RX units active 
            };
        codes = bin2dec(encodedData(:,7:8));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.RXarrayUse = reshape(categorical(codeTable(idx,2)),sz);
end

% Sonar head use (EM2040C)
switch emNumber
    case 2045
        
        codeTable = {...
            0, 'Off (Both inactive)';...     % xxxx xx00 - Off (Both inactive)
            1, 'SH 1 (port) active';...      % xxxx xx01 - SH 1 (port) active
            2, 'SH 2 (starboard) active';... % xxxx xx10 - SH 2 (starboard) active
            3, 'Both active'...              % xxxx xx11 - Both active 
            };
        codes = bin2dec(encodedData(:,7:8));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.SonarHeadUse = reshape(categorical(codeTable(idx,2)),sz);
end

% Pulse length
switch emNumber
    
    case 2040
        
        codeTable = {...
            0, 'Short CW';...  % xxxx 00xx - Short CW
            1, 'Medium CW';... % xxxx 01xx - Medium CW
            2, 'Long CW';...   % xxxx 10xx - Long CW
            3, 'FM'...         % xxxx 11xx - FM
            };
        codes = bin2dec(encodedData(:,5:6));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.PulseLength = reshape(categorical(codeTable(idx,2)),sz);
        
    case 2045
        
        codeTable = {...
            0, 'Very Short CW';... % x000 xxxx - Very Short CW
            1, 'Short CW';...      % x001 xxxx - Short CW
            2, 'Medium CW';...     % x010 xxxx - Medium CW
            3, 'Long CW';...       % x011 xxxx - Long CW
            4, 'Very Long CW';...  % x100 xxxx - Very Long CW
            5, 'Extra Long CW';... % x101 xxxx - Extra Long CW
            6, 'Short FM';...      % x110 xxxx - Short FM
            7, 'Long FM'...        % x111 xxxx - Long FM
            };
        codes = bin2dec(encodedData(:,2:4));
        [~,idx] = ismember(codes,cell2mat(codeTable(:,1)));
        out.PulseLength = reshape(categorical(codeTable(idx,2)),sz);
        
end

% Receiver fixed gain setting in dB
switch emNumber
    case {2000, 1002, 3000, 3002, 300, 120}
        codes = bin2dec(encodedData(:,1:8));
        out.ReceiverFixedGainSettingDB = codes;
end      


%% "TVG law crossover angle in degrees"
out.TVGLawCrossoverAngle = EM_Runtime.TVGLawCrossoverAngle;


%% "Source of sound speed at transducer"
% to decode properly XXX
out.SourceOfSoundSpeedAtTransducer = EM_Runtime.SourceOfSoundSpeedAtTransducer;


%% "Maximum port swath width in m"
out.MaximumPortSwathWidth = EM_Runtime.MaximumPortSwathWidth;


%% "Beam spacing"
% to decode properly XXX
out.BeamSpacing = EM_Runtime.BeamSpacing;


%% "Maximum port coverage in degrees"
out.MaximumPortCoverage = EM_Runtime.MaximumPortCoverage;


%% "Yaw and pitch stabilization mode"
% to decode properly XXX
out.YawAndPitchStabilizationMode = EM_Runtime.YawAndPitchStabilizationMode;


%% "Maximum starboard coverage in degrees"
out.MaximumStarboardCoverage = EM_Runtime.MaximumStarboardCoverage;


%% "Maximum starboard swath width in m"
out.MaximumStarboardSwathWidth = EM_Runtime.MaximumStarboardSwathWidth;


%% "Transmit along tilt in 0.1 deg. or Durotong speed in dm/s"
% to decode properly XXX
out.DurotongSpeed = EM_Runtime.DurotongSpeed;


%% "Filter identifier 2 or HiLo frequency absorption coefficient ratio"
% to decode properly XXX
out.HiLoFrequencyAbsorptionCoefficientRatio = EM_Runtime.HiLoFrequencyAbsorptionCoefficientRatio;

