function mem = CFF_memory_available(varargin)
%CFF_MEMORY_AVAILABLE  Memory available guaranteed to hold data, in bytes
%
%   Returns the memory available to hold data on CPU or GPU.
%
%   MEM = CFF_MEMORY_AVAILABLE() returns the memory available on the CPU to
%   hold data.
%
%   MEM = CFF_MEMORY_AVAILABLE('GPU') returns the memory available on the
%   GPU (if any) to hold data. If no GPU is detected, returns MEM = 0.
%
%   NOTE: this function will return the memory available if there is a GPU,
%   but this does not mean parallel computing is possible, because there
%   are other necessary criteria to meet than just having a GPU (e.g.
%   appropriate toolbox license, GPU drivers version, etc.). Use
%   CFF_IS_PARALLEL_COMPUTING_AVAILABLE to test if parallel computing is
%   available. 
%
%   See also CFF_IS_PARALLEL_COMPUTING_AVAILABLE.

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% input parser
p = inputParser;
addOptional(p,'processingUnit','CPU',@(x) ismember(upper(x),{'CPU','GPU'}));
parse(p,varargin{:});
processingUnit = p.Results.processingUnit;
clear p

switch processingUnit
    case 'GPU'
        % for now only considering the active gpuDevice
        n = gpuDeviceCount;
        if n
            D = gpuDevice;
            mem = D.AvailableMemory;
            % "Total memory (in bytes) available for data, specified as a
            % scalar value. This property is available only for the
            % currently selected device. This value can differ from the
            % value reported by the NVIDIA® System Management Interface due
            % to memory caching."
        else
            mem = 0;
        end
        
    case 'CPU'
        if ispc
            % on pc, just use the MATLAB function 'memory'
            mem_struct = memory;
            mem = mem_struct.MemAvailableAllArrays;
            % "Total memory available to hold data. The amount of memory
            % available is guaranteed to be at least as large as this
            % value. This field's value is the smaller of these two values:
            % 1) The total available MATLAB virtual address space. 2) The
            % total available system memory."
            
        elseif ismac
            % on mac, get memory information from terminal
            [~,txt] = system('top -l 1 | grep PhysMem: | awk ''{print $6}''');
            if strcmp(txt(end-1),'M')
                mem = str2num(txt(1:end-2)).*1024^2;
            elseif strcmp(txt(end),'G')
                mem = str2num(txt(1:end-2)).*1024^3;
            else
                mem = str2num(txt(1:end-1));
            end
            
        end
end

end