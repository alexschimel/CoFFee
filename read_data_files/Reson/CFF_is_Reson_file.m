function bool = CFF_is_Reson_file(file)
%CFF_IS_RESON_FILE  One-line description
%


%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

if ischar(file)
    file = {file};
end

% function checking if extension is Reson's
isK = @(x) any(strcmp(CFF_file_extension(x),{'.s7k','.S7K'}));

bool = cellfun(isK,file);