function rawfileslist = CFF_list_raw_files_in_dir(folder_init, recursive_flag, filesType)
%CFF_LIST_RAW_FILES_IN_DIR  List raw multibeam files available in folder
%
%   By default, searches only in "folder_init". If "recursive_flag" = 1,
%   also searches recursively. 
%
%   Optional FILESTYPE only search for specified types. If absent,
%   returning everything
%
%   filesTypes, and returned in this grouped order: 
%   1) ".all/.wcd" - pairs of .all/.wcd, 
%   2) ".all" - unpaired .all files, 
%   3) ".wcd" - unpaired .wcd files, 
%   4) ".kmall/.kmwcd" - pairs of .kmall/.kmwcd, 
%   5) ".kmall" - unpaired .kmall files,
%   6) ".kmwcd" - unpaired .kmwcd files, 
%   7) ".s7k" - .s7k files.
%   
%   In each group, files are listed by alphabetical fullpathname.

%   Copyright 2017-2023 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if isempty(folder_init)
    rawfileslist = {};
    return
end

% allow possibility to look for files recursively (i.e.
% including all sub-folders)
if exist('recursive_flag','var') && recursive_flag==1
    folder_init = fullfile(folder_init,'**');
end

% allow possibility to only search for certain file types
if exist('filesType','var')
    if ischar(filesType)
        filesType = {filesType};
    end
else
    filesType = {...
        '.all/.wcd',...
        '.all',...
        '.wcd',...
        '.kmall/.kmwcd',...
        '.kmall',...
        '.kmwcd',...
        '.s7k'};
end


%% Kongsberg all format

% list files
all_files = list_files_with_ext(folder_init,'*.all');
wcd_files = list_files_with_ext(folder_init,'*.wcd');

if ~ismember('.all/.wcd',filesType)
    % pairing not wanted
    paired_all_wcd_files = {};
    if ismember('.all',filesType)
        all_only_files = all_files;
    else
        all_only_files = {};
    end
    if ismember('.wcd',filesType)
        wcd_only_files = wcd_files;
    else
        wcd_only_files = {};
    end
else
    % pairing wanted
    [paired_all_wcd_files, all_only_files, wcd_only_files] = pair_files(all_files, wcd_files);
end


%% Kongsberg kmall format

% list files
kmall_files = list_files_with_ext(folder_init,'*.kmall');
kmwcd_files = list_files_with_ext(folder_init,'*.kmwcd');

if ~ismember('.kmall/.kmwcd',filesType)
    % pairing not wanted
    paired_kmall_kmwcd_files = {};
    if ismember('.kmall',filesType)
        kmall_only_files = kmall_files;
    else
        kmall_only_files = {};
    end
    if ismember('.kmwcd',filesType)
        kmwcd_only_files = kmwcd_files;
    else
        kmwcd_only_files = {};
    end
else
    % pairing wanted
    [paired_kmall_kmwcd_files, kmall_only_files, kmwcd_only_files] = pair_files(kmall_files, kmwcd_files);
end



%% Reson s7k format

% list files
if ismember('.s7k',filesType)
    s7k_files = list_files_with_ext(folder_init,'*.s7k');
else
    s7k_files = {};
end


%% Compiling full list of files

% concatenate everything
rawfileslist = cat(1, ...
    paired_all_wcd_files, ...
    all_only_files, ...
    wcd_only_files, ...
    paired_kmall_kmwcd_files, ...
    kmall_only_files, ...
    kmwcd_only_files, ...
    s7k_files);

end

%% subfunctions %%

%%
function files = list_files_with_ext(folder,extension)
% returns full filepath (with folder, name, and extension) of all files in
% "folder" with matching "extension". Note this works whatever the case of
% extension, e.g. if looking for ".all", it will also find ".ALL". If
% "folder" ends with "\**", the search is recursive.

files_list = dir(fullfile(folder,extension));

if ~isempty(files_list)
    idx = [files_list(:).isdir]==0;
    filenames = {files_list(idx).name}';
    folders = {files_list(idx).folder}';
    files = fullfile(folders,filenames);
else
    files = {};
end

end


%%
function [paired_files_list, A_only_list, B_only_list] = pair_files(file_list_A, file_list_B)
% compares the filenames (i.e. without folder or extension) of two list of
% files and returns when they match as "pairs". Also returns those that
% don't match

% extract parts of files in each list
[filepath_A,name_A,ext_A] = CFF_fileparts_as_cell(file_list_A);
[filepath_B,name_B,ext_B] = CFF_fileparts_as_cell(file_list_B);

% pairs
[C,ia,ib] = intersect(name_A, name_B, 'stable');
if ~isempty(C)
    paired_files_list = cell(length(C),1);
    for ii = 1:length(C)
        match_A_file = fullfile(filepath_A{ia(ii)},strcat(name_A{ia(ii)},ext_A{ia(ii)}));
        match_B_file = fullfile(filepath_B{ib(ii)},strcat(name_B{ib(ii)},ext_B{ib(ii)}));
        paired_files_list{ii,1} = {match_A_file, match_B_file};
    end
else
    paired_files_list = {};
end

% A only
[C,ia] = setdiff(name_A,name_B, 'stable');
if ~isempty(C)
    A_only_list = fullfile(filepath_A(ia),strcat(name_A(ia),ext_A(ia)));
else
    A_only_list = {};
end

% B only
[C,ib] = setdiff(name_B,name_A, 'stable');
if ~isempty(C)
    B_only_list = fullfile(filepath_B(ib),strcat(name_B(ib),ext_B(ib)));
else
    B_only_list = {};
end

end

