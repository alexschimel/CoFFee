function bool = CFF_is_Reson_file(file)
%CFF_IS_RESON_FILE  One-line description
%


%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

if ischar(file)
    file = {file};
end

% function checking if extension is Reson's
isK = @(x) any(strcmp(CFF_file_extension(x),{'.s7k','.S7K'}));

bool = cellfun(isK,file);