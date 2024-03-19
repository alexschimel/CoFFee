function [Kongs_files,fileroot_reshaped] = CFF_get_Kongsberg_files(fileroot)
% CFF_get_Kongsberg_files.m
%
% From a filename root (without extension), returns it with extensions .all
% and .wcd

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(fileroot)
    fileroot = {fileroot};
end

fileroot_reshaped = reshape(fileroot,[numel(fileroot),1]);
    
Kongs_files = cell(length(fileroot_reshaped),2);

for ii = 1:length(fileroot_reshaped)
    
    Kongs_files{ii,1} = strcat(fileroot_reshaped{ii}, '.all');
    Kongs_files{ii,2} = strcat(fileroot_reshaped{ii}, '.wcd');

end

        
