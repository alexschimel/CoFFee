%% CFF_watercolumn_display.m
%
% Displays Multibeam watercolumn data in various ways.
%
%% Help
%
% *USE*
%
%
%
% *INPUT VARIABLES*
%
% * |fData|: the multibeam data structure
%
% * |data|: string indicating which data in fData to grab: 'original'
% (default) or 'processed'. Can be overwritten by inputting "otherData". 
%
% * |displayType|: string indicating type of display: 'flat' (default),
% 'wedge', 'projected', 'gridded' or 'grid_average' (the two last ones
% require the data to have been gridded.) 
%
% * |movieFile|: string indicating filename for movie creation (no
% extension). By default an empty string to mean no movie is to be made.
%
% * |otherData|: array of numbers to be displayed instead of the original
% or processed data. Used in case of tests for new types of corrections.
%
% * |pings|: vector of numbers indicating which pings to be displayed. If
% more than one, the result will be an animation.
%
% * |bottomDetectDisplay|: string indicating whether to display the bottom
% detect in the data or not: 'no' (default) or 'yes'.  
%
% * |waterColumnTargets|: array of points to be displayed ontop of
% watercolumn data. Must be a table with columns Easting, Northing, Height,
% ping, beam, range. 
%
% *OUTPUT VARIABLES*
%
% * |h|: figure handle
%
% * |F|: movie frames
%
% *DEVELOPMENT NOTES*
%
% * Not tested after update: water column targets. XXX
% * bottom is not gridded in new coffee and thus display of gridded bottom
% can't work here anymore. to be fixed  XXX
% * display contents of the input parser?
%
% *NEW FEATURES*
%
% * 2018-11-01: updated to work with new Coffee v3
% * 2016-12-01: now grabbing 'X_BP_bottomSample' field for bottom in flat
% display instead of original field, after changes on how bottom is
% processed. Also, adding bottom detect display option to gridded data.
% * 2015-09-29: updating description after changing varargin management to
% inputparser
% * 2014-04-25: first version
%
% *EXAMPLE*
%
% % The following are ALL equivalent: display original data, all pings, flat, no bottom detect, no movie
% CFF_watercolumn_display(fData); 
% CFF_watercolumn_display(fData,'original');
% CFF_watercolumn_display(fData,'data','original'); 
% CFF_watercolumn_display(fData,'pings',[]);
% CFF_watercolumn_display(fData,'data','original','pings',[]);
% CFF_watercolumn_display(fData,'data','original','pings',[],'displayType','flat');
%
% % All 3 main display types with bottom detect ON
% CFF_watercolumn_display(fData,'data','processed','displayType','flat','bottomDetectDisplay','yes');
% CFF_watercolumn_display(fData,'data','processed','displayType','wedge','bottomDetectDisplay','yes');
% CFF_watercolumn_display(fData,'data','processed','displayType','projected','bottomDetectDisplay','yes');
%
% % Movie creation in flat mode
% CFF_watercolumn_display(fData,'data','processed','displayType','flat','bottomDetectDisplay','yes','movieFile','testmovie');
%
% % USe of 'otherData'
% otherM = fData.WC_SBP_SampleAmplitudes.Data.val + 50;
% CFF_watercolumn_display(fData,'otherData',otherM);
%
% % Old varargin management should still work.
% [h,F] = CFF_watercolumn_display(fData, 'original','flat','testmovie')
%
% % Finally, testing water column targets
% CFF_watercolumn_display(fData,'data','processed','displayType','flat','bottomDetectDisplay','yes','waterColumnTargets',kelp);
% CFF_watercolumn_display(fData,'data','processed','displayType','wedge','bottomDetectDisplay','yes','waterColumnTargets',kelp);
% CFF_watercolumn_display(fData,'data','processed','displayType','projected','bottomDetectDisplay','yes','waterColumnTargets',kelp);
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, Deakin University, NIWA.

%% Function
function [h,F] = CFF_watercolumn_display(fData, varargin)


%% INPUT PARSER

p = inputParser;

% 'fData', the multibeam data structure (required)
addRequired(p,'fData',@isstruct);

