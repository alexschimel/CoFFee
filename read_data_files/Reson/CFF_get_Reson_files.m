function [Reson_files,fileroot_reshaped] = CFF_get_Reson_files(fileroot)
%CFF_GET_RESON_FILES  One-line description
%

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(fileroot)
    fileroot = {fileroot};
end

fileroot_reshaped = reshape(fileroot,[numel(fileroot),1]);

Reson_files = cell(length(fileroot_reshaped),1);

for ii = 1:length(fileroot_reshaped)
    
    Reson_files{ii,1} = strcat(fileroot_reshaped{ii}, '.s7k');
    
end
