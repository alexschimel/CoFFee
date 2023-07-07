function fDataGroup = CFF_analyze_backscatter(fDataGroup,varargin)

global DEBUG
DEBUG = 0;

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

% display to check
if DEBUG
    figure(999);
    tiledlayout(2,1);
end

% process per file
for ii = 1:nLines
    
    % get fData for this line
    fData = fDataGroup{ii};
    
    % display for this line
    lineName = CFF_file_name(char(CFF_onerawfileonly(fData.ALLfilename)),1);
    comms.step(sprintf('%i/%i: line %s',ii,nLines,lineName));
    
    % data dimension
    [nBeams, nPings] = size(fData.X8_BP_ReflectivityBS);
    
    if DEBUG
        % display BS
        clf;
        ax1 = nexttile;
        imagesc(fData.X8_BP_ReflectivityBS);
        colormap gray; caxis([-40 0]); grid on
        hold on
        title(lineName,'Interpreter','none');
    end
    
    %% step 1. find bad soundings
    % criteria 1: identifying bad beams from detection info
    [DetectInfo, ~] = CFF_decode_DetectionInfo(fData.X8_BP_DetectionInformation);
    badSoundings = DetectInfo>1;
    
    if DEBUG
        % display bad soundings
        [row,col] = ind2sub([nBeams, nPings],find(badSoundings));
        plot(col,row,'y*');
    end

    %% step 2. find bad pings    

    % criteria 1: a ping with a percentage of bad soundings that exceeds a
    % given percentage threshold is a bad ping
    thr = 0.1; % between 0 and 1
    badPings1 = (sum(badSoundings)./nBeams) > thr;
    
    if DEBUG
        % display bad pings due to too many bad soundings
        [row,col] = ind2sub([nBeams, nPings],find(badSoundings.*badPings1));
        plot(col,row,'r*');
    end
    
    % criteria 2: a ping whose average backscatter level is abnormally low
    % is a bad ping
    avgBS = median(fData.X8_BP_ReflectivityBS);
    
    iKeep = zeros(1,nPings);
    nBeamsDrop = nan(1,nPings);
    
    windLen = 10;
    gateLen = 5;
    
    dropThr = -3; % threshold dB to be considered a drop
    ratDropThr = 0.5; % threhshold ratio of beams that dropped for the entire ping to be considered bad
    
    iKeep(1:windLen+gateLen) = 1;
    for jj = windLen+gateLen+1:nPings
        
        iWin = (jj-gateLen)+(-windLen:-1);
        iWin = iWin(logical(iKeep(iWin)));
        if ~isempty(iWin)
            % update average from window
            avgWin = median(fData.X8_BP_ReflectivityBS(:,iWin),2);
        else
            % keep previous average
        end
        
        % calculate difference to window average for each beam
        diffToWin = fData.X8_BP_ReflectivityBS(:,jj) - avgWin;
        
        nBeamsDrop(jj) = sum(diffToWin<=dropThr);
        
        if nBeamsDrop(jj)./nBeams>=ratDropThr
            iKeep(jj) = 0;
        else
            iKeep(jj) = 1;
        end

    end
    badPings2 = ~iKeep;
    
    if DEBUG
        if any(badPings2)
            plot(find(badPings2),round(nBeams./2),'m*');
        end
        ax2 = nexttile;
        plot(nBeamsDrop,'.-'); hold on
        plot(1:nPings,nBeams.*ratDropThr.*ones(1,nPings),'m--');
        plot(find(~iKeep),nBeamsDrop(~iKeep),'mo');
        grid on
        linkaxes(findall(gcf,'type','axes'),'x');
    end
    
    % pur two cirteria together
    badPings = badPings1 | badPings2;
    
    %% step 3. identify bad sections
    % criteria 1: a section of pings with a percentage of bad pings that
    % exceeds a threshold is a bad section
    
    % Using a sliding window size in num of pings, and threshold number of
    % bad pings within a window above which to classify window as to be
    % resurveyed
    win = 100;
    nThr = 1;
    badSections = conv2(badPings,ones(1,win),'same')>=nThr;
    
    %% step 4. save results
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