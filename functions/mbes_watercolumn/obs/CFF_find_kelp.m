function kelp = CFF_find_kelp(fData,method)

% create algorithms to find kelp in the watercolumn here

% method:
%   0: per ping basis
%   1: per horizontal slice

display_flag = 0;

% basic info on dataset
nPings = size(fData.WC_PBS_SampleAmplitudes,1);
nBeams = size(fData.WC_PBS_SampleAmplitudes,2);
nSamples = size(fData.WC_PBS_SampleAmplitudes,3);

switch method
    
    case 0    
        % METHOD #0: detect kelp on a ping basis... in development. left for now because not using the full 3D water column data...
    
        for ii = 1:nPings
            
            % get data
            D = reshape(fData.X_PBS_L1(ii,:,:),nBeams,nSamples);
            sampleUpDist     = reshape(fData.X_PBS_sampleUpDist(ii,:,:),nBeams,nSamples);
            sampleAcrossDist = reshape(fData.X_PBS_sampleAcrossDist(ii,:,:),nBeams,nSamples);
            
            % turn data from dB to natural
            D = exp(D./20);
            
            % test matrices:
            % D=[1 2 3 4 5; 6 7 8 9 10; 11 12 13 14 15; 16 17 18 19 20; 21 22 23 24 25];
            % D = rand(5);
            
            % finding local 2D maxima (data points with more amplitude than
            % their direct 8 neighbors)
            % XXX: change this to use extrema2
            
            D1 = D(1:end-2,1:end-2);
            D2 = D(1:end-2,2:end-1);
            D3 = D(1:end-2,3:end);
            
            D4 = D(2:end-1,1:end-2);
            M  = D(2:end-1,2:end-1);
            D5 = D(2:end-1,3:end);
            
            D6 = D(3:end,1:end-2);
            D7 = D(3:end,2:end-1);
            D8 = D(3:end,3:end);
            
            N1 = M>D1 & M>D2 & M>D3 & M>D4 & M>D5 & M>D6 & M>D7 & M>D8;
            N = zeros(size(D));
            N(2:end-1,2:end-1) = N1;
            
            Seeds = logical(N);
            SeedsAmplitude = D(Seeds);
            SeedsDownDist = sampleUpDist(Seeds);
            SeedsAcrossDist = sampleAcrossDist(Seeds);
            
            % next step:
            % Compute combined amplitude and distances between each pair of seeds
            [X,Y]=meshgrid(SeedsAmplitude',SeedsAmplitude);
            CombAmplitude=X+Y;
            [X,Y]=meshgrid(SeedsDownDist',SeedsDownDist);
            CombDownDist=X-Y;
            [X,Y]=meshgrid(SeedsAcrossDist',SeedsAcrossDist);
            CombAcrossDist=X-Y;
            
            % combined amplitude, vertical and horizontal distances are
            % going to be used as criteria. Map these values to a 0 (bad)
            % to 1 (good) coefficient range. We need three parameters for
            % each mapping:
            % - the min value that is associated with 0
            % - the max value that is associated with 1
            % - the function that is mapped onto [0-1]
            
            m = min(CombAmplitude(:));
            M = max(D(:));
            NormCombAmplitude = (CombAmplitude-m)./(M-m);
            
            m = 1; % any vertical distance >= 3m is associated a coeff of 0
            M = 0;
            NormCombDownDist = (abs(CombDownDist)-m)./(M-m);
            NormCombDownDist = min(1,max(0,NormCombDownDist));
            
            m = 0.1; % any horizontal distance >= 0.5m is associated a coeff of 0
            M = 0;
            NormCombAcrossDist = (abs(CombAcrossDist)-m)./(M-m);
            NormCombAcrossDist = min(1,max(0,NormCombAcrossDist));
            
            % combine all criteria:
            Crit = NormCombAmplitude .* NormCombDownDist .* NormCombAcrossDist;
            
            % remove diagonal and the lower half
            Crit = triu(Crit,1);
            [i,j,s] = find(Crit);
            M = [i,j,s];
            M = sortrows(M,-3);
            
            % threshold on full criteria
            thres = 0.2;
            M = M(M(:,3)>thres,:);
            
            % M now holds the indices of the point that have high coeff
            % (ie: high combined amplitude, low distances)
            
            % display
            if display_flag
                cla
                pcolor(sampleAcrossDist,sampleUpDist,20.*log10(D));
                colorbar
                shading interp
                hold on
                grid on
                axis equal
                
                hold on
                for jj = 1:size(M,1)
                    plot(SeedsAcrossDist(M(jj,1:2)),SeedsDownDist(M(jj,1:2)),'k.-')
                end
                drawnow
            end
            
            % but the idea would really be to "grow" those links
            % recursively. Giving more weight to points which grow
            % linearly... Let's give up this method for now and concentrate
            % on the other one
            
        end
        
    
    case 1
        % METHOD #1: detect kelp on a per-slice basis.
        
        % STEP #0: SET PARAMETERS

        %         % all samples too close to sonar head, at outer beams, or under the
        %         % bottom were removed during filtering. Now complete by removing
        %         % samples outside the forest plant?
        %         % - outside a 3m radius arond the horizontal center of the plot?
        %
        %         % get data
        %         PBS_L1 = fData.X_PBS_L1;
        %         PBS_sampleEasting = fData.X_PBS_sampleEasting;
        %         PBS_sampleNorthing = fData.X_PBS_sampleNorthing;
        %
        %         % plot center:
        %         kelpE=629556;
        %         kelpN=5748652;
        %         kelpRadius=5;
        %
        %         % build mask: 1: to conserve, 0: to remove
        %         PBS_distFromKelp = sqrt((PBS_sampleEasting-kelpE).^2 + (PBS_sampleNorthing-kelpN).^2);
        %         PBS_Mask = double(PBS_distFromKelp<=kelpRadius);
        %         PBS_Mask(PBS_Mask==0) = NaN;
        %
        %         % apply mask
        %         fData.X_PBS_L2 = fData.X_PBS_L1.* PBS_Mask;
        
        % for now, stay with L1, ie all data
        
        
        
        % STEP #1: GRID WATER COLUMN DATA
        % .. now done outside of this function. Just get them back here:
        gridEasting = fData.X_1E_gridEasting;
        gridNorthing = fData.X_N1_gridNorthing;
        gridHeight = fData.X_H_gridHeight;
        gridLevel = fData.X_NEH_gridLevel;

        
        
        % STEP #2: DETECT LOCAL MAXIMA ABOVE THRESHOLD ("men", after backgammon)

        % define the threshold for detection
        
        
        % initialize detect points. 4 columns table:
        % 1. Index in gridNorthing
        % 2. Index in gridEasting
        % 3. Index in gridHeight
        % 4. Level
        numCells = sum(~isnan(gridLevel(:)));
        men = nan( floor(numCells./4) , 4);
        
        % PARAM
        % TO CHANGE: define the threshol from the full data stats.
        % V = -45; % BS level threshold for a local maxima to be considered a man
        V = CFF_invpercentile(gridLevel,99.9); % 99th percentile in the data? fix the percentile as parameter?
        V = -inf; % no threshold, limit to 1000 men instead.
        
        
        % now find men
        mm = 0; % men counter
        for kk = 1:length(gridHeight)-1 % repeat for each slice
            
            % save slice temporarily
            xy = gridLevel(:,:,kk);
            
            % find grid cells that have a higher amplitude than neighboring 8 cells
            [xymax,smax] = extrema2(xy);
            
            % retain only those above threshold
            if ~isempty(smax)
                
                ind = find(xymax>V);
                xymax = xymax(ind);
                smax = smax(ind);
                [iN,iE] = ind2sub(size(xy),smax);
                
                % new men
                newmen = [ iN , iE , ones(length(iE),1).*kk , xymax ];
                
                % add to full list
                men(mm+1:mm+length(xymax),:) = newmen;
                mm = mm+length(xymax);
                
            end
            
        end
        
        % remove extra nan rows
        men(isnan(men(:,1)),:) = [];
        
        % NEW PIECE OF CODE TO TRY: keep only 1000 strongest targets
        tmp = sort(men(:,4),'descend');
        men(men(:,4)<tmp(1001),:) = [];
        
        if display_flag
            
            % display gridded data and men
            clear F;
            HH = figure;
            caxismin = min(gridLevel(:));
            caxismax = max(gridLevel(:));
            for kk=1:length(gridHeight)-1
                cla;
                xy = gridLevel(:,:,kk);
                h = imagesc(xy);
                %set(h,'alphadata',~isnan(xy))
                set(gca,'Ydir','normal');
                % find men to plot
                ind =(men(:,3)==kk);
                hold on;
                plot(men(ind,2),men(ind,1),'ko')
                colorbar;
                title(sprintf('slice %i/%i: %.2f m',kk,length(gridHeight)-1,gridHeight(kk)))
                caxis([caxismin caxismax]);
                grid on;
                axis square;
                axis equal;
                axis tight;
                drawnow;
                F(kk)=getframe(HH);
            end
            
            
            % OTHER QUICK DISPLAY
            for kk = 30:120
                imagesc(exp(gridLevel(:,:,kk)./20))
                ind =(men(:,3)==kk);
                hold on;
                plot(men(ind,2),men(ind,1),'ko')
                axis([157.0505  260.5491  170.7073  236.4164])
                caxis([0 0.7])
                colorbar
                drawnow
                pause(0.2)
            end
            
        end
        
        % creating companies. Method 3
        % Instead of operating per floor, which has the issue of starting linking
        % men with very limited chances of being actual targets, we run by
        % decreasing BS value, making sure we prioritize the most likely targets.
        %%
        
        men(:,5) = NaN;
        
        % distances to be part of a company:
        dht = 1.5; % hortizontal distance
        dvt = 4; % vertical distance
        det = 4.1; % euclidian distance
        
        % sort men by  decreasing BS:
        men = sortrows(men,-4);
        
        % put first man in its own company:
        men(1,5) = 1;
        
        % now for each man after that
        for kk = 2:size(men,1)
            
            ncomp = max(men(:,5)); % number of existing companies
            
            % 1. check if there is any company I can fit this man in:
            
            % for each company,
            clear compdst comptest
            for cc = 1:ncomp
                
                % get all men in this company
                comp = men(men(:,5)==cc,:);
                
                % calculate distances between candidate man and all company:
                dst = repmat(men(kk,1:3),size(comp,1),1) - comp(:,1:3); % distance in northing, easting, depth
                dst(:,4) = abs(dst(:,3)); % vertical
                dst(:,5) = sqrt( dst(:,1).^2 + dst(:,2).^2 ); % hortizontal
                dst(:,6) = sqrt( dst(:,1).^2 + dst(:,2).^2 + dst(:,3).^2); %euclidian
                
                % compare to threshold
                dst(:,7) = double(dst(:,4)<=dvt) .* double(dst(:,5)<=dht) .* double(dst(:,6)<=det); %1 if under threshold, zero otherwise
                
                % save
                compdst{cc} = dst;
                
                % for test
                ind = dst(:,7) > 0;
                if any(ind)
                    comptest(cc) = min(dst(ind,6));
                else
                    comptest(cc) = NaN;
                end
                
            end
            
            % if none is under thresholds, establish it as its own company
            % and reloop
            if all(isnan(comptest));
                men(kk,5) = ncomp+1;
            elseif sum(~isnan(comptest))==1
                % if only one, add it to that company
                [a,ind] = min(comptest);
                men(kk,5) = ind;
            elseif sum(~isnan(comptest))>1
                % if several, merge all these companies
                ind = find(~isnan(comptest));
                men(kk,5) = ind(1); % for new member
                men(find(ismember(men(:,5),ind(2:end))),5) = ind(1); % for all members of all companies other than the first
            end
            
            %comp
            
        end
        
        % finalise:
        
        % sort according to company #
        men = sortrows(men,[5,3]);
        
        % next, remove all companies that don't have at least N men
        N = 15;     % minimum length of company to be considered kelp
        
        [c,ia] = unique(men(:,5)); % get unique company numbers and the index of each first man in a company
        ind = diff(ia)>=N; % because everything is ordered by company, find where first man is separate from next one by more than 5.
        Lia = ismember(men(:,5),c(ind));
        men_N = men(Lia,:);
        
        if display_flag
            
            % display the men only
            HHH = figure;
            M = sortrows(men_N,[5,3]);
            % sum levels per company:
            C = unique(M(:,5));
            sumlevel=nan(size(C));
            for bb = 1:length(C)
                sumlevel(bb) = sum( M(M(:,5)==C(bb),4));
            end
            C = [C,sumlevel];
            C = sortrows(C,-2);
            cols = ['ymcrgbk'];
            for bb = 1:size(C,1)
                ind = find(M(:,5)==C(bb));
                plot3(M(ind,1),M(ind,2),M(ind,3),'.-','Color',cols(mod(bb,7)+1))
                hold on
                axis tight
                axis equal
                grid on
            end
            
%             % rotating view for 3D display
%             for ii=1:360
%                 view(ii,45)
%                 pause(0.1)
%                 drawnow
%             end
%             ylabel('Northing (cm)')
%             zlabel('Height (cm)')
%             xlabel('Easting (cm)')
%             
            
            % display gridded data and men
            clear F
            HH = figure
            figure
            caxismin = min(gridLevel(:));
            caxismax = max(gridLevel(:));
            for kk=1:length(gridHeight)-1
                cla
                xy = gridLevel(:,:,kk);
                h = imagesc(xy);
                %set(h,'alphadata',~isnan(xy))
                set(gca,'Ydir','normal')
                % find men to plot
                ind =(men_N(:,3)==kk);
                hold on
                plot(men_N(ind,2),men_N(ind,1),'ko')
                colorbar
                title(sprintf('slice %i/%i: %.2f m',kk,length(gridHeight)-1,gridHeight(kk)))
                caxis([caxismin caxismax])
                grid on
                axis square
                axis equal
                axis tight
                drawnow
                F(kk)=getframe(HH);
            end
            
        end
        
        
        % save
        kelp = [gridEasting(1,men_N(:,2))', gridNorthing(men_N(:,1),1), gridHeight(men_N(:,3))'];
        
        % find the closest ping/beam/sample to assoicate each kelp point to
        kelp(:,4:6) = NaN; %CFF_XYZtoPBS(fData,kelp(:,1:3));
        
        kelp = [kelp, men_N(:,4:5)];
        
        if display_flag
            % display
            CFF_watercolumn_display(fData,'data','L1','displayType','flat','bottomDetectDisplay','yes') %,'waterColumnTargets',kelp);%
            CFF_watercolumn_display(fData,'data','L1','displayType','wedge','bottomDetectDisplay','yes')%,'waterColumnTargets',kelp);
        end
        
end



%% ABANDONNDED DEVELOPMENTS:

% %% LINKING MEN METHOD ABANDONED EARLY
% % calculate vertical, horizontal and euclidian distance between ALL men:
% mE = repmat(men(:,1),[1,size(men,1)]);
% mN = repmat(men(:,2),[1,size(men,1)]);
% mH = repmat(men(:,3),[1,size(men,1)]);
% dE = tril(abs(mE-mE'));
% dN = tril(abs(mN-mN'));
% dverti = tril(abs(mH-mH'));
% dhoriz = sqrt( dE.^2 + dN.^2 );
% deucli = sqrt( dE.^2 + dN.^2 + dverti.^2);
%
% % calculate combined BS level
% mL = repmat(men(:,4),[1,size(men,1)]);
% cL = tril( 20.*log10( 10.^(mL./20) + 10.^(mL'./20) ), -1);
%
% % here are all the possible couples that can be made based on set distance
% % thresholds
% [row,col] = find(dhoriz>0 & dhoriz<2 & dverti>0 & dverti<4);
%
% % test
% i=1; men([row(i),col(i)],:)
%
% % next step, rank them by combined BS couple
% % take the top couple, make a company of them, update their total BS as the combined value, reloop


% % creating companies. Method 0:
% % for each man, starting from the lowest
% % floors and the highest BS, find if there is another man at the
% % floor just above within a set distance. If there is, that other
% % man is added to the company of that first man.
%
% % Add a column for "company", ie links of men across severall floor levels.
% % Each man its own company to start with.
% % 1. Index in gridNorthing
% % 2. Index in gridEasting
% % 3. Index in gridHeight
% % 4. Level
% % 5. company
% men(:,5) = [1:size(men,1)]';
%
% % now grow companies
%
% % PARAM
% thresh = 2; % distance thershold (in grid units) for two men to be considered in a same commapny
%
% for kk = 1:length(gridHeight)-1
%
%     % for each floor, find all men at this floor and at floor
%     % above.
%     ifloor = find(men(:,3)==kk); % men(ifloor,:)
%     ifloorplus = find(men(:,3)==kk+1); % men(ifloorplus,:)
%
%     % Men are currently sorted by ascending floor and descending BS
%     % level. We're going to go through them in that order.
%     % For each man at current floor, starting with the highest
%     % level...
%     for pp = 1:length(ifloor)
%
%         % men(ifloor(pp),:)
%
%         % calculate distance between this man and all men on above
%         % floor (distance measured in cell units)
%         tt = repmat(men(ifloor(pp),1:2),length(ifloorplus),1);
%         sdist = sqrt(sum((tt - men(ifloorplus,1:2)).^2,2));
%
%         % find the closest upper floor man
%         [a,b] = min(sdist);
%
%         % if minimum distance is below threshold, associate man
%         % from above floor to company of this man. Note on the
%         % threshold: because we're measuring distance between a man
%         % at floor N and men at floor N+1, the minimum distance
%         % achievable is exactly 1 grid unit. A man on one of the
%         % fourth closest cells exactly above will be sqrt(2)=1.41
%         % units away. On the diagonals: sqrt(3)=1.73. On the next
%         % in line: sqrt(5)=2.23. Next, sqrt(6)=2.49... So if one
%         % sets a threshold of 2 for example, we mean companies can
%         % only grow if a man is found within the 8 closest
%         % neighbours...
%
%         if a<thresh
%
%             % we mean that this man:
%             % men(ifloorplus(b),:)
%             % should join the company of this man:
%             % men(ifloor(pp),:)
%             men(ifloorplus(b),5) = men(ifloor(pp),5);
%
%             % we remove this man from the list of men at upper
%             % floor so that they cannot be associated with another
%             % company.
%             ifloorplus(b)=[];
%
%         end
%     end
% end
%
% % works fast and results OK but doesn't link up the entire individual kelp
% % plants





% % creating companies. Method 1:
% % for each man, starting from the lowest
% % floors and the highest BS, find if there is another man at the 3
% % floors just above within a set distance. If there is, that other
% % man is added to the company of that first man.
%
% % Add a column for "company", ie links of men across severall floor levels.
% % Each man its own company to start with.
% % 1. Index in gridNorthing
% % 2. Index in gridEasting
% % 3. Index in gridHeight
% % 4. Level
% % 5. company
% men(:,5) = [1:size(men,1)]';
%
% % now grow companies
%
% % Men are sorted by ascending floor and descending BS level so we're going
% % to go through them ALL, one at a time
%
% for kk = 1:size(men,1)
%
%     % find all men at the three next floors above
%     ifloorplus = find(men(:,3)>men(kk,3) & men(:,3)<men(kk,3)+4); % men(ifloorplus,:)
%
%     % compute horizontal distance between this man and men on next
%     % floor
%     tt = repmat(men(kk,1:2),length(ifloorplus),1);
%     sdist = sqrt(sum((tt - men(ifloorplus,1:2)).^2,2));
%
%     % keep only those under thresh
%     thresh = 1.5;
%     ifloorplus = ifloorplus(sdist<thresh); % men(ifloorplus,:)
%
%     if size(ifloorplus,1) == 0
%         % if there is none, reloop to next man
%         continue
%
%     elseif size(ifloorplus,1) == 1
%         % if there is one, add to company
%
%         % we mean that this man: men(ifloorplus,:)
%         % should join the company of this man: men(kk,:)
%         men(ifloorplus,5) = men(kk,5);
%
%     elseif size(ifloorplus,1) > 1
%         % if there is more than one
%
%         % retain the ones at the lowest floor
%         ifloorplus = ifloorplus(men(ifloorplus,3) == min( men(ifloorplus,3) ));
%
%         if size(ifloorplus,1) == 1
%             % if there is only one, add to company
%             men(ifloorplus,5) = men(kk,5);
%         elseif size(ifloorplus,1) > 1
%
%             % if there is more than one, rank by horizontal distance
%             tt = repmat(men(kk,1:2),length(ifloorplus),1);
%             sdist = sqrt(sum((tt - men(ifloorplus,1:2)).^2,2));
%
%             % take the lowest distance
%             ifloorplus = ifloorplus(sdist == min(sdist));
%
%             if size(ifloorplus,1) == 1
%                 % if there is only one, add to company
%                 men(ifloorplus,5) = men(kk,5);
%             elseif size(ifloorplus,1) > 1
%                 % if there are more than one, rank by BS level
%
%                 % take the strongest
%                 ifloorplus = ifloorplus(men(ifloorplus,4) == max(men(ifloorplus,4)));
%
%                 if size(ifloorplus,1) == 1
%                     % if there is only one, add to company
%                     men(ifloorplus,5) = men(kk,5);
%                 elseif size(ifloorplus,1) > 1
%                     % if there are more than one, take the first one
%                     ifloorplus = ifloorplus(1);
%                 end
%             end
%         end
%     end
% end
%
% %same as before. improvement limited...



% % creating companies. Method 4
% % trying to gain speed compared to previous method. Linking man to the
% % first possible company and lopping back. No company merge
%
%
% men(:,5) = NaN;
%
% % distances to be part of a company:
% dht = 1.5; % hortizontal distance
% dvt = 3; % vertical distance
% det = 3.1; % euclidian distance
%
% % sort men by  decreasing BS:
% men = sortrows(men,-4);
%
% % put first man in its own company:
% men(1,5) = 1;
%
% % now for each man after that
% for kk = 2:size(men,1)
%
%     kk
%     ncomp = max(men(:,5)); % number of existing companies
%
%     % 1. check if there is any company I can fit this man in:
%
%     % for each company,
%     clear compdst comptest
%     for cc = 1:ncomp
%
%         % get all men in this company
%         comp = men(men(:,5)==cc,:);
%
%         % calculate distances between candidate man and all company:
%         dst = repmat(men(kk,1:3),size(comp,1),1) - comp(:,1:3); % distance in northing, easting, depth
%         dst(:,4) = abs(dst(:,3)); % vertical
%         dst(:,5) = sqrt( dst(:,1).^2 + dst(:,2).^2 ); % hortizontal
%         dst(:,6) = sqrt( dst(:,1).^2 + dst(:,2).^2 + dst(:,3).^2); %euclidian
%
%         % compare to threshold
%         dst(:,7) = double(dst(:,4)<=dvt) .* double(dst(:,5)<=dht) .* double(dst(:,6)<=det); %1 if under threshold, zero otherwise
%
%         % link up to this company or get to next company
%         flag = any(dst(:,7)>0);
%         if flag
%             men(kk,5) = cc;
%             break
%         end
%     end
%
%     % if still at NaN, means we went through all companies and didnt find
%     % one. new company
%     if isnan(men(kk,5))
%         men(kk,5) = ncomp+1;
%     end
%
% end



% %% CODE TO VISUALISE "KERNELS": which grid cells do those distances correspond to
% % distances to be part of a company:
% dht = 1.01; % hortizontal distance
% dvt = 3; % vertical distance
% det = 3.1; % euclidian distance
%
% x=[-5:5];
% y=[-5:5];
% z=[-5:5];
% [X,Y,Z] = meshgrid(x,y,z);
% dst = [X(:) Y(:) Z(:)];
%
% dst(:,4) = abs(dst(:,3)); % vertical
% dst(:,5) = sqrt( dst(:,1).^2 + dst(:,2).^2 ); % hortizontal
% dst(:,6) = sqrt( dst(:,1).^2 + dst(:,2).^2 + dst(:,3).^2); %euclidian
%
% dst(:,7) = double(dst(:,4)<=dvt) .* double(dst(:,5)<=dht) .* double(dst(:,6)<=det); %1 if under threshold, zero otherwise
%
% ind = dst(:,7)==1;
% plot3(dst(ind,1),dst(ind,2),dst(ind,3),'o')
% axis equal
% grid on
