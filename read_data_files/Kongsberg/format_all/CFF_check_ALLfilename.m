function out = CFF_check_ALLfilename(rawfilename)
%CFF_CHECK_ALLFILENAME  Check file exists and has all extension
%
%   out = CFF_CHECK_ALLFILENAME(rawFile) checks if single file
%   rawFile (char) exists and has '.all' or ',wcd' extension.
%
%   out = CFF_CHECK_ALLFILENAME(rawFilesPair) checks if pair of files
%   rawFilesPair (2x1 cell array of chars) exist, match (same name), and
%   have '.all' and '.wcd' extensions.
%
%   See also CFF_CHECK_FILENAME.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 20-08-2021

out = CFF_check_filename(rawfilename,{'.all','.wcd'});