%
% data structures to be transfered to each worker where this plugin should be running
%
%
function pluginData = pLFPAv_initWorker( handlesParent, handlesPlugin )

appdata = getappdata( handlesPlugin.figHandle);
handles = appdata.UsedByGUIData_m;

%% get settings from the GUI

%% data structures neededed
pluginData.StimOMaticConstants = handlesParent.StimOMaticConstants;

pluginData.nTrialsLFP=0;   %LFP trials
pluginData.LFPtrials=[];
pluginData.LFPav=[];

pluginData.singleTrialSpectra = [];
pluginData.avSpectra = [];
pluginData.fLabels = [];
pluginData.xAxisColorPlot=[];

pluginData.rawSpectra = [];
