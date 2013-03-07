%part of pollDataParallel.m, externalized to allow profiling
%
%checks the scheduled events stack for this channel and executes plugins if new events have arrived that need to be processed.
%
%
function [scheduledEventsStack,processedData,trialData] = pollDataParallel_processEventsStack(chanID, scheduledEventsStack,CSCBufferData, CSCTimestampData , trialData, processedData,newDataScaled, timeStampArray, activePluginsCont)

if ~isempty( scheduledEventsStack{chanID} )
    Nstack = size(scheduledEventsStack{chanID},1);
    
    for k=1:Nstack
        t = scheduledEventsStack{chanID}(k,1);
        tFrom = scheduledEventsStack{chanID}(k,2);
        
        %disp([ num2str(CSCTimestampData(end)) ' ' num2str(t) '  ' num2str(tFrom)  ]);
        lastTimestamp = CSCTimestampData{chanID}.data(end,CSCTimestampData{chanID}.frameOrder(end));
        
        if lastTimestamp>t
            %event is here, process it
            disp(['Processing event on worker ' num2str(labindex) ' from ' num2str(tFrom) ' to ' num2str(t) ' remaining stack size ' num2str(size(scheduledEventsStack{chanID},1)-1) ]);
            
            trialData{chanID}.updatePlotPending = 1;
            
            %loop over trial-by-trial plugins
            for kk=processedData{chanID}.activePluginsTrial
                    for depNr=1:length(activePluginsCont{kk}.dependenceInds)
                        processedData{chanID}.pluginData{kk}.dependenceData{depNr} = processedData{chanID}.pluginData{activePluginsCont{kk}.dependenceInds(depNr)};
                    end
                    processedData{chanID}.pluginData{kk} = activePluginsCont{kk}.pluginDef.processDataFunc( ...
                        newDataScaled', timeStampArray, processedData{chanID}.pluginData{kk}, dataBufferFramed_retrieve_all(CSCBufferData{chanID}), ...
                        dataBufferFramed_retrieve_all(CSCTimestampData{chanID}), t, tFrom );
            end
            
            %remove it from the queue
            scheduledEventsStack{chanID} = scheduledEventsStack{chanID}( setdiff(1:Nstack,k), : );
            break; %process only one per iteration
        %else
            
        %    disp(['dont have time yet ' num2str(t) ' have so far ' num2str(lastTimestamp) ]);
        end
    end
end %end process scheduled events from stack