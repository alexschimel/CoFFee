function out = CFF_check_KMALLfilename(rawfilename)
%CFF_CHECK_KMALLFILENAME  Check file exists and has kmall extension
%
%   out = CFF_CHECK_KMALLFILENAME(rawFile) checks if single file
%   rawFile (char) exists and has '.kmall' or ',kmwcd' extension.
%
%   out = CFF_CHECK_KMALLFILENAME(rawFilesPair) checks if pair of files
%   rawFilesPair (2x1 cell array of chars) exist, match (same name), and
%   have '.kmall' and '.kmwcd' extensions.
%
%   See also CFF_CHECK_FILENAME.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021

out = CFF_check_filename(rawfilename,{'.kmall','.kmwcd'});
