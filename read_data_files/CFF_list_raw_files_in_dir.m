function rawFilesList = CFF_list_raw_files_in_dir(folder, varargin)
%CFF_LIST_RAW_FILES_IN_DIR  List raw multibeam files available in folder
%
%   CFF_LIST_RAW_FILES_IN_DIR lists and fetches the names of raw multibeam
%   files available in the specified folder. Options are available to
%   search recursively, to limit the search to certain multibeam raw data
%   format types, to pair or unpair Kongsberg files, to return a smaller
%   number of files, etc.
%
%   RAWFILESLIST = CFF_LIST_RAW_FILES_IN_DIR(FOLDER) returns a list of
%   all CoFFee supported raw multibeam files in the specified folder.
%   Subfolders are NOT searched. File formats searched include Kongsberg
%   .all, .wcd, .kmall, .kmwcd, and Reson .s7k files. Pairs of Kongbsberg
%   files are returned as pairs.
%
%   CFF_LIST_RAW_FILES_IN_DIR(..., 'recursiveSearch', RECURSIVESEARCH) where
%   RECURSIVESEARCH is true searches for files recursively (aka in
%   subfolders).
%
%   CFF_LIST_RAW_FILES_IN_DIR(..., 'filesType', FILESTYPE) only searches
%   for specified file types. FILESTYPE must be a valid string or a cell
%   array of valid strings. Valid strings are: 
%     '.all/.wcd'
%     '.all'
%     '.wcd'
%     '.kmall/.kmwcd'
%     '.kmall'
%     '.kmwcd'
%     '.s7k'
%   Note that '.all/.wcd' will search for matching .all and .wcd files and
%   return them as pairs, and ignore amy unpaired files. In contrast,
%   searching for {'.all','.wcd'} will return files matching these
%   extensions, but unpaired, even if matching files are present.
%
%   CFF_LIST_RAW_FILES_IN_DIR(..., 'nFilesWanted', NFILESWANTED) limits the
%   number of files returned to NFILESWANTED. See also parameter
%   'fileSelectMethod'.
%
%   CFF_LIST_RAW_FILES_IN_DIR(..., 'fileSelectMethod', FILESELECTMETHOD)
%   specifies the method to select files if the number of files found
%   exceeds NFILESWANTED. FILESELECTMETHOD can be 'first', 'last', or
%   'random'.
%
%   All those optional parameters can be called in order, aka as: 
%   CFF_LIST_RAW_FILES_IN_DIR(FOLDER, RECURSIVESEARCH, FILESTYPE,
%   NFILESWANTED, FILESELECTMETHOD).
%
%   See also CFF_PRINT_RAW_FILES_LIST, CFF_CONVERT_RAW_FILES,
%   CFF_FILE_NAME, CFF_ONERAWFILEONLY.

%   Copyright 2017-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% Input arguments management
supportedFileTypes = {...
    '.all/.wcd',...
    '.all',...
    '.wcd',...
    '.kmall/.kmwcd',...
    '.kmall',...
    '.kmwcd',...
    '.s7k'};

% validation function for a single string to be a valid file type
strValidFileType = @(x) any(strcmp(x,supportedFileTypes));

