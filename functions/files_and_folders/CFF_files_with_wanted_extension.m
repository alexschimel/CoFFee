%% CFF_files_with_wanted_extension.m
%
% files = CFF_files_with_wanted_extension(folder, extension) returns a cell
% array of char strings listing the files in "folder" with the wanted
% "extension" (case insensitive). "extension" is optional: if not in 
% input, the function returns all files in "folder". Using extension '.*'
% produces the same result.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-06-19: first version (Alex Schimel)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function [files,fpath] = CFF_files_with_wanted_extension(folder, extension)

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




