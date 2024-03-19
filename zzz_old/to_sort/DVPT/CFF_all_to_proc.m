function CFF_all_to_proc(raw_folder, proc_folder)
%CFF_ALL_TO_PROC  One-line description
%
%   CFF_ALL_TO_PROC(raw_folder, proc_folder) processes all Kongsberg ".all"
%   raw files that are in "raw_folder" and creates one corresponding "Proc"
%   file for each, then stored into "proc_folder".
%
%   IMPORTANT NOTE: temporary function, in development. See research notes.
%
%   Quick dirty function so just temporary:
%   * using the FPBS format because functions are readily available but
%   might be overkill and too long processing for big files 
%   * recording variables with same name as Proc file, but not fully
%   processed variables, just simple equivalents: 
%   * "ThetaCor" should be angle of incidence but here it's just beam
%   pointing angle, aka no vessel attitude, ray bending, seafloor slope,
%   etc.
%   * "SSCE" should be BS level with full radiometric corrections but
%   here's its just the raw level from the files. 

%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2007-2011 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% create output folder
mkdir(proc_folder);

% get a list of files to convert
[ALL_files,MAT_files] = CFF_filelist_for_conversion(raw_folder, proc_folder,'.all');

% total number of files
Nfiles = length(ALL_files);

% then for each file in the list
for ii = 1:Nfiles
    
    % display
    txt = sprintf('CFF_all_to_proc.m processing file %i/%i...',ii,Nfiles);
    disp(txt)
    
    % ALL file and temporary MAT file
    ALLfile = ALL_files{ii};
    tmpMATfile = './temp.mat';
    
    % Output Proc file name
    PROCfile = MAT_files{ii};
    [p,n,e] = fileparts(PROCfile);
    PROCfile = fullfile(p,['Proc_' n e]);
    
    % convert ALL to MAT
    CFF_convert_all_to_mat_v2(ALLfile,tmpMATfile);
    
    % convert MAT to FPBS
    FPBS = CFF_convert_mat_to_fpbs(tmpMATfile);
    
    % get nav data at ping times from MAT file
    FPBS = CFF_get_nav(FPBS,tmpMATfile);
    
    % project sonar lat/long to utm
    FPBS = CFF_project_nav(FPBS,'wgs84','utm');
    
    % get soundings horizontal position
    FPBS = CFF_get_soundings(FPBS);
    
    % extract wanted data in ping beam arrays
    Easting = CFF_pingbeamarray(FPBS,'Easting');
    Northing = CFF_pingbeamarray(FPBS,'Northing');
    BeamPointingAngle = CFF_pingbeamarray(FPBS,'BeamPointingAngleReNormalToSonarFace');
    BS = CFF_pingbeamarray(FPBS,'ReflectivityBS');
    
    % proc files are in BP not PB:
    X = Easting';
    Y = Northing';
    ThetaCor = abs(BeamPointingAngle)';
    SSCE = BS';
    
    % save in proc file
    save(PROCfile,'X','Y','ThetaCor','SSCE');
    
    % delete temp MAT file
    delete(tmpMATfile)
    
end

