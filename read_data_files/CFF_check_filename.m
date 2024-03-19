function out = CFF_check_filename(rawFileName,extension)
%CFF_CHECK_FILENAME  Check existence and extension of file(s)
%
%   out = CFF_CHECK_FILENAME(rawFile,ext) checks if single file
%   rawFile (char) exists and has extension ext (char).
%
%   out = CFF_CHECK_FILENAME(rawFilesPair,exts) checks if pair of files
%   rawFilesPair (2x1 cell array of chars) exist, match (same name), and
%   have extensions as specified in exts (2x1 cell array of chars).
%
%   See also CFF_CHECK_ALLFILENAME, CFF_CHECK_KMALLFILENAME.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(rawFileName)
    % single file. 
    % Check extension is valid, and that file exists.
    
    isExtValid = any(strcmpi(CFF_file_extension(rawFileName),extension));
    out = isfile(rawFileName) && isExtValid;
    
elseif iscell(rawFileName) && numel(rawFileName)==2
    % pair of files.
    % Check that extension is a valid pair, that filenames match, and that
    % files exist.
    
    exts = CFF_file_extension(rawFileName);
    areExtValidPair = all(strcmp(sort(lower(exts)),sort(lower(extension))));
    
    [~,filenames,~] = fileparts(rawFileName);
    doFilenamesMatch = strcmp(filenames{1}, filenames{2});
    
    doBothFilesExist = all(isfile(rawFileName));
    
    out = areExtValidPair && doFilenamesMatch && doBothFilesExist;
    
else
    out = false;
end

