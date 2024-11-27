classdef test_CFF_list_raw_files_in_dir < matlab.unittest.TestCase
    
    properties
        rootDataFolder_allwcd = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz';
        rootDataFolder_all = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\UTM_2019_EM2040c_Redang-Island-Malaysia';
        rootDataFolder_wcd = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg all\EM2040C\Deakin_2017_EM2040c_Bunurong';
        rootDataFolder_kmallkmwcd = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg kmall\EM 304 data\20200428_REVH_Lines';
        rootDataFolder_kmall = 'C:\Users\Schimel_Alexandre\Data\MBES\Kongsberg kmall\EM 2040C\EM 2040C Dual Head';
        rootDataFolder_s7k = 'C:\Users\Schimel_Alexandre\Data\MBES\Norbit s7k\iWBMS\Aquason_2023_iWBMS_test_file';
        rootDataFolder_recursive = 'C:\Users\Schimel_Alexandre\Data\MBES';
    end
    
    methods (TestClassSetup)
        % Share setup for the entire test class
        function init(testCase)
            % set location of CoFFee code root folder and add to path
            restoredefaultpath();
            coffeeFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee';
            addpath(genpath(coffeeFolder));
        end
    end
    
    methods (TestMethodSetup)
        % Setup for each test
    end
    
    methods (Test)
        % Test methods
        
        function check_inputs(testCase)
            
            % check search folder
            rawfileslist = CFF_list_raw_files_in_dir('non-existent-folder');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_all);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_wcd);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_kmallkmwcd);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_kmall);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_s7k);
            
            % check recursive search
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_recursive);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_recursive, 0);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_recursive, 1);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_recursive, 1);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_recursive, 1);
            
            % check wrong file type
            % rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_s7k, 0, 'bim');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_s7k, 0, '.all');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_s7k, 0, '.wcd');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_s7k, 0, '.all/.wcd');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_s7k, 0, {'.all','.kmall'});
            
            % check pairing or not
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.wcd');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all/.wcd');
            
            % check n files wanted
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', 1);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', 3);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', 3, 'first');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', 3, 'last');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', inf, 'last');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', 1, 'random');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', 1, 'random');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', 3, 'random');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 0, '.all', inf, 'random');
            
            % check parameter formatting and combinations
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 'recursiveSearch', 1);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 'filesType', '.all');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 'filesType', '.all', 'nFilesWanted', 2);
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 'filesType', '.all', 'fileSelectMethod', 'random');
            rawfileslist = CFF_list_raw_files_in_dir(testCase.rootDataFolder_allwcd, 'filesType', '.all', 'nFilesWanted', 3, 'fileSelectMethod', 'random');
        end
    end
end

