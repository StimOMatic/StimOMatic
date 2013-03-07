%
%
%
function handlesGUI = pSpikes_initPlugin(  )

%% open the GUI
handlesGUI.figHandle = pSpikes_GUI;    % open the GUI
set(handlesGUI.figHandle, 'CloseRequestFcn', '');

