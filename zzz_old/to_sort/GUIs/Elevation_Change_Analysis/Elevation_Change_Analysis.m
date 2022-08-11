function varargout = Elevation_Change_Analysis(varargin)
% ELEVATION_CHANGE_ANALYSIS MATLAB code for Elevation_Change_Analysis.fig
%      ELEVATION_CHANGE_ANALYSIS, by itself, creates a new ELEVATION_CHANGE_ANALYSIS or raises the existing
%      singleton*.
%
%      H = ELEVATION_CHANGE_ANALYSIS returns the handle to a new ELEVATION_CHANGE_ANALYSIS or the handle to
%      the existing singleton*.
%
%      ELEVATION_CHANGE_ANALYSIS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ELEVATION_CHANGE_ANALYSIS.M with the given input arguments.
%
%      ELEVATION_CHANGE_ANALYSIS('Property','Value',...) creates a new ELEVATION_CHANGE_ANALYSIS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Elevation_Change_Analysis_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Elevation_Change_Analysis_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Elevation_Change_Analysis

% Last Modified by GUIDE v2.5 28-Aug-2017 15:37:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Elevation_Change_Analysis_OpeningFcn, ...
    'gui_OutputFcn',  @Elevation_Change_Analysis_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Elevation_Change_Analysis is made visible.
function Elevation_Change_Analysis_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Elevation_Change_Analysis (see VARARGIN)

% Choose default command line output for Elevation_Change_Analysis
handles.output = hObject;

% % start session
txt = sprintf('%s - Change Analysis session',datestr(now));
set(handles.txt_out,'String',{txt});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Elevation_Change_Analysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Elevation_Change_Analysis_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pb_openDEM1.
function pb_openDEM1_Callback(hObject, eventdata, handles)
% hObject    handle to pb_openDEM1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'last_pathname')
    trythispath = handles.last_pathname;
else
    trythispath = [pwd filesep];
end

[file_name, path_name] = uigetfile({'*.txt','Delimited grid files (*.txt)'; ...
                                    '*.asc','ASCII grid files (*.asc)'; ...
                                    '*.tif;*.tiff','GeoTIF files (*.tif,*.tiff)' }, ...
                                    'select file for DEM 1',...
                                    trythispath);

if isequal(file_name,0)
    msgbox('Please try again!','Error!','Modal');
    errordlg('File not found','File Error');
    return;
end

asc_file1=[path_name file_name];

switch file_name(end-3:end)
    case '.asc'
        [DEM1,DEM1_X,DEM1_Y] = CFF_read_asc(asc_file1);
    case '.txt'
        [DEM1,DEM1_X,DEM1_Y] = CFF_read_dlm_grid(asc_file1);
    case {'.tif','tiff'}
        [DEM1,DEM1_X,DEM1_Y] = CFF_read_tif(asc_file1);
end

axes(handles.main_axes);

handles = guidata(hObject);
handles.DEM1 = DEM1;
handles.DEM1_X = DEM1_X;
handles.DEM1_Y = DEM1_Y;
handles.DEM1_cmin = min(handles.DEM1(:));
handles.DEM1_cmax = max(handles.DEM1(:));
handles.asc_file1 = asc_file1;
handles.dem1_filename = file_name;
handles.dem1_pathname = path_name;
handles.last_pathname = path_name;

% update file name and enable on gui
set(handles.text_DEM1,'string',file_name);
set(handles.text_DEM1,'Enable','on');

% enable display push button
set(handles.pb_display_DEM1,'Enable','on')

% enable coregister button
if isfield(handles,'DEM1') && isfield(handles,'DEM2')
    set(handles.pb_coregister_DEMs,'Enable','on');
end

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Opened DEM 1: %s',regexprep(asc_file1,'\','\\'));
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);

% force a display
pb_display_DEM1_Callback(hObject,[],handles);

function edt_dem1_dir_Callback(hObject, eventdata, handles)
% hObject    handle to edt_dem1_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edt_dem1_dir as text
%        str2double(get(hObject,'String')) returns contents of edt_dem1_dir as a double


% --- Executes during object creation, after setting all properties.
function edt_dem1_dir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_dem1_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edt_dem2_dir_Callback(hObject, eventdata, handles)
% hObject    handle to edt_dem2_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edt_dem2_dir as text
%        str2double(get(hObject,'String')) returns contents of edt_dem2_dir as a double


% --- Executes during object creation, after setting all properties.
function edt_dem2_dir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_dem2_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_openDEM2.
function pb_openDEM2_Callback(hObject, eventdata, handles)
% hObject    handle to pb_openDEM2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'last_pathname')
    trythispath = handles.last_pathname;
else
    trythispath = [pwd filesep];
end

[file_name, path_name] = uigetfile({'*.txt','Delimited grid files (*.txt)'; ...
                                    '*.asc','ASCII grid files (*.asc)'; ...
                                   '*.tif;*.tiff','GeoTIF files (*.tif,*.tiff)' }, ...
                                   'select file for DEM 2',...
                                   trythispath);

if isequal(file_name,0)
    msgbox('Please try again!','Error!','Modal');
    errordlg('File not found','File Error');
    return;
end

asc_file2=[path_name file_name];

switch file_name(end-3:end)
    case '.asc'
        [DEM2,DEM2_X,DEM2_Y] = CFF_read_asc(asc_file2);
    case '.txt'
        [DEM2,DEM2_X,DEM2_Y] = CFF_read_dlm_grid(asc_file2);
    case {'.tif','tiff'}
        [DEM2,DEM2_X,DEM2_Y] = CFF_read_tif(asc_file2);
end

axes(handles.main_axes);

handles=guidata(hObject);
handles.DEM2=DEM2;
handles.DEM2_X=DEM2_X;
handles.DEM2_Y=DEM2_Y;
handles.DEM2_cmin = min(handles.DEM2(:));
handles.DEM2_cmax = max(handles.DEM2(:));
handles.asc_file2=asc_file2;
handles.dem2_filename = file_name;
handles.dem2_pathname = path_name;
handles.last_pathname = path_name;

% update file name and enable on gui
set(handles.text_DEM2,'string',file_name);
set(handles.text_DEM2,'Enable','on')

% enable display push button
set(handles.pb_display_DEM2,'Enable','on')

% enable coregister button
if isfield(handles,'DEM1') && isfield(handles,'DEM2')
    set(handles.pb_coregister_DEMs,'Enable','on');
end

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Opened DEM 2: %s',regexprep(asc_file2,'\','\\'));
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);

% force a display
pb_display_DEM2_Callback(hObject,[],handles);


% --- Executes on button press in rad_DEM1.
function rad_DEM1_Callback(hObject, eventdata, handles)
% hObject    handle to rad_DEM1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rad_DEM1


% --- Executes on button press in rad_DEM2.
function rad_DEM2_Callback(hObject, eventdata, handles)
% hObject    handle to rad_DEM2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rad_DEM2


function edt_un1_dir_Callback(hObject, eventdata, handles)
% hObject    handle to edt_un1_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edt_un1_dir as text
%        str2double(get(hObject,'String')) returns contents of edt_un1_dir as a double


% --- Executes during object creation, after setting all properties.
function edt_un1_dir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_un1_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edt_un2_dir_Callback(hObject, eventdata, handles)
% hObject    handle to edt_un2_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edt_un2_dir as text
%        str2double(get(hObject,'String')) returns contents of edt_un2_dir as a double


% --- Executes during object creation, after setting all properties.
function edt_un2_dir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_un2_dir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_openUN1.
function pb_openUN1_Callback(hObject, eventdata, handles)
% hObject    handle to pb_openUN1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'last_pathname')
    trythispath = handles.last_pathname;
else
    trythispath = [pwd filesep];
end

[file_name, path_name] = uigetfile({'*.txt','Delimited grid files (*.txt)'; ...
                                    '*.asc','ASCII grid files (*.asc)'; ...
                                   '*.tif;*.tiff','GeoTIF files (*.tif,*.tiff)' }, ...
                                   'select file for UNC 1',...
                                   trythispath);

if isequal(file_name,0)
    msgbox('Please try again!','Error!','Modal');
    errordlg('File not found','File Error');
    return;
