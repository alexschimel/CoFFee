%% CFF_check_file.m
%
% [out_file] = CFF_check_file(in_file, noprompt_flag) checks if
% "in_file" is an existing file or set of files. If it/they does/do, return the absolute path of
% the input file(s), with correct filesep. If it isn't,
% "noprompt_flag" controls the resulting behaviour. If "noprompt_flag" is
% the string of characters 'noprompt', the function returns an error.
% Anything else and the function will prompt for valid file(s) as close as possible to the (invalid)
% input file(s).
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |in_file|: required. char string or cell array of char strings. The
% file(s) to test for existence. 
% * |noprompt_flag|: optional. char string. If 'noprompt' is called as
% second input, this function will return an error is the file(s) don't
% exist. If |noprompt_flag| is not called (or is anything else but
% 'noprompt', then the function will throw an UI interface to prompt for
% file(s).
%
% *OUTPUT VARIABLES*
%
% * |out_file|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-06-19: added noprompt flag. Not tested. (Alex Schimel)
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
function [out_file] = CFF_check_file(in_file, noprompt_flag)

% first off, replace wrong fileseps if any
file = CFF_correct_filesep(in_file);

% then, test for the number of files in input
if ischar(in_file)
    % if only one...

    % test if file exists
    if exist(file,'file')
        % if it does...
        
        % just return input file, with its full path
        out_file = CFF_full_path(file);
        
    else
        % if it doesn't...
        
        if nargin>1 && strcmp(noprompt_flag,'noprompt')
            
            txt = ['The file ''' file ''' does not exist.'];
            error(txt);
            
        else
            
            % get closest existing folder
            folder = CFF_closest_existing_folder(file);
            
            % prompt for one file in the closest existing folder
            txt = ['The file ''' file ''' does not exist. Please select a valid file'];
            FilterSpec = [folder filesep '*.*'];
            [FileName,PathName] = uigetfile(FilterSpec,txt,'MultiSelect','off');
            
            % output file with path
            out_file = fullfile(PathName,FileName);
            
        end
        
    end
    
elseif iscell(file)
    % if several files in input
    
    % test if all files exist
    flag = cellfun( @(x)exist(x,'file')==0, file);
    X = sum(flag);
    
    if X==0
        % if they all exist, just return input file list (with full path)
        out_file = cellfun(@CFF_full_path,file,'UniformOutput',0);
        
    else
        % if at least one does not exist...
        
        if nargin>1 && strcmp(noprompt_flag,'noprompt')
            
            % throw an error
            n_files = length(file);
            txt = sprintf('%i out of %i files do not exist.', X, n_files);
            error(txt);
            
        else
            
            % prompt for all files to be selected
            
            % get closest existing folder
            folder = CFF_closest_existing_folder(file{1});
            
            % prompt for files in the closest existing folder
            n_files = length(file);
            txt = sprintf('%i out of %i files do not exist. Please select valid files.', X, n_files);
            FilterSpec = [folder filesep '*.*'];
            [FileName,PathName] = uigetfile(FilterSpec,txt,'MultiSelect','on');
            
            % return with full path
            out_file = cell(size(file));
            for ii = 1:length(out_file)
                out_file{ii} = fullfile(PathName,FileName{ii});
            end
            
        end
        
    end
    
end
    
