function outText = CFF_print_raw_files_list(rawFilesList, varargin)
%CFF_PRINT_RAW_FILES_LIST  Print raw files list to screen
%
%   See also CFF_LIST_RAW_FILES_IN_DIR.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% manage inputs
printFlag = 1;
if nargin == 2
    printFlag = varargin{1};
end

nFiles = numel(rawFilesList);

% init output text
outText = {};

if nFiles>0
    
    % expand the list temporarily
    expandedList = rawFilesList;
    for iFile = 1:nFiles
        thisFile = expandedList{iFile};
        if iscell(thisFile) && numel(thisFile) == 2
            % move paired file to end
            expandedList{end+1,1} = expandedList{iFile}{2};
            % keep first file
            expandedList{iFile} = expandedList{iFile}{1};
        end
    end
    sort(expandedList);

    % find root folder from expanded list
    foldersList = fileparts(expandedList);
    rootFolder = unique(foldersList);
    while numel(rootFolder)>1
        foldersList = fileparts(foldersList);
        rootFolder = unique(foldersList);
    end
    rootFolder = [rootFolder{1} filesep];

    % write header
    outText{end+1,1} = sprintf('List of files in %s:\n',rootFolder);

    % then print each file
    for iFile = 1:nFiles
        thisFile = rawFilesList{iFile};
        if iscell(thisFile) && numel(thisFile) == 2
            % pair of files
            firstRawFileName = extractAfter(thisFile{1},rootFolder);
            secondFileExtension = CFF_file_extension(thisFile{2});
            outText{end+1,1} = sprintf('%i/%i: %s (and %s).\n',iFile,nFiles,firstRawFileName,secondFileExtension);
        else
            rawFileName = extractAfter(thisFile,rootFolder);
            outText{end+1,1} = sprintf('%i/%i: %s.\n',iFile,nFiles,rawFileName);
        end
    end

else    
    outText{end+1,1} = sprintf('Empty list.\n');
end

% print to screen
if printFlag
    for iLine = 1:numel(outText)
        fprintf(regexprep(outText{iLine},'\\','\\\'));
    end
end
