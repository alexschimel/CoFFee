function [badSoundings, badPings, badSections] = CFF_analyze_backscatter_CORE(reflectivity,varargin)

DEBUG = 0;

% Input arguments management
p = inputParser;
addRequired(p,'reflectivity',@(x) validateattributes(x,{'numeric'},{'2d'})); % BP array
addOptional(p,'detectionValidity',@(x) validateattributes(x,{'numeric'},{'2d'})); % BP array
addOptional(p,'params',struct(),@(x) isstruct(x)); % processing parameters
parse(p,reflectivity,varargin{:});
detectionValidity = p.Results.detectionValidity;
params = p.Results.params;
clear p

% data dimension
[nBeams, nPings] = size(reflectivity);

if DEBUG
    % display BS
    figure(999); 
    clf;
    tiledlayout(2,1);
    ax1 = nexttile;
    imagesc(reflectivity);
    colormap gray; caxis([-40 0]); grid on
    hold on
end


%% step 1. find bad soundings

% criteria 1: identifying bad beams from detection info
badSoundings = detectionValidity == 'invalid';

if DEBUG
    % display bad soundings
    [row,col] = ind2sub([nBeams, nPings],find(badSoundings));
    plot(col,row,'y*');
end


%% step 2. find bad pings

% criteria 1: a ping with a percentage of bad soundings that exceeds a
% given percentage threshold is a bad ping

% get badSoundingsPercThr
if ~isfield(params,'badSoundingsPercThr'), params.badSoundingsPercThr = 0.1; end % default
validateattributes(params.badSoundingsPercThr,{'numeric'},{'scalar','>=',0,'<=',1}); % validate
badSoundingsPercThr = params.badSoundingsPercThr;

badPings1 = (sum(badSoundings)./nBeams) > badSoundingsPercThr;

if DEBUG
    % display bad pings due to too many bad soundings
    [row,col] = ind2sub([nBeams, nPings],find(badSoundings.*badPings1));
    plot(col,row,'r*');
end

% criteria 2: a ping whose average backscatter level is abnormally low
% is a bad ping

% get pingsWindowLen (number of pings before to calculate average level)
if ~isfield(params,'pingsWindowLen'), params.pingsWindowLen = 10; end % default
validateattributes(params.pingsWindowLen,{'numeric'},{'scalar','>=',1}); % validate
pingsWindowLen = params.pingsWindowLen;

% get pingsGateLen (gate between window and ping of interest
if ~isfield(params,'pingsGateLen'), params.pingsGateLen = 5; end % default
validateattributes(params.pingsGateLen,{'numeric'},{'scalar','>=',0}); % validate
pingsGateLen = params.pingsGateLen;

% get dbDropThr (threshold dB to be considered a drop)
if ~isfield(params,'dbDropThr'), params.dbDropThr = -3; end % default
validateattributes(params.dbDropThr,{'numeric'},{'scalar','<',0}); % validate
dbDropThr = params.dbDropThr;

% get beamsRatioDropThr (threshold ratio of beams that dropped for the
% entire ping to be considered bad)
if ~isfield(params,'beamsRatioDropThr'), params.beamsRatioDropThr = 0.5; end % default
validateattributes(params.beamsRatioDropThr,{'numeric'},{'scalar','>=',0,'<=',1}); % validate
beamsRatioDropThr = params.beamsRatioDropThr;

if nPings > pingsWindowLen+pingsGateLen
    % cant run the algo on less pings...

    % init
    iKeep = zeros(1,nPings);
    nBeamsDrop = nan(1,nPings);
    iKeep(1:pingsWindowLen+pingsGateLen) = 1;

    for jj = pingsWindowLen+pingsGateLen+1:nPings

        iWin = (jj-pingsGateLen)+(-pingsWindowLen:-1);
        iWin = iWin(logical(iKeep(iWin)));
        if ~isempty(iWin)
            % update average from window
            avgWin = median(reflectivity(:,iWin),2);
        else
            % keep previous average
        end

        % calculate difference to window average for each beam
        diffToWin = reflectivity(:,jj) - avgWin;

        nBeamsDrop(jj) = sum(diffToWin<=dbDropThr);

        if nBeamsDrop(jj)./nBeams>=beamsRatioDropThr
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
        plot(1:nPings,nBeams.*beamsRatioDropThr.*ones(1,nPings),'m--');
        plot(find(~iKeep),nBeamsDrop(~iKeep),'mo');
        grid on
        linkaxes(findall(gcf,'type','axes'),'x');
        drawnow;
    end

else

    badPings2 = false(1,nPings);
end

% combine the two criteria together
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

end