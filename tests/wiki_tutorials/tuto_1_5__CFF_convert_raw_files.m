% This help page informs the use of function `CFF_convert_raw_files` in CoFFee.

% # 1. Basic use

% | Command | Description |
% | ------------- | ------------- |
% | `fData = CFF_convert_raw_files(rawFile)` | Converts a single, non-paired file `rawFile` specified as a character string of the file's path (e.g.  `rawFile='D:\Data\myfile.all'`) or a 1x1 cell containing the character string (e.g. `rawFile={'D:\Data\myfile.all'}`).| 
% | `fData = CFF_convert_raw_files(pairedRawFiles)` | Converts a pair of files `pairedRawFiles` specified as a 1x1 cell containing a 2x1 cell where each cell contains the full path as a character string (e.g. `pairedRawFiles={{'D:\Data\myfile.all','D:\Data\myfile.wcd'}}`). Note: If you omit the double cell (i.e. `pairedRawFiles={'D:\Data\myfile.all','D:\Data\myfile.wcd'}`), the two files will be converted separately.| 
% | `fDataGroup = CFF_convert_raw_files(rawFilesList)` | Converts a list of raw files `rawFilesList` specified as a cell vector where each cell corresponds to a single file or a pair of files to convert, each of which is specified as above (i.e. a character string for a single file, or a 2x1 cells of paired files (e.g. `rawFilesList = {'D:\Data\mySingleFile.all', {'D:\Data\myPairedFile.all','D:\Data\myPairedFile.wcd'}}`). Note: Use `CFF_list_raw_files_in_dir` to generate `rawFilesList` from a folder containing raw data files.|

% The default behaviour of `CFF_convert_raw_files` is that:
% * it converts every datagram supported. 
% * it does not reconvert a file that has already been converted if it's found on the disk (`fData.mat`) with the suitable version. In this case, the data are simply loaded. 
% * if an error is encountered, the error message is logged and converting continues (e.g. moves onto the next file). 
% * after conversion, the converted data are NOT saved on the hard-drive.

% Use the format `fData = CFF_convert_raw_files(...,Name,Value)` to modify this default behaviour with `Name` & `Value` pair arguments. Options are listed below.

% # 2. Conversion type

% `fData = CFF_convert_raw_files(...,'conversionType',Value)` informs the datagrams that need to be read and converted, for different purposes.

% | Value | Description |
% | ------------ | ------ | 
% | `'everything'` (default) | Converts every datagram supported. | 
% | `'seafloor'` | Converts only datagrams necessary for seafloor (bathymetry and backscatter) processing. Water-column data are ignored. | 
% | `'WCD'` | Converts only datagrams necessary for water-column data processing. Seafloor data (bathymetry and backscatter) are ignored unless they are necessary for water-column data processing (in some formats) and in this case are also converted. | 
% | `'seafloorOrWCD'` | Converts datagrams necessary for seafloor OR water-column data processing, and complete successfully if either are found. | 

% # 3. Input/Output management

% `fData = CFF_convert_raw_files(...,'saveFDataToDrive',Value)` controls whether converted data is saved to the drive.

% | Value | Description |
% | ------------ | ------ | 
% | `0` (default) | Data will NOT be saved on the drive. | 
% | `1` | Data will be saved on the drive (in `Coffee_files` folder). | 

% Note that if water-column datagrams are present and to be converted, then this parameter is overriden and `fData` is saved to the hard-drive anyway.

% `fData = CFF_convert_raw_files(...,'forceReconvert',Value)` controls behaviour if converted data already exists.

% | Value | Description |
% | ------------ | ------ | 
% | `0` (default) | Skip conversion. Load existing converted data. | 
% | `1` | Ignore existing converted data. Convert raw data. | 

% `fData = CFF_convert_raw_files(...,'outputFData',Value)` controls output variable.

% | Value | Description |
% | ------------ | ------ | 
% | `0` | Returns empty `fData`. | 
% | `1` (default) | Returns converted data in `fData`. | 

% This parameter is to avoid memory errors when converting many files. Use this in combination with `saveFDataToDrive` set to `1` as a workflow to batch-convert a lot of raw data to the hard-drive for later re-loading.

% # 4. Error management

% `fData = CFF_convert_raw_files(...,'abortOnError',Value)` controls behaviour in case exceptions (errors) occur.

% | Value | Description |
% | ------------ | ------ | 
% | `0` (default) | Exception catch execution. The error message will be logged and execution continues (to the next file).  | 
% | `1` | Normal execution. Execution will be interrupted if an error is encountered. | 

% `fData = CFF_convert_raw_files(...,'convertEvenIfDtgrmsMissing',Value)` controls behaviour in case some required datagrams are missing.

% | Value | Description |
% | ------------ | ------ | 
% | `0` (default) | Stop conversion and throw error (to be eventually caught if `abortOnError` is set to `0`).  | 
% | `1` | Continue conversion. | 

% # 5. Water-column decimation

% `fData = CFF_convert_raw_files(...,'dr_sub',Value)` where `Value` is an integer will decimate water-column data conversion in **range** by a factor of `Value`. By default, `Value` equals `1` so that all data are read and converted.

% `fData = CFF_convert_raw_files(...,'dn_sub',Value)` where `Value` is an integer will decimate water-column data conversion in **beams** by a factor of `Value`. By default, `Value` equals `1` so that all data are read and converted.

% # 6. Progress display

% `fData = CFF_convert_raw_files(...,'comms',Value)` modifies the screen display to follow execution progress.

% | Value | Description |
% | ------------ | ------ | 
% | `''` (default) | No display. | 
% | `'disp'` | Display text and progress information in the command window, one line per event. Use for debug. | 
% | `'textprogressbar'` | Display text and progress information in a text progress bar in the command window, one line for the entire execution. | 
% | `'waitbar'` | Display text and progress information in a MATLAB `waitbar` (progress bar) figure. | 
% | `'oneline'` | Display text and progress information in a dynamic (changing) single line for the entire execution. | 
% | `'multilines'` | Display text and progress information in dynamic (changing) multiple lines, on per file. Use to control progress of large batch-conversion jobs. | 
