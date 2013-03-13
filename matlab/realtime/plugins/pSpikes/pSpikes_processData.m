%
%
%
function pluginData = pSpikes_processData( newDataReceived, newTimestampsReceived, pluginData, CSCBufferData, CSCTimestampData )
%disp('pSpikes_processedData called');

% detect spikes
StimOMaticParams =  pluginData.StimOMaticConstants.StimOMaticParams;
[~, ~, ~,spikeWaveforms, spikeTimestamps] = extractSpikes( newDataReceived, pluginData.StimOMaticConstants.filters.HdSpikes,StimOMaticParams );

if length( spikeTimestamps ) > 0
    pluginData.waveforms = [pluginData.waveforms; spikeWaveforms];
    
    %convert timestamps to absolute timestamps (they are returned relative)
    spikeTimestampsConverted = convertTimestamps( newTimestampsReceived, spikeTimestamps, StimOMaticParams.samplingFreq, StimOMaticParams.rawFileVersion );
    pluginData.timestamps = [pluginData.timestamps spikeTimestampsConverted];
    
    
    pluginData.lastPlottedInfo(1) = length( spikeTimestamps );  %how many waveforms were added in this iteration
end

