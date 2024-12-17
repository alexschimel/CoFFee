classdef test_CFF_group_processing < matlab.unittest.TestCase
    properties
        fData
        rawFiles
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
            
            % convert data
            testCase.fData = CFF_convert_raw_files(testCase.rawFiles,...
                'conversionType','WCD',...
                'forceReconvert',0,...
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
            
            % missing or invalid required inputs
            verifyError(testCase,@() CFF_group_processing(), 'MATLAB:minrhs');
            verifyError(testCase,@() CFF_group_processing(1), 'MATLAB:minrhs');
            verifyError(testCase,@() CFF_group_processing(1,2), 'MATLAB:InputParser:ArgumentFailedValidation');
            verifyError(testCase,@() CFF_group_processing(testCase.fData{1},1), 'MATLAB:InputParser:ArgumentFailedValidation');
            
            % 1 dummy functions on 1 or 2 fData
            dummyProcFun = @(fData) deal(fData);
            [fData,params] = CFF_group_processing(testCase.fData{1},dummyProcFun,'comms','disp'); % as struct
            [fData,params] = CFF_group_processing(testCase.fData(1),dummyProcFun,'comms','disp'); % as cell
            [fData,params] = CFF_group_processing(testCase.fData(1:2),dummyProcFun,'comms','disp');
            % two dummy functions on 1 or 2 fData
            [fData,params] = CFF_group_processing(testCase.fData{1},{dummyProcFun,dummyProcFun},'comms','disp'); % as struct
            [fData,params] = CFF_group_processing(testCase.fData(1),{dummyProcFun,dummyProcFun},'comms','disp'); % as cell
            [fData,params] = CFF_group_processing(testCase.fData(1:2),{dummyProcFun,dummyProcFun},'comms','disp');
            % 1 dummy function with params
            dummyProcFunWithParams = @(fData,params) deal(fData,params);
            [fData,params] = CFF_group_processing(testCase.fData{1},dummyProcFunWithParams,'comms','disp'); % as struct
            [fData,params] = CFF_group_processing(testCase.fData(1),dummyProcFunWithParams,'comms','disp'); % as cell
            [fData,params] = CFF_group_processing(testCase.fData(1:2),dummyProcFunWithParams,'comms','disp');
            % 2 dummy function with params
            [fData,params] = CFF_group_processing(testCase.fData{1},{dummyProcFunWithParams,dummyProcFunWithParams},'comms','disp'); % as struct
            [fData,params] = CFF_group_processing(testCase.fData(1),{dummyProcFunWithParams,dummyProcFunWithParams},'comms','disp'); % as cell
            [fData,params] = CFF_group_processing(testCase.fData(1:2),{dummyProcFunWithParams,dummyProcFunWithParams},'comms','disp');
            
            % invalid params
            verifyError(testCase,@() CFF_group_processing(testCase.fData{1},1,dummyProcFunWithParams), 'MATLAB:InputParser:ArgumentFailedValidation');
            % too many params
            verifyError(testCase,@() CFF_group_processing(testCase.fData{1},dummyProcFunWithParams,{struct(),struct()}), '');
            % 1 dummy function with dummy params
            [fData,params] = CFF_group_processing(testCase.fData{1},dummyProcFunWithParams,struct(),'comms','disp'); 
            % single param for two functions
            [fData,params] = CFF_group_processing(testCase.fData{1},{dummyProcFunWithParams,dummyProcFunWithParams},struct(),'comms','disp');
            % two params for two functions
            [fData,params] = CFF_group_processing(testCase.fData{1},{dummyProcFunWithParams,dummyProcFunWithParams},{struct(),struct()},'comms','disp'); 
            % two params for two functions for two fData
            [fData,params] = CFF_group_processing(testCase.fData(1:2),{dummyProcFunWithParams,dummyProcFunWithParams},{struct(),struct()},'comms','disp');
            
            % with a single function, there are no info messages when it is
            % applied. So we only control the start message. 
            % Without input procmsg, we get the default start msg "Applying
            % FUNC". If you add a procmsg, this becomes the start message
            % instead 
            [fData,params] = CFF_group_processing(testCase.fData(1:2),dummyProcFunWithParams,struct(),'comms','disp');
            [fData,params] = CFF_group_processing(testCase.fData(1:2),dummyProcFunWithParams,struct(),'procMsg','Dummy processing','comms','disp');
            % with several functions, there will be an info message
            % indicating the function applied at each step. So we control
            % that info message. The start message is always 'Applying
            % multiple processing'.
            % Without input procmsg, we get the default info msg "Applying
            % FUNC". If you add a procmsg, this has to be messages for each
            % processing 
            [fData,params] = CFF_group_processing(testCase.fData(1:2),{dummyProcFunWithParams,dummyProcFunWithParams},'comms','disp');
            [fData,params] = CFF_group_processing(testCase.fData(1:2),{dummyProcFunWithParams,dummyProcFunWithParams},'procMsg',{'Dummy processing 1','Dummy processing 2'},'comms','disp');
            
            % force-save fData to drive
            [fData,params] = CFF_group_processing(testCase.fData(1:2),dummyProcFunWithParams,'saveFDataToDrive',1,'comms','disp');
            
            % piping params
            [fData,params] = CFF_group_processing(testCase.fData(1:2),dummyProcFunWithParams,'pipeParams',1,'comms','disp');
            
            % check aborting options
            if numel(testCase.fData)>1
                % create a test set of several fData, with the first one
                % having an error
                fDataTest = testCase.fData;
                datagramSource = CFF_get_datagramSource(fDataTest{1});
                fDataTest{1} = rmfield(fDataTest{1},sprintf('%s_1P_TimeSinceMidnightInMilliseconds',datagramSource));
                % process without continue on error. This should throw the
                % error
                verifyError(testCase,@() CFF_group_processing(fDataTest,@CFF_compute_ping_navigation_v2), 'MATLAB:nonExistentField');   
                % process with continuing on error. This should log the
                % error in comms and move on to the next file
                CFF_group_processing(fDataTest,@CFF_compute_ping_navigation_v2,'continueOnError',1,'comms','disp');
            end
            
            % check comms on one file
            CFF_group_processing(testCase.fData(1),dummyProcFunWithParams,'comms','');
            CFF_group_processing(testCase.fData(1),dummyProcFunWithParams,'comms','disp');
            CFF_group_processing(testCase.fData(1),dummyProcFunWithParams,'comms','textprogressbar');
            CFF_group_processing(testCase.fData(1),dummyProcFunWithParams,'comms','waitbar');
            CFF_group_processing(testCase.fData(1),dummyProcFunWithParams,'comms','oneline');
            CFF_group_processing(testCase.fData(1),dummyProcFunWithParams,'comms','multilines');
            % check comms on multiple files
            if numel(testCase.fData)>1
                CFF_group_processing(testCase.fData,dummyProcFunWithParams,'comms','');
                CFF_group_processing(testCase.fData,dummyProcFunWithParams,'comms','disp');
                CFF_group_processing(testCase.fData,dummyProcFunWithParams,'comms','textprogressbar');
                CFF_group_processing(testCase.fData,dummyProcFunWithParams,'comms','waitbar');
                CFF_group_processing(testCase.fData,dummyProcFunWithParams,'comms','oneline');
                CFF_group_processing(testCase.fData,dummyProcFunWithParams,'comms','multilines');
            end
            
            % finally, test actual functions
            [fData,outParams] = CFF_group_processing(...
                testCase.fData,...
                {@CFF_compute_ping_navigation_v2,@CFF_georeference_bottom_detect,@CFF_filter_bottom_detect_v2},...
                {struct(),struct(),struct()},...
                'procMsg',{'Processing navigation and heading','Georeferencing the bottom detections','Filtering the bottom detections'},...
                'continueOnError',0,...
                'saveFDataToDrive',1,...
                'comms','disp');
            [fData,outParams] = CFF_group_processing(...
                testCase.fData,...
                {@CFF_compute_ping_navigation_v2,@CFF_georeference_bottom_detect,@CFF_filter_bottom_detect_v2},...
                {struct(),struct(),struct()},...
                'procMsg',{'Processing navigation and heading','Georeferencing the bottom detections','Filtering the bottom detections'},...
                'continueOnError',0,...
                'saveFDataToDrive',1,...
                'pipeParams',1,...
                'comms','disp');
        end
        
    end
end

