%
% create all plot handles to allow later fast updating
%
%
function lineHandles = initializeGUIPlots( handles )
lineHandles=[];

stepsize = 1e6 / handles.OSortConstants.Fs; %in ms

%% remove old lines if they exist already
if isfield(handles,'lineHandles')
%    removeExistingLineHandles ( handles.lineHandles.plotaxesCtrlSignal );
%    removeExistingLineHandles ( handles.lineHandles.plotLine_axesAvAll );
end

%%  averages
OSortConstants = handles.OSortConstants;



%==== legacy, everything in here moved to plugins
