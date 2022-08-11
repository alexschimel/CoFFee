function displayStruct = CFF_display_structure(varargin)
% displayStruct = CFF_display_structure(varargin)
%
% DESCRIPTION
%
% use as template for a new function
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
% ...
%
% NEW FEATURES
%
% YYYY-MM-DD: second version.
% YYYY-MM-DD: first version.
%
% EXAMPLE
%
%%%
% Alex Schimel, Deakin University
%%%

if nargin==0
    displayType = 'default-half-page';
elseif nargin==1
    displayType = varargin{1};
end

switch displayType
    
    case 'default-half-page'
        
        displayStruct.display = 1;
        displayStruct.print = 1;
        displayStruct.size = [8.75 8.75.*(2/3)];
        displayStruct.fontSize = 6;
        displayStruct.format = 'png';
        displayStruct.resolution = '600';
        displayStruct.filename = 'Figure_export';
        
    otherwise
        
end
