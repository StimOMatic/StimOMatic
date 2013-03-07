%
%run on worker, prepare data to be transfered to client for plotting (as little as possible)
%this will be called once per channel that this GUI is processing
%
%
function pluginDataToTransfer = pCtrlLFP_prepareGUItransfer( pluginData )

pluginDataToTransfer=[];

pluginDataToTransfer.enabledOnChannel = pluginData.enabledOnChannel;
pluginDataToTransfer.enabledOnChannelStr = pluginData.enabledOnChannelStr;

if pluginData.enabledOnChannel == labindex
    
    if pluginData.plotModeOn
        %disp('trasnsupdating plot');
        pluginDataToTransfer.dataBuffer = pluginData.dataBuffer;
    else
        pluginDataToTransfer.dataBuffer =[];    
    end
    
    pluginDataToTransfer.params = pluginData.params;
    pluginDataToTransfer.methodNr = pluginData.methodNr;
    
end

