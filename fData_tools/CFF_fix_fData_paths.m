function [fData, flagPathsFixed] = CFF_fix_fData_paths(fData,rawFile)
%CFF_FIX_FDATA_PATHS  Fix paths in converted data if files were moved
%
%   When a raw data file is converted to a fData.mat file, the path of the
%   source file (field ALLfilename) is saved, as well as the paths to the
%   binary files containing water-column data (if that data type was
%   converted). If you then move the data to another folder (even if moving
%   appropriately both the source data, and the converted data), the
%   absolute paths in fData are no longer correct. This function fixes it.
%
%   FDATA = CFF_FIX_FDATA_PATHS(FDATA,RAWFILE) checks if
%   the absolute paths in some fields of FDATA are correct, given the
%   absolute path of the raw data file RAWFILE, and corrects them if
%   necessary. The fixed FDATA is saved back on the drive. 
%
%   [FDATA, FLAGPATHSFIXED] = CFF_FIX_FDATA_PATHS(...) returns
%   FLAGPATHSFIXED = 1 if a correction was performed, 0 otherwise.
%
%   See also CFF_LOAD_CONVERTED_FILES.

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


% path to converted data on disk
fDataFolder = CFF_converted_data_folder(rawFile);
fDataFile = fullfile(fDataFolder,'fData.mat');

% init flag indicating change
flagPathsFixed = 0;

% grab source file names in fData
fDataSourceFile = fData.ALLfilename;
if ischar(fDataSourceFile)
    fDataSourceFile = {fDataSourceFile};
end

% let's only deal with cell arrays, wether single or paired files
if ischar(rawFile)
    rawFile = {rawFile};
end

% check that input raw file(s) match fData source file(s)
if ~isequal(sort(CFF_file_name(rawFile,1)),sort(CFF_file_name(fDataSourceFile,1)))
    error('Names of source file(s) do not match those saved in fData. Please reconvert file.');
end

% check paths of source file(s) and fix if necessary
if ~isequal(sort(rawFile),sort(fDataSourceFile))
    fData.ALLfilename = sort(rawFile);
    flagPathsFixed = 1;
end

% WCD binary files fields
fields = fieldnames(fData);
fields = fields(startsWith(fields,{'WC_SBP' 'AP_SBP' 'X_SBP'}));

% Check path of WCD binary file(s) and fix if necessary
for ii = 1:numel(fields)
    field = fields{ii};
    for jj = 1:numel(fData.(field))
        if ~isempty(fData.(field){jj})
            [filepathSaved,name,ext] = fileparts(fData.(field){jj}.Filename); % path in fData
            if ~strcmp(filepathSaved,fDataFolder) % compare with expected folder
                fData.(field){jj}.Filename = fullfile(fDataFolder,[name ext]); % rename
                flagPathsFixed = 1;
            end
        end
    end
end

% If anything was fixed
if flagPathsFixed
    % update on disk
    try
        save(fDataFile,'-struct','fData','-v7.3');
    catch
        warning('Wrong paths in fData were found and modified, but it was not possible to save the corrected fData back on the disk.');
    end
end
