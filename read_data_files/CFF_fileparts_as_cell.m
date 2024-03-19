function [filepath,name,ext] = CFF_fileparts_as_cell(file_list)
%CFF_FILEPARTS_AS_CELL  Like FILEPARTS, but always returning cell arrays
%
%   The MATLAB function FILEPARTS can take a cell array of file names as
%   input. If this array has zero or N>2 elements, the parts are cell
%   arrays. But if it has only one element, the returned parts are strings.
%   CFF_FILEPARTS_AS_CELL corrects this silly behaviour by always
%   outputting cells.
%
%   See also FILEPARTS.

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

[filepath,name,ext] = fileparts(file_list);

if ischar(filepath)
    filepath = {filepath};
end
if ischar(name)
    name = {name};
end
if ischar(ext)
    ext = {ext};
end

end
