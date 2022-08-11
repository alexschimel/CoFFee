function mosaic = CFF_init_mosaic(E_lim,N_lim,res,varargin)
%CFF_INIT_MOSAIC  Initialize a new mosaic
%
%   CFF_INIT_MOSAIC(E_lim,N_lim,res,mode) initializes a new mosaic object
%   to be later filled with data. Required input are the Easting and
%   Northing boundaries (resp E_lim and N_lim as two elements vectors) and
%   the resolution, all of them in m. The optional input mode, is either
%   "blend" (default) or "stitch".

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NGU, alexandre.schimel@ngu.no)
%   2017-2021; Last revision: 25-02-2022

% input parser
p = inputParser;
addRequired(p,'E_lim',@(x) isnumeric(x) && all(size(x)==[1,2]) && x(1)<x(2));
addRequired(p,'N_lim',@(x) isnumeric(x) && all(size(x)==[1,2]) && x(1)<x(2));
addRequired(p,'res',@(x) isnumeric(x));
addOptional(p,'mode','blend',@(x) ismember(x,{'blend','stitch'}));
parse(p,E_lim,N_lim,res,varargin{:});
mode = p.Results.mode;
clear p;

% initialize mosaic with ID
mosaic.ID = str2double(datestr(now,'yyyymmddHHMMSSFFF'));

% values from input
mosaic.E_lim = E_lim;
mosaic.N_lim = N_lim;
mosaic.res   = res;
mosaic.mode  = mode;

% default values
mosaic.name     = 'New Mosaic';
mosaic.Fdata_ID = [];

% init array
if res > 0
    numElemMosaicE = ceil((E_lim(2)-E_lim(1))./res)+1;
    numElemMosaicN = ceil((N_lim(2)-N_lim(1))./res)+1;
    mosaic.mosaic_level = zeros(numElemMosaicN,numElemMosaicE,'single');
else
    mosaic.mosaic_level = single([]);
end
