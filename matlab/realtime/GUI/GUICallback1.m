% main function called by the timer callback.
%
% update the GUI triggered by Timer, to poll data.
%
%urut/dec11
function GUICallback1( obj, event, timerCallNr, guihandles )
verbose = 0;

handles = guidata(guihandles); % get data from GUI
global customData;   %not pretty,but fast; avoid call to setappdata every iteration,which is very slow.

%customData = getappdata( guihandles, 'CustomDataOSort');
%customData.counter=customData.counter+1;
%customData.counter

nrWorkersToPoll = handles.nrWorkersInUse;
customData.iterationCounter = customData.iterationCounter+1;
RTModeOn = handles.RTModeOn;

%% poll the events, prepare event cue, schedule future averaging update
updateAv=[];
tOff=[];

%pre-allocate
if customData.iterationCounter == 1
    %from NlxGetNewEventData
    bufferSizeEvents=1000;
    maxEventStringLength=128;
    customData.eventStringArray = cell(1,bufferSizeEvents);
    for index = 1:bufferSizeEvents
        customData.eventStringArray{1,index} = blanks(maxEventStringLength);
    end
    customData.eventStringArrayPtr = libpointer('stringPtrPtr', customData.eventStringArray);
end

if ~RTModeOn   % dont process events in RT Mode
    
    [handles.storedEvents,updateAv,tOff] = Netcom_processEventsIteration(handles.OSortConstants.TTLStream, verbose, handles.storedEvents, updateAv, tOff,customData.eventStringArrayPtr);
    
    %schedule a new event for future averaging
    if updateAv
        tSchedule = tOff + handles.OSortConstants.LFPAverageAfterOffset*1000;
        
        % schedule a future update event
        eventToSchedule = [tSchedule handles.OSortConstants.LFPAverageLength];
        customData.labRefs.scheduledEventsStack = scheduleEventOnWorkers( customData.labRefs.scheduledEventsStack, eventToSchedule, nrWorkersToPoll );
    end
    
end

%% poll the data (CSCs)
updateEach = 100;

t2=tic;

bufferSize = handles.OSortConstants.bufferSizeCSC;
Fs = handles.OSortConstants.Fs;

customData.labRefs = pollDataParallel(nrWorkersToPoll, customData.labRefs, RTModeOn );

sysStatus=[0 0 0];
if mod(customData.iterationCounter,updateEach)==0
    sysStatus(1) = tocWithMsg(['C:' num2str(customData.iterationCounter) ' GUICallback1 - data processing'], t2, 1);
end

%% update the GUI

t3=tic;
% dont process events in RT Mode, or if only matlab GUI independent plugins
% are found.
% TODO: add check for non RT mode, so that 'updateGUI_realtimeStreams' is
% only called for workers that depend on matlab GUI.
if ~RTModeOn && sum(cellfun(@(x) x.pluginDef.needs_matlab_gui, handles.activePlugins)) > 0
    customData.labRefs = updateGUI_realtimeStreams( handles, nrWorkersToPoll, customData.labRefs, handles.activePlugins, customData.iterationCounter );
end

if mod(customData.iterationCounter,updateEach)==0
    sysStatus(2)=tocWithMsg(['C:' num2str(customData.iterationCounter) ' GUICallback1 - plotting(prepare)'],t3, 1);
end

t1 = tic;
drawnow;

if mod(customData.iterationCounter,updateEach)==0
    sysStatus(3)=tocWithMsg(['C:' num2str(customData.iterationCounter) ' GUICallback1 - plotting(drawnow)'],t1,1);
end

if mod(customData.iterationCounter,updateEach)==0
    set( handles.labelStatusDelays, 'String', ['[ms] Data=' num2str(sysStatus(1)*1000) ' Plot=' num2str(sum(sysStatus(2:3))*1000)] );
end

%setappdata(guihandles,'CustomDataOSort',customData);

%guidata(guihandles,handles);

