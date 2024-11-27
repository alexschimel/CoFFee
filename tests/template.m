classdef template < matlab.unittest.TestCase
    
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
        
        function unimplementedTest(testCase)
            testCase.verifyTrue(true);
        end
    end
end

