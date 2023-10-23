function out_struct = CFF_decode_IOP(EMdgmIOP)
%CFF_DECODE_IOP  Read the 'runtime_txt' field from kmall #IOP datagrams 
%
%   Reads and formats the parameters listed in the 'runtime_txt' field of
%   one or several #IOP datagrams from Kongsberg Maritime data in *.kmall
%   format.
%
%   See also CFF_KMALL_FILE_INFO, CFF_READ_KMALL_FROM_FILEINFO,
%   CFF_READ_KMALL.

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no)
%   2022-2023; Last revision: 23-10-2023

% initalize output
out_struct = struct();

% read parameters, one datagram at a time
nD = numel(EMdgmIOP);
for iD = 1:nD
    
    % initialize section name to empty
    newSectionName = '';  
    
    % read runtime_txt, line by line
    lines = strsplit(EMdgmIOP(iD).runtime_txt,newline);
    for iL = 1:length(lines)
        line = lines{iL};
        if isempty(line)
            % reset section name to empty
            newSectionName = '';
        else
            % find if line is a section title or a parameter
            isNewSection = ~contains(line,':') || strcmp(line, 'Water Column: On'); % Water Column is a special case - a section with a ":" in it
            if isNewSection
                % new section starts
                % save section name with no spaces or underscores
                newSectionName = regexprep(matlab.lang.makeValidName(line,'ReplacementStyle','delete'),'_','');
            else
                % new parameter
                
                % if the line is this, just ignore it as it does not follow
                % the normal "Section name followed by parameters" format,
                % plus it's already in the Depth Settings
                if strcmp(line,'Water Column: Off')
                    continue
                end
                
                % split line into key and value
                idxSeparator = strfind(line,':');
                key = regexprep(matlab.lang.makeValidName(line(1:idxSeparator-1),'ReplacementStyle','delete'),'_','');
                val = strtrim(line(idxSeparator+2:end));
                
                % get a unique full key name including section name if any
                if isempty(newSectionName)
                    fullKey = key;
                else
                    fullKey = [newSectionName '_' key];
                end
                
                % If this fullKey name already exists as a field in the
                % same datagram (it's the case for "Water column"), then
                % incremently add a number in the name until finding a new
                % unique key name
                iK = 1;
                while isfield(out_struct, fullKey) && ...
                        numel(out_struct.(fullKey)) >= iD && ...
                        ~isundefined(out_struct.(fullKey)(iD))
                    iK = iK+1;
                    fullKey = [newSectionName '_' key '_' num2str(iK)];
                end
                
                % store parameter in fData, with value as a categorical
                out_struct.(fullKey)(iD) = categorical({val});
                
            end
        end
    end
    
end

% when finished, make sure we have entries for all datagrams, aka add
% "undefined" if necessary
fns = fieldnames(out_struct);
for iF = 1:numel(fns) 
    fn = fns{iF};
    nEntr = numel(out_struct.(fn));
    out_struct.(fn)(nEntr+1:nD) = categorical({''});
end


end

