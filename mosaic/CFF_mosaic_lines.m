function mosaic = CFF_mosaic_lines(fDataGroup,fieldname,varargin)
%CFF_MOSAIC_LINES  Mosaic a set of gridded lines
%
%   MOSAIC = CFF_MOSAIC_LINES(FDATAGROUP,FIELDNAME), where FDATAGROUP is a
%   cell array of fData structures and FIELDNAME is the (string) name of a
%   gridded data field common to these structures, creates a mosaic of that
%   data. MOSAIC is a mosaic structure whose fields include the two grids
%   'value' (containing the mosaicked value) and 'weight' (containing the
%   accumulated weight, see option 'mode' below), and other metadata.
%
%   CFF_MOSAIC_LINES(...,'xy_roi',VALUE) specifies the x,y coordinates of
%   the ROI to be mosaicked and can be of two types: either a 4-elements
%   vector containing the desired min and max limits in x and y of a box
%   [x_min x_max y_min y_max], OR a Nx2 array (with N>=3) where each row is
%   the x,y coordinates of a vertex of a polygon inside which the mosaic is
%   to be calculated.
%
%   CFF_MOSAIC_LINES(...,'res',VALUE) with VALUE a positive scalar
%   specifies the desired mosaic grid size (resolution) (use the same unit
%   as 'xy_roi', i.e. usually, meters). With VALUE empty (default), the
%   grid size will be selected as the coarsest grid size of the data
%   gridded in FDATAGROUP. Note that while you can set here a finer
%   resolution than that of the gridded data, the end-product will not
%   appear as more detailed than the componenent grids. To get a better
%   resolution, you would need to re-grid the files at a finer grid size.
%
%   CFF_MOSAIC_LINES(...,'mode',VALUE) specifies the mosaicking mode, i.e.
%   the rules of how new data gets merged with existing data when adding to
%   the mosaic. Options are 'blend' (default) or 'stitch'. With 'blend',
%   the new and existing data get (possibly weighted) averaged. Actual
%   weights can be used to privilege some data, but by default, the weight
%   of a cell is the number of data points that contributed to a cell
%   value, so the iterative weighted averaging is equivalent to a normal
%   averaging. With 'stitch', we retain for each cell whichever data has
%   largest weight. Actual weights can be used to privilege some data, but
%   by default, the new data takes precedence over the old. See
%   CFF_ADD_TO_MOSAIC for detail on accumulating algorithms.
%
%   CFF_MOSAIC_LINES(...,'comms',VALUE) specifies the logging and display
%   method. See CFF_COMMS.
%
%   See also CFF_INIT_MOSAIC_V2, CFF_ADD_TO_MOSAIC, CFF_FINALIZE_MOSAIC

%   Copyright 2017-2022 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% input parser
p = inputParser;
addRequired(p,'fDataGroup',@(x) all(CFF_is_fData_version_current(x)));
addRequired(p,'fieldname',@(x) ischar(x));
addParameter(p,'xy_roi',@(u) validateattributes(u,{'numeric'},{'2d'}));
addParameter(p,'res',[],@(x) isempty(x) || x>0);
addParameter(p,'mode','blend', @(u) ischar(u)&&ismember(u,{'blend','stitch','min'}));
addParameter(p,'comms',CFF_Comms());
parse(p,fDataGroup,fieldname,varargin{:});
xy_roi = p.Results.xy_roi;
res = p.Results.res;
mode = p.Results.mode;
comms = p.Results.comms;
clear p;
if ischar(comms)
    comms = CFF_Comms(comms);
end

% first, check that fieldname exist in every fData
if ~all(cellfun(@(s) isfield(s,fieldname),fDataGroup))
    error('Not all fData structures in "fDataGroup" have the required field "%s"',fieldname);
end

% start message
comms.start(sprintf('Mosaicking "%s" data from line(s)',fieldname));

% number of files
nLines = numel(fDataGroup);

% start progress
comms.progress(0,nLines);

