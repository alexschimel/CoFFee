function T = CFF_readtable(filename)
% T = CFF_readtable(filename)
%
% DESCRIPTION
%
% as Matlab's built-in function "readtable" but with a catch to be able to
% read tables exported from arcmap which might contain the delimiter  ','
% within individual fields identifed with double quotes. e.g.
% ID,Name,Height,Quote
% 0,'John',1.75,"normal text, with coma inside that makes readtable fail"
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
% filename = 'G:\temp1\01_Alex_Schimel\GIS\temp\Beach_polygon_vertices.txt';
% T1 = CFF_readtable(filename);
% filename = 'G:\temp1\01_Alex_Schimel\GIS\temp\test.txt';
% T2 = CFF_readtable(filename);
%
%
%%%
% Alex Schimel, Deakin University
%%%



try
    
    T = readtable(filename);
    
catch
    
    % open file
    fid = fopen(filename);
    
    % read header as cell array
    head = fscanf(fid,'%s',1);
    delimiter = ',';
    HEAD = textscan(head,'%s','Delimiter',delimiter);
    HEAD = HEAD{:}';
    
    % read contents as cell array, taking care of the issue of delimiter
    % within double quotes
    k = 0;
    while ~feof(fid)
        
        curr = fscanf(fid,'%s',1);
        
        if ~isempty(curr)
            
            % find double quotes
            b = strfind(curr,'"');
            b = reshape(b,2,[]);
            
            % identify delimiters that occur within double quotes
            a = strfind(curr,delimiter);
            for i=1:length(a)
                if all( sign(b(1,:)-a(i)) == sign(b(2,:)-a(i)) )
                    a(i) = NaN;
                end
            end
            a(isnan(a))=[];
            
            % remove them
            curr(a)= [];
            
            % add the result to contents as cell array
            k = k+1;
            temp = textscan(curr,'%s','Delimiter',',');
            CONTENTS(k,:) = temp{:}';
            
        end
    end
    
    % close fid
    fclose(fid);
    
    % put contents in proper format
    for i=1:numel(CONTENTS)
        a = strfind(CONTENTS{i},'"');
        if isempty(a)
            % numeric value, turn from string to numeric
            CONTENTS{i} = str2num(CONTENTS{i});
        else
            % string, remove the unecessary double quotes
            CONTENTS{i}(a) = [];
        end
    end
    
    % build table
    T = cell2table(CONTENTS,'VariableNames',HEAD);
    
end