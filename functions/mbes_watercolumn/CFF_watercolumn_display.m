function [h,F] = CFF_watercolumn_display(fData, varargin)
% [h,F] = CFF_watercolumn_display(fData, varargin)
%
% DESCRIPTION
%
% Displays Multibeam watercolumn data in various ways.
%
% REQUIRED INPUT ARGUMENTS
%
% - 'fData': the multibeam data structure
%
% OPTIONAL INPUT ARGUMENTS
%
% - 'data': string indicating which data in fData to grab: 'original'
% (default) or 'L1'. Can be overwritten by inputting "otherData". 
%
% - 'displayType': string indicating type of display: 'flat' (default),
% 'wedge', 'projected' or 'gridded' (this last one need the data to have
% been gridded.) 
%
% - 'movieFile': string indicating filename for movie creation. By default
% an empty string to mean no movie is to be made.
%
% - 'otherData': array of numbers to be displayed instead of the original
% or L1 data. Used in case of tests for new types of corrections.
%
% - 'pings': vector of numbers indicating which pings to be displayed. If
% more than one, the result will be an animation.
%
% - 'bottomDetectDisplay': string indicating whether to display the bottom
% detect in the data or not: 'no' (default) or 'yes'.  
%
% - 'waterColumnTargets': array of points to be displayed ontop of
% watercolumn data. Must be a table with columns Easting, Northing, Height,
% ping, beam, range. 
%
% OUTPUT VARIABLES
%
% - 'h': figure handle
%
% - 'F': movie frames
%
% RESEARCH NOTES
%
% - display contents of the input parser?
%
% NEW FEATURES
%
% - 2016-12-01: now grabbing 'X_PB_bottomSample' field for bottom in flat
% display instead of original field, after changes on how bottom is
% processed. Also, adding bottom detect display option to gridded data.
% - 2015-09-29: updating description after changing varargin management to
% inputparser
% - 2014-04-25: first version
%
% EXAMPLES
%
% % The following are ALL equivalent: display original data, all pings, flat, no bottom detect, no movie
% CFF_watercolumn_display(fData); 
% CFF_watercolumn_display(fData,'original');
% CFF_watercolumn_display(fData,'data','original'); 
% CFF_watercolumn_display(fData,'pings',NaN);
% CFF_watercolumn_display(fData,'data','original','pings',NaN);
% CFF_watercolumn_display(fData,'data','original','pings',NaN,'displayType','flat');
%
% % All 3 display types with bottom detect ON
% CFF_watercolumn_display(fData,'data','L1','displayType','flat','bottomDetectDisplay','yes');
% CFF_watercolumn_display(fData,'data','L1','displayType','wedge','bottomDetectDisplay','yes');
% CFF_watercolumn_display(fData,'data','L1','displayType','projected','bottomDetectDisplay','yes');
%
% % Movie creation in flat mode
% CFF_watercolumn_display(fData,'data','L1','displayType','flat','bottomDetectDisplay','yes','movieFile','testmovie');
%
% % USe of 'otherData'
% otherM = fData.WC_PBS_SampleAmplitudes + 50;
% CFF_watercolumn_display(fData,'otherData',otherM);
%
% % Old varargin management should still work.
% [h,F] = CFF_watercolumn_display(fData, 'original','flat','testmovie')
%
% % Finally, testing water column targets
% CFF_watercolumn_display(fData,'data','L1','displayType','flat','bottomDetectDisplay','yes','waterColumnTargets',kelp);
% CFF_watercolumn_display(fData,'data','L1','displayType','wedge','bottomDetectDisplay','yes','waterColumnTargets',kelp);
% CFF_watercolumn_display(fData,'data','L1','displayType','projected','bottomDetectDisplay','yes','waterColumnTargets',kelp);
%
%%%
% Alex Schimel, Deakin University
%%%


%% INPUT PARSER

p = inputParser;

% 'fData', the multibeam data structure (required)
addRequired(p,'fData',@isstruct);

% 'data' is an optional string indicating which data in
% fData to grab: 'original' (default) or 'L1'. Can be overwritten by
% inputting "otherData". 
arg = 'data';
defaultArg = 'original';
checkArg = @(x) any(validatestring(x,{'original','masked original','L1','masked L1','test'})); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'displayType' is an optional string indicating type of display: 'flat' (default), 'wedge' or 'projected'
arg = 'displayType';
defaultArg = 'flat';
checkArg = @(x) any(validatestring(x,{'flat', 'wedge','projected','gridded'})); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'movieFile' is an optional string indicating filename for
% movie creation. By default an empty string to mean no movie is to be
% made.
arg = 'movieFile';
defaultArg = '';
checkArg = @(x) ischar(x); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'otherData' is an optional array of numbers to be displayed instead of
% the original or L1 data. Used in case of tests for new types of
% corrections
arg = 'otherData';
defaultArg = [];
checkArg = @(x) isnumeric(x) && all(size(x)==size(fData.WC_PBS_SampleAmplitudes)); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'pings' is an optional vector of numbers indicating which pings to be
% displayed. If more than one, the result will be an animation. 
arg = 'pings';
defaultArg = NaN;
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

