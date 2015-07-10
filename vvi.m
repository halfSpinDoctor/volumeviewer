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
%      currentImage - the current loaded image (may be complex)
%      displayImage - the current form of the image actually displayed
%      currentName  - the name of the variable or expression being imaged
%      min          - the minimum intensity to display
%      max          - the maximum intensity to display
%      currentSlice - the currently selected slice
%      currentPhase - the currently selected 'phase' (z for a 4D image)
%      imageSize    - the matrix dimensions of the currently loaded image
%      imageDims    - the spatial dimensions (mm) of the currently loaded image
%      
%      imageRot     - custom rotation transform (Rx Ry Rz in deg) to apply
%
%      currentVars  - the current workspace variables
%      montage      - 0 = use imagesc,  1 = use imsc
%
%      complexMode  - 0 = Mag, 1 = Phase, 2 = Real, 3 = Imag, 4 = Colour Phase
%      fftMode      - 1st digit 0 = Img Space 1 = 2D, 2 = 3D
%                     2nd digit 0 = no shift  1 = Pre 2 = Post 3 = Both
%
% Custom Functions
%      imageDisp   - display an image with custom scale [min max] and custom colormap
%      updateCplx  - update the complex representation of the image (ABS/MAG/REAL/IMAG/CPHASE)
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
% v2.0 29-Sept-2011
%
% Changelog:
%     v1.0 Initial version 23-Aug-2011
%     v1.1 Added Mag/Phase/Real/Imag Options (May-2011)
%     v1.2 Added phplot() and imgsc() directly into vvi code to eliminate external
%          dependancies (May-2011)
%     v1.3 Added support for opening up structs of images.  Fixed colormap buttons
%          Fixed up functionality of loadVars so it will not load
%          non-images (May-2011)
%
%     v2.0 Tabbed interface for load/fft/stats. Switching from Mag/Phase/Real/Imag 
%          does not require re-loading of image (and thus does not reset slice/phase #)
%          Fixed bug setting initial min & max when the image is complex (Sep-2011)
%     v2.1 Changed FFT to 'Processing,' added options for resampling images
%          especially when you permute axes for non-isotropic scans.
%     v2.1a - Small edit to test push for BitBucket
%     v3.0a - Alpha of v3.0 Working towards using spm_slice_vol or similar
%             MEX functionality to more quickly reorient/oblique slice volumes,
%             3-axis views, loading Variables/NIfTI Volumes
%
%     v3.1a - Renamed vvi2 to vvi (to fix cross-callbacks between different GUI
%             versions). Fixed bug when 
%
%
% Last Modified by GUIDE v2.5 10-Jul-2015 02:33:32

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

% == Begin Constants ==
DEG_TO_RAD = pi/180;
% == End   Constants ==


% --- Executes just before vvi is made visible.
function vvi_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
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
handles.vvi.imageDims    = [1  1  1];   % v3: Spatial Dims of Image (mm)
handles.vvi.imageRot     = [0  0  0];   % v3: [Rx Ry Rz] (degrees) Rotations  
handles.vvi.montage      = 0;
handles.vvi.complexMode  = 0;  % 0  = Mag, 1 = Phase, 2 = Real, 3 = Imag, 4 = Colour Phase
handles.vvi.fftMode      = 00; % 00 = Image Space

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
function mainAxes_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
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

if ~isempty(x)
  y = strtrim(handles.vvi.currentVars(x, :));
else
  y = '';
end

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
if strcmp(cm, 'Jet_Mask')
  handles.vvi.colormap = colormap('Jet');
  handles.vvi.colormap(1,:) = [0 0 0];  % Set 0 value to black
  
elseif strcmp(cm, 'HSV_Mask')
  handles.vvi.colormap = colormap('HSV');
  handles.vvi.colormap(1, :) = [0 0 0]; % Set 0 value to black
  
elseif strcmp(cm, 'Parula_Mask')
  handles.vvi.colormap = colormap('Parula');
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
  img = handles.vvi.displayImage(:,:,:, handles.vvi.currentPhase);
  
else
  % Use slice min & max for standard
  img = handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase);
