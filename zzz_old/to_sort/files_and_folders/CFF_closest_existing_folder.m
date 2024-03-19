function folder = CFF_closest_existing_folder(in)
%CFF_CLOSEST_EXISTING_FOLDER  One-line description
%
%   Given a file or folder "in", folder = CFF_closest_existing_folder(in)
%   returns the closest existing folder in the file path.
%   That is, if given an input "folderA/folderB/folderC/filename.txt", this
%   function will tests, in order:
%   - if "folderA/folderB/folderC/filename.txt" is an existing folder
%   - if "folderA/folderB/folderC/" is an existing folder
%   - if "folderA/folderB/" is an existing folder
%   - if "folderA/" is an existing folder
%
%   The function will return the first of such folders if it exists.
%   And if none exist, it returns pwd.
%
%   Function to be used for uigetfile/uigetdir
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

C = strsplit(in,filesep);

for ii = length(C):-1:1
    folder = fullfile(C{1:ii});
    if exist(folder,'dir')
        return
    end
end
folder = pwd;