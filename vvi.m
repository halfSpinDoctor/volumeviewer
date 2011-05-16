function varargout = vvi(varargin)
% VVI: VolumeViewer Improved
%
% Based on volumeviewer.m by Rafael O'Halloran (UW-Madison)
%
% VOLUMEVIEWERimproved is a tool for roi analysis of 3d (and 4d) image arrays
%
%      VVI, by itself, creates a new VVI
%
%      H = VVI returns the handle to a new VVI
%
%      VVI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VVI.M with the given input arguments.
%
%      VVI('Property','Value',...) creates a new VVI 
%      Starting from the left, property value pairs are
%      applied to the GUI before vvi_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to vvi_OpeningFcn via varargin.
%
%
% Custom Options Variable (handles.vvi)
%      currentImage - the current image being displayed
%      currentName  - the name of the variable or expression being imaged
%      min          - the minimum intensity to display
%      max          - the maximum intensity to display
%      currentSlice - the currently selected slice
%      currentPhase - the currently selected 'phase' (z for a 4D image)
%      imageSize    - the dimensions of the currently loaded image
%      
%      currentVars  - the current workspace variables
%      montage      - 0 = use imagesc,  1 = use imsc
%
% Custom Functions
%      imageDisp   - display an image with custom scale [min max] and custom colormap
%      imageLogo   - display the Matlab logo
%      loadVars    - refresh list of base workspace variables
%      loadImage   - load in an image from the base workspace into vvi
%      textMessage - display a custom  message in the terminal & on image
%
% Builtin Dependancies
%      phplot      - converts a complex dataset into a color-modulated image to visualize
%                    phase and magnitude at the same time
%      imgsc       - image montage viewer
%
%
% Samuel A. Hurley
% University of Wisconsin
% v1.2  11-May-2011
%
% Changelog:
%     v1.0 Initial version 23-Aug-2011
%     v1.1 Added Mag/Phase/Real/Imag Options (May-2011)
%     v1.2 Added phplot() and imgsc() directly into vvi code to eliminate external
%          dependancies (May-2011)
%     v1.3 Added support for opening up structs of images.  Fixed colormap buttons
%          Fixed up functionality of loadVars so it will not load non-images
%
% Last Modified by GUIDE v2.5 15-May-2011 19:03:56

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @vvi_OpeningFcn, ...
                   'gui_OutputFcn',  @vvi_OutputFcn, ...
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


% --- Executes just before vvi is made visible.
function vvi_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to vvi (see VARARGIN)

% Choose default command line output for vvi
handles.output = hObject;

% Create a struct & default options for VVI
handles.vvi = struct();
handles.vvi.currentImage = magic(10);
handles.vvi.colormap     = colormap('gray');
handles.vvi.min          = 0;
handles.vvi.max          = 1;
handles.vvi.currentSlice = 1;
handles.vvi.currentPhase = 1;
handles.vvi.imageSize    = [20 20 1 1];
handles.vvi.montage      = 0;
handles.vvi.complexMode  = 0;  % 0 = Mag, 1 = Phase, 2 = Real, 3 = Imag, 4 = Colour Phase

% Populate image with Matlab logo
imageLogo(handles);

% Populate list box with current workspace variables
handles = loadVars(handles);

% Update handles structure
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = vvi_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function mainAxes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mainAxes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate mainAxes

% --- Executes on selection change in listVars.
function listVars_Callback(hObject, eventdata, handles)
% hObject    handle to listVars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get the current selected
x = get(handles.listVars, 'Value');
y = strtrim(handles.vvi.currentVars(x, :));

% Set it into the string of the textbox
set(handles.editVar, 'String', y);

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function listVars_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listVars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editVar_Callback(hObject, eventdata, handles)
% hObject    handle to editVar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Same as pushing 'load'
pushImg_Callback(hObject, eventdata, handles)



% --- Executes during object creation, after setting all properties.
function editVar_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editVar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushImg.
function pushImg_Callback(hObject, eventdata, handles)
% hObject    handle to pushImg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Update the listed variables
handles = loadVars(handles);

