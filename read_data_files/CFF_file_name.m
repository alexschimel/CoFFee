function name = CFF_file_name(filename, varargin)
%CFF_FILE_NAME  Get name of file(s)
%
%   Optional argument allows returning the extension as well. See syntax
%   examples.
%
%   NAME = CFF_FILE_NAME(FILENAME) returns the string name of the input
%   string filename, with no folder, and no extension. For example, 
%   CFF_FILE_NAME('C:\my_folder\my_file.bin') returns 'my_file'.
%
%   CFF_FILE_NAME(FILENAME,FLAG) with FLAG = 1 returns the string name,
%   with extension, of the input string filename, with no folder. For
%   example, CFF_FILE_NAME('C:\my_folder\my_file.bin',1) returns
%   'my_file.bin'.
%
%   NAMES = CFF_FILE_NAME(FILENAMES) returns the cell arrray of string
%   names of the input cell array of string filenames, with no folder. For
%   example, CFF_file_extension({'C:\my_file.bin','C:\my_other_file.jpg'})
%   returns {'my_file','my_other_file'}.
%   CFF_file_extension({'C:\my_file.bin','C:\my_other_file.jpg'},1) returns
%   {'my_file.bin','my_other_file.jpg'}

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2021-2022; Last revision: 25-07-2022

% input parser
p = inputParser;
addRequired(p,'filename',@(x) ischar(x) || iscell(x));
addOptional(p,'with_extension',0,@(x) isnumeric(x) && numel(x)==1 && (x==0|x==1) );
parse(p,filename,varargin{:});
filename = p.Results.filename;
with_extension = p.Results.with_extension;
clear p

if ischar(filename)
    % single file
    [~,name,ext] = fileparts(filename);
    % add extension if requested
    if with_extension
        name = [name, ext];
    end
elseif iscell(filename)
    % cell array of files
    name = cell(size(filename));
    for ii = 1:numel(filename)
        [~,name{ii},ext] = fileparts(filename{ii});
        % add extension if requested
        if with_extension
            name{ii} = [name{ii}, ext];
        end
    end
end


