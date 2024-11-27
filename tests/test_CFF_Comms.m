classdef test_CFF_Comms < matlab.unittest.TestCase
    
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
        
        function basicTest(testCase)
            comms = CFF_Comms('');
            comms.start('start message');
            comms.finish('end message');
        end
        
        function advancedTest1(testCase)
            comms = CFF_Comms('');
            comms.start('start message');
            comms.progress(0,3);
            comms.step('step 1');
            comms.info('information A here');
            comms.progress(1,3);
            comms.step('step 2');
            comms.progress(2,3);
            comms.info('information B here');
            comms.error('error here');
            comms.step('step 3');
            comms.progress(3,3);
            comms.finish('end message');
        end
        
        function advancedTest2(testCase)
            comms = CFF_Comms('disp');
            comms.start('start message');
            comms.progress(0,3);
            comms.step('step 1');
            comms.info('information A here');
            comms.progress(1,3);
            comms.step('step 2');
            comms.progress(2,3);
            comms.info('information B here');
            comms.error('error here');
            comms.step('step 3');
            comms.progress(3,3);
            comms.finish('end message');
        end
        
        function advancedTest3(testCase)
            comms = CFF_Comms('textprogressbar');
            comms.start('start message');
            comms.progress(0,3);
            comms.step('step 1');
            comms.info('information A here');
            comms.progress(1,3);
            comms.step('step 2');
            comms.progress(2,3);
            comms.info('information B here');
            comms.error('error here');
            comms.step('step 3');
            comms.progress(3,3);
            comms.finish('end message');
        end
        
        function advancedTest4(testCase)
            comms = CFF_Comms('waitbar');
            comms.start('start message');
            comms.progress(0,3);
            comms.step('step 1');
            comms.info('information A here');
            comms.progress(1,3);
            comms.step('step 2');
            comms.progress(2,3);
            comms.info('information B here');
            comms.error('error here');
            comms.step('step 3');
            comms.progress(3,3);
            comms.finish('end message');
            close(findall(groot,'type','figure'));
        end
        
        function advancedTest5(testCase)
            comms = CFF_Comms('oneline');
            comms.start('start message');
            comms.progress(0,3);
            comms.step('step 1');
            comms.info('information A here');
            comms.progress(1,3);
            comms.step('step 2');
            comms.progress(2,3);
            comms.info('information B here');
            comms.error('error here');
            comms.step('step 3');
            comms.progress(3,3);
            comms.finish('end message');
        end
        
        function advancedTest6(testCase)
            comms = CFF_Comms('multilines');
            comms.start('start message');
            comms.progress(0,3);
            comms.step('step 1');
            comms.info('information A here');
            comms.progress(1,3);
            comms.step('step 2');
            comms.progress(2,3);
            comms.info('information B here');
            comms.error('error here');
            comms.step('step 3');
            comms.progress(3,3);
            comms.finish('end message');
        end
        
    end
end

