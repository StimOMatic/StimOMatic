%
%run on worker, prepare data to be transfered to client for plotting (as little as possible)
%this will be called once per channel that this GUI is processing
%
%
function pluginDataToTransfer = pSpikes_prepareGUItransfer( pluginData )

%subsample appropriate number in preparation for later plotting
%only new waveforms are plotted, and they replace the oldest plotted waveform in a FIFO manner
%
if ~isempty(pluginData.lastPlottedInfo)
    nrWaveformsAdded  = pluginData.lastPlottedInfo(1);  %how many new waveforms were added in this run
    nrWaveformsTot = size( pluginData.waveforms, 1);  %how many total waveforms, including the new once

    waveformsToPlot = pluginData.waveforms(end-nrWaveformsAdded+1:end,:);
    
    %concat if too many
    if size(waveformsToPlot,1)>pluginData.OSortConstants.maxNrWaveformsToPlot
        waveformsToPlot = waveformsToPlot(  end-pluginData.OSortConstants.maxNrWaveformsToPlot+1:end,:);
    end

    %get the oldest handles to be replaced
    plotInds = mod( nrWaveformsTot-nrWaveformsAdded+1:nrWaveformsTot, 200);
    plotInds(find(plotInds==0))=200;   

    pluginDataToTransfer.handlesToUse = plotInds;
    pluginDataToTransfer.waveformsToPlot = waveformsToPlot;
else
    pluginDataToTransfer.waveformsToPlot = [];
    pluginDataToTransfer.handlesToUse    = [];
end
