function idxConverted = CFF_are_raw_files_converted(rawFilesList,flagCheckVersion)
%CFF_ARE_RAW_FILES_CONVERTED  Check if raw files are already converted.
%
%   A = CFF_ARE_RAW_FILES_CONVERTED(F) tests if each input filename in F
%   (string or cell array of strings) has already been converted to the
%   fData format (A=true) or not (A=false). The test is only for the
%   existence of the 'fData.mat' file. 
%
%   CFF_ARE_RAW_FILES_CONVERTED(F,1) also tests for the fData version in
%   the converted file. If the version does not match the current fData
%   version, the corresponding file is deemed "not converted". Note that
%   using this option takes longer.
%
%   NOTE: just added (11-01-2023) the test for fData version. This actually
%   USED to be a feature of this function but then was removed. I don't
%   remember why... So it could be that this reversion to an old feature
%   create trouble. Hopefully find this note then..
%
%   See also CFF_CONVERTED_DATA_FOLDER, CFF_IS_FDATA_VERSION_CURRENT.

%   Copyright 2017-2023 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% exit if no input raw file list
if isempty(rawFilesList)
    idxConverted = [];
    return
end

% list of names of converted file (if input files were converted)
fDataFolders = CFF_converted_data_folder(rawFilesList);
fDataFiles = fullfile(fDataFolders,'fData.mat');
if ischar(fDataFiles)
    fDataFiles = {fDataFiles};
end

% check if files exist
idxConverted = isfile(fDataFiles);

% if requested, also check that version is up to date
if exist('flagCheckVersion','var') && flagCheckVersion==1
    bool = CFF_is_fData_version_current(fDataFiles);
    idxConverted = idxConverted.*bool;
end

