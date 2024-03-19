function [IN_files,OUT_files] = CFF_filelist_for_conversion(varargin)
% CFF_filelist_for_conversion.m
%
% CFF_filelist_for_conversion creates the list of input files and output
% files prior to conversion to .mat format.
%
% *USE*
%
% [in,out] = CFF_filelist_for_conversion() 
% -> Will prompt you for files to convert, store them with full path in
% "in" and prepare the file names for after conversion in "out".
%
% The general form for using the function is as follow:
%
% [in,out] = CFF_filelist_for_conversion(var1,var2,ext)
%
% -> var1 is the input information. It can be a string file name, a cell
% array of string file names, or a folder where to find the input file
% names. If left empty [], it will prompt you for file names.
%
% -> var2 is the output information. It can be a single string file name
% (ending in ".mat") if var1 was a single string filename. Or it can
% be a cell array of string if var1 was a cell array of string filenames.
% It can be an existing or non-existing folder name for where to store the
% files (with default mat filenames). Finally, if empty [] or not given in
% input, the current directory will be used as default output folder.
%
% -> ext is the extension of the files to be converted, mostly used in
% conjunction with using a folder name for var1, example:
% [in,out] = CFF_filelist_for_conversion(input_folder,[],'.all')
%
% Note that, in all cases:
% * if no output folder is provided, the default folder for
% output files is the current folder.
% * if no output filename(s) is/are provided, the default naming convention
% is used for output files.
%
% With ZERO input -> uigetfiles to prompt for files to convert.
%
% With varargin{1}
% * Test if input is existing folder, if so list all files in folder.
% * Test if input is/are file(s) that exists, if so just take those files.
% * Otherwise, error.
%
% With varargin{2}
% * Test if it is an extension. If so, conserve only files with said
% extension out of the list of files.
% * Test if is existing folder. If so, this is output folder.
% * Test if looks like a folder (ends with filesep). If so this is output
% folder to create.
% * Test if looks like a filename that matches number of inputs. If so this
% is output filenames (with folder).
% * Otherwise, error.
%
% With varargin{3}
% * should only happen in case varargin{2} was an extension.
% * Test if is existing folder. If so, this is output folder.
% * Test if looks like a folder (ends with filesep). If so this is output
% * Otherwise, error.
%
% *EXAMPLE*
%
% % all following examples need the said input files to exist:
% [in1,out1] = CFF_filelist_for_conversion()
% [in1,out1] = CFF_filelist_for_conversion([])
% [in1,out1] = CFF_filelist_for_conversion('D:\Alex\test\test1.all')
% [in2,out2] = CFF_filelist_for_conversion('D:\Alex\test\test1.all','D:\Alex\test\tagada\test.mat')
% [in3,out3] = CFF_filelist_for_conversion({'D:\Alex\test\test1.all','D:\Alex\test\test2.all'})
% [in4,out4] = CFF_filelist_for_conversion({'D:\Alex\test\test1.all','D:\Alex\test\test2.all'},{'D:\Alex\test\boum\test1.mat','D:\Alex\test\boum\test2.mat'})
% [in5,out5] = CFF_filelist_for_conversion({'D:\Alex\test\test1.all','D:\Alex\test\test2.all'},'D:\Alex\test\tsoin\')
% [in6,out6] = CFF_filelist_for_conversion('D:\Alex\test\')
% [in7,out7] = CFF_filelist_for_conversion('D:\Alex\test\',[],'.all')
% [in8,out8] = CFF_filelist_for_conversion('D:\Alex\test\','D:\Alex\test\paf\')
% [in9,out9] = CFF_filelist_for_conversion('D:\Alex\test\','D:\Alex\test\paf\','.all',)
%
% see end of function for more working examples

%   Copyright 2014-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% The default output folder is the current folder.
OUT_folder = [pwd filesep];

% If no input -> uigetfiles to prompt for files to convert.
if nargin==0
    [IN_files,IN_folder] = uigetfile('*.*','Select file(s) to convert','MultiSelect','on');
    IN_files = fullfile(IN_folder,IN_files');
end

% varargin{1} is input
if nargin>0
    if isempty(varargin{1})
        % if varargin{1} is empty, prompt for files
        [IN_files,IN_folder] = uigetfile('*.*','Select file(s) to convert','MultiSelect','on');
        IN_files = fullfile(IN_folder,IN_files');
    elseif ischar(varargin{1}) && exist(varargin{1},'dir')
        % if varargin{1} is an existing folder name, grab all files in this folder as input files
        [IN_files,IN_folder] = CFF_files_with_wanted_extension(varargin{1});
        IN_files = fullfile(IN_folder,IN_files);
    elseif ischar(varargin{1}) && exist(varargin{1},'file')
        % if varargin{1} is an existing file name, turn it as cell
        IN_files = CFF_full_path(varargin{1});
        IN_files = {IN_files};
    elseif iscell(varargin{1})
        % if varargin{1} is a cell array, test that all cells are valid filenames
        for ii = 1:length(varargin{1})
            if exist(varargin{1}{ii},'file')
                IN_files{ii,1} = CFF_full_path(varargin{1}{ii});
            else
                error('varargin{1} is not a valid input folder or (set of) file(s)');
            end
        end
    else
        error(' varargin{1} is not a valid input folder or (set of) file(s)');
    end
end

% If we have an extension in input, reduce our list of files to only the appropriate ones
if nargin>2
    % varargin{3} should be our extension, check it out
    if ~strcmp(varargin{3}(1),'.') || ~isempty(regexp(varargin{3},'[/\\]'))
        error('varargin{3} should be an extension');
    end
    % conserve only files with said extension out of the list of files.
    for ii=length(IN_files):-1:1
        [~,~,e] = fileparts(IN_files{ii});
        if ~strcmpi(e,varargin{3})
            IN_files(ii) = [];
        end
    end
end

% varargin{2} is our output
if nargin>1
    if isempty(varargin{2})
        % if varargin{2} is empty, keep default pwd as output folder
    elseif ischar(varargin{2}) && exist(varargin{2},'dir')
        % if varargin{2} is an existing folder, this is our output folder
        OUT_folder = CFF_full_path(varargin{2});
    elseif ischar(varargin{2}) && ( strcmp(varargin{2}(end),'/') ||  strcmp(varargin{2}(end),'\') )
        % if varargin{2} is a string of characters ending with a filesep,
        % this is the output folder that will need to be created later.
        varargin{2} = CFF_correct_filesep(varargin{2});
        mkdir(varargin{2});
        OUT_folder = CFF_full_path(varargin{2});
        rmdir(OUT_folder);
    elseif ischar(varargin{2}) && strcmp(varargin{2}(end-3:end),'.mat') && length(IN_files)==1
        % if varargin{2} is a string of char ending in '.mat' while we have one input file, this is the output file to create.
        
        % first correct filsep if needed
        varargin{2} = CFF_correct_filesep(varargin{2});
        % then, get the path
        [p,n,e] = fileparts(varargin{2});
        if isempty(p)
            % if p is empty, path is current path, aka default OUT_folder
        elseif ischar(p) && exist(p,'dir')
            % if p is an existing folder, this is our output folder
            OUT_folder = CFF_full_path(p);
        else
            % if p doesn't exist, we need to create it, get its full path,
            % and delete it,
            mkdir(p);
            OUT_folder = CFF_full_path(p);
            rmdir(p);
        end
        % finally, complete OUT_files with its path
        OUT_files = {fullfile(OUT_folder,[n e])};
        
    elseif iscell(varargin{2}) && numel(varargin{2})==numel(IN_files)
        % if varargin{2} is a cell array and varargin{2} matches number of inputs, test if all those potential files have a '.mat' extention.
        for ii = 1:length(varargin{2})
            % first correct filsep if needed
            varargin{2}{ii} = CFF_correct_filesep(varargin{2}{ii});
            
            % then, get the path
            [p,n,e] = fileparts(varargin{2}{ii});
            
            % throw error if extension is not .mat
            if ~strcmp(e,'.mat')
                error('varargin{2} is not a valid output folder, extension or (set of) output file(s)')
            end
            
            % still here? Alright, get the full path for this file
            if isempty(p)
                % if p is empty, path is current path, aka default OUT_folder
            elseif ischar(p) && exist(p,'dir')
                % if p is an existing folder, this is our output folder
                OUT_folder = CFF_full_path(p);
            else
                % if p doesn't exist, we need to create it, get its full path,
                % and delete it,
                mkdir(p);
                OUT_folder = CFF_full_path(p);
                rmdir(p);
            end
            % finally, complete OUT_files with its path
            OUT_files(ii,1) = {fullfile(OUT_folder,[n e])};
        end
    else
        error('varargin{2} is not a valid output folder, extension or (set of) output file(s)')
    end
end

% last, if the last step didn't create out_files, do so now. Using default
% convention.
if ~exist('OUT_files','var')
    for ii = 1:length(IN_files)
        [~,n,e] = fileparts(IN_files{ii});
        OUT_files{ii,1} = fullfile(OUT_folder,[n e]);
    end
    OUT_files = CFF_default_mat_filename(OUT_files);
end



%% TESTING

% % no input
% [IN_files,OUT_files] = CFF_filelist_for_conversion
%
% % empty input
% [IN_files,OUT_files] = CFF_filelist_for_conversion([])
%
% % input folder in folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion('ALL')
%
% % input relative folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion('.\DATA\ALL')
%
% % input absolute folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion('C:\Users\schimela\OneDrive - NIWA\MATLAB LEGACY CODE\DEVPT\DATA\ALL')
%
% % input folder on path
% [IN_files,OUT_files] = CFF_filelist_for_conversion('\EM2040C\')
%
% % input folder with wrong filesep
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA\ALL\')
% [IN_files,OUT_files] = CFF_filelist_for_conversion('C:\Users\schimela\OneDrive - NIWA\MATLAB LEGACY CODE\DEVPT/DATA\ALL\')
%
% % input file in folder
% % NOTE IT WILL FIND THE FILE IF IT'S ON THE SEARCH PATH
% [IN_files,OUT_files] = CFF_filelist_for_conversion('0003_20140213_052947_Yolla.all')
%
% % input file in relative folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL\0003_20140213_052947_Yolla.all')
%
% % input file in absolute folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion('C:\Users\schimela\OneDrive - NIWA\MATLAB LEGACY CODE\DEVPT\DATA\ALL\0003_20140213_052947_Yolla.all')
%
% % input cell array of files
% [IN_files,OUT_files] = CFF_filelist_for_conversion({'.\DATA\ALL\0003_20140213_052947_Yolla.all','.\DATA\ALL\0001_20140213_052736_Yolla.all'})
%
% % input file with extension
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL\0003_20140213_052947_Yolla.all',[],'.all')
%
% % input set of files with extension
% [IN_files,OUT_files] = CFF_filelist_for_conversion('.\DATA\ALL\0003_20140213_052947_Yolla.all',[],'.wcd')
%
% % input folder with extension
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL/',[],'.all')
%
% % input set of files with extension
% [IN_files,OUT_files] = CFF_filelist_for_conversion({'.\DATA\ALL\0003_20140213_052947_Yolla.all','fig1.png'},[],'.all')
%
% % with existing output folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL/','./DATA/MAT')
%
% % with non-existent folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL/','./DATA/pouf2/','.all')
%
% % with input file and output filename
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL\0003_20140213_052947_Yolla.all','test.mat')
%
% % with input file and output filename in existing directory
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL\0003_20140213_052947_Yolla.all','./tempMAT/test.mat')
%
% % with input file and output filename in existing directory
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL\0003_20140213_052947_Yolla.all','C:\Users\schimela\OneDrive - NIWA\MATLAB LEGACY CODE\DEVPT/tempMAT/test.mat')
%
% % with input file and output filename in non-existing directory
% [IN_files,OUT_files] = CFF_filelist_for_conversion('./DATA/ALL\0003_20140213_052947_Yolla.all','./newdir/test.mat')
%
% % with input files and output files matching in numbers
% [IN_files,OUT_files] = CFF_filelist_for_conversion({'./DATA/ALL\0003_20140213_052947_Yolla.all','./DATA/ALL\0001_20140213_052736_Yolla.all'},{'test1.mat','test2.mat'})
%
% % with input files and output files matching in numbers, in existing folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion({'./DATA/ALL\0003_20140213_052947_Yolla.all','./DATA/ALL\0001_20140213_052736_Yolla.all'},{'./tempMAT/test1.mat','./DATA/bing98/test2.mat'})
%
% % with input files and output files matching in numbers, in existing folder
% [IN_files,OUT_files] = CFF_filelist_for_conversion({'./DATA/ALL\0003_20140213_052947_Yolla.all','fig1.png'},{'./tempMAT/test1.mat','./DATA/bing98/test2.mat'},'.all')
