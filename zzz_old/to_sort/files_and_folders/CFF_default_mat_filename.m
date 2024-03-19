function mat_files = CFF_default_mat_filename(files)
%CFF_DEFAULT_MAT_FILENAME  One-line description
%
%   MAT_FILES = CFF_DEFAULT_MAT_FILENAME(FILES) returns default .mat file
%   name(s) for one or several input filenames FILES, usually prior to
%   conversion. That default convention is to replace the period in the
%   extension with underscore, and adding .mat extension. For example:
%   'C:\DATA\myfile.all' -> 'C:\DATA\myfile_all.mat' 
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(files)
    
    [p,n,e] = fileparts(files);
    mat_files = [p filesep n  '_' e(2:end) '.mat'];
    
elseif iscell(files)
    
    mat_files = cell(size(files));
    for ii=1:length(files)
        [p,n,e] = fileparts(files{ii});
        mat_files{ii} = [p filesep n  '_' e(2:end) '.mat'];
    end
    
end