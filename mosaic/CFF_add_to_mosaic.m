function mosaic = CFF_add_to_mosaic(mosaic,x,y,v,varargin)
%CFF_ADD_TO_MOSAIC Update mosaic with new data
%
%   MOSAIC = CFF_ADD_TO_MOSAIC(MOSAIC,X,Y,V) adds data with value V at 
%   coordinates X and Y to an existing MOSAIC, and outputs the updated
%   MOSAIC. MOSAIC is a mosaic structure such as initialized with
%   CFF_INIT_MOSAIC_V2 or resulting from a prior use of CFF_ADD_TO_MOSAIC.
%   X,Y, and V can be all vectors, or all 2D arrays, in which case they
%   need to have matching size. Or V can be a matrix and X and Y its vector
%   coordinates with X as a row vector and Y a column vector. Note you need
%   to run CFF_FINALIZE_MOSAIC when you have finished adding all desired
%   data to the mosaic.
%
%   CFF_ADD_TO_MOSAIC(...,W) also uses the weights W corresponding to the
%   values V. W must be same size as V, or a single value that applies to
%   all data. By default, W = 1. The MOSAIC field MOSAIC.mode governs how
%   weight is used to update the mosaic. With 'blend', the new and existing
%   data get (possibly weighted) averaged. Actual weights can be used to
%   privilege some data, but by default, the weight of a cell is the number
%   of data points that contributed to a cell value, so the iterative
%   weighted averaging is equivalent to a normal averaging. With 'stitch',
%   we retain for each cell whichever data has largest weight. Actual
%   weights can be used to privilege some data, but by default, the new
%   data takes precedence over the old. 
%
%   Note that the averaging in 'blend' mode is performed on input values V
%   "as is". If V is backscatter data and you don't want to avearge in dB,
%   you need to transform the values before using this function, and apply
%   the reverse transformation when the mosaicking is complete. See
%   CFF_MOSAIC_LINES.
%
%   See also CFF_MOSAIC_LINES, CFF_INIT_MOSAIC_V2, CFF_FINALIZE_MOSAIC

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no)
%   2017-2022; Last revision: 06-04-2022

% input parser
p = inputParser;
addRequired(p,'mosaic',@(x) isstruct(x));
addRequired(p,'x',@(u) validateattributes(u,{'numeric'},{'2d'}));
addRequired(p,'y',@(u) validateattributes(u,{'numeric'},{'2d'}));
addRequired(p,'v',@(u) validateattributes(u,{'numeric'},{'2d'}));
addOptional(p,'w',1, @(u) isnumeric(u));
parse(p,mosaic,x,y,v,varargin{:});
w = p.Results.w;
clear p;

% input additional checks and data preparation
if ~isempty(setxor(fieldnames(mosaic),fieldnames(CFF_init_mosaic_v2([0,1,0,1]))))
    error("'mosaic' must be a mosaic struct as produced by CFF_INIT_MOSAIC_V2.");
end
sx = size(x);
sy = size(y);
sv = size(v);
check_xyv_same_size = all(sx==sy)&&all(sx==sv);
check_xyv_grid = sx(1)==1&&sx(2)==sv(2)&&sy(1)==sv(1)&&sy(2)==1;
if ~check_xyv_same_size && ~check_xyv_grid
    error("The formats of 'x', 'y' and 'v' are not correct. They must either have the same size, or 'v' must be a 2D array with 'x' and 'y' as its vector coordinates.");
end
if numel(w)==1
    w = w.*ones(sv);
else
    sw = size(w);
    if ~all(sw==sv)
        error("'w' must be same size as v.");
    end
end

% meshgrid x,y
if check_xyv_grid
    x = repmat(x,sv(1),1);
    y = repmat(y,1,sv(2));
end

% vectorize everything
if size(x,2)>1
    x = x(:);
    y = y(:);
    v = v(:);
    w = w(:);
end

% indices of new data in the mosaic
ix = round((x-mosaic.xg(1))/mosaic.res+1);
iy = round((y-mosaic.yg(1))/mosaic.res+1);

