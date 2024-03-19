function fDataGroup = CFF_grid_lines(fDataGroup,varargin)
%CFF_GRID_LINES  Create Easting-Northing grids of data in a set of lines
%
%   FDATAGROUP = CFF_GRID_LINES(FDATAGROUP) creates Easting-Northing grids
%   of bathymetry and bacskcatter data from a set of fData structures. The
%   grid size is 1m. The gridded data and the metadata are saved back into
%   the corresponding fData structure.
% 
%   CFF_GRID_LINES(...,'res',VALUE) to specify the grid size
%
%   CFF_GRID_LINES(...,'saveFDataToDrive',VALUE) to specify whether to save
%   the fData on the hard-drive (VALUE=1) or not (VALUE=0, default). 
%
%   CFF_GRID_LINES(...,'abortOnError',VALUE) to specify whether the process
%   is to be aborted upon encountering an error in a file (VALUE=1) or
%   simply continuing to the next file (VALUE=0, default).
%
%   CFF_GRID_LINES(...,'comms',VALUE) to provide a CFF_Comms() object,
%   initiate a new one (possible values 'disp', 'textprogressbar',
%   'waitbar', 'oneline', 'multilines') or leave empty for no comms
%   (default).
%
%   See also CFF_INIT_GRID, CFF_GRID_DATA

%   Copyright 2021-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% input parser
p = inputParser;
addRequired(p, 'fDataGroup',                   @(x) all(CFF_is_fData_version_current(x)));
addParameter(p,'res',             1,           @mustBePositive);
addParameter(p,'saveFDataToDrive',0,           @(x) mustBeMember(x,[0,1]));
addParameter(p,'abortOnError',    0,           @(x) mustBeMember(x,[0,1]));
addParameter(p,'comms',           CFF_Comms());
parse(p,fDataGroup,varargin{:});
res = p.Results.res;
saveFDataToDrive = p.Results.saveFDataToDrive;
abortOnError = p.Results.abortOnError;
comms = p.Results.comms;
clear p;
if ischar(comms)
    comms = CFF_Comms(comms);
end

% start message
comms.start('Gridding data in line(s)');

% number of files
nLines = numel(fDataGroup);

% start progress
comms.progress(0,nLines);