end

% Grab the min & max
handles.vvi.min = min(img(:));
handles.vvi.max = max(img(:));

if ~isreal(handles.vvi.min) || ~isreal(handles.vvi.max)
  handles.vvi.min = abs(handles.vvi.min);
  handles.vvi.max = abs(handles.vvi.max);
end

if handles.vvi.max == 0
  % Just set to 1 if image is blank
  handles.vvi.max = 1;
end

if handles.vvi.min > handles.vvi.max
  % Set minimum to 10% of max.
  handles.vvi.min = handles.vvi.max * .10;
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
handles.vvi.displayImage = permute(handles.vvi.displayImage, [1 2 4 3]);
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
    tmp = phplot(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase),handles.vvi.max);
    imagesc(tmp);
  else
    imagesc(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
  end
  
elseif handles.vvi.montage == 1
  % Show all slices of 1 phase
  imgsc(handles.vvi.displayImage(:,:,:,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
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
    tmp = phplot(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), handles.vvi.max);
    imagesc(tmp);
  else
    imagesc(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
  end
  
elseif handles.vvi.montage == 1
  % Show all slices of 1 phase
  imgsc(handles.vvi.displayImage(:,:,:,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
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
savefig(fileName{1});




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
  handles.vvi.currentVars = strvcat(handles.vvi.currentVars, z{ii}); %#ok<VCAT,REMFF1>
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
    'SpecularStrength',1.0, ...
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
    tmp = phplot(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), handles.vvi.max);
    imagesc(tmp);
  else
    imagesc(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
  end
  
elseif handles.vvi.montage == 1
  % Show all slices of 1 phase
  disp(size(handles.vvi.displayImage));
  imgsc(handles.vvi.displayImage(:,:,:,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
end

colormap(handles.vvi.colormap);
axis image;
axis off;
colorbar;

% --- Update the complex representation of an image ---
function handles = updateCplx(handles)

img = handles.vvi.currentImage;

% Take FFT First, if necessary
if handles.vvi.fftMode > 0 && handles.vvi.fftMode < 20
  % 2D FFT
  for ii = 1:size(img,4)
    switch handles.vvi.fftMode
      case 10
        % No Shifts
        img(:,:,:,ii) = ifft2(img(:,:,:,ii));
      case 11
        % Pre-Shift
        img(:,:,:,ii) = ifft2(fftshift(img(:,:,:,ii)));
      case 12
        % Post-Shift
        img(:,:,:,ii) = fftshift(ifft2(img(:,:,:,ii)));
      case 13
        % Both Shift
        img(:,:,:,ii) = fftshift(ifft2(fftshift(img(:,:,:,ii))));
    end
  end
  
elseif handles.vvi.fftMode > 10
  % 3D FFT
  for ii = 1:size(img,4)
    switch handles.vvi.fftMode
      case 20
        % No Shifts
        img(:,:,:,ii) = ifftn(img(:,:,:,ii));
      case 21
        % Pre-Shift
        img(:,:,:,ii) = ifftn(fftshift(img(:,:,:,ii)));
      case 22
        % Post-Shift
        img(:,:,:,ii) = fftshift(ifftn(img(:,:,:,ii)));
      case 23
        % Both Shift
        img(:,:,:,ii) = fftshift(ifftn(fftshift(img(:,:,:,ii))));
    end
  end
end

% Take mag/phase/real/imag as appropriate
switch handles.vvi.complexMode
  case 0
    img = double(abs(img));
  case 1
    img = double(angle(img));
  case 2
    img = double(real(img));
  case 3
    img = double(imag(img));
  case 4
    % Do nothing here
end

% Remove NaN and Infs from the image
img(isinf(img)) = 0; 
img(isnan(img)) = 0;

% Store img in displayImage
handles.vvi.displayImage = img;


% -- Load in an image from base workspace to vvi ---
function handles = loadImage(handles)

% Try to grab the image into the workspace
try
  img = double(evalin('base', get(handles.editVar, 'String')));
catch %#ok<CTCH>
  textMessage(handles, 'err', 'Incomplete or incorrect statement');
  return;
end

% If its larger than 4-D, remove higher dimensions
if ndims(img) > 4
  img = img(:,:,:,:,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
  textMessage(handles, 'info', 'Only first 4D of image loaded.');
end

% Check if the image is complex to disable the popupComplex control
if isreal(img)
  % Disable the mag/phase/real/imag control
  handles.vvi.complexMode = 0;
  set(handles.popupComplex, 'Enable', 'off');
  
else
  set(handles.popupComplex, 'Enable', 'on');
  
end

% v2.0: Store the complex image in handles.vvi.currentImage,
%       and define a new function displayImage to hold
%       the image after the abs/angle/real/imag operation
%       has been done

% Update current image
handles.vvi.currentImage = img;

% Update the image name
handles.vvi.currentName = get(handles.editVar, 'String');

% Update the complex representation of the image in handles.vvi.displayImage
handles = updateCplx(handles);

% Grab the min & max
handles.vvi.min = min(img(:));
handles.vvi.max = max(img(:));

% We don't want complex numbers here
if ~isreal(handles.vvi.min) || ~isreal(handles.vvi.max)
  handles.vvi.min = abs(handles.vvi.min);
  handles.vvi.max = abs(handles.vvi.max);
end

if handles.vvi.max == 0
  % If the image is totally blank, just set it to 1
  handles.vvi.max = 1;
end

if handles.vvi.min > handles.vvi.max
  handles.vvi.min = handles.vvi.max * 0.10;
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
    axes(handles.mainAxes); %#ok<MAXES>
    text(2,4, ['ERROR: ' msg], 'HorizontalAlignment','left', 'FontSize', 12, 'Color', 'red');
  else
    if size(msg, 2) == 1
      disp(['INFO: ' msg]);
    else
      disp(msg);
    end
    axes(handles.mainAxes); %#ok<MAXES>
    if size(msg, 2) == 1
      text(2,4, ['INFO: '  msg], 'HorizontalAlignment','left', 'FontSize', 12, 'Color', 'white');
    else
      text(2,4, msg, 'HorizontalAlignment','left', 'FontSize', 12, 'Color', 'white');
    end
  end
  
pause(1);


% ======= More Callbacks Below =====================================
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
handles = updateCplx(handles);

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

% --- Executes on button press in pushLoad.
function pushLoad_Callback(hObject, eventdata, handles)
% hObject    handle to pushLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make The Active Button Green, All Others Gray
set(handles.pushLoad, 'Value', 1.0);
set(handles.pushFFT,  'Value', 0.0);
set(handles.pushStats,'Value', 0.0);

% Make this panel visible, hide all others
set(handles.panelVars, 'Visible', 'on');
set(handles.panelFFT,  'Visible', 'off');

% --- Executes on button press in pushFFT.
function pushFFT_Callback(hObject, eventdata, handles)
% hObject    handle to pushFFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make The Active Button Green, All Others Gray
set(handles.pushLoad, 'Value', 0.0);
set(handles.pushFFT,  'Value', 1.0);
set(handles.pushStats,'Value', 0.0);

% Make this panel visible, hide all others
set(handles.panelVars, 'Visible', 'off');
set(handles.panelFFT,  'Visible', 'on');

% --- Executes on button press in pushStats.
function pushStats_Callback(hObject, eventdata, handles)
% hObject    handle to pushStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make The Active Button 'Tabbed', All Others 'Untabbed'
set(handles.pushLoad, 'Value', 0.0);
set(handles.pushFFT,  'Value', 0.0);
set(handles.pushStats,'Value', 1.0);

% --- Executes on button press in permuteXZ.
function permuteXZ_Callback(hObject, eventdata, handles)
% hObject    handle to permuteXZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Swap X/Z index (in order to view "coronal" or "sag")
handles.vvi.displayImage = permute(handles.vvi.displayImage, [3 2 1 4]);
size(handles.vvi.displayImage)
handles.vvi.imageSize = size(handles.vvi.displayImage);

% For 3D data, make sure that the 4th entry is populated with some value
if numel(handles.vvi.imageSize) < 4
  handles.vvi.imageSize(4) = 1;
end

% Reset View Index to Mid-Slice
handles.vvi.currentSlice = round(handles.vvi.imageSize(3)/2);
set(handles.editSlice, 'String', num2str(handles.vvi.currentSlice));

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushPermuteYZ.
function pushPermuteYZ_Callback(hObject, eventdata, handles)
% hObject    handle to pushPermuteYZ (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Swap X/Z index (in order to view "coronal" or "sag")
handles.vvi.displayImage = permute(handles.vvi.displayImage, [1 3 2 4]);
handles.vvi.imageSize = size(handles.vvi.displayImage);

% For 3D data, make sure that the 4th entry is populated with some value
if numel(handles.vvi.imageSize) < 4
  handles.vvi.imageSize(4) = 1;
end

% Reset View Index to Mid-Slice
handles.vvi.currentSlice = round(handles.vvi.imageSize(3)/2);
set(handles.editSlice, 'String', num2str(handles.vvi.currentSlice));

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushRotate.
function pushRotate_Callback(hObject, eventdata, handles)
% hObject    handle to pushRotate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Do Imtranspose
handles.vvi.displayImage = imtranspose(handles.vvi.displayImage);
handles.vvi.imageSize = size(handles.vvi.displayImage);

% For 3D data, make sure that the 4th entry is populated with some value
if numel(handles.vvi.imageSize) < 4
  handles.vvi.imageSize(4) = 1;
end

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushFlipLR.
function pushFlipLR_Callback(hObject, eventdata, handles)
% hObject    handle to pushFlipLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Do ImFlipLR
handles.vvi.displayImage = imfliplr(handles.vvi.displayImage);

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushFlipUD.
function pushFlipUD_Callback(hObject, eventdata, handles)
% hObject    handle to pushFlipUD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Do ImFlipUD
handles.vvi.displayImage = imflipud(handles.vvi.displayImage);

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes when selected object is changed in panelFFT.
function panelFFT_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in panelFFT 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)

% Update the fftMode based on the radio buttons and check boxes
if get(handles.radioImageSpace, 'Value') == 1
  handles.vvi.fftMode = 0;
elseif get(handles.radio2DFFT, 'Value') == 1
  handles.vvi.fftMode = 10;
else
  handles.vvi.fftMode = 20;
end

% Pre-shift
if get(handles.checkPreShift, 'Value') == 1
  handles.vvi.fftMode = handles.vvi.fftMode + 1;
end

% Post-shift
if get(handles.checkPostShift, 'Value') == 1
  handles.vvi.fftMode = handles.vvi.fftMode + 2;
end

% Update the image
handles = updateCplx(handles);

imageDisp(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in checkPreShift.
function checkPreShift_Callback(hObject, eventdata, handles)
% hObject    handle to checkPreShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkPreShift
panelFFT_SelectionChangeFcn(hObject, eventdata, handles)


% --- Executes on button press in checkPostShift.
function checkPostShift_Callback(hObject, eventdata, handles)
% hObject    handle to checkPostShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkPostShift
panelFFT_SelectionChangeFcn(hObject, eventdata, handles)

% --- Executes on button press in pushResample (to apply rotation & scale transforms).
function pushResample_Callback(hObject, eventdata, handles)
% hObject    handle to pushResample11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Formulate Rotation Matrix Based on Rx/Ry/Rz
DEG_TO_RAD = pi/180;

Rx_theta = handles.vvi.imageRot(1) * DEG_TO_RAD;
Ry_theta = handles.vvi.imageRot(2) * DEG_TO_RAD;
Rz_theta = handles.vvi.imageRot(3) * DEG_TO_RAD;

Rx = [1             0             0;             0              cos(Rx_theta)  sin(Rx_theta); 0             -sin(Rx_theta) cos(Rx_theta)];
Ry = [cos(Ry_theta) 0            -sin(Ry_theta); 0              1              0;             sin(Ry_theta)  0             cos(Ry_theta)];
Rz = [cos(Rz_theta) sin(Rz_theta) 0;            -sin(Rz_theta)  cos(Rz_theta)  0;             0              0             1            ];

% Formulate General Rotation
R  = Rx * Ry * Rz;

% Convert R into an affine transform
R(:,4) = [0 0 handles.vvi.imageRot(1)/2];
R(4,4) = 1;
R

% R(:,4) = handles.vvi.imageRot; % Use the rotations so that it stays centered in the volume

% Write out XFORM
write_xform(R, 'R.txt');

% Write out current image as a NIfTI

% Real
img_dcm_to_nifti(real(handles.vvi.currentImage), [], 'TMPxx_REAL', 1, handles.vvi.imageDims);
% Imag
img_dcm_to_nifti(imag(handles.vvi.currentImage), [], 'TMPxx_IMAG', 1, handles.vvi.imageDims);

% Apply XFORM
% Apply rotation matrix
opts = [' -datatype float  -searchcost mutualinfo -cost mutualinfo -bins 256 -dof 6 -searchrx -6 6' ...
        ' -searchry -6 6 -searchrz -6 6  -coarsesearch 2 -finesearch 1 -interp sinc'];

% % Faster Options -- Poor Resamplingf Scheme
% opts = '-datatype float';
      
ref = 'TMPxx_REAL.nii';
in  = 'TMPxx_REAL.nii';
out = 'TMPxx_REAL_CR.nii';

eval(['!flirt -in ' in ' -ref ' ref ' -out ' out ' -init R.txt -applyxfm ' opts]);
eval(['!fslchfiletype NIFTI ' out]);

ref = 'TMPxx_IMAG.nii';
in  = 'TMPxx_IMAG.nii';
out = 'TMPxx_IMAG_CR.nii';

eval(['!flirt -in ' in ' -ref ' ref ' -out ' out ' -init R.txt -applyxfm ' opts]);
eval(['!fslchfiletype NIFTI ' out]);

% Load Back In Real/Imag
imgR = load_nifti('TMPxx_REAL_CR.nii');
imgI = load_nifti('TMPxx_IMAG_CR.nii');

% Combine into single complex-valued variable
handles.vvi.currentImage = complex(imgR, imgI);
handles.vvi.displayImage = abs(handles.vvi.currentImage);

% Update handles structure
guidata(hObject, handles);

% Cleanup
!rm -f TMPxx*.nii

% =-=-=-=-=-=-= Dimensions/Rotation/Resample Callbacks Here! =-=-=-=-=-=-=

function editXDim_Callback(hObject, eventdata, handles)
% hObject    handle to editMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Convert String Input to Number
xDim = str2double(get(hObject, 'String'));

% Verify valid, non-zero non-negative input
if isnan(xDim) || isinf(xDim) || (xDim <= 0)
  xDim = 1; % Default back to 1
end

% Write value to handles struct
handles.vvi.imageDims(1) = xDim;

% Write back to edit input

set(hObject, 'String', num2str(handles.vvi.imageDims(1), '%.02f'));

% DEBUG: Write out image dims to command prompt
% disp(['DEBUG: ' num2str(handles.vvi.imageDims)]);

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editXDim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editXDim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editYDim_Callback(hObject, eventdata, handles)
% hObject    handle to editMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Convert String Input to Number
yDim = str2double(get(hObject, 'String'));

% Verify valid, non-zero non-negative input
if isnan(yDim) || isinf(yDim) || (yDim <= 0)
  yDim = 1; % Default back to 1
end

% Write value to handles struct
handles.vvi.imageDims(2) = yDim;

% Write back to edit input

set(hObject, 'String', num2str(handles.vvi.imageDims(2), '%.02f'));

% DEBUG: Write out image dims to command prompt
% disp(['DEBUG: ' num2str(handles.vvi.imageDims)]);

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editYDim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editYDim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editZDim_Callback(hObject, eventdata, handles)
% hObject    handle to editMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Convert String Input to Number
zDim = str2double(get(hObject, 'String'));

% Verify valid, non-zero non-negative input
if isnan(zDim) || isinf(zDim) || (zDim <= 0)
  zDim = 1; % Default back to 1
end

% Write value to handles struct
handles.vvi.imageDims(3) = zDim;

% Write back to edit input

set(hObject, 'String', num2str(handles.vvi.imageDims(3), '%.02f'));

% DEBUG: Write out image dims to command prompt
% disp(['DEBUG: ' num2str(handles.vvi.imageDims)]);

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editZDim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editZDim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editRx_Callback(hObject, eventdata, handles)
% hObject    handle to editMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Convert String Input to Number
Rx = str2double(get(hObject, 'String'));

% Verify valid input
if isnan(Rx) || isinf(Rx)
  Rx = 0; % Default back to 0 degrees
end

% Write value to handles struct
handles.vvi.imageRot(1) = Rx;

% Write back to edit input
set(hObject, 'String', num2str(handles.vvi.imageRot(1), '%.02f'));

% DEBUG: Write out image dims to command prompt
% disp(['DEBUG: ' num2str(handles.vvi.imageRot)]);

% Update handles structure
guidata(hObject, handles);



function editRy_Callback(hObject, eventdata, handles)
% hObject    handle to editMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Convert String Input to Number
Ry = str2double(get(hObject, 'String'));

% Verify valid input
if isnan(Ry) || isinf(Ry)
  Ry = 0; % Default back to 0 degrees
end

% Write value to handles struct
handles.vvi.imageRot(2) = Ry;

% Write back to edit input
set(hObject, 'String', num2str(handles.vvi.imageRot(2), '%.02f'));

% DEBUG: Write out image dims to command prompt
% disp(['DEBUG: ' num2str(handles.vvi.imageRot)]);

% Update handles structure
guidata(hObject, handles);



function editRz_Callback(hObject, eventdata, handles)
% hObject    handle to editMin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Convert String Input to Number
Rz = str2double(get(hObject, 'String'));

% Verify valid input
if isnan(Rz) || isinf(Rz)
  Rz = 0; % Default back to 0 degrees
end

% Write value to handles struct
handles.vvi.imageRot(3) = Rz;

% Write back to edit input
set(hObject, 'String', num2str(handles.vvi.imageRot(3), '%.02f'));

% DEBUG: Write out image dims to command prompt
% disp(['DEBUG: ' num2str(handles.vvi.imageRot)]);

% Update handles structure
guidata(hObject, handles);



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


% --- Executes during object creation, after setting all properties.
function editRx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function editRy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function editRz_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editRz (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushWriteOut.
function pushWriteOut_Callback(hObject, eventdata, handles)
% hObject    handle to pushWriteOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Write out current slice directly to TIFF (bypass creation of figure, smoothing, etc)
% Grab a copy of current slice

if handles.vvi.montage == 0
  if handles.vvi.complexMode == 4
    tmp = phplot(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), handles.vvi.max);
  else
    tmp = handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase);
  end
  
elseif handles.vvi.montage == 1
  msgbox('Cannot write out direct TIFF in Montage Mode');
end

% Scale tmp from 0->1
tmp = tmp - handles.vvi.min;
tmp(tmp < 0) = 0; % Remove negative values
tmp = tmp ./ (handles.vvi.max - handles.vvi.min);
tmp(tmp > 1) = 1; % Clip values above max

filename = inputdlg('Save TIFF As:');
filename = filename{1};
imwrite(tmp, filename);


% =-=-=-=-=-=-= Clickable UI Here =-=-=-=-=-=-=
