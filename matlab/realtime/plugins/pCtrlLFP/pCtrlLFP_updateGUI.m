%
%update the GUI with new information. called once for each channel
%
%
%
function pCtrlLFP_updateGUI( CSCChanNr, transferedGUIData, handlesPlugin, handlesParent )

%selected closed-loop channel
if CSCChanNr == transferedGUIData.enabledOnChannel

    %TODO: check a "plotting on" signal in the GUI; otherwise too slow
    if ~isempty(transferedGUIData.dataBuffer)
        
        set(handlesPlugin.lineHandles.plotaxesCtrlSignal, 'ydata', transferedGUIData.dataBuffer );
        
        
    end
end