% Process files one by one
for ii = 1:nLines
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get fData for this line
        if iscell(fDataGroup)
            fData = fDataGroup{ii};
        else
            fData = fDataGroup;
        end
            
        % display for this line
        lineName = CFF_file_name(char(CFF_onerawfileonly(fData.ALLfilename)),1);
        comms.step(sprintf('%i/%i: line %s',ii,nLines,lineName));
        
        % get x,y data
        x = fData.X_BP_bottomEasting(:);
        y = fData.X_BP_bottomNorthing(:);
        
        % initialize grid. Make it neat
        x_lim(1) = floor((min(x)+res./2)./res).*res;
        x_lim(2) = max(x);
        y_lim(1) = floor((min(y)+res./2)./res).*res; 
        y_lim(2) = max(y);
        [gridE,gridN] = CFF_init_grid(x_lim,y_lim,res);
        
        % grid bathymetry
        comms.info('Gridding bathymetry')
        [gridBathy,gridWeight] = CFF_grid_data(x,y, ...
            fData.X_BP_bottomHeight(:), ...
            gridE,gridN);
        
        % calculate slope
        comms.info('Calculating gridded slope');
        [gridSlopeX,gridSlopeY] = gradient(gridBathy);
        gridSlope = sqrt(gridSlopeX.^2 + gridSlopeY.^2);
        
        % grid backscatter
        % DEV NOTE: For backscatter we can only do it if
        % X_BP_bottomEasting/Northing match X8_BP_ReflectivityBS
        flagGridBS = CFF_is_field_or_prop(fData,'X8_BP_ReflectivityBS') &&  all(size(fData.X8_BP_ReflectivityBS)==size(fData.X_BP_bottomEasting)); 
        if flagGridBS 
            comms.info('Gridding backscatter');
            gridBS = CFF_grid_data(x,y,...
                fData.X8_BP_ReflectivityBS(:),...
                gridE,gridN);
        end 
        
        % grid ping and beam number.
        % Here we keep only the minimum linear index per grid cell. Since
        % linear indices increase by ping THEN beam, it means that the
        % smallest ping takes precedence. For example, if a grid cell has
        % only two points being at beam #256 in ping #1 and beam #1 in ping
        % #2, then the grid cell will store the information of the former,
        % because it has lower ping index. Use [iB,iP] =
        % ind2sub([nB,nP],linearIndices); to retrieve indices in beam and
        % ping from the linear indices.
        comms.info('Gridding ping and beam indices');
        [nB,nP] = size(fData.X8_BP_DepthZ);
        linIndexBP = 1:nB*nP;
        gridMinIndexBP = CFF_grid_data(x,y,...
            linIndexBP(:),...
            gridE,gridN,...
            1,... % weight, unecessary here
            'min'); % mode
        
        % [nB,nP] = size(fData.X8_BP_DepthZ);
        % gridIndexBP = fData.X_NE_indexBP;
        % [gridBind,gridPind] = ind2sub([nB,nP],gridIndexBP);
        % indNan = isnan(gridIndexBP);
        % gridIndexBP(indNan) = 1;
        % A = abs(fData.X8_BP_AcrosstrackDistanceY(gridIndexBP));
        % A(indNan) = NaN;
            
        % grid beam angle (away from nadir)
        % for now doing an approximative calculation from the distance
        % along/across-track since they are available in the X8 datagrams,
        % but when it's working and proving useful, do switch to using the
        % actual angles in the RRA78 datagrams
        %
        % Note we do not average but keep the minimum angle
        comms.info('Gridding beam angle');
        BP_beamAngle = abs(atand(fData.X_BP_bottomAcrossDist./(-fData.X_BP_bottomUpDist)));
        gridMinBeamAngle = CFF_grid_data(x,y,...
            BP_beamAngle(:),...
            gridE,gridN,...
            1,... % weight, unecessary here
            'min'); % mode
        
        
        % % gridding pingcounter as BP to display ping data as grids
        % comms.info('Gridding ping indices');
        % nB = size(fData.X8_B1_BeamNumber,1);
        % v = reshape(ones(nB,1)*fData.X8_1P_PingCounter,[],1);
        % [gridPing,gridPingWeight] = CFF_grid_data(x,y,v,gridE,gridN,...
        %     1,'stitch');
        % % why stitch does not work here?
        %
        % %indexing in Ru_1D
        % % do column per column
        % X_NE_indexInRu_1D = nan(size(gridPing));
        % nC = size(X_NE_indexInRu_1D,2);
        % for iC = 1:nC
        %     A = gridPing(:,iC) - fData.Ru_1D_PingCounter;
        %     A(A<0) = max(A(:));
        %     [M,I] = min(A,[],2);
        %     I(isnan(M)) = NaN;
        %     X_NE_indexInRu_1D(:,iC) = I;
        % end
        
        % save everything
        fData.X_1_2DgridHorizontalResolution = res;
        fData.X_1E_2DgridEasting  = gridE;
        fData.X_N1_2DgridNorthing = gridN;
        fData.X_NE_bathy  = gridBathy;
        fData.X_NE_weight = gridWeight;
        fData.X_NE_slope  = gridSlope;
        fData.X_NE_bs     = gridBS;
        fData.X_NE_minIndexBP   = gridMinIndexBP;
        fData.X_NE_minBeamAngle = gridMinBeamAngle;
        %fData.X_NE_indexInRu_1D = X_NE_indexInRu_1D;

        % save fData to drive
        if saveFDataToDrive
            % get output folder and create it if necessary
            rawFile = fData.ALLfilename;
            wc_dir = CFF_converted_data_folder(rawFile);
            if ~isfolder(wc_dir)
                mkdir(wc_dir);
            end
            mat_fdata_file = fullfile(wc_dir, 'fData.mat');
            comms.info('Saving');
            save(mat_fdata_file,'-struct','fData','-v7.3');
        end
        
        % save fData back into group
        if iscell(fDataGroup)
            fDataGroup{ii} = fData;
        else
            fDataGroup = fData;
        end
        
        % successful end of this iteration
        comms.info('Done');
        
    catch err
        if abortOnError
            % just rethrow error to terminate execution
            rethrow(err);
        else
            % log the error and continue
            errorFile = CFF_file_name(err.stack(1).file,1);
            errorLine = err.stack(1).line;
            errrorFullMsg = sprintf('%s (error in %s, line %i)',err.message,errorFile,errorLine);
            comms.error(errrorFullMsg);
        end
    end
    
    % communicate progress
    comms.progress(ii,nLines);
    
end

% output fDataGroup as single struct if that was the input
if isstruct(fDataGroup)
    fDataGroup = fDataGroup{1};
end


%% end message
comms.finish('Done');

end