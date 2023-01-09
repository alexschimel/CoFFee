% functions to copy in app.. needed 

% Initialize app's config file
function init_config_file(app)
if ~isfolder(fileparts(app.ConfigFile))
    % create folder
    mkdir(fileparts(app.ConfigFile));
end
if isfile(app.ConfigFile)
    % delete existing file
    delete(app.ConfigFile);
end
% initialize blank config file
fid = fopen(app.ConfigFile,'w');
fclose(fid);
end

% Get a field value from app's config file
function out = get_config_field(app,fieldName)
% init fail output
out = '';
if isfile(app.ConfigFile)
    % read config file
    configJSON = fileread(app.ConfigFile);
    if ~isempty(configJSON)
        % decode config file
        config = jsondecode(configJSON);
        if isfield(config,fieldName)
            % read field
            out = config.(fieldName);
        end
    end
end
end

% Set a field value in app's config file
function out = set_config_field(app,fieldName,fieldVal)
% init fail output
out = false;
if isfile(app.ConfigFile)
    % read config file
    configJSON = fileread(app.ConfigFile);
    if ~isempty(configJSON)
        % decode config file
        config = jsondecode(fileread(app.ConfigFile));
    else
        % inititate blank config
        config = struct();
    end
    % set value
    config.(fieldName) = fieldVal;
    % encode config
    configJSON = jsonencode(config);
    % rewrite config file
    fid = fopen(app.ConfigFile,'w');
    fprintf(fid,'%c',configJSON);
    fclose(fid);
    % success
    out = true;
end
end

% Check if a folder contains the CoFFee toolbox
function isCoffeeFolder = is_coffee_folder(~,folder)
% for now, we just test the existence of a folder and of the
% coffee version function
if isfolder(folder) && exist(fullfile(folder,'CFF_coffee_version.m'),'file')
    isCoffeeFolder = true;
else
    isCoffeeFolder = false;
end
end

% Get the CoFFee version from its folder
function coffeeVer = get_coffee_version(app,folder)
% first, check that it is a coffee folder
if ~is_coffee_folder(app,folder)
    coffeeVer = NaN;
    return
end
% get version of that coffee
curdir = cd;
cd(folder);
coffeeVer = CFF_coffee_version();
cd(curdir);
end

% Check if a CoFFee folder has the expected version
function isVersionOK = is_coffee_version(app,folder,coffeeVerWanted)
% first, check that it is a coffee folder
if ~is_coffee_folder(app,folder)
    isVersionOK = NaN;
    return
end
% next, get version of that coffee
coffeeVerActual = get_coffee_version(app,folder);
% finally, compare to expected version
if strcmp(coffeeVerActual,coffeeVerWanted)
    isVersionOK = true;
else
    isVersionOK = false;
end
end