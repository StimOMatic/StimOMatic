function varargout = StimOMatic(varargin)
% STIMOMATIC MATLAB code for StimOMatic.fig
%      STIMOMATIC, by itself, creates a new STIMOMATIC or raises the existing
%      singleton*.
%
%      H = STIMOMATIC returns the handle to a new STIMOMATIC or the handle to
%      the existing singleton*.
%
%      STIMOMATIC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STIMOMATIC.M with the given input arguments.
%
%      STIMOMATIC('Property','Value',...) creates a new STIMOMATIC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before StimOMatic_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to StimOMatic_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help StimOMatic

% Last Modified by GUIDE v2.5 13-Mar-2013 16:19:15

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @StimOMatic_OpeningFcn, ...
                   'gui_OutputFcn',  @StimOMatic_OutputFcn, ...
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


% --- Executes just before StimOMatic is made visible.
function StimOMatic_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for StimOMatic
handles.output = hObject;

%================= init StimOMatic params
handles.StimOMaticConstants = initStimOMaticParamsForStreaming( );

handles.storedEvents=[];

handles.activePlugins = {};
handles.absPluginCounter = 0; % keep track of the absolute ID of each plugin, even if we remove plugins in the meantime.

set(gcf,'Renderer','OpenGL'); % this is the fastest renderer if opengl=hardware is on.

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = StimOMatic_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on selection change in CSCListPopup.
function CSCListPopup_Callback(hObject, eventdata, handles)
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function CSCListPopup_CreateFcn(hObject, eventdata, handles)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonStartFeed.
function buttonStartFeed_Callback(hObject, eventdata, handles)

ChannelsActiveList1 = get(handles.ChannelsActiveList1, 'String');
if isempty(ChannelsActiveList1)
    disp('No CSC channels selected.');
    return;
end

modifyGUIStatus(handles, 1 );

%request meta data for the selected channels
handles.StimOMaticData = requestMetaDataForSelChannels(ChannelsActiveList1 , handles.StimOMaticConstants);

%update the GUI
for k=1:handles.StimOMaticData.nrActiveChannels
    addEntryToStatusListbox( handles.ListboxStatus,[handles.StimOMaticData.CSCChannels{k}.channelStr '=' handles.StimOMaticData.CSCChannels{k}.metaStr ]  );
end

% initialize GUIs of all plugins
gcfOld=gcf;
handles = plugins_allActive_initGUI( handles ); 
guidata(hObject, handles); %write back GUI data before letting the timer start
set(0,'CurrentFigure', gcfOld);    %set back to the main fig

lineHandles = initializeGUIPlots( handles  );
handles.lineHandles = lineHandles;

%create timer for callbacks
handles.guifig = gcf;
timerType=1;

callbackPeriod = 0.05; %sec



%setappdata(handles.guifig, 'CustomDataStimOMatic', customData );

handles.tmr1  = timer('TimerFcn' ,{@GUICallback1, timerType, handles.guifig}, 'Period', callbackPeriod, 'ExecutionMode', 'fixedRate');

serverIP = get( handles.ServerIP, 'String');

nrWorkersToUseMax = get( handles.popupMaxNrWorkers, 'Value');
%nrWorkersToUseMax=12;

handles.RTModeOn = get(handles.popupRealtimeMode,'Value')-1;

% initialize all the workers
[handles.labRefs,nrWorkers,workerChannelMapping, allOK, activePluginsCont, activePluginsTrial] = initializeParallelProcessing( handles.StimOMaticData.nrActiveChannels, handles.StimOMaticConstants, handles.StimOMaticData, serverIP, handles.activePlugins, handles, nrWorkersToUseMax );
handles.nrWorkersInUse = nrWorkers;
handles.workerChannelMapping = workerChannelMapping;
handles.activePluginsCont = activePluginsCont;
handles.activePluginsTrial = activePluginsTrial;

global customData;
customData.labRefs = handles.labRefs;
customData.iterationCounter = 0;


if ~allOK
    addEntryToStatusListbox( handles.ListboxStatus, ['Error streaming ' ]);
