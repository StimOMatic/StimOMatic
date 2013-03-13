function pluginData = pContinuousOpenGL_initWorker( handlesParent, handlesPlugin )
% 
% appdata = getappdata( handlesPlugin.figHandle);
% handles = appdata.UsedByGUIData_m;
% 
% %% get settings from the GUI
% 
% plotMode = (get( handles.popupPlotMode, 'Value'));
% 
% 

%% data structures neededed in 'pContinuousOpenGL_processData'
pluginData.StimOMaticConstants = handlesParent.StimOMaticConstants;

%pluginData.filteredDataLFP = zeros(1, handlesParent.StimOMaticConstants.bufferSizeCSC);
%pluginData.filteredDataSpikes = zeros(1, handlesParent.StimOMaticConstants.bufferSizeCSC);
[initFrameBuffer,initFrameOrder] = dataBufferFramed_init(handlesParent.StimOMaticConstants.frameSize, handlesParent.StimOMaticConstants.nrFramesToBuffer );

pluginData.filteredDataLFP.data = initFrameBuffer;
pluginData.filteredDataLFP.frameOrder = initFrameOrder;

pluginData.filteredDataSpikes.data = initFrameBuffer;
pluginData.filteredDataSpikes.frameOrder = initFrameOrder;
% 
% pluginData.spikesSd = [];
pluginData.plotState=[0 0];  %newdatalength / totdatalength
% 
% 
% pluginData.plotMode = plotMode;

%% memory mapping for incoming data is done in 'pContinuousOpenGL_processData'
% the first time it will be called!

% save our abs plugin ID
pluginData.mmap_abs_ID = handlesParent.abs_ID_in_parent;
% indicate that mmap is not initalized yet. will be overwritten in 'pContinuousOpenGL_processData'
pluginData.mmap_initialized = 0;

end
%% EOF