end

asc_file3=[path_name file_name];

switch file_name(end-3:end)
    case '.asc'
        [UNC1,UNC1_X,UNC1_Y] = CFF_read_asc(asc_file3);
    case '.txt'
        [UNC1,UNC1_X,UNC1_Y] = CFF_read_dlm_grid(asc_file3);
    case {'.tif','tiff'}
        [UNC1,UNC1_X,UNC1_Y] = CFF_read_tif(asc_file3);
end

axes(handles.main_axes);

handles=guidata(hObject);
handles.UNC1=UNC1;
handles.UNC1_X=UNC1_X;
handles.UNC1_Y=UNC1_Y;
handles.UNC1_cmin = min(handles.UNC1(:));
handles.UNC1_cmax = max(handles.UNC1(:));
handles.asc_file3=asc_file3;
handles.unc1_filename = file_name;
handles.unc1_pathname = path_name;
handles.last_pathname = path_name;

% update file name and enable on gui
set(handles.text_UNC1,'string',file_name,'Enable','on');

% enable drawpoly and select poly
set(handles.pb_drawpoly,'Enable','on');
set(handles.pb_select_poly,'Enable','on');

% enable display push button
set(handles.pb_display_UNC1,'Enable','on')

% enable coregister button
if isfield(handles,'UNC1') && isfield(handles,'UNC2')
    set(handles.pb_coregister_UNCs,'Enable','on');
end

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Opened spatially-variable uncertainty file 1 (UNC 1): %s',regexprep(asc_file3,'\','\\'));
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);

% force a display
pb_display_UNC1_Callback(hObject,[],handles);




% --- Executes on button press in pb_openUN2.
function pb_openUN2_Callback(hObject, eventdata, handles)
% hObject    handle to pb_openUN2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'last_pathname')
    trythispath = handles.last_pathname;
else
    trythispath = [pwd filesep];
end

[file_name, path_name] = uigetfile({'*.txt','Delimited grid files (*.txt)'; ...
                                    '*.asc','ASCII grid files (*.asc)'; ...
                                   '*.tif;*.tiff','GeoTIF files (*.tif,*.tiff)' }, ...
                                   'select file for UNC 2',...
                                   trythispath);

if isequal(file_name,0)
    msgbox('Please try again!','Error!','Modal');
    errordlg('File not found','File Error');
    return;
end

asc_file4=[path_name file_name];

switch file_name(end-3:end)
    case '.asc'
        [UNC2,UNC2_X,UNC2_Y] = CFF_read_asc(asc_file4);
    case '.txt'
        [UNC2,UNC2_X,UNC2_Y] = CFF_read_dlm_grid(asc_file4);
    case {'.tif','tiff'}
        [UNC2,UNC2_X,UNC2_Y] = CFF_read_tif(asc_file4);
end

axes(handles.main_axes);

handles=guidata(hObject);
handles.UNC2=UNC2;
handles.UNC2_X=UNC2_X;
handles.UNC2_Y=UNC2_Y;
handles.UNC2_cmin = min(handles.UNC2(:));
handles.UNC2_cmax = max(handles.UNC2(:));
handles.asc_file4=asc_file4;
handles.unc2_filename = file_name;
handles.unc2_pathname = path_name;
handles.last_pathname = path_name;

% update file name and enable on gui
set(handles.text_UNC2,'string',file_name,'Enable','on');

% enable display push button
set(handles.pb_display_UNC2,'Enable','on')

% enable coregister button
if isfield(handles,'UNC1') && isfield(handles,'UNC2')
    set(handles.pb_coregister_UNCs,'Enable','on');
end

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Opened spatially-variable uncertainty file 2 (UNC 2): %s',regexprep(asc_file4,'\','\\'));
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);

% force a display
pb_display_UNC2_Callback(hObject,[],handles);


function edt_fixed_uncertainty_Callback(hObject, eventdata, handles)
% hObject    handle to edt_fixed_uncertainty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edt_fixed_uncertainty as text
%        str2double(get(hObject,'String')) returns contents of edt_fixed_uncertainty as a double


% --- Executes during object creation, after setting all properties.
function edt_fixed_uncertainty_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_fixed_uncertainty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_reset.
function pb_reset_Callback(hObject, eventdata, handles)
% hObject    handle to pb_reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% close
close(gcbf)

% restart
Elevation_Change_Analysis



function edt_multiplying_factor_Callback(hObject, eventdata, handles)
% hObject    handle to edt_multiplying_factor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edt_multiplying_factor as text
%        str2double(get(hObject,'String')) returns contents of edt_multiplying_factor as a double


% --- Executes during object creation, after setting all properties.
function edt_multiplying_factor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_multiplying_factor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_drawpoly.
function pb_drawpoly_Callback(hObject, eventdata, handles)
% hObject    handle to pb_drawpoly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% clear existing poly
if isfield(handles,'h')
    delete(handles.h);
    handles = rmfield(handles,'h');
end

% create polygon
handles.h = impoly;

if ~isempty(handles.h)
    
    % impoly created
    
    % enable clear and clip
    set(handles.pb_clear_poly,'Enable','on');
    set(handles.pb_clip_rasters_to_poly,'Enable','on');
    
    % get current position of vertices
    pos = getPosition(handles.h);
    
    % update txt_out
    txt = get(handles.txt_out,'String');
    txt{end+1} = sprintf('- Drew new polygon with vertices (X,Y):');
    for ii = 1:size(pos,1)
        txt{end+1} = sprintf('-- %f,%f',pos(ii,1),pos(ii,2));
    end
    set(handles.txt_out,'String',txt);
    handles.txt_out.ListboxTop = length(txt); % force listbox to end
    handles.txt_out.Value = length(txt); % force listbox to end
    
else
    
    % impoly not completed
    delete(handles.h);
    handles = rmfield(handles,'h');
    
end

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_\n- .
function pb_vol_Callback(hObject, eventdata, handles)
% hObject    handle to pb_vol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab data
DOD = handles.DOD;
X = handles.DOD_X;
Y = handles.DOD_Y;
LOD = handles.LOD;
if handles.rb_fixed_uncertainty.Value
    UNC = str2num(get(handles.edt_fixed_uncertainty,'String'));
elseif handles.rb_variable_uncertainty.Value
    UNC = handles.DPU;
end

% if there's a polygon, clip the data further:
if isfield(handles,'h')
    
    % Construct a questdlg with three options
    choice = questdlg(sprintf('This project includes a polygon.\nDo you want to run the Change Analysis on the area delimited by the polygon, or on the full current dataset?'), ...
        'Change Analysis', ...
        'Polygon Only','Full Current Dataset','Cancel','Polygon Only');
    
    % Handle response
    switch choice
        case 'Full Current Dataset'
            
            h1 = waitbar(100,'Running Change Analysis on Full Current Dataset. Please wait.','Name','Change Analysis');
            
            % volume calculations:
            volumes = CFF_LOD_volumes(DOD,X,Y,LOD,UNC);
            
            % update txt_out
            txt = get(handles.txt_out,'String');
            txt{end+1} = sprintf('- Analyzed change on full current dataset. Results:');
            
        case 'Polygon Only'
            
            h1 = waitbar(100,'Running Change Analysis on polygon area. Please wait.','Name','Change Analysis');
            
            % get poly position
            pos = getPosition(handles.h);
            xv = pos(:,1);
            yv = pos(:,2);
            
            % clip rasters
            if size(LOD,1) > 1
                LOD = CFF_clip_raster(LOD,X,Y,xv,yv);
            end
            if size(UNC,1) > 1
                UNC = CFF_clip_raster(UNC,X,Y,xv,yv);
            end
            [DOD,X,Y] = CFF_clip_raster(DOD,X,Y,xv,yv);
            
            % volume calculations:
            volumes = CFF_LOD_volumes(DOD,X,Y,LOD,UNC);
            
            % update txt_out
            txt = get(handles.txt_out,'String');
            txt{end+1} = sprintf('- Analyzed change on area delimited by polygon with vertices (X,Y):');
            for ii = 1:size(pos,1)
                txt{end+1} = sprintf('-- %f,%f',pos(ii,1),pos(ii,2));
            end
            txt{end+1} = sprintf('-- Analysis results:');
            
        case 'Cancel'
            
            return
            
    end
    
