function fDataGroup = CFF_load_converted_files(rawFilesList, varargin)
%CFF_LOAD_CONVERTED_FILES  Load converted data (fData) from raw file list
%
%   FDATAGROUP = CFF_LOAD_CONVERTED_FILES(RAWFILESLIST) looks for the
%   converted versions (fData.mat) of the list of raw files RAWFILESLIST in
%   input, and load them. If an error is encountered trying to locate and
%   load a file, the error message will be logged and the function moves
%   onto the next file.
%
%   CFF_LOAD_CONVERTED_FILES(...,'fixPaths',FLAG) with FLAG = 1 will check
%   if the paths in fData (for ALLFILENAME, and memmaped files) match that
%   of the rawFile in input, fix them if they are incorrect, and re-write
%   fData on the disk (recommended, unless you have specific reasons to not
%   want to update fData on the disk).
%
%   CFF_LOAD_CONVERTED_FILES(...,'abortOnError',FLAG) with FLAG = 1 will
%   interrupt processing if an error is encountered. By default (FLAG = 0),
%   the error is logged and processing continues to the next file. 
%
%   CFF_LOAD_CONVERTED_FILES(...,'comms',COMMS) specifies if and how this
%   function communicates on its internal state (progress, info, errors).
%   COMMS can be either a CFF_COMMS object, or a text string to initiate a
%   new CFF_COMMS object. Options are 'disp', 'textprogressbar', 'waitbar',
%   'oneline', 'multilines'. By default, using an empty CFF_COMMS object
%   (i.e. no communication). See CFF_COMMS for more information.  
%
%   See also CFF_CONVERT_RAW_FILES, CFF_COMPUTE_PING_NAVIGATION_V2

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/


%% Input arguments management
p = inputParser;
addRequired(p,'rawFilesList',@(x) ~isempty(x)&&(ischar(x)||iscell(x))); % list of files (or pairs of files) to load
addParameter(p,'fixPaths',0,@(x) mustBeMember(x,[0,1])); % 1: check paths are correct, fix them, and re-write fData on the disk
addParameter(p,'abortOnError',0,@(x) mustBeMember(x,[0,1])); % what if error during conversion? 0: to next file (default), 1: abort
addParameter(p,'comms',CFF_Comms()); % information communication (none by default)
parse(p,rawFilesList,varargin{:});
fixPaths = p.Results.fixPaths;
abortOnError = p.Results.abortOnError;
comms = p.Results.comms;
clear p
if ischar(comms)
    comms = CFF_Comms(comms);
end


%% Prep

% start message
comms.start('Loading converted file(s)');

% single filename in input
if ischar(rawFilesList)
    rawFilesList = {rawFilesList};
end

% number of files
nFiles = numel(rawFilesList);

% init output
fDataGroup = cell(1,nFiles);

% start progress
comms.progress(0,nFiles);


%% Load files
for iF = 1:nFiles
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get the file (or pair of files) to process
        rawFile = rawFilesList{iF};
        
        % display for this file
        if ischar(rawFile)
            filename = CFF_file_name(rawFile,1);
            comms.step(sprintf('%i/%i: file %s',iF,nFiles,filename));
        else
            % paired files
            filename_1 = CFF_file_name(rawFile{1},1);
            filename_2_ext = CFF_file_extension(rawFile{2});
            comms.step(sprintf('%i/%i: pair of files %s and %s',iF,nFiles,filename_1,filename_2_ext));
        end
        
        % load converted data
        fDataFolder = CFF_converted_data_folder(rawFile);
        fDataGroup{iF} = load(fullfile(fDataFolder,'fData.mat'));
        
        % check paths and fix them, if necessary
        if fixPaths
            [fDataGroup{iF}, flagPathsFixed] = CFF_fix_fData_paths(fDataGroup{iF},rawFile);
            if flagPathsFixed
                comms.info('Paths in fData were fixed')
            end
        end
        
        % time-tag that fData
        fDataGroup{iF}.ID = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
        pause(1e-3); % pause to ensure unique time-tags
        
        % sort fields by name
        fDataGroup{iF} = orderfields(fDataGroup{iF});
        
        % successful end of this iteration
        comms.info('Done.');
        
    catch err
        if abortOnError
            % just rethrow error to terminate execution
            rethrow(err);
        else
            % log the error and continue
            errorFile = CFF_file_name(err.stack(1).file,1);
            errorLine = err.stack(1).line;
            errrorFullMsg = sprintf('%s (error in %s, line %i)',err.message,errorFile,errorLine);
            comms.error(errrorFullMsg);
        end
    end
    
    % communicate progress
    comms.progress(iF,nFiles);

end


%% end message
comms.finish('Done.');


end