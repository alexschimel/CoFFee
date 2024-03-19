function bool = CFF_is_Kongsberg_file(file)
% CFF_is_Kongsberg_file.m
%
% Tests if input file (string, or cell array of strings) has '.all',
% '.ALL', '.wcd' or '.WCD' extension 

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(file)
    file = {file};
end

% function checking if extension is Kongsberg's
isK = @(x) any(strcmp(CFF_file_extension(x),{'.all','.ALL','.wcd','.WCD'}));

bool = cellfun(isK,file);