else
    
    h1 = waitbar(100,'Running Change Analysis on full current dataset. Please wait.','Name','Change Analysis');
    
    % volume calculations:
    volumes = CFF_LOD_volumes(DOD,X,Y,LOD,UNC);
    
    % update txt_out
    txt = get(handles.txt_out,'String');
    txt{end+1} = sprintf('- Analyzed change on full current dataset. Results:');
    
end

% some more update txt_out
txt{end+1} = sprintf('-- Total area considered: %g m^2',volumes.areaTotal);
txt{end+1} = sprintf('-- Total area experiencing change (deposition or erosion above LOD): %g m^2 (~%.2f%% of total area)',volumes.areaTotalChange, volumes.areaTotalChange.*100./volumes.areaTotal);

txt{end+1} = sprintf('-- Area experiencing erosion above LOD: %g m^2 (~%.2f%% of total area)',                             volumes.areaEroded,      volumes.areaEroded.*100./volumes.areaTotal);
txt{end+1} = sprintf('-- Volume eroded: %g m^3',volumes.volumeEroded);
txt{end+1} = sprintf('-- Uncertainty for volume eroded (propagated in sum): ±%g m^3',volumes.uncertaintyVolumeEroded_sum);
txt{end+1} = sprintf('-- Uncertainty for volume eroded (propagated in quadrature): ±%g m^3',volumes.uncertaintyVolumeEroded_propagated);

txt{end+1} = sprintf('-- Area experiencing deposition above LOD: %g m^2 (~%.2f%% of total area)',                          volumes.areaDeposited,   volumes.areaDeposited.*100./volumes.areaTotal);
txt{end+1} = sprintf('-- Volume deposited: %g m^3',volumes.volumeDeposited);
txt{end+1} = sprintf('-- Uncertainty for volume deposited (propagated in sum): ±%g m^3',volumes.uncertaintyVolumeDeposited_sum);
txt{end+1} = sprintf('-- Uncertainty for volume deposited (propagated in quadrature): ±%g m^3',volumes.uncertaintyVolumeDeposited_propagated);

txt{end+1} = sprintf('-- Volume net change (net deposition if positive): %g m^3',volumes.volumeNetChange);

set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

close(h1);

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_select_poly.
function pb_select_poly_Callback(hObject, eventdata, handles)
% hObject    handle to pb_select_poly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'last_pathname')
    trythispath = handles.last_pathname;
else
    trythispath = [pwd filesep];
end

% prompt for file
[file_name, path_name] = uigetfile({'*.shp';'*.txt'},'select file for polygon',trythispath);

if isequal(file_name,0)
    msgbox('Please try again!','Error!','Modal');
    errordlg('File not found','File Error');
    return;
end

poly_file = [path_name file_name];

if any( strcmp(poly_file(end-3:end), {'.txt','.csv'}) )
    pos = dlmread(poly_file);
elseif strcmp(poly_file(end-3:end), '.shp')
    P = shaperead(poly_file); % needs mapping toolbox
    c = length(P); % number of polygons
    xpoly = cell(c,1); % preallocating
    ypoly = cell(c,1); % preallocating
    for ii= 1:c
        xpoly{ii,1} = P(ii).X;
        ypoly{ii,1} = P(ii).Y;
    end
    pos = [xpoly{1}',ypoly{1}'];
    pos(isnan(pos(:,1)),:)=[];
    pos(end,:)=[];
end

% clear existing poly
if isfield(handles,'h')
    delete(handles.h);
    handles = rmfield(handles,'h');
    handles = rmfield(handles,'pos');
end

% create new poly
handles.h = impoly(gca,pos);
setVerticesDraggable(handles.h,'True')

% enable clear and clip
set(handles.pb_clear_poly,'Enable','on');
set(handles.pb_clip_rasters_to_poly,'Enable','on');

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Loaded new polygon from file %s, with vertices (X,Y):',regexprep(poly_file,'\','\\'));
for ii = 1:size(pos,1)
    txt{end+1} = sprintf('-- %f,%f',pos(ii,1),pos(ii,2));
end
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_clear_poly.
function pb_clear_poly_Callback(hObject, eventdata, handles)
% hObject    handle to pb_clear_poly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% clear existing poly
delete(handles.h);
handles = rmfield(handles,'h');

% disable clear and clip
set(handles.pb_clear_poly,'Enable','Off');
set(handles.pb_clip_rasters_to_poly,'Enable','Off');

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Cleared polygon');
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_exit.
function pb_exit_Callback(hObject, eventdata, handles)
% hObject    handle to pb_exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% close
close;


% --- Executes on button press in pb_display_DEM1.
function pb_display_DEM1_Callback(hObject, eventdata, handles)
% hObject    handle to pb_display_DEM1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

axes(handles.main_axes);

% if polygon exists, save it before changing the display
if isfield(handles,'h')
    pos = getPosition(handles.h);
end

x = handles.DEM1_X(1,:);
y = handles.DEM1_Y(:,1);
M = handles.DEM1;
c(1) = handles.DEM1_cmin;
c(2) = handles.DEM1_cmax;

imagesc(x,y,M);
alpha(double(~isnan(M)));

axis xy
if isfield(handles,'axis')
    axis(handles.axis);
else
    axis equal
    daspect([1,1,1]);
end