% 'data' is an optional string indicating which data in
% fData to grab: 'original' (default) or 'processed'. Can be overwritten by
% inputting "otherData". 
arg = 'data';
defaultArg = 'original';
checkArg = @(x) any(validatestring(x,{'original','processed'})); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'displayType' is an optional string indicating type of display: 'flat' (default), 'wedge' or 'projected'
arg = 'displayType';
defaultArg = 'flat';
checkArg = @(x) any(validatestring(x,{'flat', 'wedge','projected','gridded','grid_average'})); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'movieFile' is an optional string indicating filename for
% movie creation. By default an empty string to mean no movie is to be
% made.
arg = 'movieFile';
defaultArg = '';
checkArg = @(x) ischar(x); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'otherData' is an optional array of numbers to be displayed instead of
% the original or processed data. Used in case of tests for new types of
% corrections
arg = 'otherData';
defaultArg = [];
checkArg = @(x) isnumeric(x) && all(size(x)==size(fData.WC_SBP_SampleAmplitudes.Data.val)); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'pings' is an optional vector of numbers indicating which pings to be
% displayed. If more than one, the result will be an animation. 
arg = 'pings';
defaultArg = [];
checkArg = @(x) isnumeric(x); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'bottomDetectDisplay' is a string indicating
% wether to display the bottom detect in the data or not: 'no' (default) or 'yes'. 
arg = 'bottomDetectDisplay';
defaultArg = 'no';
checkArg = @(x) any(validatestring(x,{'no', 'yes'})); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'waterColumnTargets' is an optional array of points to be displayed ontop
% of watercolumn data. Must be a table with Easting, Northing, Height,
% ping, beam, range.
arg = 'waterColumnTargets';
defaultArg = [];
checkArg = @(x) isnumeric(x); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% now parse actual inputs
parse(p,fData, varargin{:});

% extracting parser results
fData = p.Results.fData;
data = p.Results.data;
displayType = p.Results.displayType;
movieFile = p.Results.movieFile;
otherData = p.Results.otherData;
pings = p.Results.pings;
bottomDetectDisplay = p.Results.bottomDetectDisplay;
waterColumnTargets = p.Results.waterColumnTargets;

% clear parser
clear p


% display contents of the input parser?
...

%% main data info
[~, name, ext]= fileparts(fData.ALLfilename{1});
fileName = [name ext];
pingCounter = fData.WC_1P_PingCounter;
nPings = size(fData.WC_SBP_SampleAmplitudes.Data.val,3);

%% pings to display
if isempty(pings)
    pings = [1:nPings];
end 

%% grab data
switch data
    case 'original'
        M = CFF_get_WC_data(fData,'WC_SBP_SampleAmplitudes',pings,1,1,'true');
    case 'processed'
        M = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed',pings,1,1,'true');
end
if ~isempty(otherData)
    % overwrite with other data
    M = otherData;
end
switch displayType
    case 'gridded'
        M = fData.X_NEH_gridLevel;
    case 'grid_average'
        M = fData.X_NEH_gridLevel;
end

%% initalize figure
h = gcf;

% set figure to full screen if movie requested
if ~isempty(movieFile)
    set(h,'Position',get(0,'ScreenSize'))
end


