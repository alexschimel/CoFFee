function [files,fpath] = CFF_files_with_wanted_extension(folder, extension)
%CFF_FILES_WITH_WANTED_EXTENSION  One-line description
%
%   FILES = CFF_FILES_WITH_WANTED_EXTENSION(FOLDER, EXTENSION) returns a
%   cell array of char strings listing the files in FOLDER with the wanted
%   EXTENSION (case insensitive). EXTENSION is optional: if not in input,
%   the function returns all files in FOLDER. Using extension '.*' produces
%   the same result. 
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if nargin == 1
    extension = '.*';
end

% improve folder
fpath = CFF_full_path(folder);

% get content of folder
listing = dir(fpath);

% grab filenames
files = {listing.name}';

% leave folders
files = files([listing.isdir]==0);

if strcmp(extension,'.*')
    % grab all files but leave folders
    return
end

% for each, testing extension and removing from the list if it doesn't
% match. Going backwards so as not to mess with index of shrinking
% variable.
for ii=length(files):-1:1
    [~,~,e] = fileparts(files{ii});
    if ~strcmpi(e,extension)
        files(ii) = [];
    end
end




