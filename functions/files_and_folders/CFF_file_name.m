%% CFF_file_name.m
%
% Get name of file (without path or extension
%
%% Help
%
% *USE*
%
% CFF_file_extension(filename) returns the extension of filename.
%
% *INPUT VARIABLES*
%
% * |filename|: Required. String filename.
%
% *OUTPUT VARIABLES*
%
% * |ext|: String filename extension
%
% *DEVELOPMENT NOTES*
%
% *NEW FEATURES*
%
% * 2018-10-11: added header
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
%   ext = CFF_file_extension('test.mat'); % returns 'mat'
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Waikato University, Deakin University, NIWA.

%% Function
function name = CFF_file_name(filename)

[~,name,~] = fileparts(filename);