% remove data 1) outside of mosaic boundaries, 2) with a nan value, 3)
% with zero weight
iKeep = ix>=1 & ix<=numel(mosaic.xg) ...
    & iy>=1 & iy<=numel(mosaic.yg) ...
    & ~isnan(x) & ~isnan(y) & ~isnan(v) & ~isnan(w) & w~=0;
if any(iKeep==0)
    ix = ix(iKeep);
    iy = iy(iKeep);
    x  = x(iKeep);
    y  = y(iKeep);
    v  = v(iKeep);
    w  = w(iKeep);
end

% if ROI was a polygon, we also remove all data outside it
if ~isempty(mosaic.x_pol)
    iKeep = inpolygon(x,y,mosaic.x_pol,mosaic.y_pol);
    if any(iKeep==0)
        ix = ix(iKeep);
        iy = iy(iKeep);
        v =  v(iKeep);
        w =  w(iKeep);
    end
end

% indices of block (extract of mosaic where new data will contribute) in
% mosaic  
iR_block = min(iy):max(iy);
iC_block = min(ix):max(ix);

% indices of new data in block
iy_in_blc = iy - min(iy) + 1;
ix_in_blc = ix - min(ix) + 1;

% prepare for accumaray the new data
subs = [iy_in_blc ix_in_blc]; % indices of new data in block
sz   = [numel(iR_block) numel(iC_block)]; % size of output array

% regrid the new data in a new block. Since the data were originally
% gridded at the same resolution, there should only be one point per block
% cell, so we can use any function, both for value and weight.
new_v_blc = accumarray(subs,v,sz,@min,0); % gridded value
new_w_blc = accumarray(subs,w,sz,@min,0); % gridded weight

% get the current values and weights in the block
cur_v_blc = mosaic.value(iR_block,iC_block);
cur_w_blc = mosaic.weight(iR_block,iC_block);

% next we merge the new block data into the current mosaic
switch mosaic.mode
    
    case 'blend'
        % In this mode, for each grid cell in the block, the current value
        % and new value are averaged using their respective weights. This
        % has for effect of "blending" overlapping lines together.
        
        % we sum the current block and the new block weight to get the
        % updated weight
        upd_w_blc = cur_w_blc + new_w_blc;
        
        % and the updated value is the average of current and new values,
        % weighted by their respective weights.
        upd_v_blc = ((cur_v_blc.*cur_w_blc)+(new_v_blc.*new_w_blc))./upd_w_blc;
        
        % where the updated weight is still zero (no current nor new data),
        % we get nan updated values, which we don't want to keep. Reset
        % those updated values to zero
        upd_v_blc(upd_w_blc==0) = 0;
        
    case 'stitch'
        % In this mode, for each grid cell in the block, we retain either
        % the current value or the new value, whichever has the highest
        % weight. This mode is typically used with the inverse of the
        % distance to nadir as the weight, which effectively results in
        % "stitching" lines data together with stitches occuring at
        % equidistance from the vessel tracks.
        
        % get indice of data to retain (1=new, 2=current)
        [~,ind] = max([new_w_blc(:),cur_w_blc(:)],[],2,'omitnan');
        ind = reshape(ind,size(cur_w_blc));
        
        % updated data is new data where ind=1 and current data where ind=2
        upd_v_blc = new_v_blc.*(ind==1) + cur_v_blc.*(ind==2);
        upd_w_blc = new_w_blc.*(ind==1) + cur_w_blc.*(ind==2);
        
    case 'min'
        % In this mode, for each grid cell in the block, we retain
        % whichever value is the smallest.
        % We only use weights to check where there is data
        new_v_blc(new_w_blc==0) = NaN;
        cur_v_blc(cur_w_blc==0) = NaN;
        upd_v_blc = min(new_v_blc,cur_v_blc,'omitnan');
        upd_v_blc(isnan(upd_v_blc)) = 0;
        
        % the udpated weight is where there is data
        upd_w_blc = double(cur_w_blc+new_w_blc>0);
        
end

% update mosaic with updated block value and weight
mosaic.value(iR_block,iC_block)  = upd_v_blc;
mosaic.weight(iR_block,iC_block) = upd_w_blc;

end
