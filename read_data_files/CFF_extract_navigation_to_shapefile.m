function CFF_extract_navigation_to_shapefile(dataFolder,outShapefile,varargin)
%CFF_EXTRACT_NAVIGATION_TO_SHAPEFILE  Export navigation lat/long to shp
%
%   Extract the navigation (WGS84 latitude and longitude) from all
%   supported files in input folder, and export it to shapefile format

%   CFF_EXTRACT_NAVIGATION_TO_SHAPEFILE(FOLDER,SHAPEFILE) extracts the
%   navigation from all supported files in FOLDER, and export it to
%   shapefile SHAPEFILE.
%
%   CFF_EXTRACT_NAVIGATION_TO_SHAPEFILE(...,'comms',COMMS) specifies if and
%   how this function communicates on its internal state (progress, info,
%   errors). COMMS can be either a CFF_COMMS object, or a text string to
%   initiate a new CFF_COMMS object. Options are 'disp', 'textprogressbar',
%   'waitbar', 'oneline', 'multilines'. By default, using an empty
%   CFF_COMMS object (i.e. no communication). See CFF_COMMS for more
%   information. 
%
%   See also CFF_READ_ALL.

%   Copyright 2024-2024 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% input arguments management

p = inputParser;

addRequired(p,'dataFolder',@isfolder);
addRequired(p,'outShapefile');

% information communication
addParameter(p,'comms',CFF_Comms()); % no communication by default

% parse inputs
parse(p,dataFolder,outShapefile,varargin{:});

% and get results
dataFolder  = p.Results.dataFolder;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p;


%% prep

% get list of files in folder
rawFilesList = CFF_list_raw_files_in_dir(dataFolder,1);
nFiles = numel(rawFilesList);
if nFiles == 0
    warning('No files found in folder. Abort. No export shapefile created.');
    return
end

% start message
comms.start(sprintf('Extract navigation from %i files',nFiles));

% start progress
comms.progress(0,nFiles);


%% extract navigation
clear geoshapeVector
for iF = 1:numel(rawFilesList)
    
    rawfiles = rawFilesList{iF};
    filename = char(CFF_file_name(CFF_onerawfileonly(rawfiles),1));
    
    comms.step(sprintf('File %i/%i: %s...',iF, nFiles, filename));
    
    % extract navigation, per file format
    [~,~,f_ext] = fileparts(filename);
    if strcmpi(f_ext,'.all') || strcmpi(f_ext,'.wcd')
        % Kongsberg format ALL
        datagrams_to_parse = 80; % datagTypeNumber = 80. datagTypeText = 'POSITION (50H)';
        EMdata = CFF_read_all(rawfiles,datagrams_to_parse);
        % convert data
        fData = CFF_convert_ALLdata_to_fData(EMdata,1,1);
    elseif strcmpi(f_ext,'.kmall') || strcmpi(f_ext,'.kmwcd')
        error('Format KMALL not supported');
    elseif strcmpi(f_ext,'.s7k')
        error('Format S7K not supported');
    else
        error('Format "%s" not supported',f_ext);
    end
   
    % save lat long to geoshape
    geoshapeVector(iF) = geoshape(fData.Po_1D_Latitude,fData.Po_1D_Longitude,'fileNumber',iF,'fileName',filename);
    
    comms.progress(iF,nFiles);
    
end

%% export navigation
shapewrite(geoshapeVector,outShapefile);

%% end message
comms.finish('Done');
