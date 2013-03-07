%
%
%
function handlesGUI = pContinuous_initPlugin(  )

%% open the GUI
handlesGUI.figHandle = pContinuous_GUI;    % open the GUI
set(handlesGUI.figHandle, 'CloseRequestFcn', '');


