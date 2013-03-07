%
%run on worker, prepare data to be transfered to client for plotting (as little as possible)
%this will be called once per channel that this GUI is processing
%
%
function pluginDataToTransfer = pRaster_prepareGUItransfer( pluginData )

% prepare points for fast raster plotting
rasterPointsToPlot =[];

%only plot last XX trials in the raster
trialsToPlot = min( pluginData.nTrialsRaster, pluginData.OSortConstants.maxTrialsPerChannel);

for k=1:trialsToPlot
    CSCChanNr=labindex;
    
    trialIndToUse = pluginData.nTrialsRaster-trialsToPlot+k;
    trialNrOffset = (CSCChanNr-1)*pluginData.OSortConstants.maxTrialsPerChannel;
    times = pluginData.spikeTimepoints(trialIndToUse).times;
    
    %re-reference to the offset
    
    xAxisOffset = ( pluginData.OSortConstants.RasterBeforeOffset - pluginData.OSortConstants.LFPAverageAfterOffset);
    
    rasterPointsToPlot = [ rasterPointsToPlot; [repmat(trialNrOffset+k,length(times),1) (times-xAxisOffset)']];
end

pluginDataToTransfer=[];
pluginDataToTransfer.rasterPointsToPlot = rasterPointsToPlot;

