function idxConverted = CFF_are_raw_files_converted(rawFilesList)
%CFF_ARE_RAW_FILES_CONVERTED  Check if raw files are already converted.
%
%   A = CFF_ARE_RAW_FILES_CONVERTED(F) tests if each input file in F
%   is converted to the fData format (A=1) or not (A=0).
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 03-12-2021

% exit if no input
if isempty(rawFilesList)
    idxConverted = [];
    return
end

% list of names of converted files, if input were converted
fDataFolders = CFF_converted_data_folder(rawFilesList);
fDataFiles = fullfile(fDataFolders,'fData.mat');
if ischar(fDataFiles)
    fDataFiles = {fDataFiles};
end

% check if files exist
idxConverted = isfile(fDataFiles);

