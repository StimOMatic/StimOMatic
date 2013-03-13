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

StimOMaticConstants = handlesParent.StimOMaticConstants;

nrTrialsTot = StimOMaticConstants.maxTrialsPerChannel * handlesParent.StimOMaticData.nrActiveChannels;
ylimsThis = [0 nrTrialsTot];


%xlimsToUse=[0 StimOMaticConstants.RasterBeforeOffset]; 

xlimsToUse=[-1*StimOMaticConstants.LFPAverageBeforeOffset StimOMaticConstants.LFPAverageAfterOffset];

set(handles.axesRaster,'ylim',ylimsThis,'xlim',xlimsToUse, 'ylimmode','manual','xlimmode','manual'); %,'XTickLabel',[]);

handlesGUI.lineHandles = [];
