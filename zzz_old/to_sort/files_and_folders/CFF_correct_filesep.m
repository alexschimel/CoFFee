function out = CFF_correct_filesep(in)
%CFF_CORRECT_FILESEP  One-line description
%
%   The path or file separator symbol is different between windows-based
%   system ("\") and unix-based systems, including mac ("/"). 
%
%   OUT = CFF_CORRECT_FILESEP(IN) corrects file, folder and path names IN
%   with the appropriate filesep. Takes single input entries (string of
%   characters) as well as multiple entries (cell arrays of characters). 
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

correct_filesep = @(x) regexprep(x,'[/\\]',filesep);

if ischar(in)
    % if input is a string, apply to string
    out = correct_filesep(in);
elseif iscell(in)
    % if input is a cell, apply to each element
    out = cellfun(correct_filesep,in,'UniformOutput',0);
end