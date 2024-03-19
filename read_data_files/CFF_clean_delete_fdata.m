function CFF_clean_delete_fdata(wc_dir)
%CFF_CLEAN_DELETE_FDATA  Delete a fData including all memmapped files
%

%   Copyright 2017-2021 Alexandre Schimel
%   Licensed under MIT. Details on https://github.com/alexschimel/CoFFee/

% if wc_dir does not exist, exit here
if ~isfolder(wc_dir)
    return
end

% if wc_dir exists but is empty, delete it and exit
flag_wc_dir_empty = CFF_is_folder_empty(wc_dir);
if flag_wc_dir_empty
    rmdir(wc_dir);
    return
end

% init flag indicating failure to delete a file
failFlag = 0;

% clean delete the fData if it exists
mat_fdata_file = fullfile(wc_dir,'fdata.mat');
if isfile(mat_fdata_file)
    
    % load fData
    fData = load(mat_fdata_file);
    
    % find all memmaped files linked in fData, save their location on the
    % drive, and remove the field to clear the link
    j = 0;
    dname = {};
    fields = fieldnames(fData);
    for ifi = 1:numel(fields)
        
        % init
        fieldname = fields{ifi};
        rmb = 0;
        
        if isa(fData.(fieldname),'memmapfile')
            % field is a memory-mapped file
            j = j+1;
            rmb = 1;
            dname{j} = fData.(fieldname).Filename;
            fData.(fieldname) = [];
            
        elseif iscell(fData.(fieldname))
            % field is a cell array, test each cell
            for ic = 1:numel(fData.(fieldname))
                if isa(fData.(fieldname){ic},'memmapfile')
                    % field is a memory-mapped file
                    j = j+1;
                    rmb = 1;
                    dname{j} = fData.(fieldname){ic}.Filename;
                    fData.(fieldname){ic} = [];
                end
            end
        end
        
        % remove memory-mapped fields
        if rmb > 0
            fData = rmfield(fData,fieldname);
        end
    end
    
    % next delete all memmaped files
    fclose('all');
    dname = unique(dname);
    for id = 1:numel(dname)
        if isfile(dname{id})
            try
                delete(dname{id});
            catch
                % if delete returns an error, it means the file is open
                % (should not happen with the fclose. Investigate).
                failFlag = 1;
            end
            if isfile(dname{id})
                % if delete didn't return an error but file still exists,
                % it means there is still a fData somwhere in memory with
                % the link active.
                failFlag = 2;
            end
        end
    end
    
    % delete fData
    try
        delete(mat_fdata_file);
    catch
        failFlag = 3;
    end
    
end

% There may be old memmaped files (.dat) left over in the folder, due to a
% prior failure to delete them. As commented above this happens when there
% is a fData somewhere in memory with the link active. We may try to delete
% them here
datFiles = dir([wc_dir filesep '**' filesep '*.dat']);
for ii = 1:numel(datFiles)
    filename = fullfile(datFiles(ii).folder, datFiles(ii).name);
    try
        delete(filename);
    catch
        failFlag = 4;
    end
end

% finally, delete the folder.
if ~CFF_is_folder_empty(wc_dir)
    failFlag = 5;
else
    try
        rmdir(wc_dir);
    catch
        failFlag = 6;
    end
end

% final message if failure, investigate using number
if failFlag
    fprintf('Warning - Could not completely delete contents of folder %s during fData clean-up.\n',wc_dir);
end

end