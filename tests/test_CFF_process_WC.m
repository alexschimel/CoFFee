classdef test_CFF_process_WC < matlab.unittest.TestCase
    properties
        fData
    end
    properties (TestParameter)
        rawFile = CFF_test_raw_files.get('range_small_files_with_wcd_var_format');
    end
    
    methods (TestClassSetup)
        % Share setup for the entire test class
        function init(testCase)
            
            % set location of CoFFee code root folder and add to path
            restoredefaultpath();
            coffeeFolder = 'C:\Users\Schimel_Alexandre\Code\MATLAB\CoFFee';
            addpath(genpath(coffeeFolder));
            
            % pre-process data
            for i = 1:numel(testCase.rawFile)
                % convert
                fData = CFF_convert_raw_files(testCase.rawFile(i),...
                    'conversionType','WCD',...
                    'forceReconvert',0,...
                    'abortOnError',1,...
                    'comms','oneline');
                % navigation processing
                fData = CFF_compute_ping_navigation_v2(fData);
                % georeference WC bottom detect
                fData = CFF_georeference_bottom_detect(fData);
                % bottom filtering
                testCase.fData{i} = CFF_filter_bottom_detect_v2(fData);
            end
            
        end
    end
    
    methods (TestMethodSetup)
        % Setup for each test
    end
    
    methods (Test)
        % Test methods
        
        function only_sidelobe_filtering(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with no params
            fData = CFF_process_WC(testCase.fData{ii},...
                @CFF_filter_WC_sidelobe_artifact_CORE,...
                'comms','oneline');
        end
        
        function only_sidelobe_filtering_with_params(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with params
            params = struct();
            fData = CFF_process_WC(testCase.fData{ii},...
                @CFF_filter_WC_sidelobe_artifact_CORE,...
                params,...
                'comms','oneline');
        end
        
        function only_masking(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with no params
            fData = CFF_process_WC(testCase.fData{ii},...
                @CFF_mask_WC_data_CORE,...
                'comms','oneline');
        end
        
        function only_masking_with_params(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with params
            params = struct();
            params.maxAngle = 45;
            params.minRange = 1;
            params.maxRangeBelowBottomEcho = 0;
            fData = CFF_process_WC(testCase.fData{ii},...
                @CFF_mask_WC_data_CORE,...
                params,...
                'comms','oneline');
        end
        
        function only_radiometric_correction(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with no params
            fData = CFF_process_WC(testCase.fData{ii},...
                @CFF_WC_radiometric_corrections_CORE,...
                'comms','oneline');
        end
        
        function only_radiometric_correction_with_params(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with params
            params = struct();
            params.maxAngle = 45;
            params.minRange = 1;
            params.maxRangeBelowBottomEcho = 0;
            fData = CFF_process_WC(testCase.fData{ii},...
                @CFF_WC_radiometric_corrections_CORE,...
                params,...
                'comms','oneline');
        end
        
        function two_functions_1(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with no params
            fData = CFF_process_WC(testCase.fData{ii},...
                {@CFF_filter_WC_sidelobe_artifact_CORE,@CFF_mask_WC_data_CORE},...
                'comms','oneline');
        end
        
        function two_functions_2(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with no params
            fData = CFF_process_WC(testCase.fData{ii},...
                {@CFF_filter_WC_sidelobe_artifact_CORE,@CFF_WC_radiometric_corrections_CORE},...
                'comms','oneline');
        end
        
        function two_functions_3(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % apply with no params
            fData = CFF_process_WC(testCase.fData{ii},...
                {@CFF_mask_WC_data_CORE,@CFF_WC_radiometric_corrections_CORE},...
                'comms','oneline');
        end
        
        function three_functions_with_params(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % sidelobe filtering parameters
            sidelobeFiltParams = struct();
            % masking parameters
            maskParams = struct();
            maskParams.maxAngle = 45;
            maskParams.minRange = 1;
            maskParams.maxRangeBelowBottomEcho = 0;
            % radiometric correction parameters
            radiomCorParams = struct();
            [fData, allParams] = CFF_process_WC(testCase.fData{ii}, ...
                {@CFF_filter_WC_sidelobe_artifact_CORE,@CFF_mask_WC_data_CORE,@CFF_WC_radiometric_corrections_CORE},...
                {sidelobeFiltParams,maskParams,radiomCorParams},...
                'comms','oneline');
        end
        
        function each_functions_in_turn(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            % sidelobe filtering parameters
            sidelobeFiltParams = struct();
            % masking parameters
            maskParams = struct();
            maskParams.maxAngle = 45;
            maskParams.minRange = 1;
            maskParams.maxRangeBelowBottomEcho = 0;
            % radiometric correction parameters
            radiomCorParams = struct();
            fData = CFF_filter_WC_sidelobe_artifact(testCase.fData{ii},sidelobeFiltParams,'comms','oneline');
            fData = CFF_mask_WC_data(fData,maskParams,'flagReprocess',0,'comms','oneline');
            fData = CFF_WC_radiometric_corrections(fData,radiomCorParams,'flagReprocess',0,'comms','oneline');
        end
        
        function big_test(testCase, rawFile)
            [~,ii] = ismember(CFF_file_name(CFF_onerawfileonly(rawFile)),cellfun(@(x) CFF_file_name(x.ALLfilename{1}),testCase.fData,'UniformOutput',false));
            
            % sidelobe filtering parameters
            sidelobeFiltParams = struct();
            
            % masking parameters
            maskParams = struct();
            maskParams.maxAngle = 45;
            maskParams.minRange = 1;
            maskParams.maxRangeBelowBottomEcho = 0;
            
            % radiometric correction parameters
            radiomCorParams = struct();
            
            % Now trying the two approaches to stacking processes
            
            % 1. The ugly-but-best way, passing all desired processing
            % steps to CFF_process_WC. By default, this disregard any
            % existing processing at the start 
            tic
            [fData, allParams] = CFF_process_WC(testCase.fData{ii}, ...
                {@CFF_filter_WC_sidelobe_artifact_CORE,@CFF_mask_WC_data_CORE,@CFF_WC_radiometric_corrections_CORE},...
                {sidelobeFiltParams,maskParams,radiomCorParams},...
                'comms','oneline');
            t1 = toc;
            
            % save data
            iPing = 1;
            WCD_raw = CFF_get_WC_data(fData,'WC_SBP_SampleAmplitudes','iPing',iPing);
            WCD_proc_1 = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
            
            % 2. The pretty-but-not-optimal way, calling each function in turn.
            % Here we need to specify when we want to conserve existing processing.
            % Why not optimal? Done this way, the data is encoded after every
            % processing so 1) it takes longer, 2) it introduces increasingly large
            % encoding approximations
            tic
            fData = CFF_filter_WC_sidelobe_artifact(testCase.fData{ii},sidelobeFiltParams,'comms','oneline');
            fData = CFF_mask_WC_data(fData,maskParams,'flagReprocess',0,'comms','oneline');
            fData = CFF_WC_radiometric_corrections(fData,radiomCorParams,'flagReprocess',0,'comms','oneline');
            t2 = toc;
            
            % save data
            WCD_proc_2 = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
            
            % display results
            rawFileName = CFF_file_name(CFF_onerawfileonly(fData.ALLfilename{1}),1);
            minC = min([WCD_raw(:);WCD_proc_1(:);WCD_proc_2(:)]);
            maxC = max([WCD_raw(:);WCD_proc_1(:);WCD_proc_2(:)]);
            
            figure;
            t = tiledlayout(1,4);
            titleStr = sprintf('%s water-column (dB), ping %i',rawFileName,iPing);
            title(t,titleStr,'Interpreter','none');
            
            nexttile;
            imagesc(WCD_raw);
            grid on; colorbar; colormap jet
            title('raw data');
            xlabel('beam number'); ylabel('sample number');
            caxis([minC,maxC]);
            
            nexttile;
            imagesc(WCD_proc_1);
            grid on; colorbar; colormap jet
            title(sprintf('processed data (method 1)\nprocessing time %.2f sec',t1));
            xlabel('beam number'); ylabel('sample number');
            caxis([minC,maxC]);
            
            nexttile;
            imagesc(WCD_proc_2);
            grid on; colorbar; colormap jet
            title(sprintf('processed data (method 2)\nprocessing %.2f sec',t2));
            xlabel('beam number'); ylabel('sample number');
            caxis([minC,maxC]);
            
            nexttile;
            imagesc(WCD_proc_2-WCD_proc_1);
            grid on; colorbar; colormap jet
            title(sprintf('difference in processed data (method 2 - method 1)\nmin: %.3f, max: %.3f',min(WCD_proc_2(:)-WCD_proc_1(:)),max(WCD_proc_2(:)-WCD_proc_1(:))));
            xlabel('beam number'); ylabel('sample number');
            
        end
        
    end
end

