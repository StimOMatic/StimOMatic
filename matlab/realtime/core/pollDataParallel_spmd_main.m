%
% main process data routine that is run on every worker at every iteration of polling
%
%
function [scheduledEventsStack,processedData,CSCBufferData,CSCTimestampData, trialData, currentTimeOnAcquisition, dataTransferGUI,globalProperties] = pollDataParallel_spmd_main(CSCBufferData, CSCTimestampData, currentTimeOnAcquisition, CSCChannelInfo, scheduledEventsStack, trialData, processedData, dataTransferGUI, globalProperties, RTModeOn)
globalProperties.runCounter = globalProperties.runCounter+1;

%allocate memory if first run
if globalProperties.runCounter==1
    globalProperties.dataArrayPreAlloc = nan(1,(512*1000) );  %faster
    
    globalProperties.dataArrayPtr = libpointer('int16PtrPtr', globalProperties.dataArrayPreAlloc);

end

nrRunsTotal=1;
if RTModeOn
    nrRunsTotal=1000;
end

for kk=1:nrRunsTotal   %how many Runs to make till return to GUI
    
    % process new data for each worker
    for chanID = 1:length(processedData)   % loop over all channels assigned to this worker
        [dataArray,timeStampArray,timeStampArrayConv,~,numRecordsReturned] = Netcom_pollCSC( CSCChannelInfo{chanID}.channelStr, 0, globalProperties.StimOMaticConstants.Fs, globalProperties.dataArrayPreAlloc,globalProperties.dataArrayPtr );  %0/1 verbose
        
        %debug - to display every package received
        
        %update internal data structures
        if numRecordsReturned>0
            [processedData,CSCBufferData,CSCTimestampData,currentTimeOnAcquisition, newDataScaled] = ...
                pollDataParallel_processNewDataBlock(chanID, dataArray, timeStampArray,timeStampArrayConv, globalProperties.StimOMaticConstants.bufferSizeCSC, CSCChannelInfo, processedData,  CSCBufferData,CSCTimestampData, currentTimeOnAcquisition, globalProperties.activePlugins );
            
            %see if the new data that arrived contains future scheduled
            %averaging events
            [scheduledEventsStack,processedData,trialData] = pollDataParallel_processEventsStack(chanID, scheduledEventsStack,CSCBufferData, CSCTimestampData , trialData, processedData, newDataScaled, timeStampArray, globalProperties.activePlugins);
            
 
            % prepare data possibly to be transfered to master for display
            % only transfer if new data was received
            dataTransferGUI = pollDataParallel_prepareGUITransfer(chanID, processedData,trialData, globalProperties.activePlugins);
            
        end
        
 
        % display output after finished processing
        if labindex==1
              if (mod(globalProperties.runCounter,20)==0 && nrRunsTotal==1 && kk==1) || (nrRunsTotal>1 && kk==10)
              %if numRecordsReturned>0
                   disp(['C:' num2str(globalProperties.runCounter) ' worker ' num2str(labindex) ' received ' num2str(numRecordsReturned) ' updatePlotPending=' num2str(trialData{chanID}.updatePlotPending)]);
             end
        end
        
        
        
    end % end over channels on this worker
    
    if RTModeOn & numRecordsReturned==0
        pauser(0.005,clock);    % wait if there was no data
    %    pause(0.001);  % blocksize 512/32556 is ~15ms
    end
end