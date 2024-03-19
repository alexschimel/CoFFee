function ALLfileinfo = CFF_save_mat_from_all(ALLdata, MATfilename)
% CFF_save_mat_from_all.m
%
% Saves the data that is stored in structure ALLdata into a .MAT file.
%
% *USE*
%
% ALLfileinfo = CFF_save_mat_from_all(ALLdata, MATfilename) saves the
% fields in ALLdata (as obtained from CFF_read_all.m or
% CFF_read_all_from_fileinfo.m) and store them in a .mat filename given by
% MATfilename. The function also returns the |info| field in ALLdata.
%
% *INPUT VARIABLES*
%
% REQUIRED:
% * |ALLdata|: structure containing the data. Each field corresponds a
% different type of datagram. The field |ALLdata.info| contains informaton
% about datagrams in ALLdata, with fields: 
%   * |ALLfilename|: input file name
%   * |filesize|: file size in bytes
%   * |datagsizeformat|: endianness of the datagram size field 'b' or 'l'
%   * |datagramsformat|: endianness of the datagrams 'b' or 'l'
%   * |datagNumberInFile|: number of datagram in file
%   * |datagPositionInFile|: position of beginning of datagram in file
%   * |datagTypeNumber|: for each datagram, SIMRAD datagram type in decimal
%   * |datagTypeText|: for each datagram, SIMRAD datagram type description
%   * |parsed|: for each datagram, 1 if datagram has been parsed (or is to be parsed), 0 otherwise
%   * |counter|: the counter of this type of datagram in the file (ie first datagram of that type is 1 and last datagram is the total number of datagrams of that type)
%   * |number|: the number/counter found in the datagram (usually different to counter)
%   * |size|: for each datagram, datagram size in bytes
%   * |syncCounter|: for each datagram, the number of bytes founds between this datagram and the previous one (any number different than zero indicates a sync error)
%   * |emNumber|: EM Model number (eg 2045 for EM2040c)
%   * |date|: datagram date in YYYMMDD
%   * |timeSinceMidnightInMilliseconds|: time since midnight in msecs 
%
% * |MATfilename|: character string of the name of the .mat file to output.
%
% *OUTPUT VARIABLES*
%
% * |ALLfileinfo|: copy of ALLdata.info as described above.
%
% *RESEARCH NOTES*
%
% *NEW FEATURES*
%
% * 2017-06-29: header cleaned up. Changed ALLfile for ALLdata internally for consistency with other functions (Alex Schimel).
% * 2015-09-30: first version taking from last version of convert_all_to_mat (Alex Schimel).
%
% *EXAMPLE*
%
% ALLfilename = '.\data\EM2040c\0001_20140213_052736_Yolla.all';
% MATfilename = '0001_20140213_052736_Yolla.mat';
% info = CFF_all_file_info(ALLfilename);
% info.parsed(:)=1; % to save all the datagrams
% ALLdata = CFF_read_all_from_fileinfo(ALLfilename, info);
% ALLfileinfo = CFF_save_mat_from_all(ALLdata, MATfilename);
%
%   Copyright 2007-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

save(MATfilename, '-struct', 'ALLdata','-v7.3');

ALLfileinfo = ALLdata.info;


