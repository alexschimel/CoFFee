classdef CFF_test_raw_files
    %UNTITLED7 Summary of this class goes here
    %   Detailed explanation goes here
    
    methods (Static)
        
        function rawFilesList = get(inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            rootFolder = 'C:\Users\Schimel_Alexandre\Data\MBES';
            switch inputArg
                % kongsberg all/wcd
                case 'one_small_all_file'
                    dataFolder = fullfile(rootFolder,'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz');
                    rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.all',1);
                case 'one_small_wcd_file'
                    dataFolder = fullfile(rootFolder,'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz');
                    rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.wcd',1);
                case 'one_small_allwcd_pair_file'
                    dataFolder = fullfile(rootFolder,'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz');
                    rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.all/.wcd',1);
                case 'few_small_all_files'
                    dataFolder = fullfile(rootFolder,'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz');
                    rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.all',3);
                case 'few_small_wcd_files'
                    dataFolder = fullfile(rootFolder,'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz');
                    rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.wcd',3);
                case 'few_small_allwcd_pair_files'
                    dataFolder = fullfile(rootFolder,'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz');
                    rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.all/.wcd',3);
                case 'range_small_allwcd_pair_files'
                    dataFolderList = {...
                        'Kongsberg all\EM302\NIWA_2018_EM302_TAN1806',...
                        'Kongsberg all\EM710\KV-FOSAE-2015_EM710_BH02_gas_flares',...
                        'Kongsberg all\EM2040\Amy_2018_EM2040_test_WCD_file',...
                        'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz',...
                        'Kongsberg all\EM3002\Unknown_2012_EM3002'};
                    rawFilesList = {};
                    for i = 1:numel(dataFolderList)
                        rawFilesList(end+1,1) = CFF_list_raw_files_in_dir(fullfile(rootFolder,dataFolderList{i}),0,'.all/.wcd',1);
                    end
                    
                % kongsberg kmall/kmwcd
                % to complete
                case 'one_small_kmallkmwcd_pair_file'
                    dataFolder = fullfile(rootFolder,'Kongsberg kmall\EM 2040C\EM 2040C Single Head\Em2040C_SIS5_Cal Lines');
                    rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.kmall/.kmwcd',1);
                    
                % s7k
                % to do
                case 'one_small_s7k_file'
                    dataFolder = fullfile(rootFolder,'Norbit s7k\iWBMS\Aquason_2023_iWBMS_test_file');
                    rawFilesList = CFF_list_raw_files_in_dir(dataFolder,0,'.s7k',1);
                    
                    % every compatible format
                case 'one_small_file_with_wcd_per_format'
                    dataFolderList = {...
                        'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz',...
                        'Kongsberg kmall\EM 2040C\EM 2040C Single Head\Em2040C_SIS5_Cal Lines',...
                        'Norbit s7k\iWBMS\Aquason_2023_iWBMS_test_file'};
                    rawFilesList = {};
                    for i = 1:numel(dataFolderList)
                        rawFilesList(end+1,1) = CFF_list_raw_files_in_dir(fullfile(rootFolder,dataFolderList{i}),'nFilesWanted',1);
                    end
                case 'range_small_files_with_wcd_per_format'
                    dataFolderList = {...
                        'Kongsberg all\EM2040C\Deakin_2014_EM2040c_Kelp-Pilot-Study\300kHz',...
                        'Kongsberg kmall\EM 2040C\EM 2040C Single Head\Em2040C_SIS5_Cal Lines',...
                        'Norbit s7k\iWBMS\Aquason_2023_iWBMS_test_file',...
                        'Kongsberg all\EM302\NIWA_2018_EM302_TAN1806',...
                        'Kongsberg all\EM710\KV-FOSAE-2015_EM710_BH02_gas_flares',...
                        'Kongsberg all\EM2040\Amy_2018_EM2040_test_WCD_file',...
                        'Kongsberg all\EM3002\Unknown_2012_EM3002',...
                        'Kongsberg kmall\EM 304 data\20200428_REVH_Lines',...
                        'Kongsberg kmall\EM 712 data\20200428_REVH_Lines',...
                        'Norbit s7k\Winghead i77h\Norbit_2021_Winghead-i77h_Thames-7042-WC',...
                        'Norbit s7k\Winghead i80s\Lulworth_2024_Winghead-i80s_Jake-Berry',...
                        'Teledyne s7k\SeaBat T50\NIWA-DML_2020_T50_HS66-Example-files-R7042',...
                        'Teledyne s7k\SeaBat T50\Reson_2021_T50_Example-file-R7018'};
                    rawFilesList = {};
                    for i = 1:numel(dataFolderList)
                        rawFilesList(end+1,1) = CFF_list_raw_files_in_dir(fullfile(rootFolder,dataFolderList{i}),'nFilesWanted',1);
                    end
            end
        end
    end
end

