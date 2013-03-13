%
% data structures to be transfered to each worker where this plugin should be running
%
%
function pluginData = pCtrlLFP_initWorker( handlesParent, handlesPlugin )

appdata = getappdata( handlesPlugin.figHandle);
handles = appdata.UsedByGUIData_m;

%% get my abs_ID
abs_ID = handlesParent.abs_ID_in_parent;

statusStr=['PluginID=' num2str(abs_ID)];
set(handles.pluginStatus,'String', statusStr);


%% get settings from the GUI
%see if closed loop is enabled
selCtrlvalue = get( handles.popupChannelForCtrl, 'Value');
if selCtrlvalue>1  %sel1 is "none"
    %enable it
    setCtrlMethodValue = get(handles.popupControlMethod,'Value');
    
    selCtrlChoices = get( handles.popupChannelForCtrl, 'String');
    
    param1 = str2num(get(handles.editCtrlParam1,'String'));
    param2 = str2num(get(handles.editCtrlParam2,'String'));
    param3 = str2num(get(handles.editCtrlParam3,'String'));
    param4 = str2num(get(handles.editCtrlParam4,'String'));
    param5 = str2num(get(handles.editCtrlParam5,'String'));
    param6 = str2num(get(handles.editCtrlParam6,'String'));

    paramPlotMode = get(handles.popupPlotMode,'Value');
    
    closedLoopSettings=[];
    closedLoopSettings.channelToUse = selCtrlvalue-1;   %since first is none
    closedLoopSettings.channelToUseStr = selCtrlChoices{selCtrlvalue};

    closedLoopSettings.methodNr = setCtrlMethodValue;
    closedLoopSettings.params = [ param1 param2 param3 param4 param5 param6];

    closedLoopSettings.plotModeOn = paramPlotMode;
    
    % grab IP of Psychophysics computer from main GUI.
    closedLoopSettings.hostname = get( handlesParent.inputfieldPsychServer,'String');

    %if isfield(handles,'jTcpObj')
    %    closedLoopSettings.jTcpObj = handles.jTcpObj;
    %else
    %    closedLoopSettings.jTcpObj = 0;
    %end
    
    %handles.closedLoopEnabled = selCtrlvalue;
    statusStr=['PluginID=' num2str(abs_ID) ' Active Ch:'  closedLoopSettings.channelToUseStr];
    set(handles.pluginStatus,'String', statusStr);
    
else
    %ctrl is disabled
    closedLoopSettings=[];
    %handles.closedLoopEnabled = 0;
end

%% data structures neededed
pluginData.StimOMaticConstants = handlesParent.StimOMaticConstants;
 
pluginData.methodNr = 0;
pluginData.enabledOnChannel = 0;
if ~isempty(closedLoopSettings)
    pluginData.enabledOnChannel = closedLoopSettings.channelToUse;
    pluginData.enabledOnChannelStr = closedLoopSettings.channelToUseStr;
    pluginData.enabledOnChannelInt = str2num( closedLoopSettings.channelToUseStr(4:end) );
    
    pluginData.methodNr = closedLoopSettings.methodNr;
    %pluginData.dataBuffer = zeros(1, handlesParent.StimOMaticConstants.bufferSizeCSC);
    
    pluginData.dataBuffer = zeros(1, 200);
    
    pluginData.params = closedLoopSettings.params;
    pluginData.plotModeOn = closedLoopSettings.plotModeOn;
    
    pluginData.hostname = closedLoopSettings.hostname;
    pluginData.tcpConn = []; %0 not established, 1 established
    
    pluginData.previousCmdSent=0;
    
    if setCtrlMethodValue==3 || setCtrlMethodValue==4  % initialize filters
        
        freqWidth = 5;   %DEFAULT
        
        centerFreq = pluginData.params(3);
        FsDown=250;
        Wn = [centerFreq-freqWidth centerFreq+freqWidth]/(FsDown/2); % bandpass filter
        nOrder=4;
        [b,a] = butter(nOrder, Wn);  

        pluginData.bandFilter_b = [b];
        pluginData.bandFilter_a = [a];
        
        disp(['Bandpass filter used Fs=' num2str(FsDown) ' band = ' num2str(centerFreq) ' width ' num2str(freqWidth) ' Wn=' num2str(Wn)]);
    end
else
    pluginData.enabledOnChannel = 0;
    pluginData.enabledOnChannelStr=0;
    pluginData.enabledOnChannelInt=0;
end

%% memory mapping for incoming data
pluginData = setup_mmap_infrastructure(handlesParent.StimOMaticConstants, pluginData, ['pCtrlLFP-' num2str(abs_ID)]);

end
%% EOF
