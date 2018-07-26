%% CFF_full_path.m
%
% out = CFF_full_path(in) returns the absolute path for input folder or
% file "in", in case the input path is only relative.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |in|: string of characters for folder or file
%
% *OUTPUT VARIABLES*
%
% * |out|: string of characters for folder or file
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-06-06: first version (Alex Schimel)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function out = CFF_full_path(in)

% first, correct filesep if necessary:
temp = CFF_correct_filesep(in);

% then test if input variable is a file or a folder
if exist(temp,'dir')
    % if folder...
    
    % record current directory
    curdir = pwd;
    
    % go to folder
    cd(temp);
    
    % record its path
    out = pwd;
    
    % go back to original diretory
    cd(curdir);
    
elseif exist(temp,'file')
    % if file...
    
    % correcting for a quirk of matlab in which the 'exist' function does
    % recognize a file even with a filesep at the end, while 'fileparts'
    % won't
    if strcmp(temp(end),filesep)
        temp(end)=[];
    end
    
    % getting file's path
    [pathstr,name,ext] = fileparts(temp);
    
    % test if file has a path (absolute or relative, doesn't matter)
    if isempty(pathstr)
        % if it doesn't, it means file is in curent directory or on the
        % search path so 'which' directly gives result
        
        out = which(temp);
        
    else
        % if it has some path, go there
        
        % record current directory
        curdir = pwd;
        
        % go to that folder
        cd(pathstr);
        
        % use which
        out = which([name ext]);
        
        % go back to original diretory
        cd(curdir);
        
    end
    
else
    
    error('''%s'' is not an existing file or folder.', in);
    
end
