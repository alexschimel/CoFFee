classdef test_CFF_process_WC < matlab.unittest.TestCase
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
            
            testCase.rawFiles = CFF_test_raw_files.get('one_small_file_with_wcd_per_format');
            CFF_print_raw_files_list(testCase.rawFiles);
            
            % convert data
            testCase.fData = CFF_convert_raw_files(testCase.rawFiles,...
                'conversionType','WCD',...
                'forceReconvert',0,...
                'comms','multilines');
            
            % pre-process data
            testCase.fData = CFF_group_processing(testCase.fData,...
                {@CFF_compute_ping_navigation_v2, @CFF_georeference_bottom_detect, @CFF_filter_bottom_detect_v2},...
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
            
            % missing required input fData
            verifyError(testCase,@() CFF_process_WC(), 'MATLAB:minrhs');
            
            % invalid fData
            verifyError(testCase,@() CFF_process_WC(1), 'MATLAB:InputParser:ArgumentFailedValidation');
            
            % missing input func. Should return fData input with warning
            % verify with single fData
            verifyWarning(testCase,@() CFF_process_WC(testCase.fData{1}),'');
            % verify with multiple fData
            if numel(testCase.fData)>1
                verifyWarning(testCase,@() CFF_process_WC(testCase.fData),'');
            end
            
            % check with dummy processing function that just returns input
            dummyWcProcFun = @(data,fData,iPings,params) deal(data,params);
            % single fData
            try
                CFF_process_WC(testCase.fData{1},dummyWcProcFun,{},'resumeProcess',1);
                pass = true;
            catch ME
                pass = false;
            end
            verifyTrue(testCase, pass,'error');
            % multiple fData
            if numel(testCase.fData)>1
                CFF_process_WC(testCase.fData,dummyWcProcFun,{},'resumeProcess',1);
            end
            
            % check aborting options
            if numel(testCase.fData)>1
                % create a test set of several fData, with the first one
                % having an error
                fDataTest = testCase.fData;
                datagramSource = CFF_get_datagramSource(fDataTest{1});
                fDataTest{1} = rmfield(fDataTest{1},sprintf('%s_SBP_SampleAmplitudes',datagramSource));
                
                % process without continue on error. This should throw the
                % error
                verifyError(testCase,@() CFF_process_WC(fDataTest,dummyWcProcFun,{}), 'MATLAB:nonExistentField');
                
                % process with continuing on error. This should log the
                % error in comms and move on to the next file
                CFF_process_WC(fDataTest,dummyWcProcFun,{},'continueOnError',1,'Comms','multilines');
            end
            
            % check comms on one file
            CFF_process_WC(testCase.fData{1},dummyWcProcFun,'comms','');
            CFF_process_WC(testCase.fData{1},dummyWcProcFun,'comms','disp');
            CFF_process_WC(testCase.fData{1},dummyWcProcFun,'comms','textprogressbar');
            CFF_process_WC(testCase.fData{1},dummyWcProcFun,'comms','waitbar');
            CFF_process_WC(testCase.fData{1},dummyWcProcFun,'comms','oneline');
            CFF_process_WC(testCase.fData{1},dummyWcProcFun,'comms','multilines');
            
            % check comms on multiple files
            if numel(testCase.fData)>1
                CFF_process_WC(testCase.fData,dummyWcProcFun,'comms','');
                CFF_process_WC(testCase.fData,dummyWcProcFun,'comms','disp');
                CFF_process_WC(testCase.fData,dummyWcProcFun,'comms','textprogressbar');
                CFF_process_WC(testCase.fData,dummyWcProcFun,'comms','waitbar');
                CFF_process_WC(testCase.fData,dummyWcProcFun,'comms','oneline');
                CFF_process_WC(testCase.fData,dummyWcProcFun,'comms','multilines');
            end

        end
        
        function only_sidelobe_filtering_no_params_FILE_PER_FILE(testCase)
            for ii = 1:numel(testCase.rawFiles)
                fData = CFF_process_WC(testCase.fData{ii},...
                    @CFF_filter_WC_sidelobe_artifact_CORE,...
                    'comms','multilines');
                iPing = 1;
                WCD_raw = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData)),'iPing',iPing);
                WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                cmin = CFF_invpercentile(double([WCD_raw(:);WCD_proc(:)]),1);
                cmax = CFF_invpercentile(double([WCD_raw(:);WCD_proc(:)]),99);
                figure;
                t = tiledlayout('flow');
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; caxis([cmin,cmax]);
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                nexttile(); imagesc(WCD_proc);
                grid on; colorbar; colormap jet; caxis([cmin,cmax]);
                xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(fData.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                drawnow;
            end
        end
        
        function only_sidelobe_filtering_no_params(testCase)
            fData = CFF_process_WC(testCase.fData,...
                @CFF_filter_WC_sidelobe_artifact_CORE,...
                'comms','multilines');
            iPing = 1;
            for ii = 1:numel(fData)
                WCD_raw = CFF_get_WC_data(fData{ii},sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData{ii})),'iPing',iPing);
                WCD_proc = CFF_get_WC_data(fData{ii},'X_SBP_WaterColumnProcessed','iPing',iPing);
                cmin = CFF_invpercentile(double([WCD_raw(:);WCD_proc(:)]),1);
                cmax = CFF_invpercentile(double([WCD_raw(:);WCD_proc(:)]),99);
                figure;
                t = tiledlayout('flow');
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; caxis([cmin,cmax]);
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                nexttile(); imagesc(WCD_proc);
                grid on; colorbar; colormap jet; caxis([cmin,cmax]);
                xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(fData{ii}.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                drawnow;
            end
        end
        
        function only_masking_no_params(testCase)
            fDataGroup = CFF_process_WC(testCase.fData,...
                @CFF_mask_WC_data_CORE,...
                'comms','multilines');
            iPing = 1;
            for ii = 1:numel(testCase.rawFiles)
                fData = fDataGroup{ii};
                WCD_raw = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData)),'iPing',iPing);
                WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                cmin = CFF_invpercentile(double([WCD_raw(:);WCD_proc(:)]),1);
                cmax = CFF_invpercentile(double([WCD_raw(:);WCD_proc(:)]),99);
                figure;
                t = tiledlayout('flow');
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; caxis([cmin,cmax]);
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                nexttile(); imagesc(WCD_proc);
                grid on; colorbar; colormap jet; caxis([cmin,cmax]);
                xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(fData.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                drawnow;
            end
        end
        
        function only_radiometric_correction_no_params(testCase)
            fDataGroup = CFF_process_WC(testCase.fData,...
                @CFF_WC_radiometric_corrections_CORE,...
                'comms','multilines');
            iPing = 1;
            for ii = 1:numel(testCase.rawFiles)
                fData = fDataGroup{ii};
                dS = CFF_get_datagramSource(fData);
                WCD_raw = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',dS),'iPing',iPing);
                WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                figure;
                t = tiledlayout('flow');
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                nexttile(); imagesc(WCD_proc);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                titleStr = sprintf('%s\nwater-column (dB), ping %i, TPRM(1)=%g, X(1)=%g, C(1)=%g',...
                    char(CFF_onerawfileonly(fData.ALLfilename)),iPing,...
                    fData.Ru_1D_TransmitPowerReMaximum(1),...
                    fData.(sprintf('%s_1P_TVGFunctionApplied',dS))(1),...
                    fData.(sprintf('%s_1P_TVGOffset',dS))(1));
                title(t,titleStr,'Interpreter','none','fontSize',10);
                drawnow;
            end
        end
        
        function only_sidelobe_filtering_with_params(testCase)
            % create a range of parameters
            params = struct();
            params(1).avgCalc = 'median';
            params(1).refType = 'constant';
            params(1).refCst = -30;
            params(2).avgCalc = 'median';
            params(2).refType = 'fromPingData';
            params(2).refArea = 'nadirWC';
            params(2).refCalc = 'median';
            params(3).avgCalc = 'mean';
            params(3).refType = 'fromPingData';
            params(3).refArea = 'cleanWC';
            params(3).refCalc = 'perc10';
            params(4).avgCalc = 'mean';
            params(4).refType = 'fromPingData';
            params(4).refArea = 'nadirWC';
            params(4).refCalc = 'mean';
            for ii = 1:numel(testCase.rawFiles)
                iPing = 1;
                WCD_raw = CFF_get_WC_data(testCase.fData{ii},sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(testCase.fData{ii})),'iPing',iPing);
                figure;
                t = tiledlayout('flow');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(testCase.fData{ii}.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet;
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                c = caxis(); % keep the original caxis for all processing
                for jj = 1:numel(params)
                    fData = CFF_process_WC(testCase.fData{ii},...
                        @CFF_filter_WC_sidelobe_artifact_CORE,...
                        params(jj),...
                        'comms','multilines');
                    WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                    nexttile(); imagesc(WCD_proc);
                    grid on; colorbar; colormap jet; caxis(c); % keep the original caxis for all processing
                    xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                    drawnow;
                end
            end
        end
        
        function only_masking_with_params(testCase)
            % create a range of parameters
            params = struct();
            params(1).maxAngle = 30;
            params(2).minRange = 5;
            params(3).maxRangeBelowBottomEcho = 0;
            params(4).maxPercentFaultyDetects = 15;
            params(5).maxRangeBelowMSR = 0;
            params(6).maxAngle = 45;
            params(6).minRange = 2;
            params(6).maxRangeBelowBottomEcho = 0;
            for ii = 1:numel(testCase.rawFiles)
                iPing = 1;
                WCD_raw = CFF_get_WC_data(testCase.fData{ii},sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(testCase.fData{ii})),'iPing',iPing);
                figure;
                t = tiledlayout('flow');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(testCase.fData{ii}.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet;
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                c = caxis(); % keep the original caxis for all processing
                for jj = 1:numel(params)
                    fData = CFF_process_WC(testCase.fData{ii},...
                        @CFF_mask_WC_data_CORE,...
                        params(jj),...
                        'comms','multilines');
                    WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                    nexttile(); imagesc(WCD_proc);
                    grid on; colorbar; colormap jet; caxis(c); % keep the original caxis for all processing
                    xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                    drawnow;
                end
            end
        end
        
        function only_radiometric_correction_with_params(testCase)
            % create a range of parameters
            params = struct();
            params(1).outVal = 'Sv';
            params(2).outVal = 'Sa';
            params(3).outVal = 'TS';
            for ii = 1:numel(testCase.rawFiles)
                iPing = 1;
                WCD_raw = CFF_get_WC_data(testCase.fData{ii},sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(testCase.fData{ii})),'iPing',iPing);
                figure;
                t = tiledlayout('flow');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(testCase.fData{ii}.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                for jj = 1:numel(params)
                    fData = CFF_process_WC(testCase.fData{ii},...
                        @CFF_WC_radiometric_corrections_CORE,...
                        params(jj),...
                        'comms','multilines');
                    WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                    nexttile(); imagesc(WCD_proc);
                    grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                    xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                    drawnow;
                end
            end
        end
        
        function rad_and_filt_no_params(testCase)
            fDataGroup = CFF_process_WC(testCase.fData,...
                {@CFF_WC_radiometric_corrections_CORE,@CFF_filter_WC_sidelobe_artifact_CORE},...
                'comms','multilines');
            iPing = 1;
            for ii = 1:numel(testCase.rawFiles)
                fData = fDataGroup{ii};
                WCD_raw = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData)),'iPing',iPing);
                WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                figure;
                t = tiledlayout('flow');
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                nexttile(); imagesc(WCD_proc);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(fData.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                drawnow;
            end
        end
       
        function filt_and_mask_with_params(testCase)
            filtParams = struct();
            maskParams = struct();
            maskParams.maxAngle = 45;
            maskParams.minRange = 2;
            maskParams.maxRangeBelowBottomEcho = 0;
            fDataGroup = CFF_process_WC(testCase.fData,...
                {@CFF_filter_WC_sidelobe_artifact_CORE,@CFF_mask_WC_data_CORE},...
                {filtParams,maskParams},...
                'comms','multilines');
            iPing = 1;
            for ii = 1:numel(testCase.rawFiles)
                fData = fDataGroup{ii};
                WCD_raw = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData)),'iPing',iPing);
                WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                cmin = CFF_invpercentile(double([WCD_raw(:);WCD_proc(:)]),1);
                cmax = CFF_invpercentile(double([WCD_raw(:);WCD_proc(:)]),99);
                figure;
                t = tiledlayout('flow');
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; caxis([cmin,cmax]);
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                nexttile(); imagesc(WCD_proc);
                grid on; colorbar; colormap jet; caxis([cmin,cmax]);
                xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(fData.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                drawnow;
            end
        end
        
        function rad_and_mask_with_params(testCase)
            radParams = struct();
            maskParams = struct();
            maskParams.maxAngle = 45;
            maskParams.minRange = 2;
            maskParams.maxRangeBelowBottomEcho = 0;
            fDataGroup = CFF_process_WC(testCase.fData,...
                {@CFF_WC_radiometric_corrections_CORE,@CFF_mask_WC_data_CORE},...
                {radParams,maskParams},...
                'comms','multilines');
            iPing = 1;
            for ii = 1:numel(testCase.rawFiles)
                fData = fDataGroup{ii};
                WCD_raw = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData)),'iPing',iPing);
                WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                figure;
                t = tiledlayout('flow');
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                nexttile(); imagesc(WCD_proc);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(fData.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                drawnow;
            end
        end
        
        function rad_filt_and_mask(testCase)
            radParams = struct();
            filtParams = struct();
            maskParams = struct();
            maskParams.maxAngle = 45;
            maskParams.minRange = 2;
            maskParams.maxRangeBelowBottomEcho = 0;
            fDataGroup = CFF_process_WC(testCase.fData,...
                {@CFF_WC_radiometric_corrections_CORE,@CFF_filter_WC_sidelobe_artifact_CORE,@CFF_mask_WC_data_CORE},...
                {radParams,filtParams,maskParams},...
                'comms','multilines');
            iPing = 1;
            for ii = 1:numel(testCase.rawFiles)
                fData = fDataGroup{ii};
                WCD_raw = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData)),'iPing',iPing);
                WCD_proc = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                figure;
                t = tiledlayout('flow');
                nexttile(); imagesc(WCD_raw);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('raw WCD');
                nexttile(); imagesc(WCD_proc);
                grid on; colorbar; colormap jet; % note with radcorr, we don't match the color scales
                xlabel('beam number'); ylabel('sample number'); title('processed WCD');
                titleStr = sprintf('%s\nwater-column (dB), ping %i',char(CFF_onerawfileonly(fData.ALLfilename)),iPing);
                title(t,titleStr,'Interpreter','none','fontSize',10);
                drawnow;
            end
        end
        
        function comparing_with_each_function_in_turn(testCase)

            % radiometric correction parameters
            radParams = struct();
            
            % sidelobe filtering parameters
            filtParams = struct();
            
            % masking parameters
            maskParams = struct();
            maskParams.maxAngle = 45;
            maskParams.minRange = 1;
            maskParams.maxRangeBelowBottomEcho = 0;
            
            for ii = 1:numel(testCase.rawFiles)
                % Now trying the two approaches to stacking processes
                
                % 1. The ugly-but-best way, passing all desired processing
                % steps to CFF_process_WC. By default, this starts by
                % disregarding any existing processing at the start
                tic
                [fData, allParams] = CFF_process_WC(testCase.fData{ii}, ...
                    {@CFF_WC_radiometric_corrections_CORE,@CFF_filter_WC_sidelobe_artifact_CORE,@CFF_mask_WC_data_CORE},...
                    {radParams,filtParams,maskParams},...
                    'comms','multilines');
                t1 = toc;
                
                % save data
                iPing = 1;
                WCD_raw = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData)),'iPing',iPing);
                WCD_proc_1 = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                
                % start display
                rawFileName = CFF_file_name(CFF_onerawfileonly(fData.ALLfilename{1}),1);
                figure;
                t = tiledlayout('flow');
                titleStr = sprintf('%s water-column (dB), ping %i',rawFileName,iPing);
                title(t,titleStr,'Interpreter','none');
                
                nexttile;
                imagesc(WCD_raw);
                grid on; colorbar; colormap jet
                title('raw data');
                xlabel('beam number'); ylabel('sample number');
                
                nexttile;
                imagesc(WCD_proc_1);
                grid on; colorbar; colormap jet
                title(sprintf('processed data (method 1)\nprocessing time %.2f sec',t1));
                xlabel('beam number'); ylabel('sample number');
                drawnow
                
                % 2. The pretty-but-not-optimal way, calling each function
                % in turn. Here we need to specify when we want to conserve
                % existing processing. Why not optimal? Done this way, the
                % data is encoded after every processing so 1) it takes
                % longer, 2) it introduces increasingly large encoding
                % approximations
                tic
                fData = CFF_WC_radiometric_corrections(testCase.fData{ii},radParams,'comms','multilines');
                fData = CFF_filter_WC_sidelobe_artifact(fData,filtParams,'resumeProcess',1,'comms','multilines');
                fData = CFF_mask_WC_data(fData,maskParams,'resumeProcess',1,'comms','multilines');
                t2 = toc;
                
                % save data
                WCD_proc_2 = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
                
                % finish display
                nexttile;
                imagesc(WCD_proc_2);
                grid on; colorbar; colormap jet
                title(sprintf('processed data (method 2)\nprocessing %.2f sec',t2));
                xlabel('beam number'); ylabel('sample number');
                
                nexttile;
                imagesc(WCD_proc_2-WCD_proc_1);
                grid on; colorbar; colormap jet
                title(sprintf('difference in processed data (method 2 - method 1)\nmin: %.3f, max: %.3f',min(WCD_proc_2(:)-WCD_proc_1(:)),max(WCD_proc_2(:)-WCD_proc_1(:))));
                xlabel('beam number'); ylabel('sample number');
                drawnow;
                
            end
            
        end
        
    end
end

