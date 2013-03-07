%
%
function pluginData = pRaster_processData( newDataReceived, newTimestampsReceived, pluginData, CSCBufferData, CSCTimestampData, t, tFrom )
%disp('pRaster_processData called');

Fs = pluginData.OSortConstants.Fs;

%=== prepare Spikes for raster
tRasterFrom = t - pluginData.OSortConstants.RasterBeforeOffset*1000; %in us

indsSpikes = find( pluginData.dependenceData{1}.timestamps>tRasterFrom &  pluginData.dependenceData{1}.timestamps<=t );


pluginData.nTrialsRaster = pluginData.nTrialsRaster + 1;

disp(['nr spikes in trial: trialNr/nrSpikes ' num2str(pluginData.nTrialsRaster) ' ' num2str(length(indsSpikes))]);

pluginData.spikeTimepoints(pluginData.nTrialsRaster).times=[];
if ~isempty(indsSpikes)
    pluginData.spikeTimepoints(pluginData.nTrialsRaster).times = (pluginData.dependenceData{1}.timestamps(indsSpikes)-tRasterFrom)/1000;  %in ms, relative
end