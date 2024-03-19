function bools = CFF_is_folder_empty(folders)
%CFF_IS_FOLDER_EMPTY  Test if input folder(s) is empty. Return 1 if so.
%

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(folders)
    folders = {folders};
end

bools = false(size(folders));

for ii = 1:numel(folders)
    folder = folders{ii};
    dcont = dir(folder);
    if numel(dcont)==2 && strcmp(dcont(1).name,'.') && strcmp(dcont(2).name,'..')
        bools(ii) = 1;
    end
end


