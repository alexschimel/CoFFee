function out = CFF_check_S7Kfilename(rawfilename)
%CFF_CHECK_S7KFILENAME  Check file exists and has s7k extension
%
%   out = CFF_CHECK_S7KFILENAME(rawFile) checks if single file rawFile
%   (char) exists and has '.s7k' extension. 
%
%   See also CFF_CHECK_FILENAME

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 26-08-2021

out = CFF_check_filename(rawfilename,{'.s7k'});