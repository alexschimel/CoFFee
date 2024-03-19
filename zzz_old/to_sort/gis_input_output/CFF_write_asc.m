function CFF_write_asc(MAP,X,Y,filename)
% CFF_write_asc(MAP,X,Y,filename)
%
% DESCRIPTION
%
% function to save esri asc format
%
%   Copyright 2013-2015 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

[pathstr,name,ext] = fileparts(filename);
if isempty(ext)
    filename = [filename, '.asc'];
end
    
% set no data to a different value
nod = round(max(max(MAP))+2);
MAP(isnan(MAP)) = nod;

% values for header
nxllcenter = X(1,1);
nyllcenter = Y(end,1);
ncellsize = X(1,2)-X(1,1);

% header
Header_1 = sprintf('ncols %d\nnrows %d\nxllcenter %d\nyllcenter %d\ncellsize ' , size(MAP,2), size(MAP,1), nxllcenter, nyllcenter);
Header_2 = CFF_nice_sprintf(ncellsize);
Header_3 = sprintf('\nnodata_value %d\n' , nod);
Header = [Header_1 Header_2 Header_3];

% write temporary file
dlmwrite('temp.txt', MAP, 'delimiter', ' ');

% read temporary file as binary, and rewrite with header
fid = fopen('temp.txt'); F = fread(fid); fclose(fid);
fid = fopen(filename,'w');
fwrite(fid, Header); fwrite(fid, F); fclose(fid);
clear F
delete('temp.txt');
