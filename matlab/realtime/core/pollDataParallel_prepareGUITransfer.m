function [dataTransferGUI] = pollDataParallel_prepareGUITransfer(chanID, processedData,trialData, activePlugins)

%for chanID = 1:length(processedData)   % loop over all channels assigned to this worker
    
    % check if any active plugins are present, otherwise this function will
    % crash.
    if isempty(activePlugins)
        dataTransferGUI = {};
        return;
    end

    dataTransferGUIOfChannel = [];    
    
    %initialize in case there is no data
    for k=1:length(activePlugins)
        dataTransferGUIOfChannel{k}=[];
    end
    
    % call prepareGUItransfer in each continuous plugin
    for k=processedData{chanID}.activePluginsCont
        %for k=1:length(activePlugins)
        %if activePlugins{k}.pluginDef.type == 1 %continuous
        dataTransferGUIOfChannel{k} = activePlugins{k}.pluginDef.transferGUIFunc( processedData{chanID}.pluginData{k} );
        %end
    end
    
    if trialData{chanID}.updatePlotPending
        % call prepareGUItransfer in each TT plugin
        for k=processedData{chanID}.activePluginsTrial
            %if activePlugins{k}.pluginDef.type == 2 %TT
            dataTransferGUIOfChannel{k} = activePlugins{k}.pluginDef.transferGUIFunc( processedData{chanID}.pluginData{k} );
            %end
        end
    end
    
    dataTransferGUI{chanID} = dataTransferGUIOfChannel;
%end