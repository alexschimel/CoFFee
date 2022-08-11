%% CFF_list_files_in_dir.m
%
% List the files available for the app in input folder. Files are available
% only if the pair .all/.wcd exists. Also returns whether these pairs have
% been converted to .mat format.
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |folder_init|: Required. escription (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |folders|: Description (Information). XXX
% * |files|: Description (Information). XXX
% * |converted|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% * 2018-10-11: first version.
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel, NIWA.

%% Function
function [folders,files,converted] = CFF_list_files_in_dir(folder_init, varargin)

%% input parsing

% init
p = inputParser;

% required
addRequired(p,'folder_init',@ischar);

% optional
addOptional(p,'warning_flag','warning_off',@(x) ischar(x) && ismember(x,{'warning_on' 'warning_off'}));

% parse
parse(p,folder_init,varargin{:})

% get results
warning_flag = p.Results.warning_flag;
clear p


%% get .all files
AllFilename_list = subdir(fullfile(folder_init,'*.all'));

if ~isempty(AllFilename_list)
    
    AllFilename_cell = {AllFilename_list([AllFilename_list(:).isdir]==0).name};
    
    % split in folders and file names and recombine
    [all_folders,all_files,~] = cellfun(@fileparts,AllFilename_cell,'UniformOutput',0);
    all_files = fullfile(all_folders,all_files);
    
else
    all_files = {};
end

%% get .wcd files
WCDFilename_list = subdir(fullfile(folder_init,'*.wcd'));

if ~isempty(WCDFilename_list)
    
    WCDFilename_cell = {WCDFilename_list([WCDFilename_list(:).isdir]==0).name};
    
    % split in folders and file names and recombine
    [wcd_folders,wcd_files,~] = cellfun(@fileparts,WCDFilename_cell,'UniformOutput',0);
    wcd_files = fullfile(wcd_folders,wcd_files);
    
else
    wcd_files = {};
end


%% files to keep
% take pairs of files, or at default wcd files, or at default all files
files_pair = intersect(all_files,wcd_files);
if ~isempty(files_pair)
    files_full = files_pair;
else
    if ~isempty(wcd_files)
        files_full = wcd_files;
    else
        if ~isempty(all_files)
            files_full = all_files;
        else
            files_full = {};
        end
    end
end
    
    
%% warnings
switch warning_flag
    case 'warning_on'
        if isempty(all_files) && ~isempty(wcd_files)
            warning('There are no ''.all'' files in this folder or its subfolders.. Listing ''.wcd'' files only.');
        elseif ~isempty(all_files) && isempty(wcd_files)
            warning('There are no ''.wcd'' files in this folder or its subfolders.. Listing ''.all'' files only.');
        elseif ~isempty(all_files) && ~isempty(wcd_files)
            if isempty(files_pair)
                warning('There are no pairs of ''.all'' and ''.wcd'' files in this folder or its subfolders.. Listing ''.wcd'' files only.');
            else
                if length(files_pair)~=length(all_files)
                    warning('Listing pairs of ''.all'' and ''.wcd'' files in this folder or its subfolders, but note there are also ''.all'' files without a corresponding ''.wcd'' file.');
                end
                if length(files_pair)~=length(wcd_files)
                    warning('Listing pairs of ''.all'' and ''.wcd'' files in this folder or its subfolders, but note there are also ''.wcd'' files without a corresponding ''.all'' file.');
                end
            end
        elseif isempty(all_files) && isempty(wcd_files)
            warning('There are no ''.all'' nor ''.wcd'' files in this folder or its subfolders.');
        end
end

%% output
if isempty(files_full)
    
    folders = {};
    files = {};
    converted = [];
    
else
    
    % files we keep
    [folders,files,~] = cellfun(@fileparts,files_full,'UniformOutput',0);
    
    % list of fData files (aka, converted files)
    wc_dir = CFF_converted_data_folder(files_full);
    mat_fdata_files = fullfile(wc_dir,'fData.mat');
    
    % boolean for whether these mat files exist
    if ischar(mat_fdata_files)
        mat_fdata_files = {mat_fdata_files};
    end
    converted = cellfun(@(x) exist(x,'file')>0,mat_fdata_files);    
    
end