%
%plot the GUI of the plugin
%
function handlesGUI = pCtrlLFP_initGUI( handlesGUI, handlesParent )

%% delete old elements if they exist
if isfield(handlesGUI, 'lineHandles')
   removeExistingLineHandles ( handlesGUI.lineHandles.plotaxesCtrlSignal );
end

%% create handles/lines
% waveforms
appdata = getappdata( handlesGUI.figHandle);
handles = appdata.UsedByGUIData_m;

set(0,'CurrentFigure',handlesGUI.figHandle)
set( handlesGUI.figHandle,'CurrentAxes',handles.axesControlSignal1)

StimOMaticConstants = handlesParent.StimOMaticConstants;

stepsize = 1e6 / handlesParent.StimOMaticConstants.Fs; %in ms

%x = [1:stepsize:StimOMaticConstants.bufferSizeCSC*stepsize]/1000;

nrDataPoints=200;

x=1:nrDataPoints;

y=repmat(0,1,length(x));

lineHandles.plotaxesCtrlSignal = line(x, y, 'color','r' ); 

ylimsThis=[-10 10000];
set(handles.axesControlSignal1,'ylim',ylimsThis,'ylimmode','auto','xlimmode','manual'); 
xlim([0 nrDataPoints]);

handlesGUI.lineHandles = lineHandles;