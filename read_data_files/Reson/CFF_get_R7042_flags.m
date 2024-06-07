function [flags,sample_size,mag_fmt,phase_fmt] = CFF_get_R7042_flags(flag_dec)
%CFF_GET_R7042_FLAGS  Decode flags of s7k datagram R7042
%
%   FLAGS = CFF_GET_R7042_FLAGS(FLAG_DEC) decodes the flags FLAG_DEC parsed
%   in decimal numbers from the s7k raw data files records R7042 according
%   to the format documentation and return the decoded flags in structure
%   FLAGS. 
%
%   [FLAGS,SAMPLE_SIZE,MAG_FMT,PHASE_FMT] = CFF_GET_R7042_FLAGS(FLAG_DEC)
%   outputs the total sample size SAMPLE_SIZE (in bytes), and the class of
%   magnitue MAG_FMT and phase data (if any) PHASE_FMT, as a string code.
%   If there is no phase data, the empty string is returned for PHASE_FMT.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% input management
assert(isvector(flag_dec),'input flag_dec should be scalar or vector');

nEntries = numel(flag_dec);

% init
flags = struct(...
    'dataTruncatedBeyondBottom', nan(size(flag_dec)), ...
    'magnitudeOnly', nan(size(flag_dec)), ...
    'int8BitCompression', nan(size(flag_dec)), ...
    'Reserved', nan(size(flag_dec)), ...
    'downsamplingDivisor', nan(size(flag_dec)), ...
    'downsamplingType', nan(size(flag_dec)), ...
    'int32BitsData', nan(size(flag_dec)), ...
    'compressionFactorAvailable', nan(size(flag_dec)), ...
    'segmentNumbersAvailable', nan(size(flag_dec)), ...
    'firstSampleContainsRxDelay', nan(size(flag_dec)));
sample_size = nan(size(flag_dec));
mag_fmt     = cell(size(flag_dec));
phase_fmt   = cell(size(flag_dec));

% read entry by entry
for ii = 1:nEntries
    
    % dec to bin
    flag_bin = dec2bin(flag_dec(ii),32);
    
    % Bit 0 : Use maximum bottom detection point in each beam to limit data.
    % Data is included up to the bottom detection point + 10%. This flag has no
    % effect on systems which do not perform bottom detection.
    flags.dataTruncatedBeyondBottom(ii) = bin2dec(flag_bin(32-0));
    
    % Bit 1 : Include intensity data only (strip phase)
    flags.magnitudeOnly(ii) = bin2dec(flag_bin(32-1));
    
    % Bit 2 : Convert mag to dB, then compress from 16 bit to 8 bit
    % by truncation of 8 lower bits. Phase compression simply
    % truncates lower (least significant) byte of phase data.
    flags.int8BitCompression(ii) = bin2dec(flag_bin(32-2));
    
    % Bit 3 : Reserved.
    flags.Reserved(ii) = bin2dec(flag_bin(32-3));
    
    % Bit 4-7 : Downsampling divisor. Value = (BITS >> 4). Only
    % values 2-16 are valid. This field is ignored if downsampling
    % is not enabled (type = “none”).
    flags.downsamplingDivisor(ii) = bin2dec(flag_bin(32-7:32-4));
    
    % Bit 8-11 : Downsampling type:
    %             0x000 = None
    %             0x100 = Middle value
    %             0x200 = Peak value
    %             0x300 = Average value
    flags.downsamplingType(ii) = bin2dec(flag_bin(32-11:32-8));
    
    % Bit 12: 32 Bits data
    flags.int32BitsData(ii) = bin2dec(flag_bin(32-12));
    
    % Bit 13: Compression factor available
    flags.compressionFactorAvailable(ii) = bin2dec(flag_bin(32-13));
    
    % Bit 14: Segment numbers available
    flags.segmentNumbersAvailable(ii) = bin2dec(flag_bin(32-14));
    
    % Bit 15: First sample contains RxDelay value.
    flags.firstSampleContainsRxDelay(ii) = bin2dec(flag_bin(32-15));
    
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
    if ~flags.int32BitsData(ii)
        if ~flags.int8BitCompression(ii)
            if ~flags.magnitudeOnly(ii)
                % A) 16 bit Mag & 16bit Phase (32 bits total)
                sample_size(ii) = 4;
                mag_fmt{ii} = 'uint16';
                phase_fmt{ii} = 'int16';
            else
                % B) 16 bit Mag (16 bits total, no phase)
                sample_size(ii) = 2;
                mag_fmt{ii} = 'uint16';
                phase_fmt{ii} = '';
            end
        else
            if ~flags.magnitudeOnly(ii)
                % C) 8 bit Mag & 8 bit Phase (16 bits total)
                sample_size(ii) = 2;
                mag_fmt{ii} = 'int8';
                phase_fmt{ii} = 'int8';
            else
                % D) 8 bit Mag (8 bits total, no phase)
                sample_size(ii) = 1;
                mag_fmt{ii} = 'int8';
                phase_fmt{ii} = '';
            end
        end
    else
        if ~flags.magnitudeOnly(ii)
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
            sample_size(ii) = 5;
            mag_fmt{ii} = 'float32';
            phase_fmt{ii} = 'int8';
        else
            % F) 32 bit Mag (32 bits total, no phase)
            sample_size(ii) = 4;
            mag_fmt{ii} = 'float32';
            phase_fmt{ii} = '';
        end
    end
    
end

