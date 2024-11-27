classdef test_CFF_print_raw_files_list < matlab.unittest.TestCase
    
    properties
        rootDataFolder = 'C:\Users\Schimel_Alexandre\Data\MBES';
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
            
            % empty input
            CFF_print_raw_files_list('');
            CFF_print_raw_files_list({''});
            
            % one file
            rawFilesList = {'C:\Users\Django\Data\file_1.all'};
            CFF_print_raw_files_list(rawFilesList);
            
            % two files, same folder
            rawFilesList = {...
                'C:\Users\Django\Data\file_1.all',...
                'C:\Users\Django\Data\file_2.all'};
            CFF_print_raw_files_list(rawFilesList);
            
            % several files, same folder
            rawFilesList = {...
                'C:\Users\Django\Data\file_1.all',...
                'C:\Users\Django\Data\file_2.all',...
                'C:\Users\Django\Data\file_3.all',...
                'C:\Users\Django\Data\file_4.all'};
            CFF_print_raw_files_list(rawFilesList);
            
            % several files, different folders
            rawFilesList = {...
                'C:\Users\Django\Data\file_1.all',...
                'C:\Users\Django\file_2.all',...
                'C:\Users\file_3.all',...
                'C:\Users\Django\Data\file_4.all'};
            CFF_print_raw_files_list(rawFilesList);
            
            % what if no common folder?
            rawFilesList = {...
                'C:\Users\Django\Data\file_1.all',...
                'D:\Users\Django\Data\file_2.all'};
            CFF_print_raw_files_list(rawFilesList);
            
            % one paired file
            rawFilesList = {{'C:\Users\Django\Data\file_1.all','C:\Users\Django\Data\file_1.wcd'}};
            CFF_print_raw_files_list(rawFilesList);
            
            % two paired files, same folder
            rawFilesList = {...
                {'C:\Users\Django\Data\file_1.all','C:\Users\Django\Data\file_1.wcd'},...
                {'C:\Users\Django\Data\file_2.all','C:\Users\Django\Data\file_2.wcd'}};
            CFF_print_raw_files_list(rawFilesList);
            
            % several paired files, same folder
            rawFilesList = {...
                {'C:\Users\Django\Data\file_1.all','C:\Users\Django\Data\file_1.wcd'},...
                {'C:\Users\Django\Data\file_2.all','C:\Users\Django\Data\file_2.wcd'},...
                {'C:\Users\Django\Data\file_3.all','C:\Users\Django\Data\file_3.wcd'},...
                {'C:\Users\Django\Data\file_4.all','C:\Users\Django\Data\file_4.wcd'}};
            CFF_print_raw_files_list(rawFilesList);
            
            % what if no common folder?
            rawFilesList = {...
                {'C:\Users\Django\Data\file_1.all','C:\Users\Django\Data\file_1.wcd'},...
                {'C:\Users\Django\file_2.all','C:\Users\Django\file_2.wcd'}};
            CFF_print_raw_files_list(rawFilesList);
            
            % mix of paired and non-paired files
            rawFilesList = {...
                {'C:\Users\Django\Data\file_1.all','C:\Users\Django\Data\file_1.wcd'},...
                {'C:\Users\Django\file_2.all','C:\Users\Django\file_2.wcd'},...
                'C:\Users\file_3.s7k',...
                'C:\Users\file_4.s7k'};
            CFF_print_raw_files_list(rawFilesList);
            
            % sample actual data
            rawFilesList = CFF_list_raw_files_in_dir(testCase.rootDataFolder,'recursiveSearch',1,'nFilesWanted',10,'fileSelectMethod','random');
            CFF_print_raw_files_list(rawFilesList);
            
            % all of it
            rawFilesList = CFF_list_raw_files_in_dir(testCase.rootDataFolder,'recursiveSearch',1);
            CFF_print_raw_files_list(rawFilesList);
            
        end
    end
end

