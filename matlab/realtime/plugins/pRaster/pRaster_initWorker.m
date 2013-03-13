%
% data structures to be transfered to each worker where this plugin should be running
%
%
function pluginData = pRaster_initWorker( handlesParent, handlesPlugin )

appdata = getappdata( handlesPlugin.figHandle);
handles = appdata.UsedByGUIData_m;

%% get settings from the GUI

%% data structures neededed
pluginData.StimOMaticConstants = handlesParent.StimOMaticConstants;
 
pluginData.nTrialsRaster=0;   %LFP trials
pluginData.spikeTimepoints=struct('times',[]);  %structure, (x) is list of timestamps relative offset for every trial x