% Load in image to workspace
handles = loadImage(handles);

% Display the image
imageDisp(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes when selected object is changed in panelImage.
function panelImage_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panelImage 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Check which style to use: imagesc or imsc (montage)
if get(handles.radioSlice, 'Value')
  handles.vvi.montage = 0;
else
  handles.vvi.montage = 1;
end

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes on selection change in popupColormap.
function popupColormap_Callback(hObject, eventdata, handles)
% hObject    handle to popupColormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupColormap contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupColormap

% Get the selected colormap
contents = cellstr(get(hObject,'String'));
cm       = strtrim(contents{get(hObject,'Value')});

% Check for custom maps jet2 or hsv2
if strcmp(cm, 'Jet2')
  handles.vvi.colormap = colormap('Jet');
  handles.vvi.colormap(1,:) = [0 0 0]; % Set 0 value to black
  
elseif strcmp(cm, 'HSV2')
  handles.vvi.colormap = colormap('HSV');
  handles.vvi.colormap(1, :) = [0 0 0]; % Set 0 value to black

else
  % Standard colormap
  handles.vvi.colormap = colormap(cm);
end

% Update image
imageDisp(handles);

% Update handles structure
guidata(hObject, handles);

% =-=-=-=-=-=- Window & Level (Min / Max) Boxes Here =-=-=-=-=-=-=-

function editMin_Callback(hObject, eventdata, handles)
% hObject    handle to editMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set min
handles.vvi.min = str2double(get(hObject, 'String'));

% Check to make sure min !> max
if handles.vvi.min > handles.vvi.max
  handles.vvi.min = handles.vvi.max*.5;
  set(handles.editMin, 'String', num2str(handles.vvi.min));
  textMessage(handles, 'err', 'You set the min higher than the max')
end

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);

function editMax_Callback(hObject, eventdata, handles)
% hObject    handle to editMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Set max
handles.vvi.max = str2double(get(hObject, 'String'));

% Check to make sure max !< min
if handles.vvi.min > handles.vvi.max
  handles.vvi.max = handles.vvi.min*1.05;
  set(handles.editMax, 'String', num2str(handles.vvi.max));
  textMessage(handles, 'err', 'You set the max higher than the min');
end

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushLevel.
function pushLevel_Callback(hObject, eventdata, handles)
% hObject    handle to pushLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Sets min an max based on min & max of currently displayed image
if handles.vvi.montage == 1
  % Use phase min & max for montage
  img = handles.vvi.currentImage(:,:,:, handles.vvi.currentPhase);
  
else
  % Use slice min & max for standard
  img = handles.vvi.currentImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase);
end

% Grab the min & max
handles.vvi.min = min(abs(img(:)));
handles.vvi.max = max(abs(img(:)));

if handles.vvi.min > handles.vvi.max
  % Set minimum to 90% lower than max.
  handles.vvi.min = handles.vvi.max * .9;
end

% Set the value of the txt boxes
set(handles.editMin, 'String', num2str(handles.vvi.min));
set(handles.editMax, 'String', num2str(handles.vvi.max));

% Update the image
imageDisp(handles);

% Update handles structure
guidata(hObject, handles);

% =-=-=-=-= Slice Buttons Here =-=-=-=-=-=-=-=-=-=-=-=-=

function editSlice_Callback(hObject, eventdata, handles)
% hObject    handle to editSlice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

slice = str2double(get(hObject, 'String'));

% Check for valid slice
if slice < 1 || slice > handles.vvi.imageSize(3)
  textMessage(handles, 'err', 'Invalid slice chosen');
  % Re-set to the previous slice.
  set(hObject, 'String', num2str(handles.vvi.currentSlice));
else
  handles.vvi.currentSlice = slice;
end

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);
  

