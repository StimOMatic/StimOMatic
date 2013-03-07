%
%
%
function handlesGUI = pRaster_initPlugin(  )

%% open the GUI
handlesGUI.figHandle = pRaster_GUI;    % open the GUI
set(handlesGUI.figHandle, 'CloseRequestFcn', '');