% display contents of the input parser?
...

%% initalize figure
h = gcf;

% set figure to full screen if movie requested
if ~isempty(p.Results.movieFile)
    set(h,'Position',get(0,'ScreenSize'))
end


%% grab data
switch p.Results.data
    case 'original'
        M = fData.WC_PBS_SampleAmplitudes./2;% original level divided by 2 (see kongsberg datagrams document)
    case 'masked original'
        M = fData.X_PBS_Mask .* fData.WC_PBS_SampleAmplitudes./2;% original level divided by 2 (see kongsberg datagrams document)
    case 'L1'
        M = fData.X_PBS_L1;
    case 'masked L1'
        M = fData.X_PBS_Mask .* fData.X_PBS_L1;
    case 'test'
        M= fData.X_PBS_TESTAMPFILT;
end
if ~isempty(p.Results.otherData)
    % overwrite with other data
    M = p.Results.otherData;
end
if strcmp(p.Results.displayType,'gridded')
    % overwrite with gridded data if displayType is "gridded"
    M = fData.X_NEH_gridLevel;
end


%% main data info
[pathstr, name, ext]= fileparts(fData.MET_MATfilename{1});
fileName = [name ext];
pingCounter = fData.WC_P1_PingCounter;
nPings = size(fData.WC_PBS_SampleAmplitudes,1);

%% pings to display
if isnan(p.Results.pings)
    dispPings = 1:nPings;
else
    dispPings = p.Results.pings;
end 

