%
%run on worker, prepare data to be transfered to client for plotting (as little as possible)
%this will be called once per channel that this GUI is processing
%
%
function pluginDataToTransfer = pLFPAv_prepareGUItransfer( pluginData )
%pluginData

pluginDataToTransfer=[];

pluginDataToTransfer.nTrialsLFP = pluginData.nTrialsLFP;
pluginDataToTransfer.LFPav = pluginData.LFPav;

pluginDataToTransfer.avSpectra = pluginData.avSpectra;
pluginDataToTransfer.rawSpectra = pluginData.rawSpectra;
pluginDataToTransfer.fLabels = pluginData.fLabels;
pluginDataToTransfer.xAxisColorPlot = pluginData.xAxisColorPlot;
