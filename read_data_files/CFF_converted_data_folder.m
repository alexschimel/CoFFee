function wc_dir = CFF_converted_data_folder(rawfileslist)
%CFF_CONVERTED_DATA_FOLDER  Returns converted data folder for file(s)
%
%   Gets the path to the folder for data converted by CoFFee from a raw
%   filename.
%
%   WC_DIR = CFF_CONVERTED_DATA_FOLDER(RAWFILESLIST) returns the folder
%   path 'X/Coffee_files/filename/' for input filename 'X/filename.ext'.
%   Also works with cell arrays of string filenames.
%
%   See also CFF_CONVERT_RAW_FILES, CFF_LOAD_CONVERTED_FILES.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2022-2022; Last revision: 25-07-2022

if isempty(rawfileslist)
    wc_dir = [];
    return
end

if ischar(rawfileslist)
    rawfileslist = {rawfileslist};
end

% simplify rawfileslist when pairs occur
rawfileslist = CFF_onerawfileonly(rawfileslist);
n_files = numel(rawfileslist);

% get path and filename (without extension) for each file
[filepath,filename,~]  = cellfun(@fileparts,rawfileslist,'UniformOutput',0);

% define coffee folder
coffee_dir_name = 'Coffee_files';
coffee_dir_name = repmat({coffee_dir_name},[n_files, 1]);

% putting everything together
wc_dir = cellfun(@fullfile,filepath,coffee_dir_name,filename,'UniformOutput',0);

if numel(wc_dir) == 1
    wc_dir = cell2mat(wc_dir);
end