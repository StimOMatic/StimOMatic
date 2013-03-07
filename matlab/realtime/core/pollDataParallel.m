%
% main function to poll data in parallel.
% poll and process data for each channel
%
% some things in this function might seem odd or hard to read. this is due to speed-optimization.
%
% RTModeOn: stay longer in workers, faster RT control but slower GUI and trial-by-trial averaging.
%
%
function labRefs = pollDataParallel( nrWorkersToPoll, labRefs, RTModeOn  )

%restore the composite refs
CSCBufferData = labRefs.CSCBufferData;
CSCTimestampData = labRefs.CSCTimestampData;
currentTimeOnAcquisition = labRefs.currentTimeOnAcquisition;
CSCChannelInfo = labRefs.CSCChannelInfo;
scheduledEventsStack = labRefs.scheduledEventsStack;
trialData = labRefs.trialData;
processedData = labRefs.processedData;
dataTransferGUI = labRefs.dataTransferGUI;
globalProperties = labRefs.globalProperties;

try
    spmd(nrWorkersToPoll)
         % put everything in a function that returns nothing,so no automatic composite variables are created. 
         % all inputs and returns of this funct are pre-assigned composite references..
         
         
         [scheduledEventsStack,processedData,CSCBufferData,CSCTimestampData, trialData, ...
             currentTimeOnAcquisition, dataTransferGUI,globalProperties] = pollDataParallel_spmd_main(CSCBufferData, CSCTimestampData, ...
             currentTimeOnAcquisition, CSCChannelInfo, scheduledEventsStack, trialData, processedData, dataTransferGUI, globalProperties, RTModeOn);            
         
    end
catch E
    disp('Error in pollDataParallel spmd block');
    dispAllErrors(E);
end

%preserve the handles to composites so garbage collection doesnt kill them.
labRefs.CSCBufferData = CSCBufferData;
labRefs.CSCTimestampData = CSCTimestampData;
labRefs.currentTimeOnAcquisition = currentTimeOnAcquisition;
labRefs.CSCChannelInfo = CSCChannelInfo;
labRefs.scheduledEventsStack = scheduledEventsStack;
labRefs.trialData = trialData;
labRefs.processedData = processedData;
labRefs.dataTransferGUI = dataTransferGUI;
labRefs.globalProperties=globalProperties;
