%% CFF_read_dlm_grid.m
%
% Read gridded data in a delimited text file format (X,Y,Value)
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |file|: Filename (usually with ".txt" or ".csv" extension but it doesn't matter)
%
% *OUTPUT VARIABLES*
%
% * |M|: TODO: write description and info on variable
% * |easting|: TODO: write description and info on variable
% * |northing|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% * I can foresee potential issues with the way the X or Y resolution is
% calculated in case the data is very sparse. Added a catch error in case
% this happens.
%
% *NEW FEATURES*
%
% * 2017-08-30: first version. Using CFF_weight_grid as inspiration (Alex Schimel).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function [M,easting,northing] = CFF_read_dlm_grid(file,varargin)

% dlmread the file
D = dlmread(file);

% get vectors and data
x = D(:,1);
y = D(:,2);
v = D(:,3);

% get details for x
xi_firstval = min(x);
xi_lastval = max(x);
unique_diff_x = unique(diff(unique(x)));
xi_step = unique_diff_x(1);
xi_numel = numel([xi_firstval:xi_step:xi_lastval]);

% get details for y
yi_firstval = min(y);
yi_lastval = max(y);
unique_diff_y = unique(diff(unique(y)));
yi_step = unique_diff_y(1);
yi_numel = numel([yi_firstval:yi_step:yi_lastval]);

% initialize matrix
vi = nan(yi_numel,xi_numel);

% fill in matrix
for ii = 1:length(v)
    if ~isnan(v(ii))
        
        % take value one by one
        thisx = x(ii);
        thisy = y(ii);
        thisv = v(ii);
        
        % find appropriate cell indices
        i_Yi = round(((thisy-yi_firstval)./yi_step)+1);
        i_Xi = round(((thisx-xi_firstval)./xi_step)+1);
        
        % add this value to appropriate cell. It should not be filled yet.
        % If it does, there was an issue in determining the X or Y vectors.
        if isnan(vi(i_Yi,i_Xi))
            vi(i_Yi,i_Xi) = thisv;
        else
            error;
        end
        
    end
end

M = vi;
easting = [xi_firstval:xi_step:xi_lastval];
northing = [yi_firstval:yi_step:yi_lastval];
[easting,northing] = meshgrid(easting,northing);

% note. it seems CFF_read_Asc results in files where largest values of
% Y/northing are at the TOP of the matrix, aka smallest indices. Meaning Y
% values decrease as we go through the rows.
% flipud the matrices for now. Change the code if confirmed later.

northing = flipud(northing);
M = flipud(M);
