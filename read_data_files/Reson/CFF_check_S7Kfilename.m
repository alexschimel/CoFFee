function out = CFF_check_S7Kfilename(rawfilename)
%CFF_CHECK_S7KFILENAME  Check file exists and has s7k extension
%
%   out = CFF_CHECK_S7KFILENAME(rawFile) checks if single file rawFile
%   (char) exists and has '.s7k' extension. 
%
%   See also CFF_CHECK_FILENAME

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

out = CFF_check_filename(rawfilename,{'.s7k'});