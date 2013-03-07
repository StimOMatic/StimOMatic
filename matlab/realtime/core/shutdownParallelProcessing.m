function [allOK,labRefs] = shutdownParallelProcessing(nrActiveWorkers, OSortConstants, labRefs)
allOK=1;

succeededEvents = NlxCloseStream(  OSortConstants.TTLStream );

processedData = labRefs.processedData;
globalProperties = labRefs.globalProperties;

%disconnect each worker from router
spmd(nrActiveWorkers)
    succeeded = Netcom_disconnectConn();
    
    % call the shutdown routine of each plugin, if it is defined
    for chanID = 1:length(processedData)   % loop over all channels assigned to this worker
        for k=1:length( globalProperties.activePlugins)
            if isfield( globalProperties.activePlugins{k}.pluginDef, 'shutdownWorkerFunc')
                
                if ~isempty(globalProperties.activePlugins{k}.pluginDef.shutdownWorkerFunc)
                    
                    disp('calling shutdown');
                    processedData{chanID}.pluginData{k} = globalProperties.activePlugins{k}.pluginDef.shutdownWorkerFunc( processedData{chanID}.pluginData{k} );
                end
            end
            
        end
    end
    
end

labRefs.processedData=processedData;
labRefs.globalProperties=globalProperties;


for k=1:length(succeeded)
    if succeeded{k}~=1
        allOK=0;
    end
end