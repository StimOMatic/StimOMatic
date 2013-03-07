%
function pluginData = pContinuous_processData( newDataReceived, newTimestampsReceived, pluginData, CSCBufferData, CSCTimestampData )
%disp('pSpikes_processedData called');





framesize=512;
nrOverlapLFP = 4*framesize;
nrOverlapSpikes = 4*framesize;

              
% update filter buffers before raw buffers!
pluginData.filteredDataLFP = filterSignal_appendBlock( pluginData.OSortConstants.filters.HdLFP, CSCBufferData, pluginData.filteredDataLFP, newDataReceived', nrOverlapLFP, framesize );
pluginData.filteredDataSpikes = filterSignal_appendBlock( pluginData.OSortConstants.filters.HdSpikes, CSCBufferData, pluginData.filteredDataSpikes, newDataReceived', nrOverlapSpikes, framesize );

%plotState [lengthNewData, totReceived]
pluginData.plotState = [length(newDataReceived) pluginData.plotState(2)+length(newDataReceived)];

% update channel-stats
%pluginData.spikesSd = std(pluginData.filteredDataSpikes);