else
    addEntryToStatusListbox( handles.ListboxStatus, ['Start streaming ' ]);
    addEntryToStatusListbox( handles.ListboxStatus, ['#workers initialized: ' num2str(nrWorkers) ]);
    
    assignStr='';
    for j=1:nrWorkers
        chansStr='';
        [channelsOnWorkerTmp, nrChannelsOnWorkerTmp] = distributeChannels_getChannelsForWorker( workerChannelMapping, j );
        for k=1:nrChannelsOnWorkerTmp
            chansStr = [ chansStr ',' num2str(channelsOnWorkerTmp(k)) ];
        end
        assignStr = [assignStr '; W' num2str(j) '=' chansStr(2:end)];
    end
    
    addEntryToStatusListbox( handles.ListboxStatus, ['Assignment: ' assignStr(2:end) ]);
    
end

guidata(hObject, handles); %write back GUI data before letting the timer start

%start timer callbacks
start(handles.tmr1);


% --- Executes on button press in buttonStopFeed.
function buttonStopFeed_Callback(hObject, eventdata, handles)

modifyGUIStatus(handles, 0 );

if isfield(handles,'tmr1')
    if ~isempty(handles.tmr1)
        if isvalid(handles.tmr1)
            stop(handles.tmr1);  % stop the callbacks
            delete(handles.tmr1);
            handles.tmr1=[];
        end
    end
end

global customData;

%[succeeded,allOK, allChs] = startStopStreaming( handles.StimOMaticData, 2  ); %2=stop
[allOK, customData.labRefs] = shutdownParallelProcessing(handles.nrWorkersInUse, handles.StimOMaticConstants, customData.labRefs);

addEntryToStatusListbox( handles.ListboxStatus, ['Stop streaming status ' num2str(allOK)]);





function ServerIP_Callback(hObject, eventdata, handles)
% hObject    handle to ServerIP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ServerIP as text
%        str2double(get(hObject,'String')) returns contents of ServerIP as a double


% --- Executes during object creation, after setting all properties.
function ServerIP_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ServerIP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ConnectButton.
function ConnectButton_Callback(hObject, eventdata, handles)
% hObject    handle to ConnectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
serverIP = get( handles.ServerIP, 'String');

addEntryToStatusListbox( handles.ListboxStatus, ['Connecting to: ' serverIP]);

[success, eventStr, allCSCs,allSEs,allTTs] = Netcom_initConn( serverIP );
handles.StimOMaticConstants.TTLStream=eventStr;

if success ~= 1 || isempty(allCSCs)
    if isempty(allCSCs) && success == 1
        errMsg = ['Error: Connected to ' serverIP ' but list of channels is empty! '];
    else
        errMsg = ['Error connecting to: ' serverIP ' err ' num2str(success)];
    end
    % close the connection if it's open.
    if NlxAreWeConnected() 
        Netcom_disconnectConn();
    end
    addEntryToStatusListbox( handles.ListboxStatus, errMsg );
    return;
end

% activate dependent GUI elements only if connection was successful.
set(handles.buttonStartFeed, 'Enable', 'on');
set(handles.StartACQButton, 'Enable', 'on');
set(handles.StartRECButton, 'Enable', 'on');

% populate info into GUI
set(handles.CSCListPopup,  'String', {'none', allCSCs{:}} );
addEntryToStatusListbox( handles.ListboxStatus, ['Connected ' serverIP]);

%load available plugins
[pList,pListStrs] = definePluginList;
set(handles.popupPluginList,'String', pListStrs);
set(handles.popupPluginList','Value', 1);
handles.pList = pList;

% disable 'connect button'
set(hObject, 'Enable', 'off');
set(handles.DisconnectButton, 'Enable', 'on');
drawnow();

guidata(hObject, handles); %write back GUI data before letting the timer start

% --- Executes on button press in DisconnectButton.
function DisconnectButton_Callback(hObject, eventdata, handles)
% hObject    handle to DisconnectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.buttonStartFeed, 'Enable', 'off');
set(handles.ConnectButton, 'Enable', 'on');
set(handles.StartACQButton, 'Enable', 'off');
set(handles.StartRECButton, 'Enable', 'off');
Netcom_disconnectConn();

addEntryToStatusListbox( handles.ListboxStatus, 'Disconnected' );
set(handles.DisconnectButton, 'Enable', 'off');


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

% --- Executes on button press in CSCAddButton.
function CSCAddButton_Callback(hObject, eventdata, handles)

valSel = get( handles.CSCListPopup, 'Value');

