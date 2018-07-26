%% CFF_correct_filesep.m
%
% The path or file separator symbol is different between windows-based
% system ("\") and unix-based systems, including mac ("/").
% out = CFF_correct_filesep(in) corrects file, folder and path names "in"
% with the appropriate filesep. Takes single input entries (string of
% characters) as well as multiple entries (cell arrays of characters).
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
function out = CFF_correct_filesep(in)

correct_filesep = @(x) regexprep(x,'[/\\]',filesep);

if ischar(in)
    % if input is a string, apply to string
    out = correct_filesep(in);
elseif iscell(in)
    % if input is a cell, apply to each element
    out = cellfun(correct_filesep,in,'UniformOutput',0);
end