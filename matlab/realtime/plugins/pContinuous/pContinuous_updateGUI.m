%
%update the GUI with new information. called once for each channel
%
%
%
function pContinuous_updateGUI( CSCChanNr, transferedGUIData, handlesPlugin, handlesParent )

%skip if disabled entirely or only enabled for first channel
if transferedGUIData.plotMode==2 ||  (transferedGUIData.plotMode==3 && CSCChanNr>1)
    return;
end
%transferedGUIData.plotMode

if ~isempty( transferedGUIData.xdata)
    %get existing value and only replace with what is new
    ydata = get( handlesPlugin.lineHandles.plotLine1_axesCSCall(CSCChanNr), 'ydata');
    ydata( transferedGUIData.xdata ) = transferedGUIData.filteredDataLFP+(CSCChanNr-1)*handlesParent.OSortConstants.plotOffsetRawband;

    set( handlesPlugin.lineHandles.plotLine1_axesCSCall(CSCChanNr), 'ydata', ydata);
    
    ydata = get( handlesPlugin.lineHandles.plotLine1_axesSpAll(CSCChanNr), 'ydata');
    ydata( transferedGUIData.xdata ) = transferedGUIData.filteredDataSpikes+(CSCChanNr-1)*handlesParent.OSortConstants.plotOffsetSpikeband;
    set( handlesPlugin.lineHandles.plotLine1_axesSpAll(CSCChanNr), 'ydata', ydata );
end


        
appdata = getappdata( handlesPlugin.figHandle);
handles = appdata.UsedByGUIData_m;

prevVal='';
if CSCChanNr>1
    prevVal=get( handles.textStatsSpikeband, 'String' );
end
set( handles.textStatsSpikeband, 'String', [prevVal ' '  num2str(transferedGUIData.spikesSd, '%.1f') ' (' num2str(CSCChanNr) ')']);

%set( handlesPlugin.textStatsLFPband, 'String', )