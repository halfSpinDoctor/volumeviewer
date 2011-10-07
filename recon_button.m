function varargout = recon_button(varargin)
% recon_button.m: Button to recon viper scans for quick viewing on the scanner
%
% Script will copy the latest P-File from WIMR-MR2 to the current directory, reconstruct the 1st phase/echo, and
% display a montage
%
% Samuel A. Hurley
% University of Wisconsin
% v1.0  31-Aug-2011
%
% Changelog:
%     v1.0 Initial version 31-Aug-2011
%
% Last Modified by GUIDE v2.5 04-Aug-2011 09:29:05

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @recon_button_OpeningFcn, ...
                   'gui_OutputFcn',  @recon_button_OutputFcn, ...
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


% --- Executes just before recon_button is made visible.
function recon_button_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to recon_button (see VARARGIN)

% Choose default command line output for recon_button
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes recon_button wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = recon_button_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

!get_last_pfile wimrmr2
pfiles = dirf('P*7');
img    = imflipud(recon_vipr(pfiles{end}, 'SPGR'));
figure;
imgsc((img));

