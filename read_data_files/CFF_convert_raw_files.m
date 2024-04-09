function [fDataGroup,comms] = CFF_convert_raw_files(rawFilesList,varargin)
%CFF_CONVERT_RAW_FILES Read raw data file(s) and convert to fData format
%
%   Reads contents of one or several multibeam raw data files and convert
%   each of them to the CoFFee fData format used for data processing on
%   Matlab. Data supported are Kongsberg EM series binary data file in
%   .all format (.all or .wcd, or pair of .all/.wcd) or .kmall format
%   (.kmall or .kmwcd, or pair of .kmall/.kmwcd) and Reson-Teledyne .s7k
%   format.
%
%   fDataGroup = CFF_CONVERT_RAW_FILES(rawFile) converts a single,
%   non-paired file rawFile specified with full path either as a character
%   string (e.g. rawFilesList='D:\Data\myfile.all') or a 1x1 cell
%   containing the character string (e.g.
%   rawFilesList={'D:\Data\myfile.all'}).
%
%   fDataGroup = CFF_CONVERT_RAW_FILES(pairedRawFiles) converts a pair of
%   files specified as a 1x1 cell containing a 2x1 cell where each cell
%   contains the full path as a character string (e.g.
%   rawFilesList={{'D:\Data\myfile.all','D:\Data\myfile.wcd'}}). Note: If
%   you omit the double cell (i.e.
%   rawFilesList={'D:\Data\myfile.all','D:\Data\myfile.wcd'}), the two
%   files will be converted separately.
%
%   fDataGroup = CFF_CONVERT_RAW_FILES(rawFilesList) converts a cell vector
%   where each cell corresponds to a file or pair of files to convert,
%   specified as above either a character string, or 2x1 cells of paired
%   files (e.g. rawFilesList = {'D:\Data\mySingleFile.all',
%   {'D:\Data\myPairedFile.all','D:\Data\myPairedFile.wcd'}}).
%   Note: Use CFF_LIST_RAW_FILES_IN_DIR to generate rawFilesList from a
%   folder containing raw data files.
%
%   By default, CFF_CONVERT_RAW_FILES converts every datagram supported. It
%   does not reconvert a file that has already been converted if it's found
%   on the disk (fData.mat) with the suitable version. In this case, the
%   data are simply loaded. If an error is encountered, the error message
%   is logged and processing moves onto the next file. After conversion,
%   the converted data are NOT saved on the hard-drive.
%   Use the format fDataGroup = CFF_CONVERT_RAW_FILES(...,Name,Parameter)
%   to modify this default behaviour. Options below:
%
%   'conversionType' informs the datagrams to be read and converted, for
%   different purposes. 
%   'conversionType': 'everything' (default) will convert every datagram
%   supported.
%   'conversionType': 'seafloor' will only convert datagrams necessary for
%   bathy and BS processing. Water-column data are ignored.. 
%   'conversionType': 'WCD' will only convert datagrams necessary for
%   water-column data processing. Seafloor data (bathymetry and
%   backscatter) are ignored (although in some formats, they are necessary
%   for water-column data processing and in this case are also converted). 
%   'conversionType': 'seafloorOrWCD' will convert datagrams necessary for
%   seafloor OR water-column data processing, and complete successfully if
%   either are found.
%
%   'saveFDataToDrive': 1 will save the converted fData to the hard-drive.
%   'saveFDataToDrive': 0 (default) will NOT save the data to hard-drive.
%   Note that if water-column datagrams are present and to be converted,
%   then this parameter is overriden and fData is saved to the hard-drive
%   anyway. Converted data are in the 'Coffee_files' folder created in the
%   same folder as the raw data files.
%
%   'forceReconvert': 1 will force the conversion of a raw data file, even
%   if a suitable converted file is found on the hard-drive.
%   'forceReconvert': 0 (default) will skip conversion if a converted
%   version is found on the hard-drive and can be loaded.
%
%   'outputFData': 0 will clear fData after conversion of each file so that
%   the function returns empty. This avoids memory errors when converting
%   many files. Use this in combination with 'saveFDataToDrive': 1 as a
%   routine to convert fData for the purpose of saving it to the
%   hard-drive.
%   'outputFData': 1 (default) will conserve fData and return it.
%
%   'abortOnError': 1 will interrupt processing if an error is encountered.
%   'abortOnError': 0 (default) will log the error message and move onto
%   the next file.
%
%   'convertEvenIfDtgrmsMissing': 1 will continue the conversion of a file
%   even in the event that one or more datagram types required by
%   'conversionType' are not found in a file.
%   'convertEvenIfDtgrmsMissing': 0 (default) will stop conversion instead.
%
%   'dr_sub': N where N is an integer will decimate water-column data in
%   range by a factor of N. By default, 'dr_sub': 1 so that all data are
%   read and converted.
%
%   'db_sub': N where N is an integer will decimate water-column data in
%   beam by a factor of N. By default, 'db_sub': 1 so that all data are
%   read and converted.
%
%   'comms': 'disp' will display text and progress information in the
%   command window.
%   'comms': 'textprogressbar': will display text and progress information
%   in a text progress bar in the command window.
%   'comms': 'waitbar': will display text and progress information
%   in a Matlab waitbar figure.
%   'comms': '' (default) will not display any text and progress
%   information.
%
%   See also CFF_CONVERTED_DATA_FOLDER,
%   CFF_ARE_RAW_FILES_CONVERTED, CFF_READ_ALL, CFF_READ_S7K,
%   CFF_READ_KMALL, CFF_CONVERT_ALLDATA_TO_FDATA,
%   CFF_CONVERT_S7KDATA_TO_FDATA, CFF_CONVERT_KMALLDATA_TO_FDATA, CFF_COMMS

