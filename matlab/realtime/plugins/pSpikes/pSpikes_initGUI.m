%
%plot the GUI of the plugin
%
function handlesGUI = pSpikes_initGUI( handlesGUI, handlesParent )

%% delete old elements if they exist
if isfield(handlesGUI, 'lineHandles')
   removeExistingLineHandles ( handlesGUI.lineHandles.plotWaveforms );
   removeExistingLineHandles ( handlesGUI.lineHandles.texthandles );
end

%% create handles/lines
% waveforms

appdata = getappdata( handlesGUI.figHandle);
handles = appdata.UsedByGUIData_m;

set(0,'CurrentFigure',handlesGUI.figHandle)
set( handlesGUI.figHandle,'CurrentAxes',handles.axesWaveforms)

plotOffsetWaveforms = handlesParent.StimOMaticConstants.plotOffsetWaveforms;

x = [1:handlesParent.StimOMaticConstants.nrPointsPerWaveform]./handlesParent.StimOMaticConstants.Fs*1000;  %in ms
y=repmat(0,1,length(x));

%prepare one line for each potential waveform to be plotted on each channel
plotWaveforms=[];
for k=1:handlesParent.StimOMaticData.nrActiveChannels
    for j=1:handlesParent.StimOMaticConstants.maxNrWaveformsToPlot
        plotWaveforms(k,j) = line(x, y+(k-1)*plotOffsetWaveforms, 'color','b' ); 
    end
    
    channelStr = handlesParent.StimOMaticData.CSCChannels{k}.channelStr;
    texthandles(k)=text( x(1), y(1)+(k-1)*plotOffsetWaveforms+plotOffsetWaveforms/2, [channelStr] );
end

ylimsThis=[-plotOffsetWaveforms plotOffsetWaveforms+plotOffsetWaveforms*handlesParent.StimOMaticData.nrActiveChannels];
set(handles.axesWaveforms,'ylim',ylimsThis,'ylimmode','manual','xlimmode','manual'); %,'XTickLabel',[]);

lineHandles.plotWaveforms = plotWaveforms;

lineHandles.texthandles=texthandles;

handlesGUI.lineHandles = lineHandles;
