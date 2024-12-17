classdef test_CFF_grid_lines < matlab.unittest.TestCase
    properties
        rawFiles
        fData
    end
    
    methods (TestClassSetup)
        % Share setup for the entire test class
        function init(testCase)            
            % set location of CoFFee code root folder and add to path
            restoredefaultpath();
            coffeeFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee';
            addpath(genpath(coffeeFolder));
            
            testCase.rawFiles = CFF_test_raw_files.get('few_small_allwcd_pair_files');
            CFF_print_raw_files_list(testCase.rawFiles);
            
            % convert seafloor data
            testCase.fData = CFF_convert_raw_files(testCase.rawFiles,...
                'conversionType','seafloor',...
                'forceReconvert',1,...
                'continueOnError',0,...
                'comms','multilines');
            
            % pre-process data
            testCase.fData = CFF_group_processing(testCase.fData,...
                {@CFF_compute_ping_navigation_v2, @CFF_georeference_bottom_detect},...
                'continueOnError',0,...
                'comms','multilines');

        end
    end
    
    methods (TestMethodSetup)
        % Setup for each test
    end
    
    methods (Test)
        % Test methods
        
        % test inputs
        function test_inputs(testCase)
                       
            % normal execution
            fData = CFF_grid_lines(testCase.fData,...
                'comms','multilines');
            clear fData
            
            % test continueOnError
            fDataGroupWithError = testCase.fData;
            fDataGroupWithError{1} = rmfield(fDataGroupWithError{1},'X_BP_bottomEasting'); % remove needed field
            % error with default continueOnError=0
            verifyError(testCase,@() CFF_grid_lines(fDataGroupWithError),'MATLAB:nonExistentField');
            % continue with continueOnError=1
            fData = CFF_grid_lines(fDataGroupWithError,...
                'continueOnError',1,...
                'comms','multilines');
            clear fData;
            
        end
        
    end
end

