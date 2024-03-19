function B = CFF_spikefilt2(A,n,k,p,varargin)
% B = CFF_spikefilt2(A,n,k,p,varargin)
%
% DESCRIPTION
%
% Filters image A with spike filter using disk-shaped structural element of
% radius n. Acts as a median filter ONLY IF the difference between
% value and neighborhood median is larger than k times the std within the
% strel. k=1 removes a lot while k=3 removes only the most conspicuous
% spikes. n = 1 removes most peaks, any larger value removes less.
%
% EXAMPLE
%
% Z1_file = '.\DATA\WH1_Z_50cm_UTM54S_LAT_p1.tif';
% referencePoly = [   629032, 5748334;...
%                     629019, 5748370;...
%                     629063, 5748386;...
%                     629076, 5748350;...
%                     629032, 5748334];
% [Z1,Z1_easting,Z1_northing] = CFF_load_raster(Z1_file);
% 
% % clip grids to reference polygon
% polygon = referencePoly;
% xv = polygon(:,1);
% yv = polygon(:,2);
% [Z1,Z1_easting,Z1_northing] = CFF_clip_raster(Z1,Z1_easting,Z1_northing,xv,yv);
% 
% figure
% for nn = 1:4
%     for kk =1:4
%         Z1f = CFF_spikefilt2(Z1,nn,kk,1);
%         subplot(4,4,sub2ind([4,4],nn,kk));
%         imagesc( (Z1f-Z1)~=0);
%         axis equal; grid on; colormap jet
%         title(sprintf('n = %i, k = %i',nn,kk));
%     end
% end
% figure; imagesc(Z1)
%
%   Copyright 2014-2014 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% create structural element
H = CFF_disk(n); % disk of radius n
H(2*n*n+2*n+1)=0; % remove centre cell

% do p passes
for ip = 1:p
    
    % stackoffset the image
    A_stack = CFF_stack_offsets(A,H);

    % computing median (discounting nan elements)
    medA = CFF_nanfunc3('median',A_stack,3);

    % computing std (discounting nan elements)
    stdA = CFF_nanfunc3('std',A_stack,3);

    % find values to change. Keep nans as nans to not create data
    indchange = (abs(A - medA) > k.* stdA) & ~isnan(A) ; 

    % initialize output as input
    B = A;

    % replace values
    B(indchange) = medA(indchange);
    
    % for reloop
    A = B; 

end
