function ext = CFF_file_extension(filename)
%CFF_FILE_EXTENSION  Get extension of file
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

[~,~,ext] = fileparts(filename);