% validation function for input filesType (i.e. valid string or cell array of valid strings
validFilesType = @(x) (ischar(x) && strValidFileType(x)) || (iscell(x) && all(cellfun(strValidFileType,x)));

% validation function for fileSelectMethod
supportedFileSelectMethods = {'first','last','random'};
validFileSelectMethod = @(x) any(validatestring(x,supportedFileSelectMethods));

p = inputParser;
addRequired(p, 'folder', @ischar);
addOptional(p, 'recursiveSearch', false, @CFF_mustBeBoolean); % 0: ignore subfolders (default). 1: search subfolders 
addOptional(p, 'filesType', supportedFileTypes, @(x) validFilesType(x));
addOptional(p, 'nFilesWanted', inf, @CFF_mustBePositiveIntegerOrInf);
addOptional(p, 'fileSelectMethod', 'first', @(x) validFileSelectMethod(x));
parse(p, folder, varargin{:});
folder = p.Results.folder;
recursiveSearch = p.Results.recursiveSearch;
filesType = p.Results.filesType;
nFilesWanted = p.Results.nFilesWanted;
fileSelectMethod = p.Results.fileSelectMethod;
clear p

if ~isfolder(folder)
    rawFilesList = {};
    return
end

% recursive search (include subfolders)
if recursiveSearch == 1
    folder = fullfile(folder, '**');
end

% ensure filesType is a cell array
if ischar(filesType)
    filesType = {filesType};
end


%% Kongsberg all format

% list files
allFiles = list_files_with_ext(folder,'*.all');
wcdFiles = list_files_with_ext(folder,'*.wcd');

% manage pairing
if ~ismember('.all/.wcd',filesType)
    % pairing not wanted
    pairedAllWcdFiles = {};
    if ismember('.all',filesType)
        allOnlyFiles = allFiles;
    else
        allOnlyFiles = {};
    end
    if ismember('.wcd',filesType)
        wcdOnlyFiles = wcdFiles;
    else
        wcdOnlyFiles = {};
    end
else
    % pairing wanted
    [pairedAllWcdFiles, allOnlyFiles, wcdOnlyFiles] = pair_files(allFiles, wcdFiles);
end


%% Kongsberg kmall format

% list files
kmallFiles = list_files_with_ext(folder,'*.kmall');
kmwcdFiles = list_files_with_ext(folder,'*.kmwcd');

% manage pairing
if ~ismember('.kmall/.kmwcd',filesType)
    % pairing not wanted
    pairedKmallKmwcdFiles = {};
    if ismember('.kmall',filesType)
        kmallOnlyFiles = kmallFiles;
    else
        kmallOnlyFiles = {};
    end
    if ismember('.kmwcd',filesType)
        kmwcdOnlyFiles = kmwcdFiles;
    else
        kmwcdOnlyFiles = {};
    end
else
    % pairing wanted
    [pairedKmallKmwcdFiles, kmallOnlyFiles, kmwcdOnlyFiles] = pair_files(kmallFiles, kmwcdFiles);
end


%% Reson s7k format

% list files
if ismember('.s7k',filesType)
    s7kFiles = list_files_with_ext(folder,'*.s7k');
else
    s7kFiles = {};
end


%% Compiling full list
rawFilesList = cat(1, ...
    pairedAllWcdFiles, ...
    allOnlyFiles, ...
    wcdOnlyFiles, ...
    pairedKmallKmwcdFiles, ...
    kmallOnlyFiles, ...
    kmwcdOnlyFiles, ...
    s7kFiles);


%% Subselection
switch fileSelectMethod
    case 'first'
        rawFilesList = rawFilesList(1:min(nFilesWanted,length(rawFilesList)));
    case 'last'
        rawFilesList = rawFilesList(max(1,length(rawFilesList)-nFilesWanted+1):end);
    case 'random'
        iSel = randperm(length(rawFilesList),min(nFilesWanted,length(rawFilesList)));
        rawFilesList = rawFilesList(iSel);
end

end


%% subfunctions %%

%%
function files = list_files_with_ext(folder,extension)
% returns full filepath (with folder, name, and extension) of all files in
% "folder" with matching "extension". Note this works whatever the case of
% extension, e.g. if looking for ".all", it will also find ".ALL". If
% "folder" ends with "\**", the search is recursive.

filesList = dir(fullfile(folder,extension));

if ~isempty(filesList)
    idx = [filesList(:).isdir]==0;
    filenames = {filesList(idx).name}';
    folders = {filesList(idx).folder}';
    files = fullfile(folders,filenames);
else
    files = {};
end

end


%%
function [pairedFilesList, AOnlyList, BOnlyList] = pair_files(fileListA, fileListB)
% compares the filenames (i.e. without folder or extension) of two list of
% files and returns when they match as "pairs". Also returns those that
% don't match

% extract parts of files in each list
[filepathA,nameA,extA] = CFF_fileparts_as_cell(fileListA);
[filepathB,nameB,extB] = CFF_fileparts_as_cell(fileListB);

% pairs
[C,ia,ib] = intersect(nameA, nameB, 'stable');
if ~isempty(C)
    pairedFilesList = cell(length(C),1);
    for ii = 1:length(C)
        matchAFile = fullfile(filepathA{ia(ii)},strcat(nameA{ia(ii)},extA{ia(ii)}));
        matchBFile = fullfile(filepathB{ib(ii)},strcat(nameB{ib(ii)},extB{ib(ii)}));
        pairedFilesList{ii,1} = {matchAFile, matchBFile};
    end
else
    pairedFilesList = {};
end

% A only
[C,ia] = setdiff(nameA, nameB, 'stable');
if ~isempty(C)
    AOnlyList = fullfile(filepathA(ia),strcat(nameA(ia),extA(ia)));
else
    AOnlyList = {};
end

% B only
[C,ib] = setdiff(nameB, nameA, 'stable');
if ~isempty(C)
    BOnlyList = fullfile(filepathB(ib),strcat(nameB(ib),extB(ib)));
else
    BOnlyList = {};
end

end

