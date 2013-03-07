function varargout = MatRTSync(varargin)
% MATRTSYNC MATLAB code for MatRTSync.fig
%      MATRTSYNC, by itself, creates a new MATRTSYNC or raises the existing
%      singleton*.
%
%      H = MATRTSYNC returns the handle to a new MATRTSYNC or the handle to
%      the existing singleton*.
%
%      MATRTSYNC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MATRTSYNC.M with the given input arguments.
%
%      MATRTSYNC('Property','Value',...) creates a new MATRTSYNC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before MatRTSync_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to MatRTSync_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MatRTSync

% Last Modified by GUIDE v2.5 24-Feb-2012 15:24:22

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MatRTSync_OpeningFcn, ...
                   'gui_OutputFcn',  @MatRTSync_OutputFcn, ...
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


% --- Executes just before MatRTSync is made visible.
function MatRTSync_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to MatRTSync (see VARARGIN)

% Choose default command line output for MatRTSync
handles.output = hObject;


%init
handles.maxStatusEntries = 15;
handles.port = 22480;
handles.timeToWait = 200*1000;  %in ms

handles.nrValsToBuffer = 100;

handles.routerConnected=0;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes MatRTSync wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = MatRTSync_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in ButtonStart.
function ButtonStart_Callback(hObject, eventdata, handles)

%================= open the shared mem file
addEntryToStatusListbox( handles.ListboxStatus, ['Starting TCP Server '  ],1,handles.maxStatusEntries);

defineSharedVarName;   %read global settings

%close it first
if isfield(handles,'memFileHandle')
    memFileHandle = handles.memFileHandle;
    clear memFileHandle
    handles.memFileHandle=0;
    guidata(hObject, handles);
end

createFile=0;
if ~exist(fVarStore)
    createFile=1;
end
memFileHandle = initMemSharedVariable( fVarStore, handles.nrValsToBuffer, createFile );

addEntryToStatusListbox( handles.ListboxStatus, ['Shared Mem File opened:  ' memFileHandle.Filename ' Writable: ' num2str(memFileHandle.Writable) ],1,handles.maxStatusEntries);
handles.memFileHandle=memFileHandle;
drawnow;

%============== TCP
try
    addEntryToStatusListbox( handles.ListboxStatus, ['Waiting for Client...Timeout is ' num2str(handles.timeToWait) ],1,handles.maxStatusEntries);
    drawnow;
    
    jTcpObj = jtcp('accept', handles.port, 'timeout', handles.timeToWait);

    handles.jTcpObj = jTcpObj;

    tmpStr= handles.jTcpObj.socket.toString();
    addEntryToStatusListbox( handles.ListboxStatus, ['Established connection with client: ' char(tmpStr) ],1,handles.maxStatusEntries);
    
    jTcpObj.remoteHost
catch err
   if ~isempty(strfind(err.message,'Accept timed out'))
        addEntryToStatusListbox( handles.ListboxStatus, ['Timeout,no client connected within ' num2str(handles.timeToWait) 'ms. Abort.' ],1,handles.maxStatusEntries);
   else
       rethrow(err);        
   end
end

guidata(hObject, handles);

%==== now the timer callback can be active
handles.guifig = gcf;
timerType=1;
handles.tmr1  = timer('TimerFcn' ,{@MatRTSync_GUICallback, timerType, handles.guifig}, 'Period', 0.01, 'ExecutionMode', 'fixedRate');
guidata(hObject, handles);
start( handles.tmr1);



% --- Executes on selection change in ListboxStatus.
function ListboxStatus_Callback(hObject, eventdata, handles)
% hObject    handle to ListboxStatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ListboxStatus contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ListboxStatus


% --- Executes during object creation, after setting all properties.
function ListboxStatus_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ListboxStatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ButtonStopServer.
function ButtonStopServer_Callback(hObject, eventdata, handles)

memFileHandle = handles.memFileHandle;
clear memFileHandle

handles.memFileHandle=0;

guidata(hObject, handles);
addEntryToStatusListbox( handles.ListboxStatus, ['Shared Mem File closed.'],1,handles.maxStatusEntries);

if isfield(handles, 'jTcpObj')
   if ~isempty(handles.jTcpObj )
        jtcp('close',handles.jTcpObj);
        addEntryToStatusListbox( handles.ListboxStatus, ['Closed Socket.'],1,handles.maxStatusEntries);
   end
end
if ishandle(handles.tmr1)
    stop(handles.tmr1); 
    delete(handles.tmr1);
    handles.tmr1=0;
end

guidata(hObject, handles);


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)

hostname = get(handles.serverIP,'String');
succeeded = NlxConnectToServer(hostname);
NlxSetApplicationName( ['Mat2RTSync Server'] );
disp(['Router connect succeed connect is=' num2str(succeeded)  ]);

if succeeded==1
        addEntryToStatusListbox( handles.ListboxStatus, ['Connected to Router: ' hostname],1,handles.maxStatusEntries);
        
        handles.routerConnected=1;
end
guidata(hObject, handles);


function serverIP_Callback(hObject, eventdata, handles)
% hObject    handle to serverIP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of serverIP as text
%        str2double(get(hObject,'String')) returns contents of serverIP as a double


% --- Executes during object creation, after setting all properties.
function serverIP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to serverIP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonDisconnectCheetah.
function buttonDisconnectCheetah_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDisconnectCheetah (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

succeeded = Netcom_disconnectConn();
disp(['disconnect status ' num2str(succeeded)]);
if succeeded    
    addEntryToStatusListbox( handles.ListboxStatus, ['Disconnected from Router: '],1,handles.maxStatusEntries);
end
handles.routerConnected=0;
guidata(hObject, handles);
