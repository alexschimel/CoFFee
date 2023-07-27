function out = CFF_getKM(KMALLdata, L1name, L1range, L2name, L2range, L3name, L3range)
% DEV NOTE: I hate that I have to code this. Data in KMALLdata are a mess
% to access because of my initial choice to do arrays of struct. I would
% need to change a lot to fix this, so in the meantime, here's a function
% to access data in them.


out = KMALLdata;

% get top field
if exist('L1name','var') && isfield(out,L1name)
    out = KMALLdata.(L1name);
    
    % limit top field range
    if exist('L1range','var') && ~isempty(L1range)
        out = out(L1range);
    end
    
    % get middle field
    if exist('L2name','var') && isfield(out,L2name)
        out = [out.(L2name)];
        
        % limit middle field range
        if exist('L2range','var') && ~isempty(L2range)
            out = out(L2range);
        end
        
        % get bottom field
        if exist('L3name','var') && isfield(out,L3name)
            out = [out.(L3name)];
            
            % limit bottom field range
            if exist('L3range','var') && ~isempty(L3range)
                out = out(L3range);
            end
        end
        
    end
    
end

end