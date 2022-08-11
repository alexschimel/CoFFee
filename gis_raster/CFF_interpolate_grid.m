function Zout = CFF_interpolate_grid(X,Y,Z,strel_size)
% Zout = CFF_interpolate_grid(X,Y,Z,strel_size)
%
% DESCRIPTION
%
% Interpolate depth image
%
% USE
%
% ...
%
% PROCESSING SUMMARY
% 
% - ...
% - ...
% - ...
%
% INPUT VARIABLES
%
% - varagin
%
% OUTPUT VARIABLES
%
% - NA
%
% RESEARCH NOTES
%
% - Using inpaint_nans (from John d'Erico, found on Mathworks).
%
% - This function separates the full dataset into smaller ones for
% interpolation. This allows not wasting time interpolating vast expenses
% of areas without data and avoid running out on memory (inpaint_nans is a
% glutton).
%
% - For later, build here my second approach idea of filling in cells with
% 8 neighbours, then 7, etc.
%
% NEW FEATURES
%
% 2014-10-13: first version.
%
% EXAMPLE
%
% ...
%
%%%
% Alex Schimel, Deakin University
%%%

% small grids parameters
nNo = 10;   % number of northing (rows) splits
nEa = 10;   % number of easting (columns) splits
extra = 10; % number of rows and columns of data we add to the split values
            % this allows the extrapolation process to take into account
            % extra data on the boundaries although the results past the
            % boundaries will be later discarded
            
% create the arrays containing the indices of each small grids
% (DTMminE, DTMmaxE, DTMminN, DTMmaxN):
N = ceil(length(Y)./nNo);
E = ceil(length(X)./nEa);

temp = [1:N:length(Y)]';
temp = temp*ones(1,nEa);
fine(:,1) = reshape(temp', size(temp,1).*size(temp,2),1);

temp = [1:N:length(Y)]'+N-1;
temp(end) = length(Y);
temp = temp*ones(1,nEa);
fine(:,2) = reshape(temp', size(temp,1).*size(temp,2),1);

temp = [1:E:length(X)]';
temp = temp*ones(1,nNo);
fine(:,3) = reshape(temp, size(temp,1).*size(temp,2),1);

temp = [1:E:length(X)]'+E-1;
temp(end) = length(X);
temp = temp*ones(1,nNo);
fine(:,4) = reshape(temp, size(temp,1).*size(temp,2),1);

% create the arrays containing the indices of each small grids + extra for
% the Interpolation
fine2 = fine;
fine2(:,1) = fine(:,1)-extra;
fine2(:,2) = fine(:,2)+extra;
fine2(:,3) = fine(:,3)-extra;
fine2(:,4) = fine(:,4)+extra;

fine2(fine2<1) = 1;
fine2(fine2(:,1)>length(Y),1) = length(Y);
fine2(fine2(:,2)>length(Y),2) = length(Y);
fine2(fine2(:,3)>length(X),3) = length(X);
fine2(fine2(:,4)>length(X),4) = length(X);


% initialize interpolated DTM
Z2 = nan(size(Z));

% interpolate small grids separately
for ii = 1:size(fine,1)
    
    % extract original data (patch+extra)
    patch = Z(fine2(ii,1):fine2(ii,2),fine2(ii,3):fine2(ii,4));
        
    a = find(sum(~isnan(patch)) ~=0);  % list of non-empty columns
    b = find(sum(~isnan(patch')) ~=0); % list of non-empty rows  
    
    % interpolate
    if ~isempty(a)
        % do only if patch is not completely empty
        
        indexcol = [a(1):a(end)];
        indexrow = [b(1):b(end)];

        temp = patch(indexrow,indexcol); % remove empty boundaries in patch
        InterpPatch = CFF_inpaint_nans(temp,4); % interpolate that, use method specified
        temp = -999.*ones(size(patch));
        temp(indexrow,indexcol) = InterpPatch;
        InterpPatch = temp; % reintroduce the empty boundaries              

    else
        % if patch was empty, just fill it with -999. Not NaNs because
        % after Interpolation, we have no NaNs left usually.
        InterpPatch = -999.*ones(size(patch));

    end
        
    % remove extra
    InterpPatch(:,end-(fine2(ii,4)-fine(ii,4))+1:end) = [];
    InterpPatch(:,1:fine(ii,3)-fine2(ii,3)) = [];
    InterpPatch(end-(fine2(ii,2)-fine(ii,2))+1:end,:) = [];
    InterpPatch(1:fine(ii,1)-fine2(ii,1),:) = [];
    
    % replace in new dataset
    Z2(fine(ii,1):fine(ii,2),fine(ii,3):fine(ii,4)) = InterpPatch;
    
end    

% remove -999 values
Z2(Z2==-999) = NaN;


%% MASK EXTRAPOLATION

% we use the "closing" morphological image processing operation to create a
% mask to remove the extrapolation of the previous processing step.

% adapt the structuring element to the size of the gaps to close
H = CFF_disk(strel_size); % structuring element

Mask = Z;
Mask(~isnan(Mask)) = 1;
Mask(isnan(Mask)) = 0;

% close
NewMask = CFF_imclose(Mask,H);

NewMask(NewMask==0) = NaN;

% apply Mask to interpolated DTM:
Zout = Z2.*NewMask;
