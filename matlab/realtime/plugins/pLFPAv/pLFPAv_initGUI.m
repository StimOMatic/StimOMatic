%
%plot the GUI of the plugin
%
function handlesGUI = pLFPAv_initGUI( handlesGUI, handlesParent )

%% delete old elements if they exist
if isfield(handlesGUI, 'lineHandles')
   removeExistingLineHandles ( handlesGUI.lineHandles.plotLine_axesAvAll );
   removeExistingLineHandles ( handlesGUI.lineHandles.texthandles );
end

%% create handles/lines
% waveforms
appdata = getappdata( handlesGUI.figHandle);
handles = appdata.UsedByGUIData_m;

set(0,'CurrentFigure',handlesGUI.figHandle)
set( handlesGUI.figHandle,'CurrentAxes',handles.axesAv)

StimOMaticConstants = handlesParent.StimOMaticConstants;

avLengthRaw = round(StimOMaticConstants.LFPAverageLength/1000*StimOMaticConstants.Fs);
plotOffset = StimOMaticConstants.plotOffsetLFPAverage;

x = [1:avLengthRaw]/StimOMaticConstants.Fs*1000;
x = x-StimOMaticConstants.LFPAverageBeforeOffset;   %line is relative to offset

y=repmat(1,1,length(x));

for k=1:handlesParent.StimOMaticData.nrActiveChannels
    yPos = y+(k-1)*plotOffset;
    plotLine_axesAvAll(k) = line(x, yPos, 'color','b' ); 


    channelStr = handlesParent.StimOMaticData.CSCChannels{k}.channelStr;
    
    texthandles(k)=text( x(1), yPos(1)+plotOffset/2, [channelStr] );
end

ylimsThis=[-plotOffset plotOffset+plotOffset*handlesParent.StimOMaticData.nrActiveChannels];
set(handles.axesAv,'ylim',ylimsThis,'ylimmode','manual','xlimmode','manual'); %,'XTickLabel',[]);

lineHandles.plotLine_axesAvAll = plotLine_axesAvAll;

lineHandles.texthandles=texthandles;

%draw on/offset lines
x1 = x(end)-StimOMaticConstants.LFPAverageAfterOffset;
%x2 = x1-handles.StimOMaticConstants.LFPAverageBeforeOffset;
line( [x1 x1],ylimsThis, 'color', 'r'  );
%line( [x2 x2],ylimsThis, 'color', 'r'  );

handlesGUI.lineHandles = lineHandles;
