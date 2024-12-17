classdef test_CFF_convert_raw_files < matlab.unittest.TestCase
    properties
        rawFiles
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
        
        % test inputs
        function test_inputs(testCase)
                       
            testCase.rawFiles = CFF_test_raw_files.get('few_small_allwcd_pair_files');
            CFF_print_raw_files_list(testCase.rawFiles);
            
            % convert seafloor data
            fData = CFF_convert_raw_files(testCase.rawFiles,...
                'conversionType','seafloor',...
                'forceReconvert',1,...
                'comms','multilines');
            clear fData
            
            % convert WCD
            fData = CFF_convert_raw_files(testCase.rawFiles,...
                'conversionType','WCD',...
                'forceReconvert',1,...
                'comms','multilines');
            clear fData
            
            % test continueOnError
            testErrorFiles = testCase.rawFiles;
            testErrorFiles{1} = 'inexistent_file.all';
            % error with default continueOnError=0
            verifyError(testCase,@() CFF_convert_raw_files(testErrorFiles,'forceReconvert',0),'MATLAB:InputParser:ArgumentFailedValidation');
            % continue with continueOnError=1
            fData = CFF_convert_raw_files(testErrorFiles,...
                'conversionType','WCD',...
                'forceReconvert',1,...
                'continueOnError',1,...
                'comms','multilines');
            
        end
        
    end
end

