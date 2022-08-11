function [tfw,prec] = CFF_read_tfw(tfw_file)
% [tfw,prec] = CFF_read_tfw(tfw_file)
%
% DESCRIPTION
%
% reads the 6 values of a tfw file. Also outputs the maximum number of
% digits after decimal point to work around float issues. 
%
% USE
%
% ...
%
% PROCESSING SUMMARY
%
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - varagin
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% ...
%
% NEW FEATURES
%
% YYYY-MM-DD: second version.
% YYYY-MM-DD: first version.
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%

% read tfw as STRINGS
fid = fopen(tfw_file);
for ii=1:6
    tfw{ii} = fgetl(fid);
end
fclose(fid);

% get maximum precision
prec = 0;
for ii=1:6
    idot = strfind(tfw{ii},'.');
    if ~isempty(idot)
        tempprec = numel(tfw{ii}) - idot;
        prec = max(prec, tempprec);
    end
end

% re-read tfw as numeric
tfw = csvread(tfw_file);
