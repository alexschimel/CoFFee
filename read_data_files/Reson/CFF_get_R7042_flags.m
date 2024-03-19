function [flags,sample_size,mag_fmt,phase_fmt] = CFF_get_R7042_flags(flag_dec)
%CFF_GET_R7042_FLAGS  One-line description
%

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% init
flags.dataTruncatedBeyondBottom = 0;
flags.magnitudeOnly = 0;
flags.int8BitCompression = 0;
flags.downsamplingDivisor = 0;
flags.downsamplingType = 0;
flags.int32BitsData = 0;
flags.compressionFactorAvailable = 0;
flags.segmentNumbersAvailable = 0;
sample_size = 0;
mag_fmt = '';
phase_fmt = '';


%% read

if isnumeric(flag_dec)
    flag_bin = dec2bin(flag_dec, 32);
else
    flag_bin = flag_dec;
end

% Bit 0 : Use maximum bottom detection point in each beam to limit data.
% Data is included up to the bottom detection point + 10%. This flag has no
% effect on systems which do not perform bottom detection.
flags.dataTruncatedBeyondBottom = bin2dec(flag_bin(32-0));

% Bit 1 : Include intensity data only (strip phase)
flags.magnitudeOnly = bin2dec(flag_bin(32-1));

% Bit 2 : Convert mag to dB, then compress from 16 bit to 8 bit
% by truncation of 8 lower bits. Phase compression simply
% truncates lower (least significant) byte of phase data.
flags.int8BitCompression = bin2dec(flag_bin(32-2));

% Bit 3 : Reserved.
flags.Reserved = bin2dec(flag_bin(32-3));

% Bit 4-7 : Downsampling divisor. Value = (BITS >> 4). Only
% values 2-16 are valid. This field is ignored if downsampling
% is not enabled (type = “none”).
flags.downsamplingDivisor = bin2dec(flag_bin(32-7:32-4));

% Bit 8-11 : Downsampling type:
%             0x000 = None
%             0x100 = Middle value
%             0x200 = Peak value
%             0x300 = Average value
flags.downsamplingType = bin2dec(flag_bin(32-11:32-8));

% Bit 12: 32 Bits data
flags.int32BitsData = bin2dec(flag_bin(32-12));

% Bit 13: Compression factor available
flags.compressionFactorAvailable = bin2dec(flag_bin(32-13));

% Bit 14: Segment numbers available
flags.segmentNumbersAvailable = bin2dec(flag_bin(32-14));

% Bit 15: First sample contains RxDelay value.
flags.firstSampleContainsRxDelay = bin2dec(flag_bin(32-15));

% NOTE
% If downsampling is used (Flags bit 8-11), then the effective Sample Rate
% of the data is changed and is given by the sample rate field. To
% calculate the effective sample rate, the system sample rate (provided in
% the 7000 record) must be divided by the downsampling divisor factor
% specified in bits 4-7.

% NOTE
% When ‘Bit 2’ is set in the flags of the 7042 record, the record contains
% 8 bit dB values. This should never combined with ‘Bit 12’ indicating that
% intensities are stored as 32 bit values.


%% interpret

% figure the size of a "sample" in bytes based on those flags
if ~flags.int32BitsData
    if ~flags.int8BitCompression
        if ~flags.magnitudeOnly
            % A) 16 bit Mag & 16bit Phase (32 bits total)
            sample_size = 4;
            mag_fmt = 'uint16';
            phase_fmt = 'int16';
        else
            % B) 16 bit Mag (16 bits total, no phase)
            sample_size = 2;
            mag_fmt = 'uint16';
            phase_fmt = '';
        end
    else
        if ~flags.magnitudeOnly
            % C) 8 bit Mag & 8 bit Phase (16 bits total)
            sample_size = 2;
            mag_fmt = 'int8';
            phase_fmt = 'int8';
        else
            % D) 8 bit Mag (8 bits total, no phase)
            sample_size = 1;
            mag_fmt = 'int8';
            phase_fmt = '';
        end
    end
else
    if ~flags.magnitudeOnly        
        % This case is strange. We have both mag and phase, and bit 12 "32
        % Bits data" is on. One would assume it means magnitude and phase
        % are both 32 bits, for a total of 64. OR that magnitude is 32 bits
        % and phase is nominal, aka 16 bits, for a total of 48 bits. But
        % none of those cases are in the documentation.
        %
        % What we have in the documentation is case "E) 32 bit Mag & 8 bit
        % Phase (40 bits total)", which is strange. Is the phase downgraded
        % from 16 to 8 bits to save space? Anyway, we assume that the doc
        % is correct and that this case applies here.
        
        % E) 32 bit Mag & 8 bit Phase (40 bits total)
        sample_size = 5;
        mag_fmt = 'float32';
        phase_fmt = 'int8';
    else
        % F) 32 bit Mag (32 bits total, no phase)
        sample_size = 4;
        mag_fmt = 'float32';
        phase_fmt = '';
    end
end
