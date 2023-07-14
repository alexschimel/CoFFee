function pgonFinal = CFF_get_swath_coverage(fData, Nstart)

% to get the swath coverage we need to simplify the BP bottom location into
% a nice-looking polygon. This may not be simple depending on the
% complexity of the soundings location. 

% we run a routine where the polygon is increasingly simplified until it's
% "nice-looking".

% the level of simplification is defined by the number (N) of vertices we
% which to set along the first and last swathes. It must be at least 2 and
% at most, the number of beams. In the routine, we start with this number
% set to N and halve it until the polygon is "nice-looking"

nBeams = size(fData.X_BP_bottomEasting,1);
nPings = numel(fData.X_1P_pingE);

% set of N values to try
Nvec = max(min(Nstart,nBeams),2);
while Nvec(end)>2
    Nvec(end+1) = ceil(Nvec(end).*(2./3));
end

pgon = cell(numel(Nvec),1);

% run through all values with early stopping if we get a nice polygon
for ii = 1:numel(Nvec)
    
    N = Nvec(ii);
    
    % indices of beams to keep along the first and last swath:
    iBeams = round(linspace(1,nBeams,N));
    iBeams(1) = 1;
    iBeams(end) = nBeams;
    
    % calculate the approx. min. distance between any two
    % consecutive vertices, to use as our characteristic distance
    distFirstSwath = sqrt( (fData.X_BP_bottomEasting(1,1)-fData.X_BP_bottomEasting(end,1)).^2 + ...
        (fData.X_BP_bottomNorthing(1,1)-fData.X_BP_bottomNorthing(end,1)).^2 );
    distLastSwath = sqrt( (fData.X_BP_bottomEasting(1,end)-fData.X_BP_bottomEasting(end,end)).^2 + ...
        (fData.X_BP_bottomNorthing(1,end)-fData.X_BP_bottomNorthing(end,end)).^2 );
    minVDist = min(distFirstSwath, distLastSwath)./N;
    
    % calculate corresponding number of vertices (P) along the
    % file's track
    
    totDistFile = sum(sqrt(diff(fData.X_1P_pingE).^2 + diff(fData.X_1P_pingN).^2));
    P = ceil(totDistFile./minVDist);
    
    % indices of pings to keep along the line
    iPings = round(linspace(1,nPings,P));
    iPings(1) = 1;
    iPings(end) = nPings;
    
    % finally, extract the vertices coordinates starting from the
    % top-left corner and going clockwise (in BP display
    vEast = [fData.X_BP_bottomEasting(1,iPings)'; ...
        fData.X_BP_bottomEasting(iBeams,end); ...
        fliplr(fData.X_BP_bottomEasting(end,iPings))'; ...
        flipud(fData.X_BP_bottomEasting(iBeams,1))];
    vNrth = [fData.X_BP_bottomNorthing(1,iPings)'; ...
        fData.X_BP_bottomNorthing(iBeams,end); ...
        fliplr(fData.X_BP_bottomNorthing(end,iPings))'; ...
        flipud(fData.X_BP_bottomNorthing(iBeams,1))];
    pos = [vEast,vNrth];
    
    % then create polygon and simplify it. Simplification is
    % done after creation to avoid warning
    pgon{ii} = polyshape(pos,'Simplify',false,'KeepCollinearPoints',true);
    pgon{ii} = simplify(pgon{ii});
    
    % test if polygon is "nice-looking"
    if pgon{ii}.NumRegions == 1
        break
    end
    
end

pgonFinal = pgon{ii};

% debug display
dbug = 0;
if dbug
    figure;
    lgd = {}
    for ii = 1:numel(Nvec)
        if ~isempty(pgon{ii})
            plot(pgon{ii})
            lgd{ii} = sprintf('N=%i. nRegions = %i',Nvec(ii),pgon{ii}.NumRegions);
            hold on
            axis equal
            grid on
        end
        legend(lgd)
    end
end