grid on
colorbar
caxis(c);
set(gca, 'XTickLabel', num2str(get(gca, 'XTick')'));
set(gca,'XTickLabelRotation',45);
set(gca, 'YTickLabel', num2str(get(gca, 'YTick')'));

% if polygon existed, re-create it now
if exist('pos','var')
    handles.h = impoly(gca,pos);
end

% record which data is currently on display
handles.data_currently_displayed = 'DEM1';
title(handles.data_currently_displayed);

% enable stats button
set(handles.pb_stats,'Enable','on');

% enable and update caxis edit boxes
set(handles.edt_min,'String',c(1),'Enable','on');
set(handles.edt_max,'String',c(2),'Enable','on');
set(handles.pb_reset_colorbar,'Enable','on');

% enable drawpoly and select poly
set(handles.pb_drawpoly,'Enable','on');
set(handles.pb_select_poly,'Enable','on');

% Update handles structure
guidata(hObject,handles);

% --- Executes on button press in pb_display_DEM2.
function pb_display_DEM2_Callback(hObject, eventdata, handles)
% hObject    handle to pb_display_DEM2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if polygon exists, save it before changing the display
if isfield(handles,'h')
    pos = getPosition(handles.h);
end

x = handles.DEM2_X(1,:);
y = handles.DEM2_Y(:,1);
M = handles.DEM2;
c(1) = handles.DEM2_cmin;
c(2) = handles.DEM2_cmax;

axes(handles.main_axes);
imagesc(x,y,M);
alpha(double(~isnan(M)));
    
axis xy
if isfield(handles,'axis')
    axis(handles.axis);
else
    axis equal
    daspect([1,1,1]);
end

grid on
colorbar
caxis(c);
set(gca, 'XTickLabel', num2str(get(gca, 'XTick')'));
set(gca,'XTickLabelRotation',45);
set(gca, 'YTickLabel', num2str(get(gca, 'YTick')'));

% if polygon existed, re-create it now
if exist('pos','var')
    handles.h = impoly(gca,pos);
end

% record which data is currently on display
handles.data_currently_displayed = 'DEM2';
title(handles.data_currently_displayed);

% enable stats button
set(handles.pb_stats,'Enable','on');

% enable and update caxis edit boxes
set(handles.edt_min,'String',c(1),'Enable','on');
set(handles.edt_max,'String',c(2),'Enable','on');
set(handles.pb_reset_colorbar,'Enable','on');

% enable drawpoly and select poly
set(handles.pb_drawpoly,'Enable','on');
set(handles.pb_select_poly,'Enable','on');

% Update handles structure
guidata(hObject,handles);

% --- Executes on button press in pb_coregister_DEMs.
function pb_coregister_DEMs_Callback(hObject, eventdata, handles)
% hObject    handle to pb_coregister_DEMs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab data from handles
Z1 = handles.DEM1;
Z1_easting = handles.DEM1_X;
Z1_northing = handles.DEM1_Y;
Z2 = handles.DEM2;
Z2_easting = handles.DEM2_X;
Z2_northing = handles.DEM2_Y;

% coregister grids
[Z1,Z2,X,Y] = CFF_coregister_rasters(Z1,Z1_easting,Z1_northing,Z2,Z2_easting,Z2_northing);

% update data
handles.DEM1 = Z1;
handles.DEM1_X = X;
handles.DEM1_Y = Y;
handles.DEM1_cmin = min(handles.DEM1(:));
handles.DEM1_cmax = max(handles.DEM1(:));
handles.DEM2 = Z2;
handles.DEM2_X = X;
handles.DEM2_Y = Y;
handles.DEM2_cmin = min(handles.DEM2(:));
handles.DEM2_cmax = max(handles.DEM2(:));

% enable calculate DOD push button
set(handles.pb_calculate_DOD,'Enable','on')

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Coregistered DEMs');
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);

% force display update
switch handles.data_currently_displayed
    case 'DEM1'
        pb_display_DEM1_Callback(hObject,[],handles);
    case 'DEM2'
        pb_display_DEM2_Callback(hObject,[],handles);
    case 'DOD'
        pb_display_DOD_Callback(hObject,[],handles);
    case 'UNC1'
        pb_display_UNC1_Callback(hObject,[],handles);
    case 'UNC2'
        pb_display_UNC2_Callback(hObject,[],handles);
    case 'DPU'
        pb_display_DPU_Callback(hObject,[],handles);
    case 'LOD'
        pb_display_LOD_Callback(hObject,[],handles);
    otherwise
end



% --- Executes on button press in pb_display_DOD.
function pb_display_DOD_Callback(hObject, eventdata, handles)
% hObject    handle to pb_display_DOD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if polygon exists, save it before changing the display
if isfield(handles,'h')
    pos = getPosition(handles.h);
end

x = handles.DOD_X(1,:);
y = handles.DOD_Y(:,1);
M = handles.DOD;
c(1) = handles.DOD_cmin;
c(2) = handles.DOD_cmax;

axes(handles.main_axes);
imagesc(x,y,M);
alpha(double(~isnan(M)));

axis xy
if isfield(handles,'axis')
    axis(handles.axis);
else
    axis equal
    daspect([1,1,1]);
end

grid on
colorbar
caxis(c);
set(gca, 'XTickLabel', num2str(get(gca, 'XTick')'));
set(gca,'XTickLabelRotation',45);
set(gca, 'YTickLabel', num2str(get(gca, 'YTick')'));

% if polygon existed, re-create it now
if exist('pos','var')
    handles.h = impoly(gca,pos);
end

% record which data is currently on display
handles.data_currently_displayed = 'DOD';
title(handles.data_currently_displayed);

% enable stats button
set(handles.pb_stats,'Enable','on');

% enable and update caxis edit boxes
set(handles.edt_min,'String',c(1),'Enable','on');
set(handles.edt_max,'String',c(2),'Enable','on');
set(handles.pb_reset_colorbar,'Enable','on');

% enable drawpoly and select poly
set(handles.pb_drawpoly,'Enable','on');
set(handles.pb_select_poly,'Enable','on');

% Update handles structure
guidata(hObject,handles);



function edit_DOD_Callback(hObject, eventdata, handles)
% hObject    handle to edit_DOD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit_DOD as text
%        str2double(get(hObject,'String')) returns contents of edit_DOD as a double


% --- Executes during object creation, after setting all properties.
function edit_DOD_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_DOD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_calculate_DOD.
function pb_calculate_DOD_Callback(hObject, eventdata, handles)
% hObject    handle to pb_calculate_DOD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% grab data from handles
Z1 = handles.DEM1;
Z2 = handles.DEM2;

% create dod from grids
DOD = CFF_calculate_DOD(Z1,Z2);
handles.DOD = DOD;
handles.DOD_X = handles.DEM1_X;
handles.DOD_Y = handles.DEM1_Y;
handles.DOD_cmin = min(handles.DOD(:));
handles.DOD_cmax = max(handles.DOD(:));

% enable display push button
set(handles.pb_display_DOD,'Enable','on')

% enable DOD&DPU coregister button
if isfield(handles,'DOD') && isfield(handles,'DPU')
    set(handles.pb_coregister_DOD_and_DPU,'Enable','on');
end

% enable volume calculation if we have DOD and LOD
if isfield(handles,'DOD') && isfield(handles,'LOD')
    set(handles.pb_vol,'Enable','on');
end

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Calculated difference between DEMs (DOD)');
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end



% Update handles structure
guidata(hObject,handles);

% force a display
pb_display_DOD_Callback(hObject,[],handles);



% --- Executes on button press in pb_display_UNC1.
function pb_display_UNC1_Callback(hObject, eventdata, handles)
% hObject    handle to pb_display_UNC1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if polygon exists, save it before changing the display
if isfield(handles,'h')
    pos = getPosition(handles.h);
end

x = handles.UNC1_X(1,:);
y = handles.UNC1_Y(:,1);
M = handles.UNC1;
c(1) = handles.UNC1_cmin;
c(2) = handles.UNC1_cmax;

axes(handles.main_axes);
imagesc(x,y,M);
alpha(double(~isnan(M)));

axis xy
if isfield(handles,'axis')
    axis(handles.axis);
else
    axis equal
    daspect([1,1,1]);
end

grid on
colorbar
caxis(c);
set(gca, 'XTickLabel', num2str(get(gca, 'XTick')'));
set(gca,'XTickLabelRotation',45);
set(gca, 'YTickLabel', num2str(get(gca, 'YTick')'));

% if polygon existed, re-create it now
if exist('pos','var')
    handles.h = impoly(gca,pos);
end

% record which data is currently on display
handles.data_currently_displayed = 'UNC1';
title(handles.data_currently_displayed);

% enable stats button
set(handles.pb_stats,'Enable','on');

% enable and update caxis edit boxes
set(handles.edt_min,'String',c(1),'Enable','on');
set(handles.edt_max,'String',c(2),'Enable','on');
set(handles.pb_reset_colorbar,'Enable','on');

% enable drawpoly and select poly
set(handles.pb_drawpoly,'Enable','on');
set(handles.pb_select_poly,'Enable','on');

% Update handles structure
guidata(hObject,handles);



% --- Executes on button press in pb_display_UNC2.
function pb_display_UNC2_Callback(hObject, eventdata, handles)
% hObject    handle to pb_display_UNC2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if polygon exists, save it before changing the display
if isfield(handles,'h')
    pos = getPosition(handles.h);
end

x = handles.UNC2_X(1,:);
y = handles.UNC2_Y(:,1);
M = handles.UNC2;
c(1) = handles.UNC2_cmin;
c(2) = handles.UNC2_cmax;

axes(handles.main_axes);
imagesc(x,y,M);
alpha(double(~isnan(M)));

axis xy
if isfield(handles,'axis')
    axis(handles.axis);
else
    axis equal
    daspect([1,1,1]);
end

grid on
colorbar
caxis(c);
set(gca, 'XTickLabel', num2str(get(gca, 'XTick')'));
set(gca,'XTickLabelRotation',45);
set(gca, 'YTickLabel', num2str(get(gca, 'YTick')'));

% if polygon existed, re-create it now
if exist('pos','var')
    handles.h = impoly(gca,pos);
end

% record which data is currently on display
handles.data_currently_displayed = 'UNC2';
title(handles.data_currently_displayed);

% enable stats button
set(handles.pb_stats,'Enable','on');

% enable and update caxis edit boxes
set(handles.edt_min,'String',c(1),'Enable','on');
set(handles.edt_max,'String',c(2),'Enable','on');
set(handles.pb_reset_colorbar,'Enable','on');

% enable drawpoly and select poly
set(handles.pb_drawpoly,'Enable','on');
set(handles.pb_select_poly,'Enable','on');

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_clip_rasters_to_poly.
function pb_clip_rasters_to_poly_Callback(hObject, eventdata, handles)
% hObject    handle to pb_clip_rasters_to_poly (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get poly position
pos = getPosition(handles.h);
xv = pos(:,1);
yv = pos(:,2);

% clear poly
delete(handles.h);
handles = rmfield(handles,'h');

% clip rasters
if isfield(handles,'DEM1')
    [handles.DEM1,handles.DEM1_X,handles.DEM1_Y] = CFF_clip_raster(handles.DEM1,handles.DEM1_X,handles.DEM1_Y,xv,yv);
    handles.DEM1_cmin = min(handles.DEM1(:));
    handles.DEM1_cmax = max(handles.DEM1(:));
end
if isfield(handles,'DEM2')
    [handles.DEM2,handles.DEM2_X,handles.DEM2_Y] = CFF_clip_raster(handles.DEM2,handles.DEM2_X,handles.DEM2_Y,xv,yv);
    handles.DEM2_cmin = min(handles.DEM2(:));
    handles.DEM2_cmax = max(handles.DEM2(:));
end
if isfield(handles,'DOD')
    [handles.DOD,handles.DOD_X,handles.DOD_Y] = CFF_clip_raster(handles.DOD,handles.DOD_X,handles.DOD_Y,xv,yv);
    handles.DOD_cmin = min(handles.DOD(:));
    handles.DOD_cmax = max(handles.DOD(:));
end
if isfield(handles,'UNC1')
    [handles.UNC1,handles.UNC1_X,handles.UNC1_Y] = CFF_clip_raster(handles.UNC1,handles.UNC1_X,handles.UNC1_Y,xv,yv);
    handles.UNC1_cmin = min(handles.UNC1(:));
    handles.UNC1_cmax = max(handles.UNC1(:));
end
if isfield(handles,'UNC2')
    [handles.UNC2,handles.UNC2_X,handles.UNC2_Y] = CFF_clip_raster(handles.UNC2,handles.UNC2_X,handles.UNC2_Y,xv,yv);
    handles.UNC2_cmin = min(handles.UNC2(:));
    handles.UNC2_cmax = max(handles.UNC2(:));
end
if isfield(handles,'DPU')
    [handles.DPU,handles.DPU_X,handles.DPU_Y] = CFF_clip_raster(handles.DPU,handles.DPU_X,handles.DPU_Y,xv,yv);
    handles.DPU_cmin = min(handles.DPU(:));
    handles.DPU_cmax = max(handles.DPU(:));
end
if isfield(handles,'LOD_X') % because if fixed, LOD exists but not LOD_x
    [handles.LOD,handles.LOD_X,handles.LOD_Y] = CFF_clip_raster(handles.LOD,handles.LOD_X,handles.LOD_Y,xv,yv);
    handles.LOD_cmin = min(handles.LOD(:));
    handles.LOD_cmax = max(handles.LOD(:));
end

% force display update
switch handles.data_currently_displayed
    case 'DEM1'
        pb_display_DEM1_Callback(hObject,[],handles);
    case 'DEM2'
        pb_display_DEM2_Callback(hObject,[],handles);
    case 'DOD'
        pb_display_DOD_Callback(hObject,[],handles);
    case 'UNC1'
        pb_display_UNC1_Callback(hObject,[],handles);
    case 'UNC2'
        pb_display_UNC2_Callback(hObject,[],handles);
    case 'DPU'
        pb_display_DPU_Callback(hObject,[],handles);
    case 'LOD'
        pb_display_LOD_Callback(hObject,[],handles);
    otherwise
end

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Clipped all rasters to polygon with vertices (X,Y):');
for ii = 1:size(pos,1)
    txt{end+1} = sprintf('-- %f,%f',pos(ii,1),pos(ii,2));
end
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% disable clear and clip
set(handles.pb_clear_poly,'Enable','Off');
set(handles.pb_clip_rasters_to_poly,'Enable','Off');

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_coregister_UNCs.
function pb_coregister_UNCs_Callback(hObject, eventdata, handles)
% hObject    handle to pb_coregister_UNCs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab data from handles
U1 = handles.UNC1;
U1_easting = handles.UNC1_X;
U1_northing = handles.UNC1_Y;
U2 = handles.UNC2;
U2_easting = handles.UNC2_X;
U2_northing = handles.UNC2_Y;

% coregister grids
[U1,U2,X,Y] = CFF_coregister_rasters(U1,U1_easting,U1_northing,U2,U2_easting,U2_northing);

% update data
handles.UNC1 = U1;
handles.UNC1_X = X;
handles.UNC1_Y = Y;
handles.UNC1_cmin = min(handles.UNC1(:));
handles.UNC1_cmax = max(handles.UNC1(:));
handles.UNC2 = U2;
handles.UNC2_X = X;
handles.UNC2_Y = Y;
handles.UNC2_cmin = min(handles.UNC2(:));
handles.UNC2_cmax = max(handles.UNC2(:));

% enable calculate DPU push button
set(handles.pb_calculate_DPU,'Enable','on')

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Coregistered uncertainty rasters');
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);

% force display update
switch handles.data_currently_displayed
    case 'DEM1'
        pb_display_DEM1_Callback(hObject,[],handles);
    case 'DEM2'
        pb_display_DEM2_Callback(hObject,[],handles);
    case 'DOD'
        pb_display_DOD_Callback(hObject,[],handles);
    case 'UNC1'
        pb_display_UNC1_Callback(hObject,[],handles);
    case 'UNC2'
        pb_display_UNC2_Callback(hObject,[],handles);
    case 'DPU'
        pb_display_DPU_Callback(hObject,[],handles);
    case 'LOD'
        pb_display_LOD_Callback(hObject,[],handles);
    otherwise
end




% --- Executes on button press in pb_calculate_DPU.
function pb_calculate_DPU_Callback(hObject, eventdata, handles)
% hObject    handle to pb_calculate_DPU (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab data from handles
U1 = handles.UNC1;
U2 = handles.UNC2;

% create DPU from grids
DPU = CFF_calculate_DPU(U1,U2);
handles.DPU = DPU;
handles.DPU_X = handles.UNC1_X;
handles.DPU_Y = handles.UNC1_Y;
handles.DPU_cmin = min(handles.DPU(:));
handles.DPU_cmax = max(handles.DPU(:));

% enable display push button
set(handles.pb_display_DPU,'Enable','on')

% enable DOD&DPU coregister button
if isfield(handles,'DOD') && isfield(handles,'DPU')
    set(handles.pb_coregister_DOD_and_DPU,'Enable','on');
end

% enable choice in LOD
set(handles.rb_fixed_uncertainty,'Enable','on');
set(handles.rb_variable_uncertainty,'Enable','on');

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Calculated combined uncertainty raster (DPU)');
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);

% force a display
pb_display_DPU_Callback(hObject,[],handles);


% --- Executes on button press in pb_display_DPU.
function pb_display_DPU_Callback(hObject, eventdata, handles)
% hObject    handle to pb_display_DPU (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if polygon exists, save it before changing the display
if isfield(handles,'h')
    pos = getPosition(handles.h);
end

x = handles.DPU_X(1,:);
y = handles.DPU_Y(:,1);
M = handles.DPU;
c(1) = handles.DPU_cmin;
c(2) = handles.DPU_cmax;

axes(handles.main_axes);
imagesc(x,y,M);
alpha(double(~isnan(M)));

axis xy
if isfield(handles,'axis')
    axis(handles.axis);
else
    axis equal
    daspect([1,1,1]);
end

grid on
colorbar
caxis(c);
set(gca, 'XTickLabel', num2str(get(gca, 'XTick')'));
set(gca,'XTickLabelRotation',45);
set(gca, 'YTickLabel', num2str(get(gca, 'YTick')'));

% if polygon existed, re-create it now
if exist('pos','var')
    handles.h = impoly(gca,pos);
end

% record which data is currently on display
handles.data_currently_displayed = 'DPU';
title(handles.data_currently_displayed);

% enable stats button
set(handles.pb_stats,'Enable','on');

% enable and update caxis edit boxes
set(handles.edt_min,'String',c(1),'Enable','on');
set(handles.edt_max,'String',c(2),'Enable','on');
set(handles.pb_reset_colorbar,'Enable','on');

% enable drawpoly and select poly
set(handles.pb_drawpoly,'Enable','on');
set(handles.pb_select_poly,'Enable','on');

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_coregister_DOD_and_DPU.
function pb_coregister_DOD_and_DPU_Callback(hObject, eventdata, handles)
% hObject    handle to pb_coregister_DOD_and_DPU (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab data from handles
DOD = handles.DOD;
DOD_X = handles.DOD_X;
DOD_Y = handles.DOD_Y;

DPU = handles.DPU;
DPU_X = handles.DPU_X;
DPU_Y = handles.DPU_Y;

% coregister grids
[DOD,DPU,X,Y] = CFF_coregister_rasters(DOD,DOD_X,DOD_Y,DPU,DPU_X,DPU_Y);

% update data
handles.DOD = DOD;
handles.DOD_X = X;
handles.DOD_Y = Y;
handles.DOD_cmin = min(handles.DOD(:));
handles.DOD_cmax = max(handles.DOD(:));
handles.DPU = DPU;
handles.DPU_X = X;
handles.DPU_Y = Y;
handles.DPU_cmin = min(handles.DPU(:));
handles.DPU_cmax = max(handles.DPU(:));

% update txt_out
txt = get(handles.txt_out,'String');
txt{end+1} = sprintf('- Coregistered DOD and DPU');
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end

% Update handles structure
guidata(hObject,handles);

% force display update
switch handles.data_currently_displayed
    case 'DEM1'
        pb_display_DEM1_Callback(hObject,[],handles);
    case 'DEM2'
        pb_display_DEM2_Callback(hObject,[],handles);
    case 'DOD'
        pb_display_DOD_Callback(hObject,[],handles);
    case 'UNC1'
        pb_display_UNC1_Callback(hObject,[],handles);
    case 'UNC2'
        pb_display_UNC2_Callback(hObject,[],handles);
    case 'DPU'
        pb_display_DPU_Callback(hObject,[],handles);
    case 'LOD'
        pb_display_LOD_Callback(hObject,[],handles);
    otherwise
end


% --- Executes on button press in rb_fixed_uncertainty.
function rb_fixed_uncertainty_Callback(hObject, eventdata, handles)
% hObject    handle to rb_fixed_uncertainty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_fixed_uncertainty

% radio button pair toggle
tog = get(hObject,'Value');
if tog == 1
    handles.rb_variable_uncertainty.Value = 0;
else
    handles.rb_variable_uncertainty.Value = 1;
end

% enable edit box for fixed uncertainty
set(handles.edt_fixed_uncertainty,'Enable','on');

% Update handles structure
guidata(hObject,handles);



% --- Executes on button press in rb_variable_uncertainty.
function rb_variable_uncertainty_Callback(hObject, eventdata, handles)
% hObject    handle to rb_variable_uncertainty (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rb_variable_uncertainty

% radio button pair toggle
tog = get(hObject,'Value');
if tog == 1
    handles.rb_fixed_uncertainty.Value = 0;
else
    handles.rb_fixed_uncertainty.Value = 1;
end

% disable edit box for fixed uncertainty
set(handles.edt_fixed_uncertainty,'Enable','off');

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_calculate_LOD.
function pb_calculate_LOD_Callback(hObject, eventdata, handles)
% hObject    handle to pb_calculate_LOD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab data
factor = str2num(get(handles.edt_multiplying_factor,'String'));


if handles.rb_fixed_uncertainty.Value
    
    UNC = str2num(get(handles.edt_fixed_uncertainty,'String'));
    
    % calculate LOD
    LOD = factor.*UNC;
    
    % save LOD in handles
    handles.LOD = LOD;
    
    % update text
    if LOD == 0
        txt = sprintf('No LoD (LOD = 0m).');
        set(handles.txt_LOD,'String',txt);
    elseif LOD>0
        txt = sprintf('Fixed LoD = %g m.',LOD);
        set(handles.txt_LOD,'String',txt);
    end
    
    % disable LOD display
    set(handles.pb_display_LOD,'Enable','off');
    
    % delete any prior LOD results
    if isfield(handles,'LOD_X')
        handles = rmfield(handles,'LOD_X');
        handles = rmfield(handles,'LOD_Y');
    end
    
    % clear axis if variable LOD was in
    if strcmp(handles.data_currently_displayed,'LOD')
        cla
        
        % disable stats button too
        set(handles.pb_stats,'Enable','off');
        
        % clear and disable caxis edit boxes. Disable reset button
        set(handles.edt_min,'String','','Enable','off');
        set(handles.edt_max,'String','','Enable','off');
        set(handles.pb_reset_colorbar,'Enable','off');
        
    end
    
    % enable volume calculation if we have DOD and LOD
    if isfield(handles,'DOD') && isfield(handles,'LOD')
        set(handles.pb_vol,'Enable','on');
    end
    
    % update txt_out
    txt = get(handles.txt_out,'String');
    txt{end+1} = sprintf('- Calculated a fixed Limit of Detection (LOD)');
    txt{end+1} = sprintf('-- Fixed uncertainty UNC = ±%g m',UNC);
    txt{end+1} = sprintf('-- Multiplying factor k = %g',factor);
    txt{end+1} = sprintf('-- Fixed LoD = k*UNC = ±%g m',LOD);
    set(handles.txt_out,'String',txt);
    handles.txt_out.ListboxTop = length(txt); % force listbox to end
    handles.txt_out.Value = length(txt); % force listbox to end
    
    % Update handles structure
    guidata(hObject,handles);
    
elseif handles.rb_variable_uncertainty.Value
    
    UNC = handles.DPU;
    X = handles.DPU_X;
    Y = handles.DPU_Y;
    
    % calculate LOD
    LOD = factor.*UNC;
    
    % save LOD in handles
    handles.LOD = LOD;
    handles.LOD_X = X;
    handles.LOD_Y = Y;
    handles.LOD_cmin = min(handles.LOD(:));
    handles.LOD_cmax = max(handles.LOD(:));
    
    % update text
    if factor == 0
        txt = sprintf('No LoD (LOD = 0m).');
        set(handles.txt_LOD,'String',txt);
    else
        txt = sprintf('Variable LoD calculated.',LOD);
        set(handles.txt_LOD,'String',txt);
    end
    
    % enable LOD display
    set(handles.pb_display_LOD,'Enable','on');
    
    % enable volume calculation if we have DOD and LOD
    if isfield(handles,'DOD') && isfield(handles,'LOD')
        set(handles.pb_vol,'Enable','on');
    end
    
    % update txt_out
    txt = get(handles.txt_out,'String');
    txt{end+1} = sprintf('- Calculated spatially-variable Limit of Detection (LOD)');
    txt{end+1} = sprintf('-- Using combined spatially-variable uncertainty DPU',UNC);
    txt{end+1} = sprintf('-- Multiplying factor k = %g',factor);
    txt{end+1} = sprintf('-- Spatially-variable LoD = k*DPU',LOD);
    set(handles.txt_out,'String',txt);
    handles.txt_out.ListboxTop = length(txt); % force listbox to end
    handles.txt_out.Value = length(txt); % force listbox to end
    
    % Update handles structure
    guidata(hObject,handles);
    
    % force a display
    pb_display_LOD_Callback(hObject,[],handles);
    
else
    
    error('one of the two radiobuttons should be on')
    
end




% --- Executes on button press in pb_display_LOD.
function pb_display_LOD_Callback(hObject, eventdata, handles)
% hObject    handle to pb_display_LOD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if polygon exists, save it before changing the display
if isfield(handles,'h')
    pos = getPosition(handles.h);
end

x = handles.LOD_X(1,:);
y = handles.LOD_Y(:,1);
M = handles.LOD;
c(1) = handles.LOD_cmin;
c(2) = handles.LOD_cmax;

axes(handles.main_axes);
imagesc(x,y,M);
alpha(double(~isnan(M)));

axis xy
if isfield(handles,'axis')
    axis(handles.axis);
else
    axis equal
    daspect([1,1,1]);
end

grid on
colorbar
caxis(c);
set(gca, 'XTickLabel', num2str(get(gca, 'XTick')'));
set(gca,'XTickLabelRotation',45);
set(gca, 'YTickLabel', num2str(get(gca, 'YTick')'));

% if polygon existed, re-create it now
if exist('pos','var')
    handles.h = impoly(gca,pos);
end

% record which data is currently on display
handles.data_currently_displayed = 'LOD';
title(handles.data_currently_displayed);

% enable stats button
set(handles.pb_stats,'Enable','on');

% enable and update caxis edit boxes
set(handles.edt_min,'String',c(1),'Enable','on');
set(handles.edt_max,'String',c(2),'Enable','on');
set(handles.pb_reset_colorbar,'Enable','on');

% enable drawpoly and select poly
set(handles.pb_drawpoly,'Enable','on');
set(handles.pb_select_poly,'Enable','on');

% Update handles structure
guidata(hObject,handles);


% --- Executes on selection change in txt_out.
function txt_out_Callback(hObject, eventdata, handles)
% hObject    handle to txt_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns txt_out contents as cell array
%        contents{get(hObject,'Value')} returns selected item from txt_out


% --- Executes during object creation, after setting all properties.
function txt_out_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_out (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_export_echo.
function pb_export_echo_Callback(hObject, eventdata, handles)
% hObject    handle to pb_export_echo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% grab session start time as default name
txt = get(handles.txt_out,'String');
default_filename = [txt{1} '.txt'];
default_filename = regexprep(default_filename,':','-');

% path?
if isfield(handles,'last_pathname')
    trythispath = handles.last_pathname;
else
    trythispath = [pwd filesep];
end

default_file = [trythispath default_filename];

% dialog box to prompt saving
[file_name,path_name] = uiputfile('*.txt','Save file name',default_file);

if isequal(file_name,0)
    msgbox('Please try again!','Error!','Modal');
    errordlg('File not found','File Error');
    return;
end

file = [path_name file_name];

% save data in said file
fid = fopen(file,'wt');
fprintf(fid,'%s\n',txt{:});
fclose(fid);

% Update handles structure
guidata(hObject,handles);


% --- Executes on button press in pb_stats.
function pb_stats_Callback(hObject, eventdata, handles)
% hObject    handle to pb_stats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get whatever data is currently displayed
whatM = handles.data_currently_displayed;
eval(sprintf('M = handles.%s;',whatM));
eval(sprintf('X = handles.%s_X;',whatM));
eval(sprintf('Y = handles.%s_Y;',whatM));

% if we have polygon, clip data to polygon
if isfield(handles,'h')
    
    % get poly position
    pos = getPosition(handles.h);
    xv = pos(:,1);
    yv = pos(:,2);
    
    % clip raster
    [M,X,Y] = CFF_clip_raster(M,X,Y,xv,yv);
    
end

% calculate stats
stat.min = min(M(:));
stat.max = max(M(:));
stat.mean = nanmean(M(:));
stat.median = nanmedian(M(:));
stat.std = nanstd(M(:));
stat.perc6800      = CFF_invpercentile(abs(M(:)),68.00);
stat.perc6827_1sig = CFF_invpercentile(abs(M(:)),68.27);
stat.perc9545_2sig = CFF_invpercentile(abs(M(:)),95.45);
stat.perc9900      = CFF_invpercentile(abs(M(:)),99.00);
stat.perc9973_3sig = CFF_invpercentile(abs(M(:)),99.73);
stat.perc9990      = CFF_invpercentile(abs(M(:)),99.90);
stat.range = stat.max - stat.min;

% update txt_out
txt = get(handles.txt_out,'String');
if isfield(handles,'h')
    txt{end+1} = sprintf('- Calculated statistics for %s within polygon with vertices (X,Y):',whatM);
    for ii = 1:size(pos,1)
        txt{end+1} = sprintf('-- %f,%f',pos(ii,1),pos(ii,2));
    end
    txt{end+1} = sprintf('-- Statistics results:');
else
    txt{end+1} = sprintf('- Calculated statistics for %s on full current dataset. Results:',whatM);
end
txt{end+1} = sprintf('-- Minimum: %fm',stat.min);
txt{end+1} = sprintf('-- Maximum: %fm',stat.max);
txt{end+1} = sprintf('-- Mean: %fm',stat.mean);
txt{end+1} = sprintf('-- Median: %fm',stat.median);
txt{end+1} = sprintf('-- Stand dev: %fm',stat.std);
txt{end+1} = sprintf('-- 68th percentile: %fm',stat.perc6800);
txt{end+1} = sprintf('-- 68.27th percentile (1 sigma): %fm',stat.perc6827_1sig);
txt{end+1} = sprintf('-- 95.45th percentile (2 sigmas): %fm',stat.perc9545_2sig);
txt{end+1} = sprintf('-- 99th percentile: %fm',stat.perc9900);
txt{end+1} = sprintf('-- 99.73th percentile (3 sigmas): %fm',stat.perc9973_3sig);
txt{end+1} = sprintf('-- 99.9th percentile: %fm',stat.perc9990);
txt{end+1} = sprintf('-- Range: %fm',stat.range);
set(handles.txt_out,'String',txt);
handles.txt_out.ListboxTop = length(txt); % force listbox to end
handles.txt_out.Value = length(txt); % force listbox to end


% Update handles structure
guidata(hObject,handles);



function edt_min_Callback(hObject, eventdata, handles)
% hObject    handle to edt_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edt_min as text
%        str2double(get(hObject,'String')) returns contents of edt_min as a double

% get the new cmin value
c(1) = str2num(get(handles.edt_min,'String'));

% get whatever data is currently displayed
whatM = handles.data_currently_displayed;

% change its cmin
eval(sprintf('handles.%s_cmin = c(1);',whatM));

% force a re display
eval(sprintf('pb_display_%s_Callback(hObject,[],handles);',whatM));

% Update handles structure
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edt_min_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_min (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edt_max_Callback(hObject, eventdata, handles)
% hObject    handle to edt_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edt_max as text
%        str2double(get(hObject,'String')) returns contents of edt_max as a double

% get the new cmin value
c(2) = str2num(get(handles.edt_max,'String'));

% get whatever data is currently displayed
whatM = handles.data_currently_displayed;

% change its cmax
eval(sprintf('handles.%s_cmax = c(2);',whatM));

% force a re display
eval(sprintf('pb_display_%s_Callback(hObject,[],handles);',whatM));

% Update handles structure
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function edt_max_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edt_max (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pb_reset_colorbar.
function pb_reset_colorbar_Callback(hObject, eventdata, handles)
% hObject    handle to pb_reset_colorbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get whatever data is currently displayed
whatM = handles.data_currently_displayed;

% re-calculate original cmin and cmax on the data recorded
eval(sprintf('c(1) = min(handles.%s(:));',whatM));
eval(sprintf('c(2) = max(handles.%s(:));',whatM));

% register as cmin and cmax
eval(sprintf('handles.%s_cmin = c(1);',whatM));
eval(sprintf('handles.%s_cmax = c(2);',whatM));

% force a re display
eval(sprintf('pb_display_%s_Callback(hObject,[],handles);',whatM));

% Update handles structure
guidata(hObject,handles);



% --------------------------------------------------------------------
function togg_lock_axis_OffCallback(hObject, eventdata, handles)
% hObject    handle to togg_lock_axis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% remove axis field
if isfield(handles,'axis')
    handles = rmfield(handles,'axis');
end

% axis back to default
axis auto
axis equal
daspect([1 1 1])

% Update handles structure
guidata(hObject,handles);


% --------------------------------------------------------------------
function togg_lock_axis_OnCallback(hObject, eventdata, handles)
% hObject    handle to togg_lock_axis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% save current axis
handles.axis = axis;

% Update handles structure
guidata(hObject,handles);


% --------------------------------------------------------------------
function uipush_help_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipush_help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

p = get( groot, 'Screensize' );

d = dialog('Position',[300 300 0.5.*p(3) 0.8.*p(4)],'WindowStyle','normal','Resize','Off','Name','Elevation Change Analysis Help');

movegui(d,'center');

btn = uicontrol('Parent',d,...
    'Position',[0.25.*p(3)-35 5 70 25],...
    'String','Close',...
    'Callback','delete(gcf)');

lbox = uicontrol('Parent',d,...
    'Style','listbox',...
    'Position',[10 40 0.5.*p(3)-20 0.8.*p(4)-50]);

helptxt = sprintf( ['------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------', ...
                    '\n------------------------------------------------------------------------------------------ ELEVATION CHANGE ANALYSIS -------------------------------------------------------------------------------------------', ...
                    '\n------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------', ...
                    '\nA tool to measure the change in area and volume between consecutive topographic or bathymetric datasets, including estimates of uncertainty.', ...
                    '\n', ...
                    '\nAUTHORS:', ...
                    '\n- Alexandre SCHIMEL (NIWA, Deakin University) alex.schimel@niwa.co.nz', ...
                    '\n- Rozaimi CHE HASAN (Universiti Teknologi Malaysia, Deakin University)', ...
                    '\n', ...
                    '\nIMPORTANT NOTES:', ...
                    '\n- The use of the polygon tool requires the Image Processing Toolbox, but everything else should work without it.', ...
                    '\n- This tool was built to implement the methodology described in: Schimel ACG, Ierodiaconou D, Hulands L, Kennedy DM (2015) Accounting for uncertainty in volumes of seabed change', ...
                    '\nmeasured with repeat multibeam sonar surveys. Cont Shelf Res. doi: 10.1016/j.csr.2015.10.019.', ...
                    '\n- This tool makes use of individual functions found at: https://github.com/alexschimel/CoFFee/tree/master/functions/gis_DEM_analysis', ...
                    '\n- The "Reset" button will reset the entire tool to start fresh, while the "Exit" button will close it.', ...
                    '\n', ...
                    '\nBASIC USE:', ...
                    '\n- Open two DEMs using the "Open DEM 1" and "Open DEM 2" buttons. Data file formats accepted are grid ASCII and TIFF.', ...
                    '\n- Switch between datasets using the appropriate "Display" button.', ...
                    '\n- The two DEMs must be co-registered to allow computing the difference (DOD = DEM2 - DEM1), so use the "Coregister DEMs" and "Calculate DOD" buttons in that order.', ...
                    '\n- You can adjust the color scale of any dataset being displayed using the fields in the "Color Scale" panel. The button "Reset" will reset that color scale to the full range, but for the', ...
                    '\ndisplayed dataset only.', ...
                    '\n- You can zoom in and out or drag around the data using the appropriate icons in the toolbar. The "Lock" icon in the toolbar allows maintaining the boundaries of the current view when', ...
                    '\nswitching the display between datasets.', ...
                    '\n- Click the "Compute Stats" button to compute basic statistics about the dataset being displayed.', ...
                    '\n- The "Echo" panel displays all actions taken and results. At any point, you can click "Export echo" to export the contents of the window in a text file.', ...
                    '\n', ...
                    '\nPOLYGON:', ...
                    '\n- The "Draw" button allows manually drawing a polygon over the data displayed. Use the mouse''s left button to add a vertex and double-click to finish.', ...
                    '\n- The "Load" button allows inputting a file containing a polygon''s vertices. Delimited text files and shapefiles are currently accepted. Make sure the coordinate systems are the same.', ...
                    '\n- Any polygon can be interacted with, that is, you can drag around indiviudal vertices, or dragging the entire polygon.' , ...
                    '\n- The "Clear" button will clear the current polygon.', ...
                    '\n- The "Clip to" button will clip all loaded datasets to the polygon. Useful to limit the size of the datasets to the relevant overlap area, and help speed up further calculations.', ...
                    '\n- When a polygon is in, the "Compute Stats" button will apply calculations only to the data within the polygon.', ...
                    '\n', ...
                    '\nSTATS:', ...
                    '\n- Ontop of basic statistics (mean, median, standard deviation, minimum, maximum, range), the tool displays percentiles, that is, the value under which a certain percentage of values fall.', ...
                    '\n- For example, 68.72th percentile is the value under which, 68.72%% of all values fall.. which is equal to 1 standard deviation if the data were normally distributed.', ...
                    '\n- Stats allow you to figure out, among others, an estimate of variation in a DOD over an area that has not experienced change, which can be used as a fixed uncertainty estimate.', ...
                    '\n', ...
                    '\nFIXED UNCERTAINTY:', ...
                    '\n- Uncertainty is used in two manners in this tool: To provide uncertainty intervals for volumes, and to calculate a "Limit of Detection", aka a bound for any change to be considered in', ...
                    '\ncalculations.', ...
                    '\n- Say you set a fixed uncertainty value of U=±1m and a multiplying factor of k=2, then a LoD of k*U=±2m will be used, that is, only changes in height above 2m or below -2m will be', ....
                    '\nconsidered in volume calculations. However, all volumetric estimates will keep using U=±1m as the basic uncertainty to be propagated to volumetric uncertainty calculations.', ...
                    '\n- Setting a factor of k=0 allows you to compute volumes with uncertainty intervals but without using a Limit of Detection.', ...
                    '\n- You can do all the above by setting the appropriate values in the "Limit of Detection" panel, then clicking "Calculate LoD".', ...
                    '\n- Once a LoD has been calculated (Even one with LOD=0 if the factor was set to 0), it is possible to compute volumes using the "Analyze Change" button.', ...
                    '\n- Note that if a polygon is in, a window will prompt you whether you want the change analysis to be calculated on the data within the polygon only, or the full dataset', ...
                    '\n', ...
                    '\nSPATIALLY VARIABLE UNCERTAINTY:', ...
                    '\n- If you have spatially variable uncertainty rasters for each DEM, these can be loaded using the "Open UNC1" and Open UNC2" buttons', ...
                    '\n- Like DEMs, these need to be coregistered before the combined uncertainty (DPU) can be calculated. So use the "Coregister UNCs" and "Calculate DPU" in that order.', ...
                    '\n- DOD and DPU must be coregistered in order to use DPU as a source of uncertainty. Use the "Coregister DOD and DPU" accordingly.', ...
                    '\n- Once DOD and DPU exist and are coregistered, it is possible to calculate a spatially variable Limit of Detection, using the radio button "Variable uncertainty (Use DPU)".', ...
                    '\n- A spatially variable LOD can be displayed, and interacted with, just like all other datasets.', ...
                    '\n', ...
                    '\nCHANGE ANALYSIS:', ...
                    '\n- A Change Analysis includes the following calculations:', ...
                    '\n     - Total area considered: The total area in m^2 within the polygon or full dataset.', ...
                    '\n     - Total area experiencing change: The total area experiencing a deposition or erosion above the Limit of Detection. Also written as a percentage of total area considered.', ...
                    '\n     - Area experiencing erosion above LOD: The total area experiencing erosion above the Limit of Detection. Also written as a percentage of total area considered.', ...
                    '\n     - Volume eroded: The total volume eroded, considering only variation above the Limit of Detection.', ...
                    '\n     - Uncertainty for volume eroded (propagated in sum): The uncertainty interval for volume eroded, calculated by propagating uncertainty in sum over area of erosion.', ...
                    '\n     - Uncertainty for volume eroded (propagated in quadrature): The uncertainty interval for volume eroded, calculated by propagating uncertainty in quadrature over area of erosion.', ...
                    '\n     - Area experiencing deposition above LOD: The total area experiencing deposition above the Limit of Detection. Also written as a percentage of total area considered.', ...
                    '\n     - Volume deposited: The total volume deposited, considering only variation above the Limit of Detection.', ...
                    '\n     - Uncertainty for volume deposited (propagated in sum): The uncertainty interval for volume deposited, calculated by propagating uncertainty in sum over area of deposition.', ...
                    '\n     - Uncertainty for volume deposited (propagated in quadrature): The uncertainty interval for volume deposited, calculated by propagating uncertainty in quadrature over area of deposition.', ...
                    '\n     - Volume net change (net deposition if positive): Difference between volume eroded and volume deposited. Indicates a net deposition if positive and a net erosion if negative.', ...
                    ''] );
                
set(lbox,'String',helptxt);
                
                