if valSel > 0
    
    strSel = get(handles.CSCListPopup, 'String');
    CSCSel = strSel{valSel};

    % make sure 'handles.ChannelsActiveList1' has a non-empty value, non
    % zero value, otherwise we get matlab warnings.
    curr_value = get(handles.ChannelsActiveList1, 'Value');
    if isempty(curr_value) || curr_value == 0
        set(handles.ChannelsActiveList1, 'Value', 1);
    end
    % the max number of channels is arbitrarily capped to 100 here.
    maxChannels = 100;    
    addEntryToStatusListbox( handles.ChannelsActiveList1, CSCSel, 0, maxChannels  );
    addEntryToStatusListbox( handles.ListboxStatus, ['Added: ' CSCSel ] );
    
end


% --- Executes on button press in CSCRemoveButton.
function CSCRemoveButton_Callback(hObject, eventdata, handles)
valOfRemovedEntry = removeEntryFromListbox( handles.ChannelsActiveList1, -1 );
if ~isempty( valOfRemovedEntry)
    addEntryToStatusListbox( handles.ListboxStatus, ['Remove: ' valOfRemovedEntry ] );
   % handles = updateFeedbackChannelPopup( handles );    
    
end

% --- Executes on selection change in ChannelsActiveList1.
function ChannelsActiveList1_Callback(hObject, eventdata, handles)
% hObject    handle to ChannelsActiveList1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ChannelsActiveList1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ChannelsActiveList1


% --- Executes during object creation, after setting all properties.
function ChannelsActiveList1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ChannelsActiveList1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonResetAverages.
function buttonResetAverages_Callback(hObject, eventdata, handles)

try
    
    if ~isfield(handles, 'StimOMaticData') || isempty(handles.StimOMaticData)
        return;
    end
    
    nrActiveChannels = handles.StimOMaticData.nrActiveChannels;
    
    processedData = handles.labRefs.processedData;
    
    activePlugins = handles.activePlugins;
    spmd(nrActiveChannels)
        %disp('xxxx');
        for k=1:length(activePlugins)
            if isfield(activePlugins{k}.pluginDef, 'resetGUIFunc')   %if this plugin defines this function
                if ~isempty(activePlugins{k}.pluginDef.resetGUIFunc)
                    processedData.pluginData{k} = activePlugins{k}.pluginDef.resetGUIFunc( processedData.pluginData{k} ) ;
                    %activePlugins{k}.pluginDef
                end
            end
        end
    end
    handles.labRefs.processedData=processedData;
    
catch E
    disp('Error in buttonResetAverages_Callback:');
    dispAllErrors(E);
end

guidata(hObject,handles);



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



function inputfieldPsychServer_Callback(hObject, eventdata, handles)
% hObject    handle to inputfieldPsychServer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of inputfieldPsychServer as text
%        str2double(get(hObject,'String')) returns contents of inputfieldPsychServer as a double