%   Copyright 2021-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/



%% Input arguments management
p = inputParser;

% list of files (or pairs of files) to convert
argName = 'rawFilesList';
argCheck = @(x) ~isempty(x) && (ischar(x) || iscell(x));
addRequired(p,argName,argCheck);

% 'conversionType' informs the datagrams to be read and converted, for
% different purposes. 
% 'conversionType': 'everything' (default) will convert every datagram
% supported.
% 'conversionType': 'seafloor' will only convert datagrams necessary for
% bathy and BS processing. Water-column data are ignored.. 
% 'conversionType': 'WCD' will only convert datagrams necessary for
% water-column data processing. Seafloor data (bathymetry and backscatter)
% are ignored (although in some formats, they are necessary for
% water-column data processing and in this case are also converted).
% 'conversionType': 'seafloorOrWCD' will convert datagrams necessary for
% seafloor OR water-column data processing, and complete successfully if
% either are found.
addParameter(p,'conversionType','everything',@(x) mustBeMember(x,{'everything','seafloor','WCD','seafloorOrWCD'}));

% save fData to hard-drive? 0: no (default), 1: yes
% Note that if we convert for WCD processing, we will disregard that info
% and save fData to drive anyway
addParameter(p,'saveFDataToDrive',0,@(x) mustBeMember(x,[0,1]));

% what if file already converted? 0: to next file (default), 1: reconvert
addParameter(p,'forceReconvert',0,@(x) mustBeMember(x,[0,1]));

% output fData? 0: no, 1: yes (default)
% Unecessary in apps, but useful in scripts
addParameter(p,'outputFData',1,@(x) mustBeMember(x,[0,1]));

% what if error during conversion? 0: to next file (default), 1: abort
addParameter(p,'abortOnError',0,@(x) mustBeMember(x,[0,1]));

% what if missing required dtgrms? 0: to next file (def), 1: convert anyway
addParameter(p,'convertEvenIfDtgrmsMissing',0,@(x) mustBeMember(x,[0,1]));

