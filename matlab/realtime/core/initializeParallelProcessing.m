%
% initialize pool of workers, data structures
%
%urut/dec11
function [labRefs, nrWorkers, workerChannelMapping, allOKTot, activePluginsCont, activePluginsTrial] = initializeParallelProcessing( nrActiveChannels, StimOMaticConstants, StimOMaticData, serverIP, activePlugins, handlesParent, nrWorkersToUseMax )

allOKTot=[];
workerChannelMapping=[];
activePluginsCont = [];
activePluginsTrial = [];

% in case no channels are selected.
if nrActiveChannels == 0
    labRefs = [];
    nrWorkers = [];
    allOKTot = 0;
    return;
end
   
% events are received directly in the client
succeededEvents = NlxOpenStream( StimOMaticConstants.TTLStream );
if succeededEvents~=1
    nrWorkers=[];
    labRefs=[];
    allOKTot=0;
    warning(['error opening TTL stream:  ' StimOMaticConstants.TTLStream ' error code ' num2str(succeededEvents) '. Cant continue.']);
    return;
else
    disp(['opened event stream: ' StimOMaticConstants.TTLStream]);
end

% distribute channels to workers, decide how many workers are needed
[workerChannelMapping, nrWorkers] = distributeChannels_toWorkers( nrWorkersToUseMax, nrActiveChannels, StimOMaticData );

initializeWorkers( nrWorkers );

% pre-allocate data on the workers
CSCBufferData = Composite(nrWorkers);
CSCTimestampData = Composite(nrWorkers);
currentTimeOnAcquisition = Composite(nrWorkers);
CSCChannelInfo = Composite(nrWorkers);
scheduledEventsStack = Composite(nrWorkers);
trialData = Composite(nrWorkers);
processedData = Composite(nrWorkers);
dataTransferGUI = Composite(nrWorkers);
globalProperties = Composite(nrWorkers);   % global properties, sent to all workers. exists once per worker


trialDataInit = getTrialDataInit;

processedDataInit.StimOMaticConstants = StimOMaticConstants; %copy these so they are available to each worker in local workspace
processedDataInit.workerChannelMapping = workerChannelMapping;

%== init data for each plugin (all are assumed to run on all channels)

if length(activePlugins)>0

    for k=1:length(activePlugins)
        % let this plugin know what its abs_ID is.
        handlesParent.abs_ID_in_parent = activePlugins{k}.abs_ID;
        pluginData{k} = activePlugins{k}.pluginDef.initWorker( handlesParent, activePlugins{k}.handlesGUI );
        
        if activePlugins{k}.pluginDef.type == 1 %continuous
            activePluginsCont = [ activePluginsCont k ];
        end
        if activePlugins{k}.pluginDef.type == 2 %TT
            activePluginsTrial = [ activePluginsTrial k ];
        end

    end
    processedDataInit.pluginData = pluginData;
    
    %prepare lists of plugins to loop over (pre-compute)
    processedDataInit.activePluginsCont = activePluginsCont;
    processedDataInit.activePluginsTrial = activePluginsTrial;
    
else
    processedDataInit.pluginData=[];
end

globalPropertiesInit.activePlugins = activePlugins;
globalPropertiesInit.StimOMaticConstants = StimOMaticConstants;
globalPropertiesInit.runCounter = 0;

%initialize data structures on each of the workers
for workerID = 1:nrWorkers
    
    [channelsOnWorker, nrChannelsOnWorker] = distributeChannels_getChannelsForWorker( workerChannelMapping, workerID );
   
    %prepare data structures for this worker
    CSCChannelInfoForWorker=[];
    CSCBufferDataForWorker=[];
    CSCTimestampDataForWorker=[];
    for j=1:nrChannelsOnWorker
       CSCChannelInfoForWorker{j} = StimOMaticData.CSCChannels{channelsOnWorker(j)};
       scheduledEventsStackForWorker{j} = [];
       processedDataForWorker{j} = processedDataInit;
       trialDataForWorker{j} = trialDataInit;
       

       [dataInit,frameOrderInit] = dataBufferFramed_init(StimOMaticConstants.frameSize, StimOMaticConstants.nrFramesToBuffer);
       CSCTimestampDataForWorker{j}.data = dataInit;
       CSCTimestampDataForWorker{j}.frameOrder = frameOrderInit;
       CSCBufferDataForWorker{j}.data = dataInit;
       CSCBufferDataForWorker{j}.frameOrder = frameOrderInit;
       
    end

    % transfer the data to this worker
    CSCBufferData{workerID} = CSCBufferDataForWorker;
    CSCTimestampData{workerID} = CSCTimestampDataForWorker;    
    
    %CSCBufferData{workerID} = zeros(nrChannelsOnWorker, StimOMaticConstants.bufferSizeCSC)+5.5;
    %CSCTimestampData{workerID} = zeros(nrChannelsOnWorker, StimOMaticConstants.bufferSizeCSC);    
    
    CSCChannelInfo{workerID} = CSCChannelInfoForWorker;
    scheduledEventsStack{workerID} = scheduledEventsStackForWorker;
    processedData{workerID} = processedDataForWorker;
    trialData{workerID} = trialDataForWorker;  
    
    currentTimeOnAcquisition{workerID} = 0;
    
    globalProperties{workerID} = globalPropertiesInit;
    
    dataTransferGUI{workerID} = [];
end

labRefs.CSCBufferData = CSCBufferData;
labRefs.CSCTimestampData = CSCTimestampData;
labRefs.currentTimeOnAcquisition = currentTimeOnAcquisition;
labRefs.CSCChannelInfo = CSCChannelInfo;
labRefs.scheduledEventsStack = scheduledEventsStack;
labRefs.trialData = trialData;
labRefs.processedData = processedData;
labRefs.dataTransferGUI = dataTransferGUI;
labRefs.globalProperties = globalProperties;

%== connect each worker to router
%
spmd(nrWorkers)
   
    succeeded = NlxConnectToServer(serverIP);
    NlxSetApplicationName( ['StimOMatic worker #' num2str(labindex) ' ' StimOMaticConstants.versionStr] );
    disp(['Worker connect succeed connect is=' num2str(succeeded)  ]);
    if succeeded~=1
        allOK=0;
    else
        allOK=1;
    end
    
    %subscribe to the appropriate channel
    for chanID=1:length(processedData)
        CSCStr = CSCChannelInfo{chanID}.channelStr;
        succeeded = NlxOpenStream( CSCStr );
        if succeeded~=1
            disp(['Problem to subscribe to ' CSCStr]);
            allOK=0;
        else
            allOK=1;
            disp(['lab' num2str(labindex) ' succeed open stream=' num2str(succeeded) ' Channel is ' CSCChannelInfo{chanID}.channelStr]);
        end
    end
    
    %DEBUGGING only - enable profiling of the workers. 
    %call later to see the profiling info for all the workers:
    %spmd(nrWorkers) 
    %mpiprofile off; mpiprofile viewer; 
    %end     

    enableParallelProfiling = 0;
    if enableParallelProfiling
        warning('parallel profiling is enabled!');
        mpiprofile on;
    end
end

%collapse error codes across all workers
allOKTot = 1;
for k=1:length(allOK)
    if allOK{k}~=1
        allOKTot = 0;
    end
end

