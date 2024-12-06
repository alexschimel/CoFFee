function outText = CFF_print_raw_files_list(rawFilesList, varargin)
%CFF_PRINT_RAW_FILES_LIST  Print raw files list to screen
%
%   See also CFF_LIST_RAW_FILES_IN_DIR.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% manage inputs

% printing to screen
printFlag = 1;
if nargin == 2
    printFlag = varargin{1};
end

% file list
if ischar(rawFilesList)
    rawFilesList = {rawFilesList};
end
nFiles = numel(rawFilesList);

% ensure column
rawFilesList = reshape(rawFilesList,[],1);

% init output text
outText = {};

% complete output text
if nFiles == 0 || ( nFiles == 1 && isempty(rawFilesList{1}))
    
    outText{end+1,1} = sprintf('Empty list.\n');
    
else
    
    % separate pairs in list of files
    expandedFilesList = rawFilesList;
    for iFile = 1:nFiles
        thisFile = expandedFilesList{iFile};
        if iscell(thisFile) && numel(thisFile) == 2
            % move paired file to end
            expandedFilesList{end+1,1} = expandedFilesList{iFile}{2};
            % keep first file
            expandedFilesList{iFile} = expandedFilesList{iFile}{1};
        end
    end
    expandedFilesList = sort(expandedFilesList);
    
    % find root folder
    rootFolder = find_root_folder(expandedFilesList);

    % write header
    if ~isempty(rootFolder)
        rootFolder = strcat(rootFolder,filesep);
        outText{end+1,1} = sprintf('List of files in %s:\n',rootFolder);
    else
        outText{end+1,1} = sprintf('List of files:\n');
    end
    
    % then print each file
    for iFile = 1:nFiles
        thisFile = rawFilesList{iFile};
        if iscell(thisFile) && numel(thisFile) == 2
            % pair of files
            if ~isempty(rootFolder)
                firstRawFileName = extractAfter(thisFile{1},rootFolder);
            else
                firstRawFileName = thisFile{1};
            end
            secondFileExtension = CFF_file_extension(thisFile{2});
            outText{end+1,1} = sprintf('%i/%i: %s (and %s).\n',iFile,nFiles,firstRawFileName,secondFileExtension);
        else
            if ~isempty(rootFolder)
                rawFileName = extractAfter(thisFile,rootFolder);
            else
                rawFileName = thisFile;
            end
            outText{end+1,1} = sprintf('%i/%i: %s.\n',iFile,nFiles,rawFileName);
        end
    end
    
end

% print to screen
if printFlag
    for iLine = 1:numel(outText)
        fprintf(regexprep(outText{iLine},'\\','\\\'));
    end
end

end


%% subfunctions
function rootFolder = find_root_folder(expandedFilesList)
% find root folder of files list
if numel(expandedFilesList)==1
    % single file
    rootFolder = fileparts(expandedFilesList);
else
    % multiple files
    folderList = unique(fileparts(expandedFilesList));
    if numel(folderList) == 1
        % all files have same folder
        rootFolder = folderList{1};
    else
        % files with different folders. Some work needed.
        rootFolder = folderList{1};
        for i = 2:length(folderList)
            rootFolder = find_common_folder(rootFolder,folderList{i});
        end
    end
end

end

function commonFolder = find_common_folder(str1, str2)
% Find the common folder of two folders

% trim strings to same length
minLength = min(length(str1), length(str2));
str1 = str1(1:minLength);
str2 = str2(1:minLength);
if strcmp(str1,str2)
    commonFolder = str1;
    return
end

% find index of last filesep before first different character
idxFileSeps = strfind(str1,filesep); % index fileseps in str1
idxFirstDiffChar = find(str1~=str2,1); % index first different character
idxLastFileSep = idxFileSeps(find(idxFileSeps<idxFirstDiffChar,1,'last'));

% get common folder
commonFolder = str1(1:idxLastFileSep-1);

end
