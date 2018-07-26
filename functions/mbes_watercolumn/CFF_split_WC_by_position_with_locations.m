function [MATfilenameWCD, MATfilenameALL, positions] = CFF_split_WC_by_position_with_locations(WCDfilename, ALLfilename, nChunks)
%function [MATfilenameWCD, MATfilenameALL] = CFF_split_WC_by_position(WCDfilename, ALLfilename, nChunks)
% OUT = CFF_new_function(argRequired, varargin)
%
% DESCRIPTION
%
% This function divides WCD and ALL datagrams into a specified number of
% chunks so that the data can be handled in reasonable amounts
%
% USE
%
% This function can be used to divide up very large water column data files
% (e.g. 1GB) into smaller chunks that are easier to process and work with.
% This function divides the file by the number of position datagrams, so
% each chunk contains the same number of positions. This may result in a
% slight variation in the number of pings in each chunk. 
%
% PROCESSING SUMMARY
% 
% This function splits the full ALL and WCD based on the position datagrams
% so that each "chunk" of data has an equal number of positions and the
% data in the WCD and ALL file are split in the same locations.
%
% REQUIRED INPUT ARGUMENTS
%
% - 'WCDfilename': WCD file name
% - 'ALLfilename': ALL file name
% - 'nChunks': Number of chunks to split the data into
%

% OUTPUT VARIABLES
%
% - 'MATfilenameWCD': Output WCD chunk file name
% - 'MATfilenameALL': Output ALL chunk file name
%
% RESEARCH NOTES
%
% Future developments could include the ability to split the data files by
% other methods (lat/long, timestamps etc)
%
% NEW FEATURES
%
% 2016-02-22: first version.
%
% EXAMPLES
%
% This section contains examples of valid function calls. 
% WCDfilename = '0019_20150422_011209_Yolla.wcd';
% ALLfilename = '0019_20150422_011209_Yolla.all';
% nChunks= 40;
%%%
% Amy Nau, UTAS-CSIRO-Deakin
%%%

%% Check args


infoWCD= CFF_all_file_info(WCDfilename);
infoALL= CFF_all_file_info(ALLfilename);
% Get indices for POSITION datagrams
wcdPosIDX= find(infoWCD.datagTypeNumber==80);
allPosIDX= find(infoALL.datagTypeNumber==80);

nPositions= numel(wcdPosIDX);

nDatagWCD = infoWCD.datagNumberInFile(end);
nDatagALL = infoALL.datagNumberInFile(end);
nChunks = 20;

nRange = round(nPositions./nChunks);

% Get indicies for every nth POSITION datagram
chunksWCD= wcdPosIDX(1:nRange:length(wcdPosIDX));
% Set first position to 1
chunksWCD(1)= 1;

chunksALL= allPosIDX(1:nRange:length(allPosIDX));
chunksALL(1)=1;
positions= nan(nChunks,3); 
positions(:,1)=[1:nChunks];
% Get info for datagrams between every nth position datagram for WCD file
for ii=2:nChunks+1
    % WCD chunks
    infoWCD.parsed(:)=0;
    % Add installation parameters for every chunk
    infoWCD.parsed(1)=1;
    
    if ii<nChunks+1
    
    infoWCD.parsed(chunksWCD(ii-1):chunksWCD(ii)-1)=1;
    elseif ii== nChunks+1
        
    infoWCD.parsed(chunksWCD(ii-1):nDatagWCD)=1;
    end
    % read datagrams
    WCDfile = CFF_read_all_from_fileinfo(WCDfilename, infoWCD);
    
    % All file chunks
    
      infoALL.parsed(:)=0;
      % Add installation parameters for every chunk
    infoWCD.parsed(1)=1;
    
    if ii<nChunks+1
    
    infoALL.parsed(chunksALL(ii-1):chunksALL(ii)-1)=1;
    elseif ii== nChunks+1
        
    infoALL.parsed(chunksALL(ii-1):nDatagALL)=1;
    end
    
    ALLfile= CFF_read_all_from_fileinfo(ALLfilename, infoALL);
    start_lat= ALLfile.EM_Position.Latitude(1)/20000000;
    start_long= ALLfile.EM_Position.Longitude(1)/10000000;
    positions(ii-1,2)=start_lat;
    positions(ii-1,3)=start_long;
    % name for chunk mat WCD file
    [~,f,~] = fileparts(WCDfilename);
    MATfilenameWCD = [f '_part_' num2str(ii-1) '_wcd.mat'];
    
      % name for chunk mat ALL file
    [~,f,~] = fileparts(ALLfilename);
    MATfilenameALL = [f '_part_' num2str(ii-1) '_all.mat'];
    
    % save
    CFF_save_mat_from_all(WCDfile,MATfilenameWCD);
    clear WCDfile
    
    CFF_save_mat_from_all(ALLfile,MATfilenameALL);
    clear ALLfile
    
end

end

