%
%
%
function pluginData = pSpikes_processData( newDataReceived, newTimestampsReceived, pluginData, CSCBufferData, CSCTimestampData )
%disp('pSpikes_processedData called');

% detect spikes
OSortParams =  pluginData.OSortConstants.OSortParams;
[~, ~, ~,spikeWaveforms, spikeTimestamps] = extractSpikes( newDataReceived, pluginData.OSortConstants.filters.HdSpikes,OSortParams );

if length( spikeTimestamps ) > 0
    pluginData.waveforms = [pluginData.waveforms; spikeWaveforms];
    
    %convert timestamps to absolute timestamps (they are returned relative)
    spikeTimestampsConverted = convertTimestamps( newTimestampsReceived, spikeTimestamps, OSortParams.samplingFreq, OSortParams.rawFileVersion );
    pluginData.timestamps = [pluginData.timestamps spikeTimestampsConverted];
    
    
    pluginData.lastPlottedInfo(1) = length( spikeTimestamps );  %how many waveforms were added in this iteration
end

