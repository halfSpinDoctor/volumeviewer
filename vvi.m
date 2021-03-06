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
%      imageHandle  - handle to current plotted image GUI (for mouse interface)
%      displayImage - the current form of the image actually displayed
%      currentName  - the name of the variable or expression being imaged
%      min          - the minimum intensity to display
%      max          - the maximum intensity to display
%      currentSlice - the currently selected slice
%      currentPhase - the currently selected 'phase' (z for a 4D image)
%      imageSize    - the matrix dimensions of the currently loaded image
%      imageDims    - the spatial dimensions (mm) of the currently loaded image
%
%      selCoords    - current selected image coordinates from imageClick
%      selValue     - instensity of current selected coordinates
%      textHandle   - handles to annotation text object
%      textLock     - 'thread locking' so that multiple callbacks to imageClick
%                     do not generate multiple text objects concurrently
%
%      currentVars  - the current workspace variables
%      montage      - 0 = use imagesc,  1 = use imsc
%
%      isComplex    - 0 = real-valued array  1 = complex-valued array
%      complexMode  - 0 = Mag, 1 = Phase, 2 = Real, 3 = Imag, 4 = Colour Phase
%      fftMode      - 1st digit 0 = Img Space 1 = 2D, 2 = 3D
%                     2nd digit 0 = no shift  1 = Pre 2 = Post 3 = Both
%                     3rd digit 0 = linear    2 = log scale
%
% Custom Variables for QMRI Mode (handles.vvi.qmri)
%      mode         - 0 = OFF   1 = DESPOT1 2 = DESPOT2-FM 3 = mcDESPOT
%      loaded       - 0 = FALSE 1 = DESPOT1 2 = DESPOT2-FM 3 = mcDESPOT
%                     Check if data for the selected mode is already loaded
%
% Variables for mcDESPOT (handles.vvi.qmri.mcd)
%      path              - path to mcDESPOT data directory
%      file
%      mcdespot_settings - data structure containing mcdespot_settings variables
%
%      data_spgr         - SPGR data matrix 4D
%      data_ssfp_0       - SSFP data matrix 4D
%      data_ssfp_180     - SSFP data matrix 4D
%
%      pd_spgr           - SPGR proton density map
%      pd_ssfp           - SSFP proton density map
%
%      fam               - DESPOT1 flip angle map
%      omega             - DESPOT2 Off-resonance map
%
%      mcd_fv            - mcDESPOT model fitted values (FV), 3D
%
%      fitHandle         - handle to plot with data points and fitted curve overlaid
%      contractHandle    - handle to figure with contractionSteps plotted
%
% Custom Functions
%      imageDisp   - display an image with custom scale [min max] and custom colormap
%      updateCplx  - update the complex representation of the image (ABS/MAG/REAL/IMAG/CPHASE)
%                    also applies FFT/FFTshift options
%      imageLogo   - display the Matlab logo
%      loadVars    - refresh list of base workspace variables
%      loadImage   - load in an image from the base workspace into vvi
%      textMessage - display a custom  message in the terminal & on image
%      imageClick  - Callback to get image click coordinates
%
%      loadMCD     - Given a directory as input, load all of the mcDESPOT
%                    images and variables needed from run_mcdespot into
%                    handles.vvi.qmri.mcd
%
% Builtin Dependancies
%      phplot      - converts a complex dataset into a color-modulated image to visualize
%                    phase and magnitude at the same time
%      imgsc       - image montage viewer
%
%
% Samuel A. Hurley
% samuel.hurley@gmail.com
% http://www.paradime.net
% v3.5 25-Jan-2015
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
%     v3.2  - Removed 'alpha' designation on version number. Removed image
%             resample function, image rotation data structs. Kept voxel size for later
%             use. Significant cleanup of GUI elements, fonts, alignment, etc.
%             Update 'magic' to 20 (Jul-2015)
%
%     v3.3  - Fixed incorrect behaviour of pre-shift for 2DFFT. Introduce an
%             isComplex variable so that negative values are not lost in
%             non-complex valued images due to abs() operation being performed.
%             Implement code for log scale button in FFT panel.
%
%     v3.4  - Added options for mcDESPOT QMRI mode, and plotting of fit
%
%     v3.5  - Initial public release on GitHub.
%
% Copyright (c) 2011-2016, Samuel A. Hurley (samuel.hurley@gmail.com)
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 
% * Redistributions of source code must retain the above copyright notice, this
%   list of conditions and the following disclaimer.
% 
% * Redistributions in binary form must reproduce the above copyright notice,
%   this list of conditions and the following disclaimer in the documentation
%   and/or other materials provided with the distribution.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%
% Last Modified by GUIDE v2.5 12-Sep-2015 16:22:59

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
% DEG_TO_RAD
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
handles.vvi.displayImage = magic(10);
handles.vvi.currentImage = magic(10);
handles.vvi.colormap     = colormap('gray');
handles.vvi.min          = 0;
handles.vvi.max          = 1;
handles.vvi.currentSlice = 1;
handles.vvi.currentPhase = 1;
handles.vvi.imageSize    = [20 20 1 1];
handles.vvi.imageDims    = [1  1  1];   % v3: Spatial Dims of Image (mm)
handles.vvi.selCoords    = [1  1  1];   %     Current selected point from imageClick
handles.vvi.selValue     = 0;
handles.vvi.textHandle   = [];
handles.vvi.textLock     = 0;
handles.vvi.currentVars  = [];
handles.vvi.montage      = 0;
handles.vvi.isComplex    = 0;   % 0 = real-valued array, 1 = complex-valued array
handles.vvi.complexMode  = 0;   % 0 = Mag, 1 = Phase, 2 = Real, 3 = Imag, 4 = Colour Phase
handles.vvi.fftMode      = 000; % 000 = Image Space, no shift, linear scale

% Variables for QMRI Mode
handles.vvi.qmri.mode    = 0;   % 0 = OFF 1 = DESPOT1 2 = DESPOT2-FM 3 = mcDESPOT
handles.vvi.qmri.loaded  = 0;   % 0 = no data loaded, do not plot, 1 = data loaded

% Variables for mcDESPOT (handles.vvi.qmri.mcd)
handles.vvi.qmri.mcd.path              = '';
handles.vvi.qmri.mcd.file              = '';
handles.vvi.qmri.mcd.mcdespot_settings = [];

handles.vvi.qmri.mcd.data_spgr         = [];
handles.vvi.qmri.mcd.data_ssfp_0       = [];
handles.vvi.qmri.mcd.data_ssfp_180     = [];

handles.vvi.qmri.mcd.pd_spgr           = [];
handles.vvi.qmri.mcd.pd_ssfp           = [];

handles.vvi.qmri.mcd.fam               = [];
handles.vvi.qmri.mcd.omega             = [];

handles.vvi.qmri.mcd.mcd_fv            = [];

handles.vvi.qmri.mcd.fitHandle         = [];
handles.vvi.qmri.mcd.contractHandle    = [];

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
handles = imageDisp(hObject, handles);

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

handles = imageDisp(hObject, handles);

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

% Check for custom maps: jet2, hsv2, parula, viridis
if strcmp(cm, 'Jet_Mask')
  handles.vvi.colormap = colormap('Jet');
  handles.vvi.colormap(1,:) = [0 0 0];  % Set 0 value to black
  
elseif strcmp(cm, 'HSV_Mask')
  handles.vvi.colormap = colormap('HSV');
  handles.vvi.colormap(1, :) = [0 0 0]; % Set 0 value to black
  
elseif strcmp(cm, 'Parula');
  % Hard-code parula so it works for older MATLAB versions
  handles.vvi.colormap = [...
   0.208100000000000   0.166300000000000   0.529200000000000
   0.211623809523810   0.189780952380952   0.577676190476190
   0.212252380952381   0.213771428571429   0.626971428571429
   0.208100000000000   0.238600000000000   0.677085714285714
   0.195904761904762   0.264457142857143   0.727900000000000
   0.170728571428571   0.291938095238095   0.779247619047619
   0.125271428571429   0.324242857142857   0.830271428571429
   0.059133333333333   0.359833333333333   0.868333333333333
   0.011695238095238   0.387509523809524   0.881957142857143
   0.005957142857143   0.408614285714286   0.882842857142857
   0.016514285714286   0.426600000000000   0.878633333333333
   0.032852380952381   0.443042857142857   0.871957142857143
   0.049814285714286   0.458571428571429   0.864057142857143
   0.062933333333333   0.473690476190476   0.855438095238095
   0.072266666666667   0.488666666666667   0.846700000000000
   0.077942857142857   0.503985714285714   0.838371428571429
   0.079347619047619   0.520023809523810   0.831180952380952
   0.074942857142857   0.537542857142857   0.826271428571429
   0.064057142857143   0.556985714285714   0.823957142857143
   0.048771428571429   0.577223809523809   0.822828571428571
   0.034342857142857   0.596580952380952   0.819852380952381
   0.026500000000000   0.613700000000000   0.813500000000000
   0.023890476190476   0.628661904761905   0.803761904761905
   0.023090476190476   0.641785714285714   0.791266666666667
   0.022771428571429   0.653485714285714   0.776757142857143
   0.026661904761905   0.664195238095238   0.760719047619048
   0.038371428571429   0.674271428571429   0.743552380952381
   0.058971428571429   0.683757142857143   0.725385714285714
   0.084300000000000   0.692833333333333   0.706166666666667
   0.113295238095238   0.701500000000000   0.685857142857143
   0.145271428571429   0.709757142857143   0.664628571428571
   0.180133333333333   0.717657142857143   0.642433333333333
   0.217828571428571   0.725042857142857   0.619261904761905
   0.258642857142857   0.731714285714286   0.595428571428571
   0.302171428571429   0.737604761904762   0.571185714285714
   0.348166666666667   0.742433333333333   0.547266666666667
   0.395257142857143   0.745900000000000   0.524442857142857
   0.442009523809524   0.748080952380952   0.503314285714286
   0.487123809523809   0.749061904761905   0.483976190476191
   0.530028571428571   0.749114285714286   0.466114285714286
   0.570857142857143   0.748519047619048   0.449390476190476
   0.609852380952381   0.747314285714286   0.433685714285714
   0.647300000000000   0.745600000000000   0.418800000000000
   0.683419047619047   0.743476190476191   0.404433333333333
   0.718409523809524   0.741133333333333   0.390476190476190
   0.752485714285714   0.738400000000000   0.376814285714286
   0.785842857142857   0.735566666666667   0.363271428571429
   0.818504761904762   0.732733333333333   0.349790476190476
   0.850657142857143   0.729900000000000   0.336028571428571
   0.882433333333333   0.727433333333333   0.321700000000000
   0.913933333333333   0.725785714285714   0.306276190476190
   0.944957142857143   0.726114285714286   0.288642857142857
   0.973895238095238   0.731395238095238   0.266647619047619
   0.993771428571429   0.745457142857143   0.240347619047619
   0.999042857142857   0.765314285714286   0.216414285714286
   0.995533333333333   0.786057142857143   0.196652380952381
   0.988000000000000   0.806600000000000   0.179366666666667
   0.978857142857143   0.827142857142857   0.163314285714286
   0.969700000000000   0.848138095238095   0.147452380952381
   0.962585714285714   0.870514285714286   0.130900000000000
   0.958871428571429   0.894900000000000   0.113242857142857
   0.959823809523810   0.921833333333333   0.094838095238095
   0.966100000000000   0.951442857142857   0.075533333333333
   0.976300000000000   0.983100000000000   0.053800000000000];

  
elseif strcmp(cm, 'Parula_Mask')
  % Hard-code parula so it works for older MATLAB versions
  handles.vvi.colormap = [...
   0.000000000000000   0.000000000000000   0.000000000000000
   0.211623809523810   0.189780952380952   0.577676190476190
   0.212252380952381   0.213771428571429   0.626971428571429
   0.208100000000000   0.238600000000000   0.677085714285714
   0.195904761904762   0.264457142857143   0.727900000000000
   0.170728571428571   0.291938095238095   0.779247619047619
   0.125271428571429   0.324242857142857   0.830271428571429
   0.059133333333333   0.359833333333333   0.868333333333333
   0.011695238095238   0.387509523809524   0.881957142857143
   0.005957142857143   0.408614285714286   0.882842857142857
   0.016514285714286   0.426600000000000   0.878633333333333
   0.032852380952381   0.443042857142857   0.871957142857143
   0.049814285714286   0.458571428571429   0.864057142857143
   0.062933333333333   0.473690476190476   0.855438095238095
   0.072266666666667   0.488666666666667   0.846700000000000
   0.077942857142857   0.503985714285714   0.838371428571429
   0.079347619047619   0.520023809523810   0.831180952380952
   0.074942857142857   0.537542857142857   0.826271428571429
   0.064057142857143   0.556985714285714   0.823957142857143
   0.048771428571429   0.577223809523809   0.822828571428571
   0.034342857142857   0.596580952380952   0.819852380952381
   0.026500000000000   0.613700000000000   0.813500000000000
   0.023890476190476   0.628661904761905   0.803761904761905
   0.023090476190476   0.641785714285714   0.791266666666667
   0.022771428571429   0.653485714285714   0.776757142857143
   0.026661904761905   0.664195238095238   0.760719047619048
   0.038371428571429   0.674271428571429   0.743552380952381
   0.058971428571429   0.683757142857143   0.725385714285714
   0.084300000000000   0.692833333333333   0.706166666666667
   0.113295238095238   0.701500000000000   0.685857142857143
   0.145271428571429   0.709757142857143   0.664628571428571
   0.180133333333333   0.717657142857143   0.642433333333333
   0.217828571428571   0.725042857142857   0.619261904761905
   0.258642857142857   0.731714285714286   0.595428571428571
   0.302171428571429   0.737604761904762   0.571185714285714
   0.348166666666667   0.742433333333333   0.547266666666667
   0.395257142857143   0.745900000000000   0.524442857142857
   0.442009523809524   0.748080952380952   0.503314285714286
   0.487123809523809   0.749061904761905   0.483976190476191
   0.530028571428571   0.749114285714286   0.466114285714286
   0.570857142857143   0.748519047619048   0.449390476190476
   0.609852380952381   0.747314285714286   0.433685714285714
   0.647300000000000   0.745600000000000   0.418800000000000
   0.683419047619047   0.743476190476191   0.404433333333333
   0.718409523809524   0.741133333333333   0.390476190476190
   0.752485714285714   0.738400000000000   0.376814285714286
   0.785842857142857   0.735566666666667   0.363271428571429
   0.818504761904762   0.732733333333333   0.349790476190476
   0.850657142857143   0.729900000000000   0.336028571428571
   0.882433333333333   0.727433333333333   0.321700000000000
   0.913933333333333   0.725785714285714   0.306276190476190
   0.944957142857143   0.726114285714286   0.288642857142857
   0.973895238095238   0.731395238095238   0.266647619047619
   0.993771428571429   0.745457142857143   0.240347619047619
   0.999042857142857   0.765314285714286   0.216414285714286
   0.995533333333333   0.786057142857143   0.196652380952381
   0.988000000000000   0.806600000000000   0.179366666666667
   0.978857142857143   0.827142857142857   0.163314285714286
   0.969700000000000   0.848138095238095   0.147452380952381
   0.962585714285714   0.870514285714286   0.130900000000000
   0.958871428571429   0.894900000000000   0.113242857142857
   0.959823809523810   0.921833333333333   0.094838095238095
   0.966100000000000   0.951442857142857   0.075533333333333
   0.976300000000000   0.983100000000000   0.053800000000000];
  