% for mosaic grid size, we use by default the coarsest resolution of
% component grids 
if isempty(res)
    res = max(cellfun(@(x) x.X_1_2DgridHorizontalResolution, fDataGroup));
end

% if no ROI in input, do the entire dataset
if isempty(xy_roi)
    xy_roi = [NaN NaN NaN NaN];
    for iF = 1:numel(fDataGroup)
        xy_roi(1) = min( xy_roi(1), min(fDataGroup{iF}.X_1E_gridEasting) );
        xy_roi(2) = max( xy_roi(2), max(fDataGroup{iF}.X_1E_gridEasting) );
        xy_roi(3) = min( xy_roi(3), min(fDataGroup{iF}.X_N1_gridNorthing) );
        xy_roi(4) = max( xy_roi(4), max(fDataGroup{iF}.X_N1_gridNorthing) );
    end
end

% initialize mosaic
mosaic = CFF_init_mosaic_v2(xy_roi,'res',res,'mode',mode);

% flag for special processing if we average backscatter values
flagAverageBackscatter = 0;
if strcmp(fieldname,'X_NE_bs') && strcmp(mosaic.mode,'blend')
    flagAverageBackscatter = 1;
end

if flagAverageBackscatter
    % for backscatter and mosaicking modes involving averaging (i.e.
    % 'blend') one needs to decide whether to average the dB values, or the
    % equivalent amplitude or power values. The "mathematically" correct
    % one is power, but is strongly affected by outliers. The best choice
    % "aesthetically" is to use dB. We set here the transformation
    % necessary before data is averaged, and the reverse transformation to
    % get back in dB. For now the choice is hard-code, but perhaps
    % eventually turn it as an input parameter
    bs_averaging_mode = 'power';
    switch bs_averaging_mode
        case 'dB'
            % no transformation as data is natively in dB.
            bs_trsfm = @(x) x;
            inv_trsfm = @(x) x;
        case 'amplitude'
            bs_trsfm = @(x) 10.^(x./20); % dB to amplitude
            inv_trsfm = @(x) 20.*log10(x); % amplitude to dB
        case 'power'
            bs_trsfm = @(x) 10.^(x./10); % dB to power
            inv_trsfm = @(x) 10.*log10(x); % power to dB
    end
end

% loop through fData
for ii = 1:nLines
    
    % get fData for this line
    if iscell(fDataGroup)
        fData = fDataGroup{ii};
    else
        fData = fDataGroup;
    end
    
    % display for this line
    lineName = CFF_file_name(char(CFF_onerawfileonly(fData.ALLfilename)),1);
    comms.step(sprintf('%i/%i: line %s',ii,nLines,lineName));
    
    % get x,y,v data
    x = fData.X_1E_2DgridEasting;
    y = fData.X_N1_2DgridNorthing;
    v = fData.(fieldname);
    
    if flagAverageBackscatter
        % transform backscatter now. Mosaic will remain in transformed unit
        % until finalization. 
        v = bs_trsfm(v);
    end
    
    % set weight
    switch mosaic.mode
        case 'blend'
            % weight here is the number of points per gridded cell
            w = fData.X_NE_weight;
        case 'stitch'
            % weight here is the inverse of the distance of the grid cell
            % to nadir
            tempIndBP = fData.X_NE_indexBP;
            indNan = isnan(tempIndBP);
            tempIndBP(indNan) = 1;
            w = 1./abs(fData.X8_BP_AcrosstrackDistanceY(tempIndBP));
            w(indNan) = 0;
        case 'min'
            % no need for weight in this mode, use dummy value
            w = 1;
    end
    % add to mosaic
    mosaic = CFF_add_to_mosaic(mosaic,x,y,v,w);
    
    % successful end of this iteration
    comms.info('Done');
    
    % communicate progress
    comms.progress(ii,nLines);
    
end

% finalize mosaic
mosaic = CFF_finalize_mosaic(mosaic);

if flagAverageBackscatter
    % apply reverse transform to backscatter
    mosaic.value = inv_trsfm(mosaic.value);
end

% end message
comms.finish('Done');

end