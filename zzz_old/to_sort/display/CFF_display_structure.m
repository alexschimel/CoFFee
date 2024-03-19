function displayStruct = CFF_display_structure(varargin)
%CFF_DISPLAY_STRUCTURE  One-line description
%
%   See also CFF_OTHER_FUNCTION_NAME.

%   Copyright 2017-2017 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

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