elseif strcmp(cm, 'Viridis');
  handles.vvi.colormap = [...
    0.26700401  0.00487433  0.32941519
    0.26851048  0.00960483  0.33542652
    0.26994384  0.01462494  0.34137895
    0.27130489  0.01994186  0.34726862
    0.27259384  0.02556309  0.35309303
    0.27380934  0.03149748  0.35885256
    0.27495242  0.03775181  0.36454323
    0.27602238  0.04416723  0.37016418
    0.27701840  0.05034437  0.37571452
    0.27794143  0.05632444  0.38119074
    0.27879067  0.06214536  0.38659204
    0.27956550  0.06783587  0.39191723
    0.28026658  0.07341724  0.39716349
    0.28089358  0.07890703  0.40232944
    0.28144581  0.08431970  0.40741404
    0.28192358  0.08966622  0.41241521
    0.28232739  0.09495545  0.41733086
    0.28265633  0.10019576  0.42216032
    0.28291049  0.10539345  0.42690202
    0.28309095  0.11055307  0.43155375
    0.28319704  0.11567966  0.43611482
    0.28322882  0.12077701  0.44058404
    0.28318684  0.12584799  0.44496000
    0.28307200  0.13089477  0.44924127
    0.28288389  0.13592005  0.45342734
    0.28262297  0.14092556  0.45751726
    0.28229037  0.14591233  0.46150995
    0.28188676  0.15088147  0.46540474
    0.28141228  0.15583425  0.46920128
    0.28086773  0.16077132  0.47289909
    0.28025468  0.16569272  0.47649762
    0.27957399  0.17059884  0.47999675
    0.27882618  0.17549020  0.48339654
    0.27801236  0.18036684  0.48669702
    0.27713437  0.18522836  0.48989831
    0.27619376  0.19007447  0.49300074
    0.27519116  0.19490540  0.49600488
    0.27412802  0.19972086  0.49891131
    0.27300596  0.20452049  0.50172076
    0.27182812  0.20930306  0.50443413
    0.27059473  0.21406899  0.50705243
    0.26930756  0.21881782  0.50957678
    0.26796846  0.22354911  0.51200840
    0.26657984  0.22826210  0.51434870
    0.26514450  0.23295593  0.51659930
    0.26366320  0.23763078  0.51876163
    0.26213801  0.24228619  0.52083736
    0.26057103  0.24692170  0.52282822
    0.25896451  0.25153685  0.52473609
    0.25732244  0.25613040  0.52656332
    0.25564519  0.26070284  0.52831152
    0.25393498  0.26525384  0.52998273
    0.25219404  0.26978306  0.53157905
    0.25042462  0.27429024  0.53310261
    0.24862899  0.27877509  0.53455561
    0.24681140  0.28323662  0.53594093
    0.24497208  0.28767547  0.53726018
    0.24311324  0.29209154  0.53851561
    0.24123708  0.29648471  0.53970946
    0.23934575  0.30085494  0.54084398
    0.23744138  0.30520222  0.54192140
    0.23552606  0.30952657  0.54294396
    0.23360277  0.31382773  0.54391424
    0.23167350  0.31810580  0.54483444
    0.22973926  0.32236127  0.54570633
    0.22780192  0.32659432  0.54653200
    0.22586330  0.33080515  0.54731353
    0.22392515  0.33499400  0.54805291
    0.22198915  0.33916114  0.54875211
    0.22005691  0.34330688  0.54941304
    0.21812995  0.34743154  0.55003755
    0.21620971  0.35153548  0.55062743
    0.21429757  0.35561907  0.55118440
    0.21239477  0.35968273  0.55171011
    0.21050310  0.36372671  0.55220646
    0.20862342  0.36775151  0.55267486
    0.20675628  0.37175775  0.55311653
    0.20490257  0.37574589  0.55353282
    0.20306309  0.37971644  0.55392505
    0.20123854  0.38366989  0.55429441
    0.19942950  0.38760678  0.55464205
    0.19763650  0.39152762  0.55496905
    0.19585993  0.39543297  0.55527637
    0.19410009  0.39932336  0.55556494
    0.19235719  0.40319934  0.55583559
    0.19063135  0.40706148  0.55608907
    0.18892259  0.41091033  0.55632606
    0.18723083  0.41474645  0.55654717
    0.18555593  0.41857040  0.55675292
    0.18389763  0.42238275  0.55694377
    0.18225561  0.42618405  0.55712010
    0.18062949  0.42997486  0.55728221
    0.17901879  0.43375572  0.55743035
    0.17742298  0.43752720  0.55756466
    0.17584148  0.44128981  0.55768526
    0.17427363  0.44504410  0.55779216
    0.17271876  0.44879060  0.55788532
    0.17117615  0.45252980  0.55796464
    0.16964573  0.45626209  0.55803034
    0.16812641  0.45998802  0.55808199
    0.16661710  0.46370813  0.55811913
    0.16511703  0.46742290  0.55814141
    0.16362543  0.47113278  0.55814842
    0.16214155  0.47483821  0.55813967
    0.16066467  0.47853961  0.55811466
    0.15919413  0.48223740  0.55807280
    0.15772933  0.48593197  0.55801347
    0.15626973  0.48962370  0.55793600
    0.15481488  0.49331293  0.55783967
    0.15336445  0.49700003  0.55772371
    0.15191820  0.50068529  0.55758733
    0.15047605  0.50436904  0.55742968
    0.14903918  0.50805136  0.55725050
    0.14760731  0.51173263  0.55704861
    0.14618026  0.51541316  0.55682271
    0.14475863  0.51909319  0.55657181
    0.14334327  0.52277292  0.55629491
    0.14193527  0.52645254  0.55599097
    0.14053599  0.53013219  0.55565893
    0.13914708  0.53381201  0.55529773
    0.13777048  0.53749213  0.55490625
    0.13640850  0.54117264  0.55448339
    0.13506561  0.54485335  0.55402906
    0.13374299  0.54853458  0.55354108
    0.13244401  0.55221637  0.55301828
    0.13117249  0.55589872  0.55245948
    0.12993270  0.55958162  0.55186354
    0.12872938  0.56326503  0.55122927
    0.12756771  0.56694891  0.55055551
    0.12645338  0.57063316  0.54984110
    0.12539383  0.57431754  0.54908564
    0.12439474  0.57800205  0.54828740
    0.12346281  0.58168661  0.54744498
    0.12260562  0.58537105  0.54655722
    0.12183122  0.58905521  0.54562298
    0.12114807  0.59273889  0.54464114
    0.12056501  0.59642187  0.54361058
    0.12009154  0.60010387  0.54253043
    0.11973756  0.60378459  0.54139999
    0.11951163  0.60746388  0.54021751
    0.11942341  0.61114146  0.53898192
    0.11948255  0.61481702  0.53769219
    0.11969858  0.61849025  0.53634733
    0.12008079  0.62216081  0.53494633
    0.12063824  0.62582833  0.53348834
    0.12137972  0.62949242  0.53197275
    0.12231244  0.63315277  0.53039808
    0.12344358  0.63680899  0.52876343
    0.12477953  0.64046069  0.52706792
    0.12632581  0.64410744  0.52531069
    0.12808703  0.64774881  0.52349092
    0.13006688  0.65138436  0.52160791
    0.13226797  0.65501363  0.51966086
    0.13469183  0.65863619  0.51764880
    0.13733921  0.66225157  0.51557101
    0.14020991  0.66585927  0.51342680
    0.14330291  0.66945881  0.51121549
    0.14661640  0.67304968  0.50893644
    0.15014782  0.67663139  0.50658890
    0.15389405  0.68020343  0.50417217
    0.15785146  0.68376525  0.50168574
    0.16201598  0.68731632  0.49912906
    0.16638320  0.69085611  0.49650163
    0.17094840  0.69438405  0.49380294
    0.17570671  0.69789960  0.49103252
    0.18065314  0.70140222  0.48818938
    0.18578266  0.70489133  0.48527326
    0.19109018  0.70836635  0.48228395
    0.19657063  0.71182668  0.47922108
    0.20221902  0.71527175  0.47608431
    0.20803045  0.71870095  0.47287330
    0.21400015  0.72211371  0.46958774
    0.22012381  0.72550945  0.46622638
    0.22639690  0.72888753  0.46278934
    0.23281498  0.73224735  0.45927675
    0.23937390  0.73558828  0.45568838
    0.24606968  0.73890972  0.45202405
    0.25289851  0.74221104  0.44828355
    0.25985676  0.74549162  0.44446673
    0.26694127  0.74875084  0.44057284
    0.27414922  0.75198807  0.43660090
    0.28147681  0.75520266  0.43255207
    0.28892102  0.75839399  0.42842626
    0.29647899  0.76156142  0.42422341
    0.30414796  0.76470433  0.41994346
    0.31192534  0.76782207  0.41558638
    0.31980860  0.77091403  0.41115215
    0.32779580  0.77397953  0.40664011
    0.33588539  0.77701790  0.40204917
    0.34407411  0.78002855  0.39738103
    0.35235985  0.78301086  0.39263579
    0.36074053  0.78596419  0.38781353
    0.36921420  0.78888793  0.38291438
    0.37777892  0.79178146  0.37793850
    0.38643282  0.79464415  0.37288606
    0.39517408  0.79747541  0.36775726
    0.40400101  0.80027461  0.36255223
    0.41291350  0.80304099  0.35726893
    0.42190813  0.80577412  0.35191009
    0.43098317  0.80847343  0.34647607
    0.44013691  0.81113836  0.34096730
    0.44936763  0.81376835  0.33538426
    0.45867362  0.81636288  0.32972749
    0.46805314  0.81892143  0.32399761
    0.47750446  0.82144351  0.31819529
    0.48702580  0.82392862  0.31232133
    0.49661536  0.82637633  0.30637661
    0.50627130  0.82878621  0.30036211
    0.51599182  0.83115784  0.29427888
    0.52577622  0.83349064  0.28812650
    0.53562110  0.83578452  0.28190832
    0.54552440  0.83803918  0.27562602
    0.55548397  0.84025437  0.26928147
    0.56549760  0.84242990  0.26287683
    0.57556297  0.84456561  0.25641457
    0.58567772  0.84666139  0.24989748
    0.59583934  0.84871722  0.24332878
    0.60604528  0.85073310  0.23671214
    0.61629283  0.85270912  0.23005179
    0.62657923  0.85464543  0.22335258
    0.63690157  0.85654226  0.21662012
    0.64725685  0.85839991  0.20986086
    0.65764197  0.86021878  0.20308229
    0.66805369  0.86199932  0.19629307
    0.67848868  0.86374211  0.18950326
    0.68894351  0.86544779  0.18272455
    0.69941463  0.86711711  0.17597055
    0.70989842  0.86875092  0.16925712
    0.72039115  0.87035015  0.16260273
    0.73088902  0.87191584  0.15602894
    0.74138803  0.87344918  0.14956101
    0.75188414  0.87495143  0.14322828
    0.76237342  0.87642392  0.13706449
    0.77285183  0.87786808  0.13110864
    0.78331535  0.87928545  0.12540538
    0.79375994  0.88067763  0.12000532
    0.80418159  0.88204632  0.11496505
    0.81457634  0.88339329  0.11034678
    0.82494028  0.88472036  0.10621724
    0.83526959  0.88602943  0.10264590
    0.84556056  0.88732243  0.09970219
    0.85580960  0.88860134  0.09745186
    0.86601325  0.88986815  0.09595277
    0.87616824  0.89112487  0.09525046
    0.88627146  0.89237353  0.09537439
    0.89632002  0.89361614  0.09633538
    0.90631121  0.89485467  0.09812496
    0.91624212  0.89609127  0.10071680
    0.92610579  0.89732977  0.10407067
    0.93590444  0.89857040  0.10813094
    0.94563626  0.89981500  0.11283773
    0.95529972  0.90106534  0.11812832
    0.96489353  0.90232311  0.12394051
    0.97441665  0.90358991  0.13021494
    0.98386829  0.90486726  0.13689671
    0.99324789  0.90615657  0.1439362]; 

