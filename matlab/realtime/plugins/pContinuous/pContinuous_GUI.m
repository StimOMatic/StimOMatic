function varargout = pContinuous_GUI(varargin)
% PCONTINUOUS_GUI MATLAB code for pContinuous_GUI.fig
%      PCONTINUOUS_GUI, by itself, creates a new PCONTINUOUS_GUI or raises the existing
%      singleton*.
%
%      H = PCONTINUOUS_GUI returns the handle to a new PCONTINUOUS_GUI or the handle to
%      the existing singleton*.
%
%      PCONTINUOUS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PCONTINUOUS_GUI.M with the given input arguments.
%
%      PCONTINUOUS_GUI('Property','Value',...) creates a new PCONTINUOUS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pContinuous_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pContinuous_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pContinuous_GUI

% Last Modified by GUIDE v2.5 20-Feb-2012 18:07:26

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pContinuous_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @pContinuous_GUI_OutputFcn, ...
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


% --- Executes just before pContinuous_GUI is made visible.
function pContinuous_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pContinuous_GUI (see VARARGIN)

% Choose default command line output for pContinuous_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pContinuous_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = pContinuous_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupPlotMode.
function popupPlotMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupPlotMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupPlotMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupPlotMode


% --- Executes during object creation, after setting all properties.
function popupPlotMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupPlotMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function uipanel1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to uipanel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on selection change in popupPlotStyle.
function popupPlotStyle_Callback(hObject, eventdata, handles)
% hObject    handle to popupPlotStyle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupPlotStyle contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupPlotStyle


% --- Executes during object creation, after setting all properties.
function popupPlotStyle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupPlotStyle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
