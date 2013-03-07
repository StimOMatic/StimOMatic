
function handlesGUI = pLFPAv_initPlugin(  )

%% open the GUI
handlesGUI.figHandle = pLFPAv_GUI;    % open the GUI
set(handlesGUI.figHandle, 'CloseRequestFcn', '');

