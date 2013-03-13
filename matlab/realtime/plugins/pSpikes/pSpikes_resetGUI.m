function pluginData = pSpikes_resetGUI( pluginData )
pluginData.waveforms =[];
pluginData.timestamps =[];
pluginData.lastPlottedInfo = [];

disp('resetGUI func called');

%waveforms
%for jj=1:size(spikeWaveforms,1)
%    set( handlesPlugin.lineHandles.plotWaveforms(CSCChanNr,jj), 'ydata', spikeWaveforms(jj,:)+(CSCChanNr-1)*handlesParent.StimOMaticConstants.plotOffsetWaveforms );
%end