elseif strcmp(cm, 'Viridis_Mask');
  handles.vvi.colormap = [...
    0.0         0.0         0.0       
    0.26851048  0.00960483  0.33542652
    0.26994384  0.01462494  0.34137895
    0.27130489  0.01994186  0.34726862
    0.27259384  0.02556309  0.35309303
    0.27380934  0.03149748  0.35885256
    0.27495242  0.03775181  0.36454323
    0.27602238  0.04416723  0.37016418
    0.27701840  0.05034437  0.37571452
    0.27794143  0.05632444  0.38119074
    0.27879067  0.06214536  0.38659204
    0.27956550  0.06783587  0.39191723
    0.28026658  0.07341724  0.39716349
    0.28089358  0.07890703  0.40232944
    0.28144581  0.08431970  0.40741404
    0.28192358  0.08966622  0.41241521
    0.28232739  0.09495545  0.41733086
    0.28265633  0.10019576  0.42216032
    0.28291049  0.10539345  0.42690202
    0.28309095  0.11055307  0.43155375
    0.28319704  0.11567966  0.43611482
    0.28322882  0.12077701  0.44058404
    0.28318684  0.12584799  0.44496000
    0.28307200  0.13089477  0.44924127
    0.28288389  0.13592005  0.45342734
    0.28262297  0.14092556  0.45751726
    0.28229037  0.14591233  0.46150995
    0.28188676  0.15088147  0.46540474
    0.28141228  0.15583425  0.46920128
    0.28086773  0.16077132  0.47289909
    0.28025468  0.16569272  0.47649762
    0.27957399  0.17059884  0.47999675
    0.27882618  0.17549020  0.48339654
    0.27801236  0.18036684  0.48669702
    0.27713437  0.18522836  0.48989831
    0.27619376  0.19007447  0.49300074
    0.27519116  0.19490540  0.49600488
    0.27412802  0.19972086  0.49891131
    0.27300596  0.20452049  0.50172076
    0.27182812  0.20930306  0.50443413
    0.27059473  0.21406899  0.50705243
    0.26930756  0.21881782  0.50957678
    0.26796846  0.22354911  0.51200840
    0.26657984  0.22826210  0.51434870
    0.26514450  0.23295593  0.51659930
    0.26366320  0.23763078  0.51876163
    0.26213801  0.24228619  0.52083736
    0.26057103  0.24692170  0.52282822
    0.25896451  0.25153685  0.52473609
    0.25732244  0.25613040  0.52656332
    0.25564519  0.26070284  0.52831152
    0.25393498  0.26525384  0.52998273
    0.25219404  0.26978306  0.53157905
    0.25042462  0.27429024  0.53310261
    0.24862899  0.27877509  0.53455561
    0.24681140  0.28323662  0.53594093
    0.24497208  0.28767547  0.53726018
    0.24311324  0.29209154  0.53851561
    0.24123708  0.29648471  0.53970946
    0.23934575  0.30085494  0.54084398
    0.23744138  0.30520222  0.54192140
    0.23552606  0.30952657  0.54294396
    0.23360277  0.31382773  0.54391424
    0.23167350  0.31810580  0.54483444
    0.22973926  0.32236127  0.54570633
    0.22780192  0.32659432  0.54653200
    0.22586330  0.33080515  0.54731353
    0.22392515  0.33499400  0.54805291
    0.22198915  0.33916114  0.54875211
    0.22005691  0.34330688  0.54941304
    0.21812995  0.34743154  0.55003755
    0.21620971  0.35153548  0.55062743
    0.21429757  0.35561907  0.55118440
    0.21239477  0.35968273  0.55171011
    0.21050310  0.36372671  0.55220646
    0.20862342  0.36775151  0.55267486
    0.20675628  0.37175775  0.55311653
    0.20490257  0.37574589  0.55353282
    0.20306309  0.37971644  0.55392505
    0.20123854  0.38366989  0.55429441
    0.19942950  0.38760678  0.55464205
    0.19763650  0.39152762  0.55496905
    0.19585993  0.39543297  0.55527637
    0.19410009  0.39932336  0.55556494
    0.19235719  0.40319934  0.55583559
    0.19063135  0.40706148  0.55608907
    0.18892259  0.41091033  0.55632606
    0.18723083  0.41474645  0.55654717
    0.18555593  0.41857040  0.55675292
    0.18389763  0.42238275  0.55694377
    0.18225561  0.42618405  0.55712010
    0.18062949  0.42997486  0.55728221
    0.17901879  0.43375572  0.55743035
    0.17742298  0.43752720  0.55756466
    0.17584148  0.44128981  0.55768526
    0.17427363  0.44504410  0.55779216
    0.17271876  0.44879060  0.55788532
    0.17117615  0.45252980  0.55796464
    0.16964573  0.45626209  0.55803034
    0.16812641  0.45998802  0.55808199
    0.16661710  0.46370813  0.55811913
    0.16511703  0.46742290  0.55814141
    0.16362543  0.47113278  0.55814842
    0.16214155  0.47483821  0.55813967
    0.16066467  0.47853961  0.55811466
    0.15919413  0.48223740  0.55807280
    0.15772933  0.48593197  0.55801347
    0.15626973  0.48962370  0.55793600
    0.15481488  0.49331293  0.55783967
    0.15336445  0.49700003  0.55772371
    0.15191820  0.50068529  0.55758733
    0.15047605  0.50436904  0.55742968
    0.14903918  0.50805136  0.55725050
    0.14760731  0.51173263  0.55704861
    0.14618026  0.51541316  0.55682271
    0.14475863  0.51909319  0.55657181
    0.14334327  0.52277292  0.55629491
    0.14193527  0.52645254  0.55599097
    0.14053599  0.53013219  0.55565893
    0.13914708  0.53381201  0.55529773
    0.13777048  0.53749213  0.55490625
    0.13640850  0.54117264  0.55448339
    0.13506561  0.54485335  0.55402906
    0.13374299  0.54853458  0.55354108
    0.13244401  0.55221637  0.55301828
    0.13117249  0.55589872  0.55245948
    0.12993270  0.55958162  0.55186354
    0.12872938  0.56326503  0.55122927
    0.12756771  0.56694891  0.55055551
    0.12645338  0.57063316  0.54984110
    0.12539383  0.57431754  0.54908564
    0.12439474  0.57800205  0.54828740
    0.12346281  0.58168661  0.54744498
    0.12260562  0.58537105  0.54655722
    0.12183122  0.58905521  0.54562298
    0.12114807  0.59273889  0.54464114
    0.12056501  0.59642187  0.54361058
    0.12009154  0.60010387  0.54253043
    0.11973756  0.60378459  0.54139999
    0.11951163  0.60746388  0.54021751
    0.11942341  0.61114146  0.53898192
    0.11948255  0.61481702  0.53769219
    0.11969858  0.61849025  0.53634733
    0.12008079  0.62216081  0.53494633
    0.12063824  0.62582833  0.53348834
    0.12137972  0.62949242  0.53197275
    0.12231244  0.63315277  0.53039808
    0.12344358  0.63680899  0.52876343
    0.12477953  0.64046069  0.52706792
    0.12632581  0.64410744  0.52531069
    0.12808703  0.64774881  0.52349092
    0.13006688  0.65138436  0.52160791
    0.13226797  0.65501363  0.51966086
    0.13469183  0.65863619  0.51764880
    0.13733921  0.66225157  0.51557101
    0.14020991  0.66585927  0.51342680
    0.14330291  0.66945881  0.51121549
    0.14661640  0.67304968  0.50893644
    0.15014782  0.67663139  0.50658890
    0.15389405  0.68020343  0.50417217
    0.15785146  0.68376525  0.50168574
    0.16201598  0.68731632  0.49912906
    0.16638320  0.69085611  0.49650163
    0.17094840  0.69438405  0.49380294
    0.17570671  0.69789960  0.49103252
    0.18065314  0.70140222  0.48818938
    0.18578266  0.70489133  0.48527326
    0.19109018  0.70836635  0.48228395
    0.19657063  0.71182668  0.47922108
    0.20221902  0.71527175  0.47608431
    0.20803045  0.71870095  0.47287330
    0.21400015  0.72211371  0.46958774
    0.22012381  0.72550945  0.46622638
    0.22639690  0.72888753  0.46278934
    0.23281498  0.73224735  0.45927675
    0.23937390  0.73558828  0.45568838
    0.24606968  0.73890972  0.45202405
    0.25289851  0.74221104  0.44828355
    0.25985676  0.74549162  0.44446673
    0.26694127  0.74875084  0.44057284
    0.27414922  0.75198807  0.43660090
    0.28147681  0.75520266  0.43255207
    0.28892102  0.75839399  0.42842626
    0.29647899  0.76156142  0.42422341
    0.30414796  0.76470433  0.41994346
    0.31192534  0.76782207  0.41558638
    0.31980860  0.77091403  0.41115215
    0.32779580  0.77397953  0.40664011
    0.33588539  0.77701790  0.40204917
    0.34407411  0.78002855  0.39738103
    0.35235985  0.78301086  0.39263579
    0.36074053  0.78596419  0.38781353
    0.36921420  0.78888793  0.38291438
    0.37777892  0.79178146  0.37793850
    0.38643282  0.79464415  0.37288606
    0.39517408  0.79747541  0.36775726
    0.40400101  0.80027461  0.36255223
    0.41291350  0.80304099  0.35726893
    0.42190813  0.80577412  0.35191009
    0.43098317  0.80847343  0.34647607
    0.44013691  0.81113836  0.34096730
    0.44936763  0.81376835  0.33538426
    0.45867362  0.81636288  0.32972749
    0.46805314  0.81892143  0.32399761
    0.47750446  0.82144351  0.31819529
    0.48702580  0.82392862  0.31232133
    0.49661536  0.82637633  0.30637661
    0.50627130  0.82878621  0.30036211
    0.51599182  0.83115784  0.29427888
    0.52577622  0.83349064  0.28812650
    0.53562110  0.83578452  0.28190832
    0.54552440  0.83803918  0.27562602
    0.55548397  0.84025437  0.26928147
    0.56549760  0.84242990  0.26287683
    0.57556297  0.84456561  0.25641457
    0.58567772  0.84666139  0.24989748
    0.59583934  0.84871722  0.24332878
    0.60604528  0.85073310  0.23671214
    0.61629283  0.85270912  0.23005179
    0.62657923  0.85464543  0.22335258
    0.63690157  0.85654226  0.21662012
    0.64725685  0.85839991  0.20986086
    0.65764197  0.86021878  0.20308229
    0.66805369  0.86199932  0.19629307
    0.67848868  0.86374211  0.18950326
    0.68894351  0.86544779  0.18272455
    0.69941463  0.86711711  0.17597055
    0.70989842  0.86875092  0.16925712
    0.72039115  0.87035015  0.16260273
    0.73088902  0.87191584  0.15602894
    0.74138803  0.87344918  0.14956101
    0.75188414  0.87495143  0.14322828
    0.76237342  0.87642392  0.13706449
    0.77285183  0.87786808  0.13110864
    0.78331535  0.87928545  0.12540538
    0.79375994  0.88067763  0.12000532
    0.80418159  0.88204632  0.11496505
    0.81457634  0.88339329  0.11034678
    0.82494028  0.88472036  0.10621724
    0.83526959  0.88602943  0.10264590
    0.84556056  0.88732243  0.09970219
    0.85580960  0.88860134  0.09745186
    0.86601325  0.88986815  0.09595277
    0.87616824  0.89112487  0.09525046
    0.88627146  0.89237353  0.09537439
    0.89632002  0.89361614  0.09633538
    0.90631121  0.89485467  0.09812496
    0.91624212  0.89609127  0.10071680
    0.92610579  0.89732977  0.10407067
    0.93590444  0.89857040  0.10813094
    0.94563626  0.89981500  0.11283773
    0.95529972  0.90106534  0.11812832
    0.96489353  0.90232311  0.12394051
    0.97441665  0.90358991  0.13021494
    0.98386829  0.90486726  0.13689671
    0.99324789  0.90615657  0.1439362]; 
  
