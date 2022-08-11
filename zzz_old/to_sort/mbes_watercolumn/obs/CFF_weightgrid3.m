%% CFF_weightgrid3.m
%
% Weight gridding of 3D points.
%
% IMPORTANT NOTE: This function is now obsolete. Use CFF_weightgrid_3D.m
% instead.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-06: added header (Alex Schimel).
% * YYYY-MM-DD: first version (Alex Schimel).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.


%% Function
function [gridV,gridW,gridX,gridY,gridZ] = CFF_weightgrid3(x,y,z,v,xi,yi,zi,w)
 

%% OPTION 1: just taking code from CFF_grid_watercolumn

% if weight is a single value (1), expand to size of other variables
if length(w)==1
    w=ones(size(x));
end

% build the grids
gridX = [0:xi(3)-1].*xi(2) + xi(1);
gridY = [0:yi(3)-1]'.*yi(2) + yi(1);
gridZ = [0:zi(3)-1].*zi(2) + zi(1);

%% now grid watercolumn data

% option 1: griddata in 3D (takes too long, gave up on this)
% gridV = griddata(E,N,H,L,gridX,gridY,gridZ); 

% option 2: slice by slice

% initialize cubes of values and density
gridV = nan(yi(3),xi(3),zi(3));
gridW = nan(yi(3),xi(3),zi(3));

for kk = 1:zi(3)-1
    
    % find all samples in slice
    ind = find( z>gridZ(kk) & z<gridZ(kk+1) );
    
    if ~isempty(ind)
        
        % gridding at constant weight
        [tmpgridV,tmpgridW] = CFF_weightgrid(x(ind),y(ind),v(ind),xi,yi,w(ind));
        
        % add to cubes
        gridV(:,:,kk) = tmpgridV;
        gridW(:,:,kk) = tmpgridW;
        
    end
    
end

% 
% 
% %% OPTION 2: rewriting in 3D (in progress)
% 
% 
% 
% % prepare interpolation grids
% zi_firstval = zi(1);
% zi_step = zi(2);
% zi_numel = zi(3);
% zi_lastval = (zi_numel-1).*zi_step+zi_firstval;
% 
% % note: this is unused but just for info, here's how you'd build the grid
% % vectors from these parameters:
% % zi_grid=[0:zi_numel-1].*zi_step + zi_firstval;
% 
% % turn (x,y,v,w) variables to vectors
% x = reshape(x,1,[]);
% y = reshape(y,1,[]);
% z = reshape(z,1,[]);
% v = reshape(v,1,[]);
% w = reshape(w,1,[]);
% 
% % if weight is a single value (1), expand to size of other variables
% if length(w)==1
%     w=ones(size(x));
% end
% 
% % find x,y values that are outside the grid & remove them
% indout = z<zi_firstval | z>zi_lastval;
% x(indout)=[];
% y(indout)=[];
% z(indout)=[];
% v(indout)=[];
% w(indout)=[];
% 
% % define a default NO_VALUE that allows progressive averaging (can't use
% % NaN). This value must be impossible to attain during the averaging. We'll
% % replace it with NaN at the end so no worries
% NO_VALUE = floor(min(v))-1000;
% 
% % initialize cubes of values and density
% gridV   = nan(numN,numE,numH);
% gridW = nan(numN,numE,numH);
% 
% for kk = 1:length(gridZ)-1
%     
%     % find all samples in slice
%     ind = find( z>gridZ(kk) & z<gridZ(kk+1) );
%     
%     if ~isempty(ind)
%         
%         % gridding at constant weight
%         [vi,wi] = CFF_weightgrid(x(ind),y(ind),v(ind),xi,yi,w(ind));
%         
%         % add to cubes
%         vi3(:,:,kk) = vi;
%         wi3(:,:,kk) = wi;
%         
%     end
%     
% end