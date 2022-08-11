function bool = CFF_is_valid_kmall_format_extension(file)
%CFF_IS_VALID_KMALL_FORMAT_EXTENSION  Check file extension is kmall/wcd
%
%   Tests if input file (string, or cell array of strings) has '.kmall',
%   '.KMALL', '.kmwcd' or '.KMWCD' extension
%

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

if ischar(file)
    file = {file};
end

% function checking if extension is Kongsberg's
isK = @(x) any(strcmp(CFF_file_extension(x),{'.kmall','.KMALL','.kmwcd','.KMWCD'}));

bool = cellfun(isK,file);