else
  % Standard colormap
  handles.vvi.colormap = colormap(cm);
end

% Update image
handles = imageDisp(hObject, handles);

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
  handles.vvi.min = handles.vvi.max * 0.10;
  set(handles.editMin, 'String', num2str(handles.vvi.min));
  textMessage(handles, 'err', 'You set the min higher than the max')
end

handles = imageDisp(hObject, handles);

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
  handles.vvi.max = handles.vvi.min * 1.10;
  set(handles.editMax, 'String', num2str(handles.vvi.max));
  textMessage(handles, 'err', 'You set the max higher than the min');
end

handles = imageDisp(hObject, handles);

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
if handles.vvi.isComplex == 0
  handles.vvi.min = min(img(:));
  handles.vvi.max = max(img(:));
else
  handles.vvi.min = min(abs(img(:)));
  handles.vvi.max = max(abs(img(:)));
end

if handles.vvi.max < handles.vvi.min
  % If max is less than min, set it to min + 10%
  handles.vvi.max = handles.vvi.min * 1.10;
end

if handles.vvi.min > handles.vvi.max
  % Set minimum to 10% of max.
  handles.vvi.min = handles.vvi.max * 0.10;
end

% Set the value of the txt boxes
set(handles.editMin, 'String', num2str(handles.vvi.min));
set(handles.editMax, 'String', num2str(handles.vvi.max));

% Update the image
handles = imageDisp(hObject, handles);

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

handles = imageDisp(hObject, handles);

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
  handles = imageDisp(hObject, handles);
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
  handles = imageDisp(hObject, handles);
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

handles = imageDisp(hObject, handles);

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
  handles = imageDisp(hObject, handles);
end

% Update handles structure
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
  handles = imageDisp(hObject, handles);
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

handles = imageDisp(hObject, handles);

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
for ii = 1:size(z, 2)
  if ii == 1
    handles.vvi.currentVars = z{ii};
  else
    handles.vvi.currentVars = char(handles.vvi.currentVars, z{ii});
  end
end

% Update the string in listVars
set(handles.listVars, 'String', handles.vvi.currentVars);

% --- Dispaly Matlab Logo on mainAxes ---
function imageLogo(handles)

% Populate main axis w matlab logo
L = 40*membrane(1,25);

axes(handles.mainAxes);
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
function handles = imageDisp(hObject, handles)

axes(handles.mainAxes);

