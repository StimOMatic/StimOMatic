%
%run on worker, prepare data to be transfered to client for plotting (as little as possible)
%this will be called once per channel that this GUI is processing
%
%
function pluginDataToTransfer = pRaster_prepareGUItransfer( pluginData )

% prepare points for fast raster plotting
rasterPointsToPlot =[];

%only plot last XX trials in the raster
trialsToPlot = min( pluginData.nTrialsRaster, pluginData.StimOMaticConstants.maxTrialsPerChannel);

for k=1:trialsToPlot
    CSCChanNr=labindex;
    
    trialIndToUse = pluginData.nTrialsRaster-trialsToPlot+k;
    trialNrOffset = (CSCChanNr-1)*pluginData.StimOMaticConstants.maxTrialsPerChannel;
    times = pluginData.spikeTimepoints(trialIndToUse).times;
    
    %re-reference to the offset
    
    xAxisOffset = ( pluginData.StimOMaticConstants.RasterBeforeOffset - pluginData.StimOMaticConstants.LFPAverageAfterOffset);
    
    rasterPointsToPlot = [ rasterPointsToPlot; [repmat(trialNrOffset+k,length(times),1) (times-xAxisOffset)']];
end

pluginDataToTransfer=[];
pluginDataToTransfer.rasterPointsToPlot = rasterPointsToPlot;

