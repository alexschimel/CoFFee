function CFF_write_all_from_fileinfo(info, rawFileOut)
%CFF_WRITE_ALL_FROM_FILEINFO  Write all file from fileinfo
%
%   Write a Kongsberg EM series binary data file (.all format) containing
%   only specific datagrams of a data file *.all format) specified in
%   input.
%
%   CFF_WRITE_ALL_FROM_FILEINFO(INFO, RAWFILEOUT) parses the raw data file
%   specified in INFO.ALLfilename, and copies the datagrams where
%   INFO.parsed = 1 into a new raw data file RAWFILEOUT.
%
%   See also CFF_ALL_FILE_INFO, CFF_READ_ALL_FROM_FILEINFO

%   Copyright 2023-2023 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

comms = CFF_Comms('textprogressbar');
comms.start(sprintf('Reading/writing datagrams'));

% get basic info for file opening
datagramsformat = info.datagramsformat;
rawFileIn = info.ALLfilename;

% open files
[fidIn,~]  = fopen(rawFileIn, 'r',datagramsformat);
[fidOut,~] = fopen(rawFileOut, 'w',datagramsformat);


nDtg = numel(info.datagNumberInFile);

comms.progress(0,nDtg);
for iDatag = 1:nDtg
    if info.parsed(iDatag) == 1
        
        % current position in file
        curpos = ftell(fidIn);
        
        % position of datagram in file
        datpos = info.datagPositionInFile(iDatag);
    
        % go to datagram position
        fread(fidIn, datpos - curpos);
    
        % read datagram
        A = fread(fidIn, info.size(iDatag)+4, 'uint8');
        
        % write datagram in destination file
        fwrite(fidOut, A, 'uint8');
        
        comms.progress(iDatag,nDtg);
        
    end
end

% close files
fclose(fidIn);
fclose(fidOut);

comms.finish('Done');

end