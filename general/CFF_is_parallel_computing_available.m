function [gpuAvail,info] = CFF_is_parallel_computing_available()
%CFF_IS_PARALLEL_COMPUTING_AVAILABLE  Suitability of GPU for parallel computing
%
%   This function checks 1) if you have the appropriate licence for
%   parallel computing, 2) if you have a GPU, 3) if that GPU is suitable
%   for parall computing, and 4) if its drivers are up to date given your
%   MATLAB release.
%
%   [GPUAVAIL, INFO] = CFF_IS_PARALLEL_COMPUTING_AVAILABLE() returns
%   GPUAVAIL = 1 if you can use parallel computing, 0 if not. The second
%   output INFO is a text string providing information.
%
%   NOTES:
%   * modified from function get_gpu_comp_stat.m. This function does not
%   return memory available on the GPU anymore. Use CFF_MEMORY_AVAILABLE
%   for this.
%   * the look-up table for MATLAB Release vs CUDA Toolkit driver version
%   must be edited manually when new MATLAB are released. See
%   https://mathworks.com/help/releases/R2021b/parallel-computing/gpu-support-by-release.html.
%
%   See also CFF_MEMORY_AVAILABLE.

%	Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2022; Last revision: 03-08-2022


% Each new release of MATLAB requires updated CUDA toolkit, with a driver
% version at least as recent as indicated on the table at:
% https://mathworks.com/help/releases/R2021b/parallel-computing/gpu-support-by-release.html.
% Reproducing the table here, but it must be updated for later MATLAB
% releases
lookUpTable = {...
    'R2021b - 11.0',...
    'R2021a - 11.0',...
    'R2020b - 10.2',...
    'R2020a - 10.1',...
    'R2019b - 10.1',...
    'R2019a - 10.0',...
    'R2018b - 9.1',...
    'R2018a - 9.0',...
    'R2017b - 8.0',...
    'R2017a - 8.0',...
    'R2016b - 7.5',...
    'R2016a - 7.5',...
    'R2015b - 7.0',...
    'R2015a - 6.5',...
    'R2014b - 6.0',...
    'R2014a - 5.5',...
    'R2013b - 5.0',...
    'R2013a - 5.0',...
    'R2012b - 4.2',...
    'R2012a - 4.0',...
    'R2011b - 4.0'};

% 1) check if there is a licence for parallel computing
if license('checkout','Distrib_Computing_Toolbox')
    
    % 2) check if there is a GPU
    try
        D = gpuDevice; % get the default GPU device
    catch err
        % cannot detect a GPU. Could be a CUDA driver error
        if contains((err.message),'CUDA') || contains((err.message),'graphics driver')
            gpuAvail = 0;
            info = ['No GPU detected, but it could just be a driver issue.',...
                ' If you do have a GPU, update its driver and try this function again.'];
        else
            gpuAvail = 0;
            info = 'No GPU detected.';
        end
    end
    
    if exist('D','var')
        % 3) check GPU suitability for parallel computing
        if str2double(D.ComputeCapability) >= 3 && ... % Computational capability of the CUDA device. Must meet required specification.
                D.SupportsDouble && ...                % Indicates if this device can support double precision operations.
                D.DeviceSupported > 0                  % Indicates if toolbox can use this device. Not all devices are supported; for example, if their ComputeCapability is insufficient, the toolbox cannot use them.
            
            % 4) check that GPU driver is up to date for current MATLAB
            % release
            curMatRel = version('-release');
            k = contains(lookUpTable,curMatRel);
            if any(k)
                % we have a match in the lookup table
                minToolkitVersion = str2double(extractAfter(lookUpTable(k),'-'));
                if  D.DriverVersion > 10 && ...               % The CUDA device driver version currently in use. Must meet required specification.
                        D.ToolkitVersion >= minToolkitVersion % Version of the CUDA toolkit used by the current release of MATLAB.
                    % all good, proceed
                    gpuAvail = 1;
                    info = sprintf('Your GPU is supported (%s).',D.Name);
                else
                    gpuAvail = 0;
                    info = sprintf(['Your GPU is supported (%s), but you must',...
                        ' update its driver to be able to use it.'],D.Name);
                end
            elseif str2double(curMatRel(1:4)) >= str2double(lookUpTable{1}(2:5))
                % no match because MATLAB is too recent
                minToolkitVersion = str2double(extractAfter(lookUpTable(1),'-'));
                if  D.DriverVersion > 10 && ...               % The CUDA device driver version currently in use. Must meet required specification.
                        D.ToolkitVersion >= minToolkitVersion % Version of the CUDA toolkit used by the current release of MATLAB.
                    % all good, proceed
                    gpuAvail = 1;
                    info = sprintf(['Your GPU is supported (%s), and its',...
                        ' driver version is suitable for the latest MATLAB release (%s)',...
                        ' for which we have information available in this function (%s).',...
                        ' However, your MATLAB release is MORE RECENT (%s), so we cannot',...
                        ' tell if your driver is sufficiently up-to-date to actually allow GPU computing.',...
                        ' If you experience issues, try updating your driver. For more certainty about',...
                        ' GPU support, update the look-up table in this function with the most recent',...
                        ' information online.'],D.Name,lookUpTable{1}(2:6),upper(mfilename),curMatRel);
                else
                    gpuAvail = 0;
                    info = sprintf(['Your GPU is supported (%s), but you must',...
                        ' update its driver to be able to use it. Note: your MATLAB release (%s)',...
                        ' is more recent than the latest one (%s) for which we have',...
                        ' information available in this function (%s). Update the',...
                        ' look-up table in this function with the most recent',...
                        ' information online.'],D.Name,curMatRel,lookUpTable{1}(2:6),upper(mfilename));
                end
            else
                % if here, must be an antique MATLAB
                gpuAvail = 0;
                info = sprintf(['Your GPU is supported (%s), but your MATLAB release (%s)',...
                    ' is OLDER than the earliest release (%s) for which',...
                    ' parallel computing is available.'],D.Name,curMatRel,lookUpTable{end}(2:6));
            end
            
        else
            gpuAvail = 0;
            info = 'Your GPU is not supported.';
        end
    end
    
else
    gpuAvail = 0;
    info = 'You do not seem to have a MATLAB Parallel Computing Toolbox installed.';
end

% adding availability
if gpuAvail
    info = sprintf('Parallel computing AVAILABLE. %s',info);
else
    info = sprintf('Parallel computing UNAVAILABLE. %s',info);
end


end