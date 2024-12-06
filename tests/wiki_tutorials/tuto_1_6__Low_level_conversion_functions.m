% This help page informs the use of low-level functions in _CoFFee_ for more granular raw data conversion .

% In tutorials so far, we used `CFF_convert_raw_files` to convert raw data files into CoFFee's data format (`fData`). `CFF_convert_raw_files` is a format-independent, high-level function to operate the conversion. This is how it works under the hood.

% # 1. Low-level processing sequence

% CoFFee actually converts raw data with the following sequence:
% 1. List all datagrams in file.
% 2. Read desired datagrams from file.
% 3. Convert those datagrams to `fData`.

% Those three steps depend on the raw data format, and thus are done with format-dependent, low-level functions:

% | Step                 | Kongsberg all/wcd              | Kongsberg kmall/kmwcd            | Teledyne Reson s7k             |
% | -------------        | -------------                  | -------------                    | -------------                  | 
% | 1. List datagrams    | `CFF_all_file_info`            | `CFF_kmall_file_info`            | `CFF_s7k_file_info`            |
% | 2. Read datagrams    | `CFF_read_all_from_fileinfo`   | `CFF_read_kmall_from_fileinfo`   | `CFF_read_s7k_from_fileinfo`   |
% | 3. Convert datagrams | `CFF_convert_ALLdata_to_fData` | `CFF_convert_KMALLdata_to_fData` | `CFF_convert_S7Kdata_to_fData` |

% Note that the output of step 2 is a data format that is very close to the original raw data, but in MATLAB. So if you want to use _CoFFee_ to explore the raw data contents, this is the output you want to produce and examine. The next step of conversion (step 3) only retains parts of the original data, and transforms it for other _CoFFee_ functions to exploit, so it is not as close to the original raw data.

% Here is an example code sequence using those low-level functions to convert only the 'XYZ 88' datagrams from a Kongsberg .all file:
rawFile = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz\0001_20140213_052736_Yolla.all';
fileInfo = CFF_all_file_info(rawFile);
iDatagramsToConvert = find(fileInfo.datagTypeNumber==88);
fileInfo.parsed(iDatagramsToConvert) = 1; % use the 'parsed' field to inform the next function which datagrams to read
EMdata = CFF_read_all_from_fileinfo(rawFile, fileInfo);
fData = CFF_convert_ALLdata_to_fData(EMdata);

% In the case of a file pair (i.e. Kongsberg all/wcd or kmall/kmwcd), you need to run the steps 1 and 2 functions on each file separately, then use the step 3 function on the result. Here is an example code sequence to convert all datagrams from a pair of Kongsberg .all/.wcd files:
rawFiles = {...
'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz\0001_20140213_052736_Yolla.all',...
'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz\0001_20140213_052736_Yolla.wcd'};

ALLinfo = CFF_all_file_info(rawFiles{1});
ALLinfo.parsed(:) = 1;
ALLdata = CFF_read_all_from_fileinfo(rawFiles{1}, ALLinfo);

WCDinfo = CFF_all_file_info(rawFiles{2});
WCDinfo.parsed(:) = 1;
WCDdata = CFF_read_all_from_fileinfo(rawFiles{2}, WCDinfo);

fData = CFF_convert_ALLdata_to_fData({ALLdata,WCDdata});

% # 2. Medium-level processing sequence

% A format-dependent, medium-level function exists to operate steps 1 and 2 together:

% | Kongsberg all/wcd  | Kongsberg kmall/kmwcd | Teledyne Reson s7k |
% | -------------      | -------------         | -------------      | 
% | `CFF_read_all`     | `CFF_read_kmall`      | `CFF_read_s7k`     |

% Rewriting our first example (convert only the 'XYZ 88' datagrams from a Kongsberg .all file) using this medium-level function:
rawFile = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz\0001_20140213_052736_Yolla.all';
codesDatagramsToParse = 88; % Note you can make this an array of datagram codes to parse
EMdata = CFF_read_all(rawFile,codesDatagramsToParse);
fData = CFF_convert_ALLdata_to_fData(EMdata);

% The advantage of this function is that it works with file pairs and manages for you the case of duplicate datagrams. You give it a pair of files and it will skip the reading of a type of datagrams from the second file if this type was found in the first file.  

% Rewriting our second example (convert all datagrams from a pair of Kongsberg .all/.wcd files) using this medium-level function:
rawFiles = {...
'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz\0001_20140213_052736_Yolla.all',...
'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz\0001_20140213_052736_Yolla.wcd'};
codesDatagramsToParse  = []; % empty means convert all datagram types (but don't duplicate conversion)
EMdata = CFF_read_all(rawFiles,codesDatagramsToParse);
fData = CFF_convert_ALLdata_to_fData(EMdata);
