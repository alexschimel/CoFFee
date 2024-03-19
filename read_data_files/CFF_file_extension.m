function ext = CFF_file_extension(filename)
%CFF_FILE_EXTENSION  Get extension of file(s)
%
%   ext = CFF_FILE_EXTENSION(filename) returns the STRING extension of
%   input STRING filename.
%
%   ext = CFF_FILE_EXTENSION(filename) returns a cell array of STRING
%   extensions of input cell array of STRING filenames.
%
%   *EXAMPLE*
%   ext = CFF_file_extension('f.mat'); % returns 'mat'
%   ext = CFF_file_extension({'f.mat', 'g.bin'}); % returns {'mat','bin'}

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(filename)
    [~,~,ext] = fileparts(filename);
    return
elseif iscell(filename)
    ext = cell(size(filename));
    for ii = 1:numel(filename)
        [~,~,ext{ii}] = fileparts(filename{ii});
    end
end


