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
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

if ischar(filename)
    [~,~,ext] = fileparts(filename);
    return
elseif iscell(filename)
    ext = cell(size(filename));
    for ii = 1:numel(filename)
        [~,~,ext{ii}] = fileparts(filename{ii});
    end
end