if handles.vvi.montage == 0
  if handles.vvi.complexMode == 4
    tmp = phplot(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), handles.vvi.max);
    imageHandle = imagesc(tmp);
  else
    imageHandle = imagesc(handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
  end
  
elseif handles.vvi.montage == 1
  % Show all slices of 1 phase
  % disp(size(handles.vvi.displayImage));
  imageHandle = imgsc(handles.vvi.displayImage(:,:,:,handles.vvi.currentPhase), [handles.vvi.min handles.vvi.max]);
end

colormap(handles.vvi.colormap);
axis image;
axis off;
colorbar;

% Set image handle to call imageClick callback
set(imageHandle, 'ButtonDownFcn', {@imageClick, hObject});

% Create image pixel info corner
hPixelinfo = impixelinfoval(handles.figure1, imageHandle);
set(hPixelinfo, 'FontName', 'Tahoma');
set(hPixelinfo, 'FontSize', 11.0);

% Save handle to image for GUI click interface
handles.vvi.imageHandle = imageHandle;


% --- Callback to return image click coordinates ---
function imageClick(objectHandle, eventData, hObject)

% Get fresh GUI data
handles = guidata(hObject);

% Workaround for old matlab version that does not support eventData
v = ver('MATLAB');
if str2double(v.Version) < 8.4
  % Old version - use alternative means of getting needed fields
  eventData.Button = 1;
  pt = get(gca, 'CurrentPoint');
  eventData.IntersectionPoint(1) = pt(1,1);
  eventData.IntersectionPoint(2) = pt(1,2);
end
% </WORKAROUND>

% Only execute this function for non-montage, if lock is not set, and if left click
if (handles.vvi.montage == 0) && (eventData.Button == 1) && (handles.vvi.textLock ~= 1)
  
  if handles.vvi.montage
    % X-Y click coordinates - calibration factor
    selCoords(1) = eventData.IntersectionPoint(2);
    selCoords(2) = eventData.IntersectionPoint(1);
    selCoords(3) = handles.vvi.currentSlice;
  else
    selCoords(1) = eventData.IntersectionPoint(2) - 0.02;
    selCoords(2) = eventData.IntersectionPoint(1) - 0.02;
    selCoords(3) = handles.vvi.currentSlice;
  end
  
  selCoords  = round(selCoords);
  
  % Make sure selected coordinates are within image matrix indicies
  if selCoords(1) < 1
    selCoords(1) = 1;
  elseif selCoords(1) > size(handles.vvi.displayImage, 1)
    selCoords(1) = size(handles.vvi.displayImage, 1);
  end
  
  if selCoords(2) < 1
    selCoords(2) = 1;
  elseif selCoords(2) > size(handles.vvi.displayImage, 2)
    selCoords(2) = size(handles.vvi.displayImage, 2);
  end
  
  % Image value at X-Y coordinates
  selValue = handles.vvi.displayImage(selCoords(1), selCoords(2), selCoords(3), :);
  
  % DEBUG: Display unrounded selection values
  % disp(['FLOAT COORDS: X:' num2str(selCoords(1)) ' Y:' num2str(selCoords(2)) ' V:' num2str(selValue)]);
  
  % Format leading zeros for display
  if     handles.vvi.imageSize(1) <   10 && handles.vvi.imageSize(2) <   10
    strFormat = '%01.0f';
  elseif handles.vvi.imageSize(1) <  100 && handles.vvi.imageSize(2) <  100
    strFormat = '%02.0f';
  elseif handles.vvi.imageSize(1) < 1000 && handles.vvi.imageSize(2) < 1000
    strFormat = '%03.0f';
  else
    strFormat = '%.0f';
  end
  
  % Create X/Y/V string
  msgString = ['Selected: X:' num2str(selCoords(1), strFormat) ' Y:' num2str(selCoords(2), strFormat) ' V:' num2str(selValue(1))];
  
  % == Image Marker Code Below ==
  img = handles.vvi.displayImage(:,:,handles.vvi.currentSlice,handles.vvi.currentPhase);
  
  % Make sure marker indicies do not go past bounds of image indicies
  xFarLeft  = max(selCoords(1)-3, 1);
  xLeft     = max(selCoords(1)-1, 1);
  xFarRight = min(selCoords(1)+3, size(img,1));
  xRight    = min(selCoords(1)+1, size(img,1));
  
  yFarLeft  = max(selCoords(2)-3, 1);
  yLeft     = max(selCoords(2)-1, 1);
  yFarRight = min(selCoords(2)+3, size(img,2));
  yRight    = min(selCoords(2)+1, size(img,2));
  
  % Put marker on image
  if handles.vvi.complexMode == 4
    
    % Apply Phplot to make colour phase map
    img = phplot(img, handles.vvi.max);
    
    % Use a white cross for colour phase images
    img([xFarLeft:xLeft xRight:xFarRight],selCoords(2),:) = 255;
    img(selCoords(1),[yFarLeft:yLeft yRight:yFarRight],:) = 255;
  else
    
    % Use inverted cross. Overlapping crosses make centre pixel the original value
    maxVal = max(img(:));
    img(xFarLeft:xFarRight,selCoords(2),:) = maxVal - img(xFarLeft:xFarRight,selCoords(2),:);
    img(selCoords(1),yFarLeft:yFarRight,:) = maxVal - img(selCoords(1),yFarLeft:yFarRight,:);
  end
  
  set(objectHandle, 'CData', img);
  % == DONE Image Marker Code ==
  
  if isa(handles.vvi.textHandle, 'handle') && isvalid(handles.vvi.textHandle)
    
    % Set the text in the existing object
    set(handles.vvi.textHandle, 'String', msgString);
    
    % Also display updated text on command line
    disp([msgString]);
  
  else
    % Set lock in handles structure
    handles.vvi.textLock   = 1;
    guidata(hObject, handles);
    
    % Create new text graphics object - this will also show on the cmd line
    handles.vvi.textHandle = textMessage(handles, [], msgString);
    
    % Unset lock in handles structure
    handles.vvi.textLock   = 0;
    guidata(hObject, handles);
  end
  
  % Update the handles.vvi structure with new values
  handles.vvi.selCoords = selCoords;
  handles.vvi.selValue  = selValue;
  guidata(hObject, handles);
  
  % If QMRI Mode is on (and data are loaded), do fit plots
  if handles.vvi.qmri.mode == 3 && handles.vvi.qmri.loaded == 3
    
    % Setup function arguments
    mcd = handles.vvi.qmri.mcd;
    data_spgr_sl = squeeze(mcd.data_spgr(selCoords(1), selCoords(2), selCoords(3), :))';
    data_ssfp_0_sl = squeeze(mcd.data_ssfp_0(selCoords(1), selCoords(2), selCoords(3), :))';
    data_ssfp_180_sl = squeeze(mcd.data_ssfp_180(selCoords(1), selCoords(2), selCoords(3), :))';
    
    pd_spgr_sl = mcd.pd_spgr(selCoords(1), selCoords(2), selCoords(3));
    pd_ssfp_sl = mcd.pd_ssfp(selCoords(1), selCoords(2), selCoords(3));
    
    fam_sl = mcd.fam(selCoords(1), selCoords(2), selCoords(3));
    omega_sl = mcd.omega(selCoords(1), selCoords(2), selCoords(3));

    % 1st and 2nd element of IG are T1 and T2 single - not actually used in
    % algorithm so just supply 1s for both of these values
    ig = [1 1 pd_spgr_sl(:) pd_ssfp_sl(:)];
    
    numThreads = 1;
    
    % Call mcdespot_model_fit with debug == 2 to get plot fitted curve to data
    try
      figure(handles.vvi.qmri.mcd.fitHandle);
    catch
      handles.vvi.qmri.mcd.fitHandle = figure;
      guidata(hObject, handles);
    end
    
    DEBUG = 2;
    [fv rnrm] = mcdespot_model_fit(data_spgr_sl, data_ssfp_0_sl, data_ssfp_180_sl, mcd.mcdespot_settings.alpha_spgr, mcd.mcdespot_settings.alpha_ssfp, mcd.mcdespot_settings.tr_spgr, mcd.mcdespot_settings.tr_ssfp, fam_sl(:), omega_sl(:), ig, numThreads, DEBUG);
  
    % Call mcdespot_model_fit again with debug == 4 to get plot of contraction steps
    try
      figure(handles.vvi.qmri.mcd.contractHandle);
    catch
      handles.vvi.qmri.mcd.contractHandle = figure;
      guidata(hObject, handles);
    end
    
    DEBUG = 4;
    [fv rnrm] = mcdespot_model_fit(data_spgr_sl, data_ssfp_0_sl, data_ssfp_180_sl, mcd.mcdespot_settings.alpha_spgr, mcd.mcdespot_settings.alpha_ssfp, mcd.mcdespot_settings.tr_spgr, mcd.mcdespot_settings.tr_ssfp, fam_sl(:), omega_sl(:), ig, numThreads, DEBUG);
  
    % Display mcDESPOT Parameters at this location
    fv = squeeze(handles.vvi.qmri.mcd.mcd_fv(selCoords(1), selCoords(2), selCoords(3), :));
    disp(['  ' num2str(fv(1)*1000, '%03.0f') ' ms  | ' num2str(fv(2)*1000, '%04.0f') ' ms |   ' num2str(fv(3)*1000, '%02.0f') ' ms   |  ' num2str(fv(4)*1000, '%03.0f') ' ms | ' num2str(fv(5)*100, '%02.0f') '% | ' num2str(fv(6)*1000, '%03.0f') ' ms']);  
  end % if QMRI mode is on & loaded (...qmri.mode == 3)
 
end


% --- Update the complex representation of an image ---
function handles = updateCplx(handles)

img = handles.vvi.currentImage;

% Take FFT First, if necessary
if handles.vvi.fftMode > 0 && handles.vvi.fftMode < 200
  % 2D FFT
  for ii = 1:size(img,4)
    for jj = 1:size(img,3)
      switch handles.vvi.fftMode
        case 100
          % No Shifts
          img(:,:,jj,ii) = ifft2(img(:,:,jj,ii));
        case 110
          % Pre-Shift
          img(:,:,jj,ii) = ifft2(fftshift(img(:,:,jj,ii)));
        case 120
          % Post-Shift
          img(:,:,jj,ii) = fftshift(ifft2(img(:,:,jj,ii)));
        case 130
          % Both Shift
          img(:,:,jj,ii) = fftshift(ifft2(fftshift(img(:,:,jj,ii))));
      end
    end
  end
  
elseif handles.vvi.fftMode > 100
  % 3D FFT
  for ii = 1:size(img,4)
    switch handles.vvi.fftMode
      case 200
        % No Shifts
        img(:,:,:,ii) = ifftn(img(:,:,:,ii));
      case 210
        % Pre-Shift
        img(:,:,:,ii) = ifftn(fftshift(img(:,:,:,ii)));
      case 220
        % Post-Shift
        img(:,:,:,ii) = fftshift(ifftn(img(:,:,:,ii)));
      case 230
        % Both Shift
        img(:,:,:,ii) = fftshift(ifftn(fftshift(img(:,:,:,ii))));
    end
  end
end

if handles.vvi.isComplex == 0
  % Just display the image - no complex operations are needed
  img = double(img);
else
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
  img = img(:,:,:,:,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
  textMessage(handles, 'info', 'Only first 4D of image loaded.');
end

% Check if the image is real vs. complex to disable the popupComplex control
if isreal(img)
  % Disable the mag/phase/real/imag control
  handles.vvi.isComplex = 0;
  set(handles.popupComplex, 'Value' , 1);       % String #1 = Magnitude
  set(handles.popupComplex, 'Enable', 'off');
  
else
  handles.vvi.isComplex = 1;
  set(handles.popupComplex, 'Enable', 'on');
  
end

% v2.0: Store the complex image in handles.vvi.currentImage,
%       and define a new function displayImage to hold
%       the image after the abs/angle/real/imag operation
%       has been done

% Update current image value, name, and selCoords
handles.vvi.currentImage = img;
handles.vvi.currentName  = get(handles.editVar, 'String');
handles.vvi.selCoords   = [1 1 1];

% Update the complex representation of the display image in handles.vvi.displayImage
handles = updateCplx(handles);

% Grab the current display image to set min/max, rather than using global values
img     = handles.vvi.displayImage;

% Grab the min & max
if handles.vvi.isComplex == 0
  handles.vvi.min = min(img(:));
  handles.vvi.max = max(img(:));
else
  handles.vvi.min = min(abs(img(:)));
  handles.vvi.max = max(abs(img(:)));
end

if handles.vvi.max < handles.vvi.min
  % If max is less than min, set it to min + 10%
  handles.vvi.max = handles.vvi.min * 1.10;
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
elseif ndims(img) < 3 %#ok<ISMAT>
  handles.vvi.imageSize(3) = 1;
  handles.vvi.imageSize(4) = 1;
end

% If matrix size of new image is same as old image, display same slice as before
% if c 
%   
% else
  % Take middle slice as current slice
  handles.vvi.currentSlice = round(size(img, 3)/2);
  set(handles.editSlice, 'String', num2str(handles.vvi.currentSlice));
  
% end



% Take first phase as current phase
handles.vvi.currentPhase = 1;
set(handles.editPhase, 'String', num2str(handles.vvi.currentPhase));


% --- Display a text message, both on the image itself and the command window ---
function tHandle = textMessage(handles, type, msg)

  if strcmp(type, 'err')
    disp(['ERROR: ' msg]);
    axes(handles.mainAxes);
    tHandle = text(2,5, ['ERROR: ' msg], 'HorizontalAlignment','left', 'FontName', 'Tahoma', 'FontSize', 12, 'Color', 'red', 'BackgroundColor', 'black');
  else
    if size(msg, 2) == 1
      disp(['INFO: ' msg]);
    else
      disp(msg);
    end
    axes(handles.mainAxes);
    if size(msg, 2) == 1
      tHandle = text(2,5, ['INFO: '  msg], 'HorizontalAlignment','left', 'FontName', 'Tahoma', 'FontSize', 12, 'Color', 'white', 'BackgroundColor', 'black');
    else
      tHandle = text(2,5, msg, 'HorizontalAlignment','left', 'FontName', 'Tahoma', 'FontSize', 12, 'Color', 'white', 'BackgroundColor', 'black');
    end
  end
  
pause(1);

% -- Load in all needed mcDESPOT variables --
% -- Based on run_mcdespot.m               --

function handles = loadMCD(handles)

disp('QMRI: Begin loading mcDESPOT data, calibration, and parameter maps...');

% Get the full path and file name for _mcdespot_settings.mat from handles
mcdespot_settings_fname = [handles.vvi.qmri.mcd.path handles.vvi.qmri.mcd.name];

% Check that mat-file exists
if ~exist(mcdespot_settings_fname, 'file');
	textMessage(handles, 'err', '_mcdespot_settings.mat not found.')
  return;
end

% Change directory 
initialDir = pwd();
cd(handles.vvi.qmri.mcd.path);

% Load settings file
handles.vvi.qmri.mcd.mcdespot_settings = load(mcdespot_settings_fname);

% -- Modified code from run_mcdespot.m --

% Try to load the T1 and flip angle map, if they exist
if isfield(handles.vvi.qmri.mcd.mcdespot_settings.status, 'despot1') && handles.vvi.qmri.mcd.mcdespot_settings.status.despot1 == 1 %#ok<*NODEF>
  % Load the t1 map
  handles.vvi.qmri.mcd.pd_spgr = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.DESPOT1 'DESPOT1-PD.nii']);
  % handles.vvi.qmri.mcd.t1    = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.DESPOT1 'DESPOT1-T1.nii']);
  handles.vvi.qmri.mcd.fam     = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.DESPOT1 'DESPOT1-FAM.nii']);
  disp('DESPOT1 data loaded.');
