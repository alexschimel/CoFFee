function rawfileslist = CFF_list_raw_files_in_dir(folder_init)
%CFF_LIST_RAW_FILES_IN_DIR  List raw multibeam files available in folder
%
%   Returns in this order: pairs of .all/.wcd, unpaired .all files,
%   unpaired .wcd files, pairs of .kmall/.kmwcd, unpaired .kmall files,
%   unpaired .kmwcd files, .s7k files.
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% for now, list all raw files whatever the sonar type, but maybe at some
% point add some control in input to sspecify what sonar types we want

if isempty(folder_init)
    rawfileslist = {};
    return
end


%% Kongsberg all format

% list files
all_files = list_files_with_ext(folder_init,'*.all');
wcd_files = list_files_with_ext(folder_init,'*.wcd');

% finding pairs
[paired_all_wcd_files, all_only_files, wcd_only_files] = pair_files(all_files, wcd_files);


%% Kongsberg kmall format

% list files
kmall_files = list_files_with_ext(folder_init,'*.kmall');
kmwcd_files = list_files_with_ext(folder_init,'*.kmwcd');

% finding pairs
[paired_kmall_kmwcd_files, kmall_only_files, kmwcd_only_files] = pair_files(kmall_files, kmwcd_files);


%% Reson s7k format

% list files
s7k_files = list_files_with_ext(folder_init,'*.s7k');


%% Compiling full list of files
rawfileslist = cat(1, ...
    paired_all_wcd_files, all_only_files, wcd_only_files, ...
    paired_kmall_kmwcd_files, kmall_only_files, kmwcd_only_files, ...
    s7k_files);


end

%% subfunctions %%

%%
function files = list_files_with_ext(folder,extension)
% returns full filepath (with folder, name, and extension) of all files in
% "folder" with matching "extension". Note this works whatever the case of
% extension, e.g. if looking for ".all", it will also find ".ALL"

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
[C,ia,ib] = intersect(name_A, name_B);
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
[C,ia] = setdiff(name_A,name_B);
if ~isempty(C)
    A_only_list = fullfile(filepath_A(ia),strcat(name_A(ia),ext_A(ia)));
else
    A_only_list = {};
end

% B only
[C,ib] = setdiff(name_B,name_A);
if ~isempty(C)
    B_only_list = fullfile(filepath_B(ib),strcat(name_B(ib),ext_B(ib)));
else
    B_only_list = {};
end

end