%% display data
switch displayType
    
    case 'flat'
        
        if strcmp(bottomDetectDisplay,'yes')
            % bottom detect
            b = fData.X_BP_bottomSample(:,pings);
        end
        
        % data bounds
        maxM = max(max(max(M)));
        minM = min(min(min(M)));
        
        for iP = 1:numel(pings)
            cla
            imagesc(M(:,:,iP));
            colormap jet
            colorbar
            hold on
            if strcmp(bottomDetectDisplay,'yes')
                plot(b(:,iP),'k.');
            end
            if ~isempty(waterColumnTargets)
                ind = find( waterColumnTargets(:,4) == iP);
                if ~isempty(ind)
                    temp = waterColumnTargets(ind,5:6);
                    plot(temp(:,1),temp(:,2),'ko')
                end
            end
            caxis([minM maxM])
            grid on
            title(sprintf('File: %s. Ping %i/%i (#%i)',fileName,pings(iP),nPings,pingCounter(iP)),'FontWeight','normal','Interpreter','none')
            xlabel('beam #')
            ylabel('sample #')
            set(findall(gcf,'-property','FontSize'),'FontSize',8)
            drawnow
            if ~isempty(movieFile)
                F(iP) = getframe(gcf);
            end
        end
        
    case 'wedge'
        
        % inter-sample distance
        soundSpeed           = fData.WC_1P_SoundSpeed(1,pings).*0.1; %m/s
        samplingFrequencyHz  = fData.WC_1P_SamplingFrequencyHz(1,pings); %Hz
        interSamplesDistance = soundSpeed./(samplingFrequencyHz.*2); % in m
        
        % samples
        nSamples = size(fData.WC_SBP_SampleAmplitudes.Data.val,1);
        idxSamples = [1:nSamples]';
        startRangeSampleNumber = fData.WC_BP_StartRangeSampleNumber(:,pings);
        
        % beam pointing angle
        beamPointingAngle = deg2rad(fData.WC_BP_BeamPointingAngle(:,pings)/100);
    
        % Get across and upwards distance
        sampleRange = CFF_get_samples_range(idxSamples,startRangeSampleNumber,interSamplesDistance);
        [sampleAcrossDistance,sampleUpwardsDistance] = CFF_get_samples_dist(sampleRange,beamPointingAngle);
        
        X = sampleAcrossDistance;
        Y = sampleUpwardsDistance;
        
        if strcmp(bottomDetectDisplay,'yes')
            % bottom detect
            bX = fData.X_BP_bottomAcrossDist(:,pings);
            bY = fData.X_BP_bottomUpDist(:,pings);
        end
        
        % data bounds
        ind = ~isnan(M);
        maxX = max(X(ind));
        minX = min(X(ind));
        maxY = max(Y(ind));
        minY = min(Y(ind));
        maxM = max(M(ind));
        minM = min(M(ind));
        
        for iP = 1:numel(pings)
            cla
            pcolor(X(:,:,iP),Y(:,:,iP),M(:,:,iP));
            colormap jet
            colorbar
            shading flat
            hold on
            if strcmp(bottomDetectDisplay,'yes')
                plot(bX(:,iP),bY(:,iP),'k.')
            end
            if ~isempty(waterColumnTargets)
                ind = find( waterColumnTargets(:,4) == iP);
                if ~isempty(ind)
                    temp = waterColumnTargets(ind,5:6);
                    clear up across
                    for jj = 1:size(temp,1)
                        up(jj) = fData.X_SBP_sampleUpDist(iP,temp(jj,1),temp(jj,2));
                        across(jj) = fData.X_SBP_sampleAcrossDist(iP,temp(jj,1),temp(jj,2));
                    end
                    plot(across,up,'ko')
                end
            end
            axis equal
            axis tight
            axis([minX maxX minY maxY])
            caxis([minM maxM])
            grid on
            title(sprintf('File: %s. Ping %i/%i (#%i)',fileName,pings(iP),nPings,pingCounter(iP)),'FontWeight','normal','Interpreter','none')
            xlabel('across distance (starboard) (m)')
            ylabel('height above sonar (m)')
            set(findall(gcf,'-property','FontSize'),'FontSize',8)
            drawnow
            if ~isempty(movieFile)
                F(iP) = getframe(gcf);
            end
        end
        
    case 'projected'

        % sonar location
        sonarEasting  = fData.X_1P_pingE(1,pings); %m
        sonarNorthing = fData.X_1P_pingN(1,pings); %m
        sonarHeight   = fData.X_1P_pingH(1,pings); %m
        
        % sonar heading
        gridConvergence    = fData.X_1P_pingGridConv(1,pings); %deg
        vesselHeading      = fData.X_1P_pingHeading(1,pings); %deg
        sonarHeadingOffset = fData.IP_ASCIIparameters.S1H; %deg
        sonarHeading       = deg2rad(-mod(gridConvergence + vesselHeading + sonarHeadingOffset,360));
        
        % inter-sample distance
        soundSpeed           = fData.WC_1P_SoundSpeed(1,pings).*0.1; %m/s
        samplingFrequencyHz  = fData.WC_1P_SamplingFrequencyHz(1,pings); %Hz
        interSamplesDistance = soundSpeed./(samplingFrequencyHz.*2); % in m
        
        % samples
        nSamples = size(fData.WC_SBP_SampleAmplitudes.Data.val,1);
        idxSamples = [1:nSamples]';
        startRangeSampleNumber = fData.WC_BP_StartRangeSampleNumber(:,pings);
        
        % beam pointing angle
        beamPointingAngle = deg2rad(fData.WC_BP_BeamPointingAngle(:,pings)/100);
    
        % Get across and upwards distance
        [Easting, Northing, Height] = CFF_georeference_sample(idxSamples, startRangeSampleNumber, interSamplesDistance, beamPointingAngle, sonarEasting, sonarNorthing, sonarHeight, sonarHeading);
        
        if strcmp(bottomDetectDisplay,'yes')
            % bottom detect
            bEasting = fData.X_BP_bottomEasting(:,pings);
            bNorthing = fData.X_BP_bottomNorthing(:,pings);
            bHeight = fData.X_BP_bottomHeight(:,pings);
        end
        
        % data bounds
        maxEasting = max(max(max(Easting)));
        minEasting = min(min(min(Easting)));
        maxNorthing = max(max(max(Northing)));
        minNorthing = min(min(min(Northing)));
        maxHeight = max(max(max(Height)));
        minHeight = min(min(min(Height)));
        maxM = max(max(max(M)));
        minM = min(min(min(M)));
        
        for iP = 1:numel(pings)
            cla
            x = reshape(Easting(:,:,iP),1,[]);
            y = reshape(Northing(:,:,iP),1,[]);
            z = reshape(Height(:,:,iP),1,[]);
            c = reshape(M(:,:,iP),1,[]);
            scatter3(x,y,z,2,c,'.')
            colormap jet
            colorbar
            hold on
            if strcmp(bottomDetectDisplay,'yes')
                plot3(bEasting(:,iP),bNorthing(:,iP),bHeight(:,iP),'k.')
            end
            if ~isempty(waterColumnTargets)
                plot3(waterColumnTargets(:,1),waterColumnTargets(:,2),waterColumnTargets(:,3),'ko')
            end
            axis equal
            axis([minEasting maxEasting minNorthing maxNorthing minHeight maxHeight])
            caxis([minM maxM])
            grid on
            title(sprintf('File: %s. Ping %i/%i (#%i)',fileName,pings(iP),nPings,pingCounter(iP)),'FontWeight','normal','Interpreter','none')
            xlabel('Easting (m)')
            ylabel('Northing (m)')
            zlabel('Height above datum (m)')
            set(findall(gcf,'-property','FontSize'),'FontSize',8)
            CFF_nice_easting_northing
            drawnow
            if ~isempty(movieFile)
                F(iP) = getframe(gcf);
            end
        end
        
    case 'gridded'
        
        % grab data
        Easting = fData.X_1E_gridEasting;
        Northing = fData.X_N1_gridNorthing;
        Height = fData.X_11H_gridHeight;
        
        if strcmp(bottomDetectDisplay,'yes')
            % bottom detect
            bottom = fData.X_NE_gridBottom;
        end
        
        % data bounds
        nE = length(Easting);
        nN = length(Northing);
        maxM = nanmax(M(:));
        minM = nanmin(M(:));
        
        for kk = 1:length(Height)
            cla
            im = imagesc(Easting,Northing,M(:,:,kk));
            set(im,'alphadata',~isnan(M(:,:,kk)));
            
            if strcmp(bottomDetectDisplay,'yes')
                % bottom display part
                if kk<length(Height)
                    ind = find( bottom>Height(kk) & bottom<Height(kk+1) );
                    if ~isempty(ind)
                        [iN,iE] = ind2sub([nN,nE],ind);
                        hold on
                        plot(Easting(iE),Northing(iN),'k*');
                    end
                end
            end
            
            axis equal
            grid on;
            set(gca,'Ydir','normal')
            caxis([minM maxM])
            colormap jet
            colorbar
            CFF_nice_easting_northing
            title(sprintf('File: %s (gridded). Slice %i/%i - Height above datum: %.2f m',fileName,kk,length(Height),Height(kk)),'FontWeight','normal','Interpreter','none')
            xlabel('Easting (m)')
            ylabel('Northing (m)')
            set(findall(gcf,'-property','FontSize'),'FontSize',8)
            drawnow
            if ~isempty(movieFile)
                F(kk) = getframe(gcf);
            end
        end
        
    case 'grid_average'
        
        % grab data
        Easting = fData.X_1E_gridEasting;
        Northing = fData.X_N1_gridNorthing;
        Height = fData.X_11H_gridHeight;
        
        % find desired height above bottom
        bottomHeight = median(fData.X_BP_bottomHeight(:));
        heighAboveBottom = 1.5;
        [~,ind] = min(abs(Height-bottomHeight-heighAboveBottom));
        avgL = M(:,:,ind);
        
        % average the level:
        % avgL = nanmean(M,3);
        
        % data bounds
        nE = length(Easting);
        nN = length(Northing);
        maxM = nanmax(avgL(:));
        minM = nanmin(avgL(:));
        
        cla
        im = imagesc(Easting,Northing,avgL);
        set(im,'alphadata',~isnan(avgL));
     
        axis equal
        grid on;
        set(gca,'Ydir','normal')
        caxis([minM maxM])
        colormap jet
        colorbar
        CFF_nice_easting_northing
        title(sprintf('File: %s (gridded, vertical average).',fileName),'FontWeight','normal','Interpreter','none')
        xlabel('Easting (m)')
        ylabel('Northing (m)')
        set(findall(gcf,'-property','FontSize'),'FontSize',8)
        drawnow

end

% write movie
if ~isempty(movieFile)
    writerObj = VideoWriter(movieFile,'MPEG-4');
    set(writerObj,'Quality',100)
    open(writerObj)
    writeVideo(writerObj,F);
    close(writerObj);
end