else
  error('Must run DESPOT1-HIFI first to obtain FAM and T1 map');
end

% Try to load the T2 and off-resonance map, if they exist
if isfield(handles.vvi.qmri.mcd.mcdespot_settings.status, 'despot2') && handles.vvi.qmri.mcd.mcdespot_settings.status.despot2 == 1
  % Load the t1 map
  handles.vvi.qmri.mcd.pd_ssfp = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.DESPOT1 'DESPOT2-PD.nii']);
  % handles.vvi.qmri.mcd.t2    = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.DESPOT1 'DESPOT2-T2.nii']);
  handles.vvi.qmri.mcd.omega   = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.DESPOT1 'DESPOT2-Omega.nii']);
  disp('DESPOT2 data loaded.');
else
  error('Must run DESPOT2-FM first to obtain Omega and T2 map');
end

% Try to load the multi-component maps, if they exist
if isfield(handles.vvi.qmri.mcd.mcdespot_settings.status, 'mcdespot') && handles.vvi.qmri.mcd.mcdespot_settings.status.mcdespot > 0
  % Load the t1 map
  mcd_fv(:,:,:,1) = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.MCDESPOT 'mcDESPOT-T1m.nii']);
  mcd_fv(:,:,:,2) = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.MCDESPOT 'mcDESPOT-T1f.nii']);
  mcd_fv(:,:,:,3) = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.MCDESPOT 'mcDESPOT-T2m.nii']);
  mcd_fv(:,:,:,4) = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.MCDESPOT 'mcDESPOT-T2f.nii']);
  mcd_fv(:,:,:,5) = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.MCDESPOT 'mcDESPOT-MWF.nii']);
  mcd_fv(:,:,:,6) = load_nifti([handles.vvi.qmri.mcd.mcdespot_settings.dir.MCDESPOT 'mcDESPOT-Tau.nii']);

  handles.vvi.qmri.mcd.mcd_fv = mcd_fv;
  
  disp('mcDESPOT data loaded.');
else
  error('Must run mcDESPOT first to obtain multicomponent maps.');
end

% Load MR Data. Will automatically choose coreg data, if it exists
img = load_mcdespot_series();

spgr     = img.spgr;
ssfp_0   = img.ssfp_0;
ssfp_180 = img.ssfp_180;
clear img;

% Rescale data 
handles.vvi.qmri.mcd.data_spgr     = spgr     ./ handles.vvi.qmri.mcd.mcdespot_settings.status.despot1_signalScale;
handles.vvi.qmri.mcd.data_ssfp_0   = ssfp_0   ./ handles.vvi.qmri.mcd.mcdespot_settings.status.despot2_signalScale;
handles.vvi.qmri.mcd.data_ssfp_180 = ssfp_180 ./ handles.vvi.qmri.mcd.mcdespot_settings.status.despot2_signalScale;
clear spgr ssfp_0 ssfp_180;

% -- End code from run_mcdespot.m --

% Also load mcd_fv into base workspace: Save to .mat, load in base scope, cleanup tmp
save('tmp_mcd_128', 'mcd_fv');
evalin('base', 'load(''tmp_mcd_128'');');
delete('tmp_mcd_128.mat');
clear mcd_fv;

% Spawn two figure windows for plotting mcDESPOT fit and contraction steps
handles.vvi.qmri.mcd.fitHandle      = figure;

% Setup fit window titles
xlabel('flip angle [deg]');
ylabel('MR signal [a.u.]');

handles.vvi.qmri.mcd.contractHandle = figure;

% Setup subplots for contraction steps

% Contraction Steps 1-4
for ii = 1:4
  subplot(4,3,3*ii-2);
  xlabel('T1m [s]');
  ylabel('T1f [s]');
  set(gca, 'clim', [0 5e-14]);
  
  subplot(4,3,3*ii-1);
  xlabel('T2m [s]');
  ylabel('T2f [s]');
  set(gca, 'clim', [0 5e-14]);
  
  subplot(4,3,3*ii);
  xlabel('MWF');
  ylabel('Tau [s]');
  set(gca, 'clim', [0 5e-14]);