%% display data
switch p.Results.displayType
    
    case 'flat'
        
        if strcmp(p.Results.bottomDetectDisplay,'yes')
            % bottom detect
            b = fData.X_PB_bottomSample;
        end
        
        % data bounds
        maxM = max(max(max(M)));
        minM = min(min(min(M)));
        
        for ii = dispPings
            cla
            imagesc(squeeze(M(ii,:,:))')
            colorbar
            hold on
            if strcmp(p.Results.bottomDetectDisplay,'yes')
                plot(b(ii,:),'k.')
            end
            if ~isempty(p.Results.waterColumnTargets)
                ind = find( p.Results.waterColumnTargets(:,4) == ii);
                if ~isempty(ind)
                    temp = p.Results.waterColumnTargets(ind,5:6);
                    plot(temp(:,1),temp(:,2),'ko')
                end
            end
            caxis([minM maxM])
            grid on
            title(sprintf('File: %s. Ping %i/%i (#%i)',fileName,ii,nPings,pingCounter(ii)),'FontWeight','normal','Interpreter','none')
            xlabel('beam #')
            ylabel('sample #')
            drawnow
            if ~isempty(p.Results.movieFile)
                F(ii) = getframe(gcf);
            end
        end
        
    case 'wedge'
        
        % grab data
        X = fData.X_PBS_sampleAcrossDist;
        Y = fData.X_PBS_sampleUpDist;
        
        if strcmp(p.Results.bottomDetectDisplay,'yes')
            % bottom detect
            bX = fData.X_PB_bottomAcrossDist;
            bY = fData.X_PB_bottomUpDist;
        end
        
        % data bounds
        ind = ~isnan(M);
        maxX = max(X(ind));
        minX = min(X(ind));
        maxY = max(Y(ind));
        minY = min(Y(ind));
        maxM = max(M(ind));
        minM = min(M(ind));
        
        for ii = dispPings
            cla
            pcolor(squeeze(X(ii,:,:)),squeeze(Y(ii,:,:)),squeeze(M(ii,:,:)));
            colorbar
            shading interp
            hold on
            if strcmp(p.Results.bottomDetectDisplay,'yes')
                plot(bX(ii,:),bY(ii,:),'k.')
            end
            if ~isempty(p.Results.waterColumnTargets)
                ind = find( p.Results.waterColumnTargets(:,4) == ii);
                if ~isempty(ind)
                    temp = p.Results.waterColumnTargets(ind,5:6);
                    clear up across
                    for jj = 1:size(temp,1)
                        up(jj) = fData.X_PBS_sampleUpDist(ii,temp(jj,1),temp(jj,2));
                        across(jj) = fData.X_PBS_sampleAcrossDist(ii,temp(jj,1),temp(jj,2));
                    end
                    plot(across,up,'ko')
                end
            end
            axis equal
            axis tight
            axis([minX maxX minY maxY])
            caxis([minM maxM])
            grid on
            title(sprintf('File: %s. Ping %i/%i (#%i)',fileName,ii,nPings,pingCounter(ii)),'FontWeight','normal','Interpreter','none')
            xlabel('across distance (starboard) (m)')
            ylabel('height above sonar (m)')
            drawnow
            if ~isempty(p.Results.movieFile)
                F(ii) = getframe(gcf);
            end
        end
        
    case 'projected'
        
        % grab data
        Easting = fData.X_PBS_sampleEasting;
        Northing = fData.X_PBS_sampleNorthing;
        Height = fData.X_PBS_sampleHeight;
        
        if strcmp(p.Results.bottomDetectDisplay,'yes')
            % bottom detect
            bEasting = fData.X_PB_bottomEasting;
            bNorthing = fData.X_PB_bottomNorthing;
            bHeight = fData.X_PB_bottomHeight;
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
        
        for ii = dispPings
            cla
            x = reshape(Easting(ii,:,:),1,[]);
            y = reshape(Northing(ii,:,:),1,[]);
            z = reshape(Height(ii,:,:),1,[]);
            c = reshape(M(ii,:,:),1,[]);
            scatter3(x,y,z,2,c,'.')
            colorbar
            hold on
            if strcmp(p.Results.bottomDetectDisplay,'yes')
                plot3(bEasting(ii,:),bNorthing(ii,:),bHeight(ii,:),'k.')
            end
            if ~isempty(p.Results.waterColumnTargets)
                plot3(p.Results.waterColumnTargets(:,1),p.Results.waterColumnTargets(:,2),p.Results.waterColumnTargets(:,3),'ko')
            end
            axis equal
            axis([minEasting maxEasting minNorthing maxNorthing minHeight maxHeight])
            caxis([minM maxM])
            grid on
            title(sprintf('File: %s. Ping %i/%i (#%i)',fileName,ii,nPings,pingCounter(ii)),'FontWeight','normal','Interpreter','none')
            xlabel('Easting (m)')
            ylabel('Northing (m)')
            zlabel('Height above datum (m)')
            CFF_nice_easting_northing
            drawnow
            if ~isempty(p.Results.movieFile)
                F(ii) = getframe(gcf);
            end
        end
        
    case 'gridded'
        
        % grab data
        Easting = fData.X_1E_gridEasting;
        Northing = fData.X_N1_gridNorthing;
        Height = fData.X_H_gridHeight;
        
        if strcmp(p.Results.bottomDetectDisplay,'yes')
            % bottom detect
            bottom = fData.X_NE_gridBottom;
        end
        
        % data bounds
        nE = length(Easting);
        nN = length(Northing);
        maxEasting = max(Easting(:));
        minEasting = min(Easting(:));
        maxNorthing = max(Northing(:));
        minNorthing = min(Northing(:));
        maxHeight = max(Height(:));
        minHeight = min(Height(:));
        maxM = nanmax(M(:));
        minM = nanmin(M(:));
        
        for kk=1:length(Height)
            cla
            h1 = imagesc(Easting,Northing,M(:,:,kk));
            set(h1,'alphadata',~isnan(M(:,:,kk)));
            
            if strcmp(p.Results.bottomDetectDisplay,'yes')
                % bottom display part
                if kk<length(Height)
                    ind = find( bottom>Height(kk) & bottom<Height(kk+1) );
                    if ~isempty(ind)
                        [iN,iE] = ind2sub([nN,nE],ind);f
                        hold on
                        plot(Easting(iE),Northing(iN),'k*');
                    end
                end
            end
            
            axis equal
            grid on;
            set(gca,'Ydir','normal')
            caxis([minM maxM])
            colorbar
            CFF_nice_easting_northing
            title(sprintf('File: %s. Slice %i/%i - Height above datum: %.2f m',fileName,kk,length(Height),Height(kk)),'FontWeight','normal','Interpreter','none')
            xlabel('Easting (m)')
            ylabel('Northing (m)')
            drawnow
            if ~isempty(p.Results.movieFile)
                F(kk) = getframe(gcf);
            end
        end
        
end

% write movie
if ~isempty(p.Results.movieFile)
    writerObj = VideoWriter(p.Results.movieFile,'MPEG-4');
    set(writerObj,'Quality',100)
    open(writerObj)
    writeVideo(writerObj,F);
    close(writerObj);
end


% OLD CODE
%
% figure; plot(SeedsAcrossDist,SeedsDownDist,'.')
% axis equal
% hold on
% for jj = 1:size(M,1)
%     pause(0.1)
%     plot([SeedsAcrossDist(M(jj,1)),SeedsAcrossDist(M(jj,2))],[SeedsDownDist(M(jj,1)),SeedsDownDist(M(jj,2))], 'ro-')
%     drawnow
% end
%
% %figure
% clf
% surf(DownDist,AcrossDist,DATACorr);
% hold on
% shading interp;
% view(90,-90);
% axis equal;
% set(gca,'layer','top')
% axis([-10 0 -20 20])
% set(gca,'Color',[0.8 0.8 0.8],'XLimMode','manual','YLimMode','manual')
% set(gca,'ZDir','reverse')
% hold on
% plot(BottomY(BottomY~=0),BottomX(BottomY~=0),'k.-')
%
% for jj = 1:size(M,1)
%     plot([SeedsDownDist(M(jj,1)),SeedsDownDist(M(jj,2))],[SeedsAcrossDist(M(jj,1)),SeedsAcrossDist(M(jj,2))],'k.-')
% end
%
