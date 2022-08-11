function bools = CFF_is_folder_empty(folders)
%CFF_IS_FOLDER_EMPTY  Test if input folder(s) is empty. Return 1 if so.
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no)
%   2017-2021; Last revision: 21-05-2021

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


