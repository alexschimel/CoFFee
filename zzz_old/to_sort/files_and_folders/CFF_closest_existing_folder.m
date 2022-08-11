%% CFF_closest_existing_folder.m
%
% Given a file or folder "in", folder = CFF_closest_existing_folder(in)
% returns the closest existing folder in the file path.
% That is, if given an input "folderA/folderB/folderC/filename.txt", this
% function will tests, in order:
% - if "folderA/folderB/folderC/filename.txt" is an existing folder
% - if "folderA/folderB/folderC/" is an existing folder
% - if "folderA/folderB/" is an existing folder
% - if "folderA/" is an existing folder
%
% The function will return the first of such folders if it exists.
% And if none exist, it returns pwd.
%
% Function to be used for uigetfile/uigetdir
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |in|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |folder|: TODO: write description and info on variable
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
function folder = CFF_closest_existing_folder(in)

C = strsplit(in,filesep);

for ii = length(C):-1:1
    folder = fullfile(C{1:ii});
    if exist(folder,'dir')
        return
    end
end
folder = pwd;