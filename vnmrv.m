function varargout = vnmrv(varargin)
% VNMRV: Vnmr Viewer 
%
% VNMRV is a tool to quickly review studies scanned on the VnmrJ software,
%      eventually including basic 2D and 3D reconstruction, fitting of IR-T1,
%      SE-T2, DESPOT-1 and AFI quantative datasets.
%
%      Will also load pre-reconstructed fdf format files.
%
%      VNMRV, by itself, creates a new VNMRV or raises the existing
%      singleton*.
%
%      H = VNMRV returns the handle to a new VNMRV or the handle to
%      the existing singleton*.
%
%      VNMRV('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VNMRV.M with the given input arguments.
%
%      VNMRV('Property','Value',...) creates a new VNMRV or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before vnmrv_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vnmrv_OpeningFcn via varargin.
%
% Custom Options Variable (handles.vnmrv)
%      currentDir  - Current directory
%      series      - Cell array containing the *.fdf series names
%
% Custom Functions
%      loadSdir       - similar to load_sdir() command, but only spits out 
%      populateSeries - Try to load all series within the dir into the listbox 
%
% Builtin Dependancies
%      function    - description
%
% Samuel A. Hurley
% University of Wisconsin
% v1.0 14-Oct-2011
%
% Changelog:
%      v1.0 - Initial version as a tool for IJR.
%
% Last Modified by GUIDE v2.5 18-Oct-2011 15:51:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vnmrv_OpeningFcn, ...
                   'gui_OutputFcn',  @vnmrv_OutputFcn, ...
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

% ================= GUI Callbacks Below ==========================%

% --- Executes just before vnmrv is made visible.
function vnmrv_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vnmrv (see VARARGIN)

% Choose default command line output for vnmrv
handles.output = hObject;

% Create a struct & default options for VnmrV
handles.vnmrv = struct();
handles.vnmrv.currentDir = pwd;
handles.vnmrv.opts_txt   = 'Error: procpar not loaded';

% Set the current dir in the directory field
set(handles.editDir, 'String', handles.vnmrv.currentDir);

% Try to populate series within the current dir
handles = populateSeries(handles);

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = vnmrv_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function editDir_Callback(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
% hObject    handle to editDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editDir as text
%        str2double(get(hObject,'String')) returns contents of editDir as a double

% Try to change dir to the pasted directory
try
  dir = get(hObject, 'String')
  cd(dir);
  handles.vnmrv.currentDir = dir;
catch
  cd(handles.vnmrv.currentDir);
end

% Update editDir to the current path
set(handles.editDir, 'String', pwd);

% Try to populate the listbox with series info
handles = populateSeries(handles);

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushChangeDir.
function pushChangeDir_Callback(hObject, eventdata, handles)
% hObject    handle to pushChangeDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Change current path
try
  dir = uigetdir();
  cd(dir);
  handles.vnmrv.currentDir = dir;
catch
  cd(handles.vnmrv.currentDir);
end

% Update editDir to the current path
set(handles.editDir, 'String', pwd);

% Try to populate the listbox with series info
handles = populateSeries(handles);

guidata(hObject, handles);

% --- Executes on selection change in listSeries.
function listSeries_Callback(hObject, eventdata, handles)
% hObject    handle to listSeries (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listSeries contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listSeries

% Load the procpar for the series
try
seriesNum = get(handles.listSeries, 'Value');
info      = load_procpar([handles.vnmrv.series{seriesNum} '/procpar']);

% Check for 2d/3d PSG
if info.nv2 == 0
  type = '2d';
else
  type = '3d';
end

% Grab seqfil (some params depend on it)
seqfil = info.seqfil;
if length(seqfil) < 5
  % Pad seqfil
  seqfil = [seqfil '     '];
end

% Create a text field to output formatted text data
opts_txt = [];
opts_txt = strvcat(opts_txt, ['==============Series Information==============']); %#ok<NBRAK,VCAT>
opts_txt = strvcat(opts_txt, ['Series:   ' pwd()]);       %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['Sequence: ' info.seqfil]);       %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['Comment:  ' info.comment]);      %#ok<VCAT>
try
  opts_txt = strvcat(opts_txt, ['Time:     ' info.scantime]);      %#ok<VCAT>
catch
  opts_txt = opts_txt;
end
opts_txt = strvcat(opts_txt, ['==============Imaging Parameters==============']); %#ok<NBRAK,VCAT>
opts_txt = strvcat(opts_txt, ['TR:   ' num2str(info.tr*1000) ' ms']); %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['TE:   ' num2str(info.te*1000,'%01.2f ') ' ms']); %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['NEX:  ' num2str(info.nt)]); %#ok<VCAT>
% Number of echoes for multi-echo sequence
if strcmp(seqfil(1:4), 'mems') || strcmp(seqfil(1:5), 'mge3d') || strcmp(seqfil(1:5), 'mgems')
  try
    opts_txt = strvcat(opts_txt, ['TE2:  ' num2str(info.te2*1000) ' ms']); %#ok<VCAT>
  catch
    %
  end
  opts_txt = strvcat(opts_txt, ['NE:   ' num2str(info.ne) ' echoes']); %#ok<VCAT>