% --- Executes on button press in pushSliceDown.
function pushSliceDown_Callback(hObject, eventdata, handles)
% hObject    handle to pushSliceDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Cannot go below 1
if ~(handles.vvi.currentSlice == 1)
  handles.vvi.currentSlice = handles.vvi.currentSlice - 1;
  set(handles.editSlice, 'String', num2str(handles.vvi.currentSlice));
  imageDisp(handles);
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushSliceUp.
function pushSliceUp_Callback(hObject, eventdata, handles)
% hObject    handle to pushSliceUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Cannot go above max
if ~(handles.vvi.currentSlice == handles.vvi.imageSize(3))
  handles.vvi.currentSlice = handles.vvi.currentSlice + 1;
  set(handles.editSlice, 'String', num2str(handles.vvi.currentSlice));
  imageDisp(handles);
end

% Update handles structure
guidata(hObject, handles);


% =-=-=-=-=- Phase Buttons Here =-=-=-=-=-=-=-=-=-=-
function editPhase_Callback(hObject, eventdata, handles)
% hObject    handle to editPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

phase = str2double(get(hObject, 'String'));

% Check for valid slice
if phase < 1 || phase > handles.vvi.imageSize(4)
  textMessage(handles, 'err', 'Invalid phase chosen');
  % Re-set to the previous slice.
  set(hObject, 'String', num2str(handles.vvi.currentPhase));
else
  handles.vvi.currentPhase = phase;
end

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushPhaseDown.
function pushPhaseDown_Callback(hObject, eventdata, handles)
% hObject    handle to pushPhaseDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Cannot go below 1
if ~(handles.vvi.currentPhase == 1)
  handles.vvi.currentPhase = handles.vvi.currentPhase - 1;
  set(handles.editPhase, 'String', num2str(handles.vvi.currentPhase));
  imageDisp(handles);
end


guidata(hObject, handles);


% --- Executes on button press in pushPhaseUp.
function pushPhaseUp_Callback(hObject, eventdata, handles)
% hObject    handle to pushPhaseUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Cannot go above max
if ~(handles.vvi.currentPhase == handles.vvi.imageSize(4))
  handles.vvi.currentPhase = handles.vvi.currentPhase + 1;
  set(handles.editPhase, 'String', num2str(handles.vvi.currentPhase));
  imageDisp(handles);
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushPermute.
function pushPermute_Callback(hObject, eventdata, handles)
% hObject    handle to pushPermute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Swap slice & phase index (in order to do montage with phases instead of slices)
handles.vvi.currentImage = permute(handles.vvi.currentImage, [1 2 4 3]);
size = handles.vvi.imageSize;
handles.vvi.imageSize(3) = size(4);
handles.vvi.imageSize(4) = size(3);

slice = handles.vvi.currentSlice;
phase = handles.vvi.currentPhase;

handles.vvi.currentPhase = slice;
handles.vvi.currentSlice = phase;
set(handles.editSlice, 'String', num2str(handles.vvi.currentSlice));
set(handles.editPhase, 'String', num2str(handles.vvi.currentPhase));

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);

% =-=-=-=-=- External Figure =-=-=-=-=-=-=-=-

% --- Executes on button press in pushFigure.
function pushFigure_Callback(hObject, eventdata, handles)
% hObject    handle to pushFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call is same as imageDisp, but with a new figure
figure;