% decimation factor in range and beam (def 1, aka no decimation)
addParameter(p,'dr_sub',1,@(x) isnumeric(x)&&x>0&&mod(x,1)==0);
addParameter(p,'db_sub',1,@(x) isnumeric(x)&&x>0&&mod(x,1)==0);

% information communication (none by default)
addParameter(p,'comms',CFF_Comms());

% parse inputs
parse(p,rawFilesList,varargin{:});

% and get results
rawFilesList = p.Results.rawFilesList;
forceReconvert = p.Results.forceReconvert;
abortOnError = p.Results.abortOnError;
convertEvenIfDtgrmsMissing = p.Results.convertEvenIfDtgrmsMissing;
conversionType = p.Results.conversionType;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
saveFDataToDrive = p.Results.saveFDataToDrive;
outputFData = p.Results.outputFData;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p


%% Prep

% start message
comms.start('Reading and converting file(s)');

% single filename in input
if ischar(rawFilesList)
    rawFilesList = {rawFilesList};
end

% number of files
nFiles = numel(rawFilesList);

% init output
if outputFData
    fDataGroup = cell(1,nFiles);
else
    fDataGroup = [];
end

% start progress
comms.progress(0,nFiles);


%% Read and convert files
for iF = 1:nFiles
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get the file (or pair of files) to convert
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
        
        % file format
        [~,~,f_ext] = fileparts(CFF_onerawfileonly(rawFile));
        if strcmpi(f_ext,'.all') || strcmpi(f_ext,'.wcd')
            file_format = 'Kongsberg_all';
        elseif strcmpi(f_ext,'.kmall') || strcmpi(f_ext,'.kmwcd')
            file_format = 'Kongsberg_kmall';
        elseif strcmpi(f_ext,'.s7k')
            file_format = 'Reson_s7k';
        else
            error('Cannot be converted. Format ("%s") not supported',f_ext);
        end
        
        % convert, reconvert, update, or ignore based on file status
        idxConverted = CFF_are_raw_files_converted(rawFile);
        if ~idxConverted
            % File is not converted yet: proceed with conversion.
            comms.info('Never converted. Try to convert');
        else
            % File has already been converted...
            if forceReconvert
                % ...but asking for reconversion: proceed with
                % reconversion.
                comms.info('Already converted. Try to re-convert');
            else
                % ...and not asking for reconversion. Load data for checks
                wc_dir = CFF_converted_data_folder(rawFile);
                mat_fdata_file = fullfile(wc_dir, 'fData.mat');
                fData = load(mat_fdata_file);
                % test if version correct, and if has WC data)
                idxFDataUpToDate = strcmp(CFF_get_fData_version(fData),CFF_get_current_fData_version());
                idxHasWCD = any(startsWith(fieldnames(fData),{'WC_','AP_'}));
                if ~idxFDataUpToDate || (strcmp(conversionType,'WCD') && ~idxHasWCD)
                    comms.info('Already converted but unsuitable. Try to update conversion');
                else
                    % Converted file is suitable and doesn't need to be
                    % reconverted.
                    comms.info('Already converted and suitable. Ignore');
                    if outputFData
                        fDataGroup{iF} = fData;
                    end
                    % communicate progress and move on to next file
                    comms.progress(iF,nFiles);
                    continue
                end
            end
        end
        
        % reading and converting depending on file format
        switch file_format
            case 'Kongsberg_all'
                
                % datagram types to read
                switch conversionType
                    case 'everything'
                        % request to convert every datagram type supported
                        dtgs = [];
                    case 'seafloor'
                        % convert only datagram types needed for bathy/bs
                        % work (i.e. ignore water-column data)
                        dtgsAllRequired = [73, ... % installation parameters (73)
                            80, ...                % position (80)
                            82, ...                % runtime parameters (82)
                            88];                   % X8 depth (88)
                        dtgs = sort(unique(dtgsAllRequired));
                    case 'WCD'
                        % convert datagram types to visualize WCD
                        dtgsAllRequired = [73, ...   % installation parameters (73)
                            80, ...                  % position (80)
                            82];                     % runtime parameters (82)
                        % dtgsOptional = 88;         % X8 depth (88)
                        dtgsAtLeastOneOf = [107, ... % water-column (107)
                            114];                    % Amplitude and Phase (114)
                        % dtgs = sort(unique([dtgsAllRequired, dtgsOptional, dtgsAtLeastOneOf]));
                        dtgs = sort(unique([dtgsAllRequired, dtgsAtLeastOneOf]));
                    case 'seafloorOrWCD'
                        dtgsAllRequired = [73, ...  % installation parameters (73)
                            80, ...                 % position (80)
                            82];                    % runtime parameters (82)
                        dtgsAtLeastOneOf = [88, ... % X8 depth (88)
                            107, ...                % water-column (107)
                            114];                   % Amplitude and Phase (114)
                        dtgs = sort(unique([dtgsAllRequired, dtgsAtLeastOneOf]));
                end
                
                % conversion step 1: read what we can
                comms.info('Reading raw data...');
                [EMdata,iDtgsParsed] = CFF_read_all(rawFile, dtgs);
                
                if ~strcmp(conversionType,'everything')
                    % if requesting specific conversion, a couple of checks
                    % are necessary 
                    
                    % check if all required datagrams have been found
                    iDtgsRequired = ismember(dtgsAllRequired,dtgs(iDtgsParsed));
                    if ~all(iDtgsRequired)
                        strdisp = sprintf('File is missing required datagram type(s) %s.',strjoin(string(dtgsAllRequired(~iDtgsRequired)),', '));
                        if convertEvenIfDtgrmsMissing
                            % log message and resume conversion
                            comms.info([strdisp ' Converting anyway']);
                        else
                            % abort conversion by throwing error
                            error([strdisp ' Conversion aborted']);
                        end
                    end
                    
                    % check if at least one of the desired datagrams have
                    % been found 
                    if exist('dtgsAtLeastOneOf','var') && ~any(ismember(dtgsAtLeastOneOf,dtgs(iDtgsParsed)))
                        iDtgsAtLeastOne = ismember(dtgsAtLeastOneOf,dtgs(iDtgsParsed));
                        strdisp = sprintf('File has none of desired datagram type(s) %s.',strjoin(string(dtgsAtLeastOneOf(~iDtgsAtLeastOne)),', '));
                        if convertEvenIfDtgrmsMissing
                            % log message and resume conversion
                            comms.info([strdisp ' Converting anyway'])
                        else
                            % abort conversion by throwing error
                            error([strdisp ' Conversion aborted']);
                        end
                    end
                    
                end
                
                % conversion step 2: convert
                comms.info('Converting to fData format...');
                fData = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub);

                % sort fields by name
                fData = orderfields(fData);
                
            case 'Kongsberg_kmall'
                
                % datagram types to read
                switch conversionType
                    case 'everything'
                        % convert every datagrams supported
                        dtgs = [];
                    case 'seafloor'
                        dtgsAllRequired = {'#IIP',... % Installation Parameters
                            '#SPO',...                % Position
                            '#IOP',...                % Runtime Parameters
                            '#MRZ'};                  % Bathy and BS
                        dtgs = sort(unique(dtgsAllRequired));
                    case 'WCD'
                        dtgsAllRequired = {'#IIP',... % Installation Parameters
                            '#SPO',...                % Position        
                            '#IOP',...                % Runtime Parameters
                            '#MWC'};                  % Water-column Data 
                        % USED TO ALSO HAVE '#MRZ',... % Bathy and BS
                        dtgs = sort(unique(dtgsAllRequired));
                    case 'seafloorOrWCD'
                        dtgsAllRequired = {'#IIP',...  % Installation Parameters
                            '#SPO',...                 % Position
                            '#IOP'};                   % Runtime Parameters
                        dtgsAtLeastOneOf = {'#MRZ',... % Bathy and BS
                            '#MWC'};                   % Water-column Data
                        dtgs = sort(unique([dtgsAllRequired, dtgsAtLeastOneOf]));
                end
                
                % conversion step 1: read what we can
                if ischar(rawFile)
                    comms.info('Reading data in file...');
                else
                    comms.info('Reading data in pair of files...');
                end
                [EMdata,iDtgsParsed] = CFF_read_kmall(rawFile, dtgs);
                
                if ~strcmp(conversionType,'everything')
                    % if requesting specific conversion, a couple of checks
                    % are necessary
                    
                    % check if all required datagrams have been found
                    iDtgsRequired = ismember(dtgsAllRequired,dtgs(iDtgsParsed));
                    if ~all(iDtgsRequired)
                        strdisp = sprintf('File is missing required datagram type(s) %s.',strjoin(string(dtgsAllRequired(~iDtgsRequired)),', '));
                        if convertEvenIfDtgrmsMissing
                            % log message and resume conversion
                            comms.info([strdisp ' Converting anyway']);
                        else
                            % abort conversion by throwing error
                            error([strdisp ' Conversion aborted']);
                        end
                    end
                    
                    % check if at least one of the desired datagrams have
                    % been found
                    if exist('dtgsAtLeastOneOf','var') && ~any(ismember(dtgsAtLeastOneOf,dtgs(iDtgsParsed)))
                        iDtgsAtLeastOne = ismember(dtgsAtLeastOneOf,dtgs(iDtgsParsed));
                        strdisp = sprintf('File has none of desired datagram type(s) %s.',strjoin(string(dtgsAtLeastOneOf(~iDtgsAtLeastOne)),', '));
                        if convertEvenIfDtgrmsMissing
                            % log message and resume conversion
                            comms.info([strdisp ' Converting anyway'])
                        else
                            % abort conversion by throwing error
                            error([strdisp ' Conversion aborted']);
                        end
                    end
                    
                end
                
                % conversion step 2: convert
                comms.info('Converting to fData format...');
                fData = CFF_convert_KMALLdata_to_fData(EMdata,dr_sub,db_sub);
                
                % sort fields by name
                fData = orderfields(fData);
                
            case 'Reson_s7k'
                
                % datagram types to read
                switch conversionType
                    case 'everything'
                        % convert every datagrams supported
                        dtgs = [];
                    case 'seafloor'
                        dtgsAllRequired = [7000, ...     % R7000_SonarSettings
                            7027];                       % R7027_RawDetectionData
                        dtgsAtLeastOneOfNav = [1015, ... % R1015_Navigation
                            1003];                       % R1003_Position
                        dtgs = sort(unique([dtgsAllRequired, dtgsAtLeastOneOfNav]));
                    case 'WCD'
                        dtgsAllRequired = [7000, ...     % R7000_SonarSettings
                            7004, ...                    % R7004_BeamGeometry
                            7027];                       % R7027_RawDetectionData, NOTE: contains X8 data but needed for WCD
                        dtgsAtLeastOneOfNav = [1015, ... % R1015_Navigation
                            1003];                       % R1003_Position
                        dtgsAtLeastOneOfWCD = [7018, ... % R7018_BeamformedData
                            7042];                       % R7042_CompressedWaterColumnData
                        dtgs = sort(unique([dtgsAllRequired, dtgsAtLeastOneOfNav, dtgsAtLeastOneOfWCD]));
                    case 'seafloorOrWCD'
                        dtgsAllRequired = [7000, ...     % R7000_SonarSettings
                            7027];                       % R7027_RawDetectionData
                        dtgsAtLeastOneOfNav = [1015, ... % R1015_Navigation
                            1003];                       % R1003_Position
                        dtgsOptionalWCD = [7018, ...     % R7018_BeamformedData
                            7042];                       % R7042_CompressedWaterColumnData
                        dtgRequiredForWCD = 7004;        % R7004_BeamGeometry
                        dtgs = sort(unique([dtgsAllRequired, dtgsAtLeastOneOfNav, dtgsOptionalWCD, dtgRequiredForWCD]));
                end
                
                % conversion step 1: read what we can
                comms.info('Reading data in file...');
                [S7Kdata,iDtgsParsed] = CFF_read_s7k(rawFile, dtgs);
                
                if ~strcmp(conversionType,'everything')
                    % if requesting specific conversion, a couple of checks
                    % are necessary 
                    
                    % check if all required datagrams have been found
                    iDtgsRequired = ismember(dtgsAllRequired,dtgs(iDtgsParsed));
                    if ~all(iDtgsRequired)
                        strdisp = sprintf('File is missing required datagram type(s) %s.',strjoin(string(dtgsAllRequired(~iDtgsRequired)),', '));
                        if convertEvenIfDtgrmsMissing
                            % log message and resume conversion
                            comms.info([strdisp ' Converting anyway']);
                        else
                            % abort conversion by throwing error
                            error([strdisp ' Conversion aborted']);
                        end
                    end
                    
                    % check if at least one type of navigation datagram has
                    % been found
                    if ~any(ismember(dtgsAtLeastOneOfNav,dtgs(iDtgsParsed)))
                        strdisp = 'File does not contain navigation datagrams.';
                        if convertEvenIfDtgrmsMissing
                            % log message and resume conversion
                            comms.info([strdisp ' Converting anyway'])
                        else
                            % abort conversion by throwing error
                            error([strdisp ' Conversion aborted']);
                        end
                    end
                    
                    % and special cases for 'WCD' and 'seafloorOrWCD'
                    if strcmp(conversionType,'WCD')
                        % if requesting conversion for WCD, check if at
                        % least one type of water-column datagram has been
                        % found 
                        if ~any(ismember(dtgsAtLeastOneOfWCD,dtgs(iDtgsParsed)))
                            strdisp = 'File does not contain water-column datagrams.';
                            if convertEvenIfDtgrmsMissing
                                % log message and resume conversion
                                comms.info([strdisp ' Converting anyway'])
                            else
                                % abort conversion by throwing error
                                error([strdisp ' Conversion aborted']);
                            end
                        end
                    elseif strcmp(conversionType,'seafloorOrWCD')
                        % if requesting conversion for seafloorOrWCD, check
                        % that if we have WCD (either of dtgsOptionalWCD),
                        % then we also have dtgRequiredForWCD.
                        if any(ismember(dtgsOptionalWCD,dtgs(iDtgsParsed))) && ~all(ismember(dtgRequiredForWCD,dtgs(iDtgsParsed)))
                            strdisp = 'File has water-column datagrams, but not the necessary ancillary datagrams.';
                            if convertEvenIfDtgrmsMissing
                                % log message and resume conversion
                                comms.info([strdisp ' Converting anyway'])
                            else
                                % abort conversion by throwing error
                                error([strdisp ' Conversion aborted']);
                            end
                        end
                    end
                end
                
                % conversion step 2: convert
                comms.info('Converting to fData format...');
                fData = CFF_convert_S7Kdata_to_fData(S7Kdata,dr_sub,db_sub);
                
                % sort fields by name
                fData = orderfields(fData);
                
        end
        
        % save fData to drive
        if saveFDataToDrive || any(startsWith(fieldnames(fData),{'WC_','AP_'}))
            % get output folder and create it if necessary
            wc_dir = CFF_converted_data_folder(rawFile);
            if ~isfolder(wc_dir)
                mkdir(wc_dir);
            end
            mat_fdata_file = fullfile(wc_dir, 'fData.mat');
            comms.info('Saving...');
            save(mat_fdata_file,'-struct','fData','-v7.3');
        end
        
        % add to group for output
        if outputFData
            fDataGroup{iF} = fData;
        end
        clear fData
        
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

if outputFData
    % output struct directly if only one element
    if numel(fDataGroup)==1
        fDataGroup = fDataGroup{1};
    end
end

%% end message
comms.finish('Done.');

end


