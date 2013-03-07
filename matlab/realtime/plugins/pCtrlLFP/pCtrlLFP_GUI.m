function varargout = pCtrlLFP_GUI(varargin)
% PCTRLLFP_GUI MATLAB code for pCtrlLFP_GUI.fig
%      PCTRLLFP_GUI, by itself, creates a new PCTRLLFP_GUI or raises the existing
%      singleton*.
%
%      H = PCTRLLFP_GUI returns the handle to a new PCTRLLFP_GUI or the handle to
%      the existing singleton*.
%
%      PCTRLLFP_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PCTRLLFP_GUI.M with the given input arguments.
%
%      PCTRLLFP_GUI('Property','Value',...) creates a new PCTRLLFP_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pCtrlLFP_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pCtrlLFP_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pCtrlLFP_GUI

% Last Modified by GUIDE v2.5 25-May-2012 14:14:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pCtrlLFP_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @pCtrlLFP_GUI_OutputFcn, ...
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


% --- Executes just before pCtrlLFP_GUI is made visible.
function pCtrlLFP_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pCtrlLFP_GUI (see VARARGIN)

% Choose default command line output for pCtrlLFP_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pCtrlLFP_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = pCtrlLFP_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupChannelForCtrl.
function popupChannelForCtrl_Callback(hObject, eventdata, handles)
% hObject    handle to popupChannelForCtrl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupChannelForCtrl contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupChannelForCtrl


% --- Executes during object creation, after setting all properties.
function popupChannelForCtrl_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupChannelForCtrl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupControlMethod.
function popupControlMethod_Callback(hObject, eventdata, handles)
% hObject    handle to popupControlMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupControlMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupControlMethod

%adjust name of the labels
valSel = get(hObject,'Value');

%mean amplitude: thresh (uV), P2: time (ms), P3: center freq (w=5), 0=broadband
%power Taper: thresh (au) P2: time (ms) P3: freq [hz]
%power Hilbert: thresh (au) P2: time (ms) P3: center freq (w=5) [hz] P4: len
%phase Hilbert: thresh (au) P2: time (ms) P3: center freq (w=5) [hz] P4: len P5: phase [-pi...pi,peak=pi/2]

 
switch(valSel)
    case 1
        set(handles.labelParam1,'String', 'Thresh [uV]');
        set(handles.labelParam2,'String', 'Time [ms]');
        set(handles.labelParam3,'String', 'Center Freq [Hz]');
        set(handles.labelParam4,'String', 'n/a');
        set(handles.labelParam5,'String', 'n/a');
        set(handles.labelParam6,'String', 'n/a');
    case 2
        set(handles.labelParam1,'String', 'Thresh [au]');
        set(handles.labelParam2,'String', 'Time [ms]');
        set(handles.labelParam3,'String', 'Freq [Hz]');
        set(handles.labelParam4,'String', 'n/a');
        set(handles.labelParam5,'String', 'n/a');
        set(handles.labelParam6,'String', 'n/a');
    case 3
        set(handles.labelParam1,'String', 'Th#1');
        set(handles.labelParam2,'String', 'Time [ms]');
        set(handles.labelParam3,'String', 'Center Freq [Hz]');
        set(handles.labelParam4,'String', 'Length [ms]');
        set(handles.labelParam5,'String', 'Th#2 (0=no)');
        set(handles.labelParam6,'String', 'n/a');
    case 4
        set(handles.labelParam1,'String', 'Thresh [au]');
        set(handles.labelParam2,'String', 'Time [ms]');
        set(handles.labelParam3,'String', 'Center Freq [Hz]');
        set(handles.labelParam4,'String', 'Length [ms]');
        set(handles.labelParam5,'String', 'Phase [\pm pi,99=rand]');
        set(handles.labelParam6,'String', 'Th#2 (0=no)');
        
end


% --- Executes during object creation, after setting all properties.
function popupControlMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupControlMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCtrlParam1_Callback(hObject, eventdata, handles)
% hObject    handle to editCtrlParam1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCtrlParam1 as text
%        str2double(get(hObject,'String')) returns contents of editCtrlParam1 as a double


% --- Executes during object creation, after setting all properties.
function editCtrlParam1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCtrlParam1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCtrlParam2_Callback(hObject, eventdata, handles)
% hObject    handle to editCtrlParam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCtrlParam2 as text
%        str2double(get(hObject,'String')) returns contents of editCtrlParam2 as a double


% --- Executes during object creation, after setting all properties.
function editCtrlParam2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCtrlParam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonRefreshChannels.
function buttonRefreshChannels_Callback(hObject, eventdata, handles)


% copy all active channels also into choice popup for closed loop control    
%activeChanList = get( handles.ChannelsActiveList1, 'String' );
%set(handles.popupChannelForCtrl,  'String', {'none', activeChanList{:} } );
%set(handles.popupChannelForCtrl,  'Value', 1);

appdataRemote = getappdata( handles.parentFigHandle);
channelList = appdataRemote.UsedByGUIData_m.ChannelsActiveList1;

%==== find out what the abs_ID of this plugin is so it can be updated in
%the GUI
self=handles.figure1;  % what is the handle of the GUI of this plugin
allActivePlugins = appdataRemote.UsedByGUIData_m.activePlugins;
abs_ID_us=0;
for j=1:length(allActivePlugins)
    if allActivePlugins{j}.handlesGUI.figHandle == self
        %this is us
        abs_ID_us = allActivePlugins{j}.abs_ID;
        break;
    end
end

statusStr=['PluginID=' num2str(abs_ID_us)];
set(handles.pluginStatus,'String', statusStr);

updateFeedbackChannelPopup( channelList, handles.popupChannelForCtrl );    


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



function editCtrlParam3_Callback(hObject, eventdata, handles)
% hObject    handle to editCtrlParam3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCtrlParam3 as text
%        str2double(get(hObject,'String')) returns contents of editCtrlParam3 as a double


% --- Executes during object creation, after setting all properties.
function editCtrlParam3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCtrlParam3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCtrlParam4_Callback(hObject, eventdata, handles)
% hObject    handle to editCtrlParam4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCtrlParam4 as text
%        str2double(get(hObject,'String')) returns contents of editCtrlParam4 as a double


% --- Executes during object creation, after setting all properties.
function editCtrlParam4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCtrlParam4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCtrlParam5_Callback(hObject, eventdata, handles)
% hObject    handle to editCtrlParam5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCtrlParam5 as text
%        str2double(get(hObject,'String')) returns contents of editCtrlParam5 as a double


% --- Executes during object creation, after setting all properties.
function editCtrlParam5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCtrlParam5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editCtrlParam6_Callback(hObject, eventdata, handles)
% hObject    handle to editCtrlParam6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editCtrlParam6 as text
%        str2double(get(hObject,'String')) returns contents of editCtrlParam6 as a double


% --- Executes during object creation, after setting all properties.
function editCtrlParam6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editCtrlParam6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