end
% ETL and ESP for FSE sequences
if strcmp(seqfil(1:5), 'fsems')
  opts_txt = strvcat(opts_txt, ['ETL:  ' num2str(info.etl) ' echoes']); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['ESP:  ' num2str(info.esp*1000) ' ms']); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['kZero:' num2str(info.kzero) '']); %#ok<VCAT>
end
opts_txt = strvcat(opts_txt, ['FA:   ' num2str(info.flip1) ' degrees']); %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['BW:   ' num2str(info.sw/1000) ' kHz']); %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['==============Matrix and FOV==================']); %#ok<NBRAK,VCAT>
if strcmp(type, '3d')
  opts_txt = strvcat(opts_txt, ['Matrix: ' num2str(info.np/2) 'x' num2str(info.nv) 'x' num2str(info.nv2)]); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['FOV:    ' num2str(info.lro*10) 'mm x ' num2str(info.lpe*10) 'mm x ' num2str(info.lpe2*10) ' mm']); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['Slab:   ' num2str(info.thk) 'mm']); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['VoxDim: ' num2str(info.lro*20/info.np) ' x ' num2str(info.lpe*10/info.nv) ' x ' num2str(info.lpe2*10/info.nv2) ' mm^3']); %#ok<VCAT>
else
  opts_txt = strvcat(opts_txt, ['Matrix: ' num2str(info.np/2) 'x' num2str(info.nv)]); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['FOV:    ' num2str(info.lro*10) 'mm x ' num2str(info.lpe*10) 'mm']); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['Slices: ' num2str(info.ns)]); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['VoxDim: ' num2str(info.lro*20/info.np) 'mm x ' num2str(info.lpe*10/info.nv) 'mm']); %#ok<VCAT>
  opts_txt = strvcat(opts_txt, ['THK:    ' num2str(info.thk) 'mm']); %#ok<VCAT>
end
opts_txt = strvcat(opts_txt, ['==============Prepulse Options================']); %#ok<NBRAK,VCAT>
opts_txt = strvcat(opts_txt, ['IR / FLAIR: ' info.ir]);   %#ok<VCAT>
if strcmp(info.ir, 'y')
  opts_txt = strvcat(opts_txt, ['TI Values:  ' num2str(info.ti,'%01.3f ') ' s']);   %#ok<VCAT>
end
opts_txt = strvcat(opts_txt, ['MT Pulse:   ' info.mt]);   %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['Fatsat:     ' info.fsat]); %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['Satbands:   ' info.sat]);  %#ok<VCAT>
opts_txt = strvcat(opts_txt, ['==============================================']); %#ok<NBRAK,VCAT>


% Display opts text in listInfo
set(handles.listInfo, 'String', opts_txt);

% Save opts_txt to handles
handles.vnmrv.opts_txt = opts_txt;

% Enable save txt button
set(handles.pushSave, 'Enable', 'on');

catch
% Display error message
set(handles.listInfo, 'String', 'Error Reading Procpar');

% Disable save txt button
set(handles.pushSave, 'Enable', 'off');

end

% Save handles structure to the GUI
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function listSeries_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listSeries (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function handles = populateSeries(handles)
% Try to populate listSeries, if the dir contains .fid series
series = dirf('*.img');

if isempty(series)
  set(handles.listSeries, 'String', 'NONE');
else
  seriesNames = [];
  for ii = 1:length(series)
    progressbar(ii/length(series));
    
    seriesNameTmp = series{ii};
    
    try
      % Try to load the info and get a comment from it
      info          = load_procpar([series{ii} '/procpar']);
      seriesNameTmp = [seriesNameTmp ' | ' info.comment];
    catch
      seriesNameTmp = [seriesNameTmp ' |  <no comment>'];
    end
    
    seriesNames = strvcat(seriesNames, seriesNameTmp);
  end
  
  set(handles.listSeries, 'String', seriesNames);
  
end

% Save the series variable to handles structure
handles.vnmrv.series = series;


% --- Executes on selection change in listInfo.
function listInfo_Callback(hObject, eventdata, handles)
% hObject    handle to listInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listInfo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listInfo


% --- Executes during object creation, after setting all properties.
function listInfo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushSave.
function pushSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Save handles.vnmrv.opts_txt to a text file
[x y] = uiputfile('Text Document *.txt', 'Save Scan Parameters');

opts_txt = handles.vnmrv.opts_txt;

% Write to a new text file
txtfid = fopen([y x], 'w');
for ii = 1:size(opts_txt, 1);
  fprintf(txtfid, [opts_txt(ii,:) '\n']);
end
fclose(txtfid);
