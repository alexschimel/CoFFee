%% CFF_check_ALLfilename.m
%
% CFF_check_ALLfilename checks if input filename is a Kongsberg file
% ("myfile.all" or "myfile.wcd") or the root name ("myfile") of a pair of
% all/wcd and that it/they exist.
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._  
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX 
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
% 
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._ 
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._ 
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._ 
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function out = CFF_check_ALLfilename(file)

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