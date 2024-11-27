classdef test_tutorials < matlab.unittest.TestCase
    
    methods (TestClassSetup)
        % Share setup for the entire test class
    end
    
    methods (TestMethodSetup)
        % Setup for each test
    end
    
    methods (Test)
        % Test methods
        
        function testTutorials(testCase)

            rootFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee.wiki';

            % get list of files in wiki
            files = dir(fullfile(rootFolder));

            % for each file
            for i = 1:length(files)
                if ~files(i).isdir
                    % read contents
                    file = fullfile(rootFolder,files(i).name);
                    fid = fopen(file);
                    contents = textscan(fid, '%s', 'Delimiter', '\n');
                    fclose(fid);
                    % start a new matlab .m file to copy code to
                    tutorialsFolder = fullfile(pwd,'wiki_tutorials');
                    if ~isfolder(tutorialsFolder)
                        mkdir(tutorialsFolder);
                    end
                    matlabFile = fullfile(tutorialsFolder,'temp_tutorial.m');
                    fid = fopen(matlabFile, 'w');
                    % for each line in contents, write to matlab file
                    flagCode = 0;
                    for j = 1:length(contents{1})
                        if strcmp(contents{1}{j}, '```')
                            % start of code block, switch flag
                            flagCode = ~flagCode;
                        elseif isempty(contents{1}{j})
                            % empty line
                            fprintf(fid, '\n');
                        else
                            % text, write as comment or code
                            if flagCode
                                % code
                                fprintf(fid, '%s\n', contents{1}{j});
                            else
                                % comment
                                fprintf(fid, '%% %s\n', contents{1}{j});
                            end
                        end
                    end
                    % close matlab file
                    fclose(fid);
                    % save all variables before running the file
                    save(fullfile(pwd,'workspace.mat'));
                    % execute matlab file
                    run(matlabFile);
                    % clear everything and reload all variables
                    clear all
                    close all
                    load(fullfile(pwd,'workspace.mat'));
                    % delete matlab file and workspace
                    delete(matlabFile);
                    delete(fullfile(pwd,'workspace.mat'));
                end
            end

        end
    end
end