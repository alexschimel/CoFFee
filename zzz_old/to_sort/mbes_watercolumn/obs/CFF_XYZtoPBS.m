function PBS = CFF_XYZtoPBS(fData,ENH)
% PBS = CFF_XYZtoPBS(fData,ENH)
%
% DESCRIPTION
%
% function to find in a MB dataset the closest ping/beam/sample to any
% given data point in easting/northing/height. Used for display of
% watercolumn targets

%   Copyright 2014-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% data sizes
[nPings,nBeams,nSamples] = size(fData.X_PBS_sampleEasting);
nPoints = size(ENH,1);

% grab data
dataE = fData.X_PBS_sampleEasting;
dataN = fData.X_PBS_sampleNorthing;
dataH = fData.X_PBS_sampleHeight;

% now find closest sample for each point of interest

%% option 3: finding the 5% closest ping swathes and brute-forcing through them

% first, define the planes for each ping, once and in advance
% {0,1,2} are resp locations of sonar and last sample in outermost beams
E0 = dataE(:,round(nBeams./2),1);
N0 = dataN(:,round(nBeams./2),1);
H0 = dataH(:,round(nBeams./2),1);
E1 = dataE(:,1,end);
N1 = dataN(:,1,end);
H1 = dataH(:,1,end);
E2 = dataE(:,end,end);
N2 = dataN(:,end,end);
H2 = dataH(:,end,end);
planes = [E0 N0 H0 E1-E0 N1-N0 H1-H0 E2-E0 N2-N0 H2-H0];

for ii = 1:nPoints
    PBSlist = [];
    mindist = 3; % 5 percent closest
    d = [(1:nPings)',nan(nPings,1)];
    for jj = 1:nPings
        % distance from point to swath plane:
        d(jj,2) = abs(distancePointPlane( [ENH(ii,1) ENH(ii,2) ENH(ii,3)] , planes(jj,:)));
    end
    d = sortrows(d,2);
    d = sort(d(1:ceil(mindist.*nPings./100),1));
    
    dataEp = dataE(d(1):d(end),:,:);
    dataNp = dataN(d(1):d(end),:,:);
    dataHp = dataH(d(1):d(end),:,:);
    
    dist = sqrt( (ENH(ii,1) - dataEp(:)).^2 + (ENH(ii,2) - dataNp(:)).^2 + (ENH(ii,3) - dataHp(:)).^2 );
    [a,b] = min(dist);
    [PBS3(ii,1),PBS3(ii,2),PBS3(ii,3)] = ind2sub([d(end)-d(1)+1,nBeams,nSamples],b);
    PBS3(ii,1) = PBS3(ii,1)+d(1)-1;
end

PBS = PBS3;



% %% option 1 brute force
% for ii = 1:nPoints
%     dist = sqrt( (ENH(ii,1) - dataE(:)).^2 + (ENH(ii,2) - dataN(:)).^2 + (ENH(ii,3) - dataH(:)).^2 );
%     [a,b] = min(dist);
%     [PBS1(ii,1),PBS1(ii,2),PBS1(ii,3)] = ind2sub([nPings,nBeams,nSamples],b);
% end

% %% option 2: complex but hopefully faster
% % find all ping/beam/samples where target is within a desired minimum distance of:
% % * the ping's plane defined by the locations of sonar and last sample of outside beams
% % * the beam's straight line between sonar and last sample
% % * the samples within that ping and beam.
% 
% % first, define the planes for each ping, once and in advance
% % {0,1,2} are resp locations of sonar and last sample in outermost beams
% E0 = dataE(:,round(nBeams./2),1);
% N0 = dataN(:,round(nBeams./2),1);
% H0 = dataH(:,round(nBeams./2),1);
% E1 = dataE(:,1,end);
% N1 = dataN(:,1,end);
% H1 = dataH(:,1,end);
% E2 = dataE(:,end,end);
% N2 = dataN(:,end,end);
% H2 = dataH(:,end,end);
% planes = [E0 N0 H0 E1-E0 N1-N0 H1-H0 E2-E0 N2-N0 H2-H0];
% 
% for ii = 1:nPoints
%     PBSlist = [];
%     mindist = 1; % minimum distance in m
%     for jj = 1:nPings
%         % distance from point to swath plane:
%         d = abs(distancePointPlane( [ENH(ii,1) ENH(ii,2) ENH(ii,3)] , planes(jj,:)));
%         if d<=mindist
%             for kk = 1:nBeams
%                 % last sample of this ping and beam
%                 E1 = dataE(jj,kk,end);
%                 N1 = dataN(jj,kk,end);
%                 H1 = dataH(jj,kk,end);
%                 % distance from point to beam straight line:
%                 line = [E0(jj) N0(jj) H0(jj) E1-E0(jj) N1-N0(jj) H1-H0(jj)];
%                 d = abs(distancePointLine3d([ENH(ii,1) ENH(ii,2) ENH(ii,3)], line));
%                 if d<=mindist
%                     % distance from point to all samples in this ping/beam
%                     d = abs(squeeze(sqrt( (ENH(ii,1) - dataE(jj,kk,:)).^2 + (ENH(ii,2) - dataN(jj,kk,:)).^2 + (ENH(ii,3) - dataH(jj,kk,:)).^2 )));
%                     ll = find(d<=mindist);
%                     d = d(d<=mindist);
%                     PBSlist = [PBSlist; [repmat(jj,size(ll)),repmat(kk,size(ll)),ll],d];
%                 end
%             end
%         end
%     end
%     PBSlist = sortrows(PBSlist,4);
%     PBS2(ii,:) = PBSlist(1,1:3);
% end



