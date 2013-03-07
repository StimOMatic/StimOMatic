%
%enable/disable controls based on current status of system
%
%urut/dec11
function modifyGUIStatus( handles, mode )

switch(mode)
    case 0
        %currently not running
        set(handles.CSCAddButton,'Enable','on');
        set(handles.CSCRemoveButton,'Enable','on');
        set(handles.CSCListPopup,'Enable','on');
        set(handles.popupRealtimeMode, 'Enable', 'on');
        set(handles.popupMaxNrWorkers, 'Enable', 'on');
        set(handles.buttonRemovePlugin, 'Enable', 'on');
        set(handles.buttonPluginLoad', 'Enable', 'on');
        set(handles.popupPluginList, 'Enable', 'on');
        set(handles.buttonStopFeed, 'Enable', 'off');
        set(handles.buttonStartFeed, 'Enable', 'on');

        %set(handles.popupChannelForCtrl,'Enable','on');
        %set(handles.popupControlMethod,'Enable','on');
        
    case 1
        %currently running
        set(handles.CSCAddButton,'Enable','off');
        set(handles.CSCRemoveButton,'Enable','off');
        set(handles.CSCListPopup,'Enable','off');
        set(handles.popupRealtimeMode, 'Enable', 'off');
        set(handles.popupMaxNrWorkers, 'Enable', 'off');
        set(handles.buttonRemovePlugin, 'Enable', 'off');
        set(handles.buttonPluginLoad', 'Enable', 'off');
        set(handles.popupPluginList, 'Enable', 'off');
        set(handles.labelStatusDelays, 'String', '');
        set(handles.buttonStopFeed, 'Enable', 'on');
        set(handles.buttonStartFeed, 'Enable', 'off');

        %set(handles.popupChannelForCtrl,'Enable','off');
        %set(handles.popupControlMethod,'Enable','off');

    otherwise
        error('unknown mode');
end