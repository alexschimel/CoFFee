function stepsize = CFF_get_vector_stepsize(vector)
% stepsize = CFF_get_vector_stepsize(vector)
%
% DESCRIPTION
%
% find stepsize of a vector
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

[C,ia,ic] = unique(diff(vector));

if numel(C)==1
    % perfectly regular grid. integer?
    
    stepsize = C(1);
    
elseif numel(C)==2
    % two values. very likely a floating point issue. Find the precision

    ii=1;
    while fix(C(2).*10.^ii) == fix(C(1).*10.^ii)
        ii=ii+1;
    end
    
    stepsize = round(C(1),ii);
        
else
    % more than two values? Not a regular grid? Force interpolation
    
    stepsize = C(1);
    
end