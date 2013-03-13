%
%plot the GUI of the plugin
%
function handlesGUI = pContinuousOpenGL_initGUI( handlesGUI, handlesParent )

handlesGUI = [];

% TODO: add creation of files - this function is only called once on the master.
nrActiveChannels = handlesParent.StimOMaticData.nrActiveChannels;



return;

stepsize = 1e6 / handlesParent.StimOMaticConstants.Fs; %in ms

%% delete old elements if they exist
if isfield(handlesGUI, 'lineHandles')
   hTmp = handlesGUI.lineHandles;
    
   removeExistingLineHandles ([hTmp.plotLine1_axesSpAll hTmp.plotLine1_axesCSC1_title hTmp.plotLine1_axesCSCall] );
   removeExistingLineHandles ([hTmp.textHandles]);
    removeExistingLineHandles ([hTmp.textHandles2]);
  
end

%% CSC plot (fullband)
appdata = getappdata( handlesGUI.figHandle);
handles = appdata.UsedByGUIData_m;

set(0,'CurrentFigure',handlesGUI.figHandle)
set( handlesGUI.figHandle,'CurrentAxes',handles.axesCSC1)

%set(gcf,'CurrentAxes',handles.axesCSC1)

x = [1:stepsize:handlesParent.StimOMaticConstants.bufferSizeCSC*stepsize]/1000;
y=repmat(10,1,length(x));

plotStyle = (get( handles.popupPlotStyle, 'Value'));

if plotStyle==1
    eraseMode='Normal';
else
    eraseMode='background';
end

for k=1:handlesParent.StimOMaticData.nrActiveChannels
    yPos = y+(k-1)*handlesParent.StimOMaticConstants.plotOffsetRawband;
    plotLine1_axesCSCall(k) = line(x, yPos, 'color','b', 'EraseMode',eraseMode ); 

    channelStr = handlesParent.StimOMaticData.CSCChannels{k}.channelStr(4:end);
    texthandles(k)=text( x(1), yPos(1)+handlesParent.StimOMaticConstants.plotOffsetRawband/2, [channelStr] );

    %texthandles2(k)=text( 0, yPos(1)+handlesParent.StimOMaticConstants.plotOffsetRawband/2, 'n/a' );
end

plotLine1_axesCSC1_title = title('CSC');
set(handles.axesCSC1,'ylim',[-500 500+500*handlesParent.StimOMaticData.nrActiveChannels],'ylimmode','manual','xlimmode','manual','XTickLabel',[]);

lineHandles.plotLine1_axesCSC1_title = plotLine1_axesCSC1_title;
lineHandles.plotLine1_axesCSCall = plotLine1_axesCSCall;
lineHandles.textHandles=texthandles;

%% spikes plot (bandpass filtered
set(handlesGUI.figHandle,'CurrentAxes',handles.axesSp1)

for k=1:handlesParent.StimOMaticData.nrActiveChannels
    
    yPos = y+(k-1)*handlesParent.StimOMaticConstants.plotOffsetSpikeband;    
    plotLine1_axesSpAll(k) = line(x, yPos, 'color','b', 'EraseMode',eraseMode);
    
    channelStr = handlesParent.StimOMaticData.CSCChannels{k}.channelStr;
    texthandles2(k)=text( x(1), yPos(1)+handlesParent.StimOMaticConstants.plotOffsetSpikeband/2, [channelStr] );    
end

set(handles.axesSp1,'ylim',[-100 100+100*handlesParent.StimOMaticData.nrActiveChannels],'ylimmode','manual','xlimmode','manual');

lineHandles.plotLine1_axesSpAll = plotLine1_axesSpAll;
lineHandles.textHandles2=texthandles2;


handlesGUI.lineHandles = lineHandles;