if handles.vvi.montage == 0
  if handles.vvi.complexMode == 4
    tmp = phplot(handles.vvi.currentImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase),handles.vvi.max);
    imagesc(tmp);
  else
    imagesc(handles.vvi.currentImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
  end
  
elseif handles.vvi.montage == 1
  % Show all slices of 1 phase
  imgsc(handles.vvi.currentImage(:,:,:,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
end

colormap(handles.vvi.colormap);

% Extra stuff to make the window around the figure tighter
% Adapted from volumeviewer by Raf O'Halloran
set(gca, 'Units', 'normalized', 'Position', [.02 0  1 0.91]);

axis image;
axis off;
title(handles.vvi.currentName, 'FontSize', 12);
colorbar;

% =-=-=-=-=- External Figure + Save TIFF -=-=-=-=-=

% --- Executes on button press in pushTIFF.
function pushTIFF_Callback(hObject, eventdata, handles)
% hObject    handle to pushTIFF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call is same as pushFigure, but also saves a TIFF file

% Prompt for Figure title/Filename
figureCaption = inputdlg('Figure Caption:');
fileName      = inputdlg('Image Filename:');

figure;
if handles.vvi.montage == 0
  if handles.vvi.complexMode == 4
    tmp = phplot(handles.vvi.currentImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), handles.vvi.max);
    imagesc(tmp);
  else
    imagesc(handles.vvi.currentImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
  end
  
elseif handles.vvi.montage == 1
  % Show all slices of 1 phase
  imgsc(handles.vvi.currentImage(:,:,:,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
end

colormap(handles.vvi.colormap);

% Extra stuff to make the window around the figure tighter
% Adapted from volumeviewer by Raf O'Halloran
set(gca, 'Units', 'normalized', 'Position', [.02 0  1 0.91]);

axis image;
axis off;
title(figureCaption, 'FontSize', 12);
colorbar;

% Save
saveas(gcf, fileName{1});




% ========= SAH Functions Below =============================================

% --- Populate the list with workspace variables
function handles = loadVars(handles)

x = evalin('base', 'whos');

% Temporary cell array for storing image variable names
z = cell(0);

% Loop thru vars and check for images & structs
for ii = 1:size(x, 1)
  
  % Loop into struct
  if strcmp(x(ii).class, 'struct')
    % Loop thru all field names in the struct
    fn = evalin('base', ['fieldnames(' x(ii).name ');']);
    
    for jj = 1:size(fn, 1)
      if evalin('base', ['size(' x(ii).name '(1).' fn{jj} ', 1) > 1']) && evalin('base', ['size(' x(ii).name '(1).' fn{jj} ', 2) > 1'])
        z = [z [x(ii).name '.' fn{jj}]]; %#ok<*AGROW>
      end
    end
  end
  
  % An image must be larger than 1x2
  if x(ii).size(1) > 2 && x(ii).size(2) > 2
    z = [z x(ii).name];
  end
end

% Convert from cell array to string
handles.vvi.currentVars = [];
for ii = 1:size(z, 2)
  handles.vvi.currentVars = strvcat(handles.vvi.currentVars, z{ii}); %#ok<REMFF1>
end

% Update the string in listVars
set(handles.listVars, 'String', handles.vvi.currentVars);

% --- Dispaly Matlab Logo on mainAxes ---
function imageLogo(handles)

% Populate main axis w matlab logo
L = 40*membrane(1,25);

axes(handles.mainAxes); %#ok<MAXES>
set(handles.mainAxes, 'CameraPosition', [-193.4013 -265.1546  220.4819],...
    'Color', [1 1 1], ...
    'CameraTarget',[26 26 10], ...
    'CameraUpVector',[0 0 1], ...
    'CameraViewAngle',9.5, ...
    'DataAspectRatio', [1 1 .9],...
    'Visible','off', ...
    'XLim',[1 51], ...
    'YLim',[1 51], ...
    'ZLim',[-13 40]);
axis off;
surface(L, ...
    'EdgeColor','none', ...
    'FaceColor',[0.9 0.2 0.2], ...
    'FaceLighting','phong', ...
    'AmbientStrength',0.3, ...
    'DiffuseStrength',0.6, ... 
    'Clipping','off',...
    'BackFaceLighting','lit', ...
    'SpecularStrength',1.1, ...
    'SpecularColorReflectance',1, ...
    'SpecularExponent',7, ...
    'Tag','TheMathWorksLogo', ...
    'parent',handles.mainAxes);
light('Position',[40 100 20], ...
    'Style','local', ...
    'Color',[0 0.8 0.8], ...
    'parent',handles.mainAxes);
light('Position',[.5 -1 .4], ...
    'Color',[0.8 0.8 0], ...
    'parent',handles.mainAxes);
  

% --- Display image on mainAxes ---
function imageDisp(handles)

axes(handles.mainAxes); %#ok<MAXES>

if handles.vvi.montage == 0
  if handles.vvi.complexMode == 4
    tmp = phplot(handles.vvi.currentImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), handles.vvi.max);
    imagesc(tmp);
  else
    imagesc(handles.vvi.currentImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
  end
  
elseif handles.vvi.montage == 1
  % Show all slices of 1 phase
  imgsc(handles.vvi.currentImage(:,:,:,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
end

colormap(handles.vvi.colormap);
axis image;
axis off;
colorbar;


% -- Load in an image from base workspace to vvi ---
function handles = loadImage(handles)

% Try to grab the image into the workspace
try
  img = double(evalin('base', get(handles.editVar, 'String')));
catch
  textMessage(handles, 'err', 'Incomplete or incorrect statement');
  return;
end

% If its larger than 4-D, remove higher dimensions
if ndims(img) > 4
  img = img(:,:,:,:,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
  textMessage(handles, 'info', 'Only first 4D of image loaded.');
end

% Check if the image is complex
if isreal(img)
  % Disable the mag/phase/real/imag control
  handles.vvi.complexMode = 0;
  set(handles.popupComplex, 'Enable', 'off');
  
else
  set(handles.popupComplex, 'Enable', 'on');
  
end

% Take mag/phase/real/imag as appropriate
switch handles.vvi.complexMode
  case 0
    img = abs(img);
  case 1
    img = angle(img);
  case 2
    img = real(img);
  case 3
    img = imag(img);
  case 4
    % Do nothing here
end

% Remove NaN and Infs from the image
img(isinf(img)) = 0;
img(isnan(img)) = 0;

% Update current image
handles.vvi.currentImage = double(img);

% Update the image name
handles.vvi.currentName = get(handles.editVar, 'String');

% Grab the min & max
handles.vvi.min = min(abs(img(:)));
handles.vvi.max = max(abs(img(:)));

if handles.vvi.min > handles.vvi.max
  handles.vvi.min = handles.vvi.max * 0.90;
end

% Set the value of the txt boxes
set(handles.editMin, 'String', num2str(handles.vvi.min));
set(handles.editMax, 'String', num2str(handles.vvi.max));

% Get the size of the image
handles.vvi.imageSize = size(img);

% Fix size for 2-D and 3-D images
if ndims(img) < 4
  handles.vvi.imageSize(4) = 1;
elseif ndims(img) < 3
  handles.vvi.imageSize(3) = 1;
  handles.vvi.imageSize(4) = 1;
end

% Take middle slice as current slice
handles.vvi.currentSlice = round(size(img, 3)/2);
set(handles.editSlice, 'String', num2str(handles.vvi.currentSlice));

% Take the first phase as default
handles.vvi.currentPhase = 1;
set(handles.editPhase, 'String', num2str(handles.vvi.currentPhase));


% --- Display a text message, both on the image itself and the command window ---
function textMessage(handles, type, msg)

  if strcmp(type, 'err')
    disp(['ERROR: ' msg]);
    axes(handles.mainAxes);
    text(2,4, ['ERROR: ' msg], 'HorizontalAlignment','left', 'FontSize', 12, 'Color', 'red');
  else
    if size(msg, 2) == 1
      disp(['INFO: ' msg]);
    else
      disp(msg);
    end
    axes(handles.mainAxes);
    if size(msg, 2) == 1
      text(2,4, ['INFO: '  msg], 'HorizontalAlignment','left', 'FontSize', 12, 'Color', 'white');
    else
      text(2,4, msg, 'HorizontalAlignment','left', 'FontSize', 12, 'Color', 'white');
    end
  end
  
pause(1);


% ======= Unused Callbacks Below =====================================
% Required to be here in order to avoid errors when clicking on 
% certain GUI elements

% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over pushImg.
function pushImg_ButtonDownFcn(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function popupColormap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupColormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function editMin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function editMax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function editSlice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSlice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function editPhase_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupComplex.
function popupComplex_Callback(hObject, eventdata, handles)
% hObject    handle to popupComplex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupComplex contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupComplex

% Get the selected colormap
contents = cellstr(get(hObject,'String'));
cm       = strtrim(contents{get(hObject,'Value')});

% Check for custom maps jet2 or hsv2
set(handles.popupColormap, 'Enable', 'on');    % Re-enable colormap choice

if strcmp(cm, 'Magnitude')
  handles.vvi.complexMode = 0;
  
elseif strcmp(cm, 'Phase')
  handles.vvi.complexMode = 1;
  
elseif strcmp(cm, 'Real')
  handles.vvi.complexMode = 2;
  
elseif strcmp(cm, 'Imag')
  handles.vvi.complexMode = 3;

else
  % Colour Phase
  handles.vvi.complexMode = 4;
  
  % Disable colormap choice
  set(handles.popupColormap, 'Enable', 'off');  % Disable colormap for mode 4
end

% Update image
handles = loadImage(handles);

% Display the image
imageDisp(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popupComplex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupComplex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ==== External Programs Below ==============

function varargout=phplot(varargin)

%PHPLOT(FIELD)
%Plots the phase of FIELD in a continuous color scale (hue) and represents
%the normalized amplitude as brightness (r+g+b)*amplitude.
%PHPLOT(FIELD,AMP,FLAG)
%If AMP = 0 the amplitude is not plot
%If FLAG = 1 the function creates a figure with a dial scale (from 0 to
%2*pi) and radial brightness (from 0 to one)
%A=PHPLOT(...) creates a 3D uint8 array that can be saved as an image with
%IMWRITE(A,'filename','fmt').
%Iacopo Mochi, Lawrence Berkeley National Laboratory 06/6/2010


% Copyright (c) 2010, Iacopo Mochi
% All rights reserved.

% Modified by Samuel A. Hurley
%             University of Wisconsin
%             vUW1.0 7-Jun-2010

field=varargin{1};
Amp=varargin{2};

Im=imag(field);
Re=real(field);

phase=atan2(Im,Re);
amplitude=abs(field);
if Amp > 0
  amplitude=amplitude/Amp;
  amplitude(amplitude>1) = 1;
else
  amplitude=amplitude/max(amplitude(:));
end

if Amp==0
    amplitude=ones(size(amplitude));
end
A=zeros(size(field,1),size(field,2),3);     %Declare RGB array

A(:,:,1)=0.5*(sin(phase)+1).*amplitude;     %Red
A(:,:,2)=0.5*(sin(phase+pi/2)+1).*amplitude;%Green
A(:,:,3)=0.5*(-sin(phase)+1).*amplitude;    %Blue


A=uint8(A*255);
varargout{1}=A;

% FUNCTION [] = imgsc(img, window, range)
%
% Display a montage of a 3D grayscale image
%
% Inputs:
%   img    - the input image
%   window - the slices you wish to view
%   range  - the range of values to map to the color scale
%
% Samuel A. Hurley
% University of Wisconsin
% v1.2 7-Jun-2010
%
% Changelog
%    v1.0  Initial version, roughly based off of Alexey's imsc command (2008)
%    v1.1  Added squeeze(img).  Clean up documentation (May 2010)
%    v1.2  Added ability to plot complex data using the phplot command,
%          phase data represented in colour (Jun 2010)
%    v1.3  Changed name to imgsc so as to not interfere with Alexey's version

function imgsc(img, window, range)

% Remove non-singleton dimensions
img = squeeze(img);

% if the data are > 3-d, use first volume
if ndims(img) > 3
  img = img(:,:,:,1,1,1,1,1,1);
end

if exist('window', 'var') == 0 || size(window, 1) == 0
  window(1) = 0;
  window(2) = max(img(:));
end

if exist('range', 'var') == 0
  range(1) = 1;
  range(2) = size(img, 3);
end

% if the data are complex, use a phplot
if ~isreal(img)
  for ii = 1:size(img, 3)
    img1(:,:,:,ii) = phplot(img(:,:,ii), window(2)); %#ok<AGROW>
  end
  montage(img1(:,:,:,range(1):range(2)));
else
  % Grayscale img
  img1(:,:,1,:) = img;
  montage(img1(:,:,1,range(1):range(2)), 'DisplayRange', window);
end
