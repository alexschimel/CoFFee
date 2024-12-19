function fDataGroup = CFF_analyze_backscatter(fDataGroup,varargin)

% input parser
p = inputParser;
addRequired(p,'fDataGroup',@(x) all(CFF_is_fData_version_current(x)));
addParameter(p,'comms',CFF_Comms());
parse(p,fDataGroup,varargin{:});
comms = p.Results.comms;
clear p;
if ischar(comms)
    comms = CFF_Comms(comms);
end

% start message
comms.start('Analyzing backscatter in line(s)');

% number of lines
nLines = numel(fDataGroup);

% start progress
comms.progress(0,nLines);

% process per file
for ii = 1:nLines
    
    % get fData for this line
    fData = fDataGroup{ii};
    
    % display for this line
    lineName = CFF_file_name(char(CFF_onerawfileonly(fData.ALLfilename)),1);
    comms.step(sprintf('%i/%i: line %s',ii,nLines,lineName));
    
    % run algos
    reflectivity = fData.X8_BP_ReflectivityBS;
    detectionValidity = fData.X8_BP_DetectionValidity;
    [badSoundings, badPings, badSections] = CFF_analyze_backscatter_CORE(reflectivity,detectionValidity);
    
    % save results
    fData.X_BP_goodData = ~badSoundings;
    fData.X_1P_badPing = badPings;
    fData.X_1P_toResurvey = badSections;
    fDataGroup{ii} = fData;
    
    % successful end of this iteration
    comms.info('Done');
    
    % communicate progress
    comms.progress(ii,nLines);
    
end

% end message
comms.finish('Done');

end