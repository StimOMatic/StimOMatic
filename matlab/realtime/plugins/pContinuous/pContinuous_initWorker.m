function pluginData = pContinuous_initWorker( handlesParent, handlesPlugin )

appdata = getappdata( handlesPlugin.figHandle);
handles = appdata.UsedByGUIData_m;

%% get settings from the GUI

plotMode = (get( handles.popupPlotMode, 'Value'));


%% data structures neededed
pluginData.StimOMaticConstants = handlesParent.StimOMaticConstants;

%pluginData.filteredDataLFP = zeros(1, handlesParent.StimOMaticConstants.bufferSizeCSC);
%pluginData.filteredDataSpikes = zeros(1, handlesParent.StimOMaticConstants.bufferSizeCSC);
[initFrameBuffer,initFrameOrder] = dataBufferFramed_init(handlesParent.StimOMaticConstants.frameSize, handlesParent.StimOMaticConstants.nrFramesToBuffer );

pluginData.filteredDataLFP.data = initFrameBuffer;
pluginData.filteredDataLFP.frameOrder = initFrameOrder;

pluginData.filteredDataSpikes.data = initFrameBuffer;
pluginData.filteredDataSpikes.frameOrder = initFrameOrder;

pluginData.spikesSd = [];
pluginData.plotState=[0 0];  %newdatalength / totdatalength


pluginData.plotMode = plotMode;