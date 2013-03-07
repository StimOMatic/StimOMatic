%
%plot the GUI of the plugin
%
function handlesGUI = pRaster_initGUI( handlesGUI, handlesParent )

%% delete old elements if they exist
if isfield(handlesGUI, 'lineHandles')
%   removeExistingLineHandles ( handlesGUI.lineHandles.plotLine_axesAvAll );
end

%% create handles/lines
% waveforms
appdata = getappdata( handlesGUI.figHandle);
handles = appdata.UsedByGUIData_m;

set(0,'CurrentFigure',handlesGUI.figHandle)
set( handlesGUI.figHandle,'CurrentAxes',handles.axesRaster)

OSortConstants = handlesParent.OSortConstants;

nrTrialsTot = OSortConstants.maxTrialsPerChannel * handlesParent.OSortData.nrActiveChannels;
ylimsThis = [0 nrTrialsTot];


%xlimsToUse=[0 OSortConstants.RasterBeforeOffset]; 

xlimsToUse=[-1*OSortConstants.LFPAverageBeforeOffset OSortConstants.LFPAverageAfterOffset];

set(handles.axesRaster,'ylim',ylimsThis,'xlim',xlimsToUse, 'ylimmode','manual','xlimmode','manual'); %,'XTickLabel',[]);

handlesGUI.lineHandles = [];
