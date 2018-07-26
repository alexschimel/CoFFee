function CFF_inputparser_test(filename,varargin)
% CFF_inputparser_test(filename,varargin)
%
% DESCRIPTION
%
% Simple function to illustrate how inputParser works. Check comments
% inside function for details.
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
% 2015-09-29: first version.
%
% EXAMPLE
%
% example of valid calls:
% CFF_inputparser_test('myfile.jpg'); % filename is required argument, everything else optional and filled with defaults
% CFF_inputparser_test('myfile.jpg','glossy'); % first optional argument value can be given without specifying its name
% CFF_inputparser_test('myfile.jpg','finish','glossy'); % better practice is to give the argument name though. avoids confusion.
% CFF_inputparser_test('myfile.jpg','color','CMYK') % if not called in the right order, optional arguments NEED their argument name 
% CFF_inputparser_test('myfile.jpg','color','CMYK','finish','glossy') % if arg names are given, the order doesn't matter
% CFF_inputparser_test('myfile.jpg','color','CMYK','finish','matte') % other value for first optional arg
% CFF_inputparser_test('myfile.jpg','color','CMYK','finish','matte','width',5) % adding parameter arg
% CFF_inputparser_test('myfile.jpg','color','CMYK','width',5) % not all optionals args needed before calling parameter args
% CFF_inputparser_test('myfile.jpg','CMYK','glossy') % optional args not called in the right order, function uses default because given arg values don't correspond to set of valid arg values
% CFF_inputparser_test('myfile.jpg','glossy','CMYK') % optional args called in the right order, erverything works fine
% 
% % example of unvalid calls
% CFF_inputparser_test('myfile.jpg','satin') % The value of 'finish' is invalid 
% CFF_inputparser_test('myfile.jpg','finish','satin') % The value of 'finish' is invalid. 
% CFF_inputparser_test('myfile.jpg','color','satin') % The value of 'color' is invalid.
% CFF_inputparser_test('myfile.jpg','color','CMYK','finish','satin') % The value of 'finish' is invalid. 
% CFF_inputparser_test('myfile.jpg','color','CMYK','finish','matte',5) % Arg name not given
% CFF_inputparser_test('myfile.jpg','color','CMYK',5) % Arg name not given
%
%%%
% Alex Schimel, Deakin University
%%%


%% 1. Create an InputParser object.
p = inputParser;

% There are 3 types of input:

% 1.1. "required" inputs
% are positional. When you call a function with positional inputs, you must
% specify inputs in the order that they are added to the input parser
% scheme. 
% Use "addRequired", give name, and optional test for the type of input
% required.

addRequired(p,'filename',@ischar);

% 1.2. "optional" inputs
% are positional. When you call a function with positional inputs, you must
% specify inputs in the order that they are added to the input parser
% scheme.  Optional inputs only accept a set of possible valid values
% Setup the default value, the set of valid values and a check on valid
% values. Then use addOptional to the inputparser

defaultFinish = 'glossy';
validFinishes = {'glossy','matte'};
checkFinish = @(x) any(validatestring(x,validFinishes));
addOptional(p,'finish',defaultFinish,checkFinish)

defaultColor = 'RGB';
validColors = {'RGB','CMYK'};
checkColor = @(x) any(validatestring(x,validColors));
addOptional(p,'color',defaultColor,checkColor)

% 1.3. "parameters"
% call as pairs of variable name / value. Parameters can be anything within
% a type of values.
% Setup the default value, then use addParameter to the inputparser

defaultWidth = 6;
addParameter(p,'width',defaultWidth,@isnumeric)

defaultHeight = 4;
addParameter(p,'height',defaultHeight,@isnumeric)

% 1.4. finalizing
% Scalar logical value that indicates how to handle parameter name and
% value inputs that are not in the input scheme. 
% Possible values: false (0) throws an error whenever inputs are not in the
% scheme. true (1) stores the parameter names and values of unmatched
% inputs in the Unmatched property of the inputParser object, and suppress
% the error.n
p.KeepUnmatched = true ;


%% 2. parse inputs
% once the parser is properly setup, get the input values from varargin
parse(p,filename,varargin{:})


%% 3. display inputs
% finally, get the code to do its thing

% display extra inputs, values used as defaults, and the list of inputs
if ~isempty(fieldnames(p.Unmatched))
   disp('Extra inputs:')
   disp(p.Unmatched)
end
if ~isempty(p.UsingDefaults)
   disp('Using defaults:')
   disp(p.UsingDefaults)
end
disp(['File name: ',p.Results.filename])
disp(['Finish: ', p.Results.finish])
disp(['Color: ',p.Results.color])
disp(['Width: ', num2str(p.Results.width)])
disp(['Height: ', num2str(p.Results.height)])



