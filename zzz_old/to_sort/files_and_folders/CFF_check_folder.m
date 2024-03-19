function [out_folder] = CFF_check_folder(in_folder,noprompt_flag)
%CFF_CHECK_FOLDER  One-line description
%
%   out_folder = CFF_CHECK_FOLDER(IN_FOLDER,NOPROMPT_FLAG) checks if
%   IN_FOLDER is an existing folder. If it is, it returns the absolute path
%   of the input folder, with correct filesep. If it isn't, NOPROMPT_FLAG
%   controls the resulting behaviour. If NOPROMPT_FLAG is the string of
%   characters 'noprompt', the function returns an error. Anything else and
%   the function will prompt for a valid input folder as close as possible
%   to the (invalid) input folder. 
%
%   *INPUT VARIABLES*
%   * |in_folder|: required. char string. the folder to test for existence
%   * |noprompt_flag|: optional. char string. If 'noprompt' is called as
%   second input, this function will return an error is the folder doesn't
%   exist. If |noprompt_flag| is not called (or is anything else but
%   'noprompt', then the function will throw an UI interface to prompt for
%   a folder.
%
%   *OUTPUT VARIABLES*
%   * |output_variable_1|: TODO: write description and info on variable
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

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



