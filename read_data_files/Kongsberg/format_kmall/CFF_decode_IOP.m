function out_struct = CFF_decode_IOP(EMdgmIOP)

% read parameters, one datagram at a time
nD = numel(EMdgmIOP);
for iD = 1:nD
    % read runtime_txt, line by line
    lines = strsplit(EMdgmIOP(iD).runtime_txt,newline);
    for iL = 1:length(lines)
        line = lines{iL};
        if ~isempty(line)
            % find if line contains ":"
            idxSeparator = strfind(line,':');
            if isempty(idxSeparator)
                % new section starts
                % save section name by removing any space from line
                newSectionName = regexprep(matlab.lang.makeValidName(line,'ReplacementStyle','delete'),'_','');
            else
                % new key and value pair
                % split line into key and value
                key = regexprep(matlab.lang.makeValidName(line(1:idxSeparator-1),'ReplacementStyle','delete'),'_','');
                fullKey = [newSectionName key];
                val = strtrim(line(idxSeparator+2:end));
                % store in fData as a categorical
                out_struct.(fullKey)(iD) = categorical({val});
            end
        end
    end
end


end