% --- Executes during object creation, after setting all properties.
function inputfieldPsychServer_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inputfieldPsychServer (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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

function buttonPluginLoad_Callback(hObject, eventdata, handles)

% load the chosen plugin
pickedPluginNr = get( handles.popupPluginList, 'Value');
if ~isfield(handles, 'pList')
    msgbox('no plugin list found - please connect to router first!');
    return;
end
pickedPluginDef = handles.pList(pickedPluginNr);

% check if required plugins are loaded already
if ~isempty( pickedPluginDef.dependsOn )
    dependsOn = pickedPluginDef.dependsOn;
    
    dependencySatisfied = zeros(1, length(dependsOn) );
    for j=1:length( dependsOn )
        for k=1:length( handles.activePlugins)
            if dependsOn(j) == handles.activePlugins{k}.pluginDef.ID
                dependencySatisfied(j) = 1;
            end
        end
    end
    
    if length(dependsOn) ~= sum( dependencySatisfied )
       msgbox([' Can not load plugin - required plugin(s) not loaded. Need plugins: ' num2str(dependsOn)],'Cant load plugin','warn'); 
       return;
    end
end

% add to list of currently active plugins
% addActivePlugin()
abs_ID = handles.absPluginCounter + 1; % will always increase
rel_ID = length(handles.activePlugins)+1; % will decrease if plugin is removed in the meantime.
oneActivePlugin.handlesGUI = pickedPluginDef.initFunc( );   %initialize the GUI of this plugin in the client;
oneActivePlugin.pluginDef = pickedPluginDef;
oneActivePlugin.abs_ID = abs_ID;
handles.activePlugins{rel_ID} = oneActivePlugin;

% overwrite the absPluginCounter so it keeps increasing.
handles.absPluginCounter = abs_ID;

%give plugin a way to interact with main GUI
% check for valid handle. 'oneActivePlugin.handlesGUI.figHandle' might be 
% empty, if a plugin is not using plotting into a matlab figure.
if ishandle(oneActivePlugin.handlesGUI.figHandle)
    
    appdata = getappdata( oneActivePlugin.handlesGUI.figHandle);
    appdata.UsedByGUIData_m.parentFigHandle = handles.figure1;
    setappdata(oneActivePlugin.handlesGUI.figHandle, 'UsedByGUIData_m', appdata.UsedByGUIData_m);

end

updateActivePluginsList(handles);

guidata(hObject,handles);





% --- Executes on selection change in popupPluginList.
function popupPluginList_Callback(hObject, eventdata, handles)
% hObject    handle to popupPluginList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupPluginList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupPluginList


% --- Executes during object creation, after setting all properties.
function popupPluginList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupPluginList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonPluginInfo.
function buttonPluginInfo_Callback(hObject, eventdata, handles)
nbr_active_plugins = length(handles.activePlugins);
if nbr_active_plugins == 0
    disp('No running plugins configured.');
    return;
end

disp('List of running plugins:');
for k = 1 : nbr_active_plugins
    disp(['Active plugin: ' handles.activePlugins{k}.pluginDef.displayName ' k=' num2str(k)]);
end


% --- Executes on selection change in popupmenu7.
function popupmenu7_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu7 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu7


% --- Executes during object creation, after setting all properties.
function popupmenu7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in listLoadedPlugins.
function listLoadedPlugins_Callback(hObject, eventdata, handles)
% hObject    handle to listLoadedPlugins (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listLoadedPlugins contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listLoadedPlugins


% --- Executes during object creation, after setting all properties.
function listLoadedPlugins_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listLoadedPlugins (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonRemovePlugin.
function buttonRemovePlugin_Callback(hObject, eventdata, handles)
selNr = get( handles.listLoadedPlugins,'Value' );

%close the window with this handle
% 'handles.activePlugins{selNr}.handlesGUI' might be empty, if a plugin is
% not using plotting into a matlab figure.
%
% TODO: add '_plugin_remove' function, so that we can clean up mmap
% handles, etc ...
%
% 'handles.activePlugins' is empty if we haven't added any plugins yet.
if isempty(handles.activePlugins)
    return;
end

if isfield(handles.activePlugins{selNr}.handlesGUI, 'figHandle')
    figHandleTmp = handles.activePlugins{selNr}.handlesGUI.figHandle;
    
    if ishandle(figHandleTmp)
        close( figHandleTmp );
        delete( figHandleTmp );
    end
end

%remove this plugin
inds = setdiff( 1:length(handles.activePlugins), selNr);
activePluginsNew = handles.activePlugins(inds);

handles.activePlugins = activePluginsNew;    
    
updateActivePluginsList(handles);
guidata(hObject,handles);


% --- Executes on button press in buttonReorderUp.
function buttonReorderUp_Callback(hObject, eventdata, handles)

valSel = get( handles.ChannelsActiveList1, 'Value');

if valSel>1   %dont do if already at top
    
    strSelAll = get(handles.ChannelsActiveList1, 'String');

    oldVal1 = strSelAll{valSel-1};
    oldVal2 = strSelAll{valSel};
    
    strSelAll{valSel-1} = oldVal2;
    strSelAll{valSel} = oldVal1;
    
    set(handles.ChannelsActiveList1,'String',strSelAll);
    set(handles.ChannelsActiveList1,'Value',valSel-1);
end


% --- Executes on button press in buttonReorderDown.
function buttonReorderDown_Callback(hObject, eventdata, handles)

valSel = get( handles.ChannelsActiveList1, 'Value');

strSelAll = get(handles.ChannelsActiveList1, 'String');

if valSel>0 & valSel<length(strSelAll)   %dont do if already at bottom
    

    oldVal1 = strSelAll{valSel+1};
    oldVal2 = strSelAll{valSel};
    
    strSelAll{valSel+1} = oldVal2;
    strSelAll{valSel} = oldVal1;
    
    set(handles.ChannelsActiveList1,'String',strSelAll);
    
    set(handles.ChannelsActiveList1,'Value',valSel+1);
end


% --- Executes on selection change in popupMaxNrWorkers.
function popupMaxNrWorkers_Callback(hObject, eventdata, handles)
% hObject    handle to popupMaxNrWorkers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupMaxNrWorkers contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupMaxNrWorkers


% --- Executes during object creation, after setting all properties.
function popupMaxNrWorkers_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupMaxNrWorkers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonSaveList.
function buttonSaveList_Callback(hObject, eventdata, handles)
% hObject    handle to buttonSaveList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%save list of marked channels, to re-load later

allLoadedChannels = get(handles.ChannelsActiveList1, 'String');
if isempty(allLoadedChannels)
    disp('No channels in list - nothing to save.');
    return;
end

[fname, fpath] = uiputfile('ChsList.mat','Select name of file to save params to');
if fname
    disp(['saving ' fpath fname]);
    save([fpath fname],'allLoadedChannels');
end


% --- Executes on button press in buttonLoadList.
function buttonLoadList_Callback(hObject, eventdata, handles)
% hObject    handle to buttonLoadList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fname, fpath] = uigetfile('*.mat','Select name of file to load params from', 'ChsList.mat');

if fname
    disp(['loading ' fpath fname]);
    load([fpath fname],'allLoadedChannels');
    set(handles.ChannelsActiveList1, 'String',allLoadedChannels);
end

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)

% disconnet from NetCom
Netcom_disconnectConn();


%delete all plugins that are still open
for k=1:length(handles.activePlugins)
    
    if isfield(handles.activePlugins{k}.handlesGUI, 'figHandle')
        figHandleTmp = handles.activePlugins{k}.handlesGUI.figHandle;
        
        if ishandle(figHandleTmp)
            close( figHandleTmp );
            delete(figHandleTmp );
        end
    end
end


% --- Executes on selection change in popupRealtimeMode.
function popupRealtimeMode_Callback(hObject, eventdata, handles)
% hObject    handle to popupRealtimeMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupRealtimeMode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupRealtimeMode
if get(hObject, 'Value') == 1
    set(handles.labelStatusDelays, 'Visible', 'on');
else
    set(handles.labelStatusDelays, 'Visible', 'off');
end

% --- Executes during object creation, after setting all properties.
function popupRealtimeMode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupRealtimeMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in StartACQButton.
function StartACQButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartACQButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
button_state = get(hObject, 'Value');
button_max = get(hObject, 'Max');
button_min = get(hObject, 'Min');

if button_state == button_max
    [succeeded, cheetahReply] = NlxSendCommand('-StartAcquisition');
    if succeeded == 1
        set(hObject, 'String', 'Stop ACQ', 'BackgroundColor', [0 1 0]);
    else
        set(hObject, 'Value', button_min);
    end
    
elseif button_state == button_min
    [succeeded, cheetahReply] = NlxSendCommand('-StopAcquisition');
    if succeeded == 1
        set(hObject, 'String', 'Start ACQ', 'BackgroundColor', [0.941 0.941 0.941]);
    else
        set(hObject, 'Value', button_max);
    end    
    
end

% --- Executes on button press in StartRECButton.
function StartRECButton_Callback(hObject, eventdata, handles)
% hObject    handle to StartRECButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
button_state = get(hObject, 'Value');
button_max = get(hObject, 'Max');
button_min = get(hObject, 'Min');

if button_state == button_max
    [succeeded, cheetahReply] = NlxSendCommand('-StartRecording');
    if succeeded == 1
        set(hObject, 'String', 'Stop REC', 'BackgroundColor', [0.48 0.06 0.89]);
        % toggle ACQ button too, since stopping the REC will not stop ACQ.
        if get(handles.StartACQButton, 'Value') == button_min
            disp('setting ACQ too!');
            set(handles.StartACQButton, 'Enable', 'off', 'String', 'Stop ACQ', 'BackgroundColor', [0 1 0], 'Value', button_max);
        end
    else
        set(hObject, 'Value', button_min);
    end
    
elseif button_state == button_min
    [succeeded, cheetahReply] = NlxSendCommand('-StopRecording');
    if succeeded == 1
        set(hObject, 'String', 'Start REC', 'BackgroundColor', [0.941 0.941 0.941]);
        set(handles.StartACQButton, 'Enable', 'on');
    else
        set(hObject, 'Value', button_max);
    end    
    
end
