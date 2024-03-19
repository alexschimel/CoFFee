function bool = CFF_is_valid_kmall_format_extension(file)
%CFF_IS_VALID_KMALL_FORMAT_EXTENSION  Check file extension is kmall/wcd
%
%   Tests if input file (string, or cell array of strings) has '.kmall',
%   '.KMALL', '.kmwcd' or '.KMWCD' extension

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(file)
    file = {file};
end

% function checking if extension is Kongsberg's
isK = @(x) any(strcmp(CFF_file_extension(x),{'.kmall','.KMALL','.kmwcd','.KMWCD'}));

bool = cellfun(isK,file);
