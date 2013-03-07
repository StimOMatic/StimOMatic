%
%
%
function handlesGUI = pCtrlLFP_initPlugin(  )

%% open the GUI
handlesGUI.figHandle = pCtrlLFP_GUI;    % open the GUI
set(handlesGUI.figHandle, 'CloseRequestFcn', '');

%appdataRemote = getappdata( handlesGUI.figHandle);
%channelList = appdataRemote.UsedByGUIData_m.ChannelsActiveList1;

