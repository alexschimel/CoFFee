function out = CFF_check_ALLfilename(file)
% CFF_check_ALLfilename.m
%
% CFF_check_ALLfilename checks if input filename is a Kongsberg file
% ("myfile.all" or "myfile.wcd") or the root name ("myfile") of a pair of
% all/wcd and that it/they exist.

%   Copyright 2007-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% does filename has an extension
if ~isempty(CFF_file_extension(file))
    % if filename has an extension
    
    % check it's a kongsberg file and that it exists.
    out = CFF_is_Kongsberg_file(file) && exist(file,'file');
    
else
    % if filename doesn't have an extension, aka file root
    
    % build the all and wcd full filenames
    file = CFF_get_Kongsberg_files(file);
    
    % check that they both exist
    out = exist(file{1},'file') && exist(file{2},'file');
    
end