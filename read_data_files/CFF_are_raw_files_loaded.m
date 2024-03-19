function idxLoaded = CFF_are_raw_files_loaded(rawFilesList, fData)
%CFF_ARE_RAW_FILES_LOADED  One-line description
%
%   List the files available for the app in input folder. Files are
%   available only if the pair .all/.wcd exists. Also returns whether these
%   pairs have been converted to .mat format.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% exit if no input
if isempty(rawFilesList)
    idxLoaded = [];
    return
end

% test if input is just ONE file (or ONE pair of files), and turn to cell
if ischar(rawFilesList)
    % single file
    rawFilesList = {rawFilesList};
elseif is_pair_of_files(rawFilesList)
    % pair of files
    rawFilesList = {rawFilesList};
end
n_rawfiles = size(rawFilesList,1);

% if no files are loaded, simply output false here, and exit
if isempty(fData)
    idxLoaded = false([n_rawfiles,1]);
    return
end

% otherwise, first get list of loaded files
loaded_files = cell(numel(fData),1);
for nF = 1:numel(fData)
    ALLfilename = fData{nF}.ALLfilename;
    if numel(ALLfilename) == 1
        % single file. Save the string
        loaded_files{nF} = ALLfilename{1};
    else
        % pair of files. Save the cell array
        loaded_files{nF} = ALLfilename;
    end
end

% next, split single files from pairs
idx_single = cell2mat(cellfun(@ischar,loaded_files,'UniformOutput',0));
loaded_files_single = loaded_files(idx_single);
loaded_files_pair = loaded_files(~idx_single);

% and extract the filenames
[~,loaded_files_single_rootfilename,~] = fileparts(loaded_files_single);
if ischar(loaded_files_single_rootfilename)
    loaded_files_single_rootfilename = {loaded_files_single_rootfilename};
end
[~,loaded_files_pair_rootfilename,~] = fileparts(CFF_onerawfileonly(loaded_files_pair));
if ischar(loaded_files_pair_rootfilename)
    loaded_files_pair_rootfilename = {loaded_files_pair_rootfilename};
end

% init output
idxLoaded = false([n_rawfiles,1]);

% fill in for each rawfile
for nF = 1:n_rawfiles
    
    rawfile = rawFilesList{nF};
    
    if ischar(rawfile)
        % single file
        
        % extract the filename
        [~,rawfilename,~] = fileparts(rawfile);
        rawfilename = {rawfilename};
        
        % and compare to those loaded
        idxLoaded(nF) = ismember(rawfilename, loaded_files_single_rootfilename);
        
    elseif is_pair_of_files(rawfile)
        % pair of files
        
        % extract the common filename
        [~,onerawfilename,~] = fileparts(CFF_onerawfileonly(rawfile));
        % onerawfilename = {onerawfilename};
        
        % and compare to those loaded
        idxLoaded(nF) = ismember(onerawfilename, loaded_files_pair_rootfilename);
        
    else
        % not recognized
        idxLoaded(nF) = false;
    end
    
end

function bool = is_pair_of_files(input)
bool = iscell(input) && all(size(input)==[1,2]) && all(cellfun(@ischar,input));
