%
%update the GUI with new information. called once for each channel
%
%
%
function pSpikes_updateGUI( CSCChanNr, transferedGUIData, handlesPlugin, handlesParent )

%waveforms
if ~isempty(transferedGUIData.waveformsToPlot)
    
    %plot all new waveforms as determined by the worker and overwrite the existing waveform with it
    for jj=1:size(transferedGUIData.waveformsToPlot,1)
        set( handlesPlugin.lineHandles.plotWaveforms(CSCChanNr,  transferedGUIData.handlesToUse(jj) ), ...
            'ydata', transferedGUIData.waveformsToPlot(jj,:)+(CSCChanNr-1)*handlesParent.StimOMaticConstants.plotOffsetWaveforms, 'color', 'r' );
    end
else
    
    %reset them all
    initWaveform=zeros(1,handlesParent.StimOMaticConstants.nrPointsPerWaveform);
    for jj=1:size(handlesPlugin.lineHandles.plotWaveforms,2)
        set( handlesPlugin.lineHandles.plotWaveforms(CSCChanNr,jj), 'ydata', initWaveform+(CSCChanNr-1)*handlesParent.StimOMaticConstants.plotOffsetWaveforms );
    end    
    
end

