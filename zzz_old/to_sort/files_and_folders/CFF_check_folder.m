%% CFF_check_folder.m
%
% [out_folder] = CFF_check_folder(in_folder,noprompt_flag) checks if
% "in_folder" is an existing folder. If it is, it returns the absolute
% path of the input folder, with correct filesep. If it isn't,
% "noprompt_flag" controls the resulting behaviour. If "noprompt_flag" is
% the string of characters 'noprompt', the function returns an error.
% Anything else and the function will prompt for a valid input folder as
% close as possible to the (invalid) input folder.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |in_folder|: required. char string. the folder to test for existence
% * |noprompt_flag|: optional. char string. If 'noprompt' is called as
% second input, this function will return an error is the folder doesn't
% exist. If |noprompt_flag| is not called (or is anything else but
% 'noprompt', then the function will throw an UI interface to prompt for a
% folder.
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
function [out_folder] = CFF_check_folder(in_folder,noprompt_flag)

% first off, replace wrong fileseps if any
folder = CFF_correct_filesep(in_folder);

% then test if folder exists
if exist(folder,'dir')
    
    % folder exists, return its full path
    out_folder = CFF_full_path(folder);
    
else
    % folder doesn't exist
    
    if nargin>1 && strcmp(noprompt_flag,'noprompt')
        
        txt = ['The folder ''' in_folder ''' does not exist.'];
        error(txt);
        
    else
        
        % check input path to find the closest existing folder in the input
        % path (or pwd if there none valid)
        folder = CFF_closest_existing_folder(folder);
        
        % prompt for an existing folder
        txt = ['The folder ''' in_folder ''' does not exist. Please select a valid folder.'];
        out_folder = uigetdir(folder,txt);
        
    end
    
end



