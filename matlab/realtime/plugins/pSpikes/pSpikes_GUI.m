function varargout = pSpikes_GUI(varargin)
% PSPIKES_GUI MATLAB code for pSpikes_GUI.fig
%      PSPIKES_GUI, by itself, creates a new PSPIKES_GUI or raises the existing
%      singleton*.
%
%      H = PSPIKES_GUI returns the handle to a new PSPIKES_GUI or the handle to
%      the existing singleton*.
%
%      PSPIKES_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PSPIKES_GUI.M with the given input arguments.
%
%      PSPIKES_GUI('Property','Value',...) creates a new PSPIKES_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pSpikes_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pSpikes_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pSpikes_GUI

% Last Modified by GUIDE v2.5 08-Feb-2012 15:11:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pSpikes_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @pSpikes_GUI_OutputFcn, ...
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


% --- Executes just before pSpikes_GUI is made visible.
function pSpikes_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pSpikes_GUI (see VARARGIN)

% Choose default command line output for pSpikes_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pSpikes_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = pSpikes_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function fieldDetectionThreshold_Callback(hObject, eventdata, handles)
% hObject    handle to fieldDetectionThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fieldDetectionThreshold as text
%        str2double(get(hObject,'String')) returns contents of fieldDetectionThreshold as a double


% --- Executes during object creation, after setting all properties.
function fieldDetectionThreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fieldDetectionThreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

% TODO: window is closed - notify that plugin should be removed from the active list


% --- Executes on button press in buttonReset.
function buttonReset_Callback(hObject, eventdata, handles)
% hObject    handle to buttonReset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
