%
%run on worker, prepare data to be transfered to client for plotting (as little as possible)
%this will be called once per channel that this GUI is processing
%
%
function pluginDataToTransfer = pContinuousOpenGL_prepareGUItransfer( pluginData )

pluginDataToTransfer = [];

return

%old: plot all
%pluginDataToTransfer.filteredDataLFP = pluginData.filteredDataLFP;
%pluginDataToTransfer.filteredDataSpikes = pluginData.filteredDataSpikes;

%new: only plot new data

nNew = pluginData.plotState(1);
if nNew>0
    framesize=512;
    
    %nrFramesNew=nNew/framesize
    
    %pluginDataToTransfer.filteredDataLFP = pluginData.filteredDataLFP(end-nNew+1:end);
    %pluginDataToTransfer.filteredDataSpikes = pluginData.filteredDataSpikes(end-nNew+1:end);
    
    %pluginDataToTransfer.filteredDataLFP = pluginData.filteredDataLFP.data(:, pluginData.filteredDataLFP.frameOrder(end-nNew/framesize+1:end));
    %pluginDataToTransfer.filteredDataSpikes = pluginData.filteredDataSpikes.data(:, pluginData.filteredDataSpikes.frameOrder(end-nNew/framesize+1:end));
   
    %pluginDataToTransfer.filteredDataLFP = pluginDataToTransfer.filteredDataLFP(:);
    %pluginDataToTransfer.filteredDataSpikes = pluginDataToTransfer.filteredDataSpikes(:);
    

    pluginDataToTransfer.filteredDataLFP = dataBufferFramed_retrieve(pluginData.filteredDataLFP.data, pluginData.filteredDataLFP.frameOrder, framesize, nNew/framesize);
    pluginDataToTransfer.filteredDataSpikes = dataBufferFramed_retrieve(pluginData.filteredDataSpikes.data, pluginData.filteredDataSpikes.frameOrder, framesize, nNew/framesize);

    %which part of the xdata to replace with this new data
    bufSize=size(pluginData.filteredDataLFP.data,1)*size(pluginData.filteredDataLFP.data,2);
    xdata = mod( [pluginData.plotState(2)-nNew+1:pluginData.plotState(2)], bufSize );
    xdata( xdata==0 ) = bufSize; %wrap-around of mod
    pluginDataToTransfer.xdata = xdata;
    
else
    pluginDataToTransfer.filteredDataLFP =[];
    pluginDataToTransfer.filteredDataSpikes =[];
    pluginDataToTransfer.xdata=[];
end


pluginDataToTransfer.plotMode = pluginData.plotMode; %from GUI
pluginDataToTransfer.spikesSd = pluginData.spikesSd;