end

disp('All mcDESPOT data, calibration, and parameter maps loaded.');

% Header for plotting display
disp('----------|---------|-----------|---------|-----|--------');
disp(['Dataset: ' handles.vvi.qmri.mcd.path                     ]);
disp('----------|---------|-----------|---------|-----|--------');
disp('T1 Myelin | T1 Free | T2 Myelin | T2 Free | MWF |  Tau   ');
disp('----------|---------|-----------|---------|-----|--------');

% CD back to initial directory
cd(initialDir);



% ========= END SAH Functions  =============================================


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

% Check for custom color maps (_Mask)
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
handles = imageDisp(hObject, handles);

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
set(handles.panelStat, 'Visible', 'off');

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
set(handles.panelStat, 'Visible', 'off');

% --- Executes on button press in pushStats.
function pushStats_Callback(hObject, eventdata, handles)
% hObject    handle to pushStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make The Active Button 'Tabbed', All Others 'Untabbed'
set(handles.pushLoad, 'Value', 0.0);
set(handles.pushFFT,  'Value', 0.0);
set(handles.pushStats,'Value', 1.0);

% Make this panel visible, hide all others
set(handles.panelVars, 'Visible', 'off');
set(handles.panelFFT,  'Visible', 'off');
set(handles.panelStat, 'Visible', 'on');

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

handles = imageDisp(hObject, handles);

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

handles = imageDisp(hObject, handles);

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

handles = imageDisp(hObject, handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushFlipLR.
function pushFlipLR_Callback(hObject, eventdata, handles)
% hObject    handle to pushFlipLR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Do ImFlipLR
handles.vvi.displayImage = imfliplr(handles.vvi.displayImage);

handles = imageDisp(hObject, handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushFlipUD.
function pushFlipUD_Callback(hObject, eventdata, handles)
% hObject    handle to pushFlipUD (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Do ImFlipUD
handles.vvi.displayImage = imflipud(handles.vvi.displayImage);

handles = imageDisp(hObject, handles);

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
  handles.vvi.fftMode = 000;
  
  % Go back to base image and see if it is complex-valued
  if isreal(handles.vvi.currentImage)
    handles.vvi.isComplex = 0;
  else
    handles.vvi.isComplex = 1;
  end
  
elseif get(handles.radio2DFFT, 'Value') == 1
  handles.vvi.fftMode = 100;
  handles.vvi.isComplex = 1;
else
  handles.vvi.fftMode = 200;
  handles.vvi.isComplex = 1;
end

% Enable or Disable the mag/phase/real/imag control as needed
if handles.vvi.isComplex == 0
  set(handles.popupComplex, 'Value' , 1);
  set(handles.popupComplex, 'Enable', 'off');
else
  handles.vvi.isComplex = 1;
  set(handles.popupComplex, 'Enable', 'on');
end

% Pre-shift
if get(handles.checkPreShift,  'Value') == 1
  handles.vvi.fftMode = handles.vvi.fftMode + 10;
end

% Post-shift
if get(handles.checkPostShift, 'Value') == 1
  handles.vvi.fftMode = handles.vvi.fftMode + 20;
end

% Log scale
if get(handles.checkLog,       'Value') == 1
  handles.vvi.fftMode = handles.vvi.fftMode + 1;
end

% Update the current image
handles = updateCplx(handles);

% Update the displayImage min & max after FFT operation
img = handles.vvi.displayImage;

if handles.vvi.isComplex == 0
  handles.vvi.min = min(img(:));
  handles.vvi.max = max(img(:));
else
  handles.vvi.min = min(abs(img(:)));
  handles.vvi.max = max(abs(img(:)));
end

if handles.vvi.max < handles.vvi.min
  % If max is less than min, set it to min + 10%
  handles.vvi.max = handles.vvi.min * 1.10;
end

if handles.vvi.min > handles.vvi.max
  handles.vvi.min = handles.vvi.max * 0.10;
end

% Set the value of the txt boxes
set(handles.editMin, 'String', num2str(handles.vvi.min));
set(handles.editMax, 'String', num2str(handles.vvi.max));

% Display the image
handles = imageDisp(hObject, handles);

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

function checkLog_Callback(hObject, eventdata, handles)
% hObject    handle to checkPostShift (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkPostShift
panelFFT_SelectionChangeFcn(hObject, eventdata, handles)

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

% =-=-=-=-=-=-= END Dimensions/Rotation/Resample Callbacks! =-=-=-=-=-=-=


% ============== External Programs Below ==============

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

function imgHandle = imgsc(img, window, range)

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
    img1(:,:,:,ii) = phplot(img(:,:,ii), window(2));
  end
  imgHandle = montage(img1(:,:,:,range(1):range(2)));
else
  % Grayscale img
  img1(:,:,1,:) = img;
  imgHandle = montage(img1(:,:,1,range(1):range(2)), 'DisplayRange', window);
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
  msgbox('Cannot write out direct image in Mosaic Mode');
end

% Scale tmp from 0->1
tmp = tmp - handles.vvi.min;
tmp(tmp < 0) = 0; % Remove negative values
tmp = tmp ./ (handles.vvi.max - handles.vvi.min);
tmp(tmp > 1) = 1; % Clip values above max

filename = inputdlg('Save TIFF As:');
filename = filename{1};

% Re-scale to colormap index
tmp = tmp .* size(handles.vvi.colormap,1);

imwrite(tmp, handles.vvi.colormap, filename);

% ======= Object Creation Callbacks Section ====================================
% Required to be here in order to avoid errors when clicking on 
% certain GUI elements, but otherwise unused for vvi functionality

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


% ======= END Object Creation Callbacks Section ================================

% -=-=-=-=-= Right Click Menu Callback =-=-=-=-=- 

% --------------------------------------------------------------------
function Rt_Click_Callback(hObject, eventdata, handles)
% hObject    handle to Rt_Click (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Yarr');


% --------------------------------------------------------------------
function mnuAbout_Callback(hObject, eventdata, handles)
% hObject    handle to mnuAbout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% -=-=-=-=-= Callbacks for FFT button presses =-=-=-=-=-
% This is because, on OSX, the panelSelectionChange callback is fired
% for toggle button presses, the same as if they were radioButtons
% But on Win32, this is not the case. So put in extra callbacks on
% buttonPress to fire the panelSelectionChange event
%
% Removed the panel's callback for panelSelectionChange so that
% the event is not fired twice.
%
% SAH v3.3

% --- Executes on button press in radioImageSpace.
function radioImageSpace_Callback(hObject, eventdata, handles)
% hObject    handle to radioImageSpace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

panelFFT_SelectionChangeFcn(hObject, eventdata, handles)


% --- Executes on button press in radio2DFFT.
function radio2DFFT_Callback(hObject, eventdata, handles)
% hObject    handle to radio2DFFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

panelFFT_SelectionChangeFcn(hObject, eventdata, handles)


% --- Executes on button press in radio3DFFT.
function radio3DFFT_Callback(hObject, eventdata, handles)
% hObject    handle to radio3DFFT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

panelFFT_SelectionChangeFcn(hObject, eventdata, handles)

% =-=-=-=-=- END FFT Button Press Callbacks =-=-=-=-=-=-=-=-=



% =-=-=-=-=- QMRI Mode Callbacks =-=-=-=-=-=-=-=-=

% --- Executes on button press in rdoQmriOff.
function rdoQmriOff_Callback(hObject, eventdata, handles)
% hObject    handle to rdoQmriOff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rdoQmriOff

handles.vvi.qmri.mode = 0; % Set mode to OFF

% Turn off the 'Load' button for mcDESPOT
set(handles.pushLoadMcd, 'Enable', 'off');

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in rdoQmriMcd.
function rdoQmriMcd_Callback(hObject, eventdata, handles)
% hObject    handle to rdoQmriMcd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rdoQmriMcd

handles.vvi.qmri.mode = 3; % Set mode to mcDESPOT

% Turn on the 'Load' button for mcDESPOT
set(handles.pushLoadMcd, 'Enable', 'on');

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in pushLoadMcd.
function pushLoadMcd_Callback(hObject, eventdata, handles)
% hObject    handle to pushLoadMcd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% GUI for user to select _mcdespot_settings file
[name path] = uigetfile('*.mat', 'Select _mcdespot_settings file');

% Check for cancel or invalid selection
if (name == 0)
  textMessage(handles, 'err', '_mcdespot_settings.mat not selected.')
  return;
end

handles.vvi.qmri.mcd.path = path;
handles.vvi.qmri.mcd.name = name;

% Call loadMCD to populate .qmri.mcd with new data
handles = loadMCD(handles);

% Set the loaded flag to mcDESPOT
handles.vvi.qmri.loaded = 3;

% Update handles structure
guidata(hObject, handles);

% =-=-=-=-=- END QMRI Mode Callbacks =-=-=-=-=-=-=
