%
% called by callbacks initiated by timers
%
%urut/dec11
function labRefs = updateGUI_realtimeStreams( handles, nrWorkersToPoll, labRefs, activePlugins, iterationCounter )

trialData = labRefs.trialData;
CSCTimestampData = labRefs.CSCTimestampData;
currentTimeOnAcquisition = labRefs.currentTimeOnAcquisition;
processedData = labRefs.processedData;
dataTransferGUI = labRefs.dataTransferGUI;

%% update plots, single threaded
try    
    workerIDForGlobal=1; %keep global update state only in this worker,use for all
    
    for workerID = 1:nrWorkersToPoll
        
        %loop over channels that are assigned to this worker
        [channelsOnWorker, nrChannelsOnWorker] = distributeChannels_getChannelsForWorker( handles.workerChannelMapping, workerID );
        
        if ~isempty(activePlugins) && workerID==workerIDForGlobal
                %GUIDataOfWorker = dataTransferGUI{workerID};   %transfer this selectively only (below); on-demand
                % very expensive! ~ 8 seconds for 1200 runs
                trialDataOfWorker = trialData{workerID}; %transfer to client from this worker; only once,treat it as global. (same all workers/channels)
                % dummy 'trialDataOfWorker' if no data needed.
                %trialDataOfWorker{1}.updatePlotPending = 0;
        end
        
        trialDataUpdatedOnWorker = 0;
            
        for chanID = 1:nrChannelsOnWorker
            
            
            dataTransferedOfWorker = 0;  %only transfer data from worker when needed, then cache
            GUIDataOfWorkerTmp = [];
            
            %chanID is local channelID on this worker
            CSCChanNr = channelsOnWorker(chanID);   %global channel ID of this channel
            
            %get latest timestamp we have, same on all channels.
            if CSCChanNr==1
                %currentTimeOnAcquisition{workerID}
                if mod(iterationCounter,50)==0    %update only once in a while
                    set( handles.labelCurrentTimestamp, 'String', [num2str(currentTimeOnAcquisition{workerID})] );
                    
                end
            end
            
            %get the data for all plugins of this channel
            if ~isempty(activePlugins)
                %thisData = dataTransferGUI{workerID};
                %trialDataOfWorker = trialData{workderID}; %transfer to client from this worker

                %% matlab-plot plot all TT plugins
                chanIDForGlobal=1;
                if trialDataOfWorker{chanIDForGlobal}.updatePlotPending
                    for k=handles.activePluginsTrial
                        
                        % check if this plugin does need to update any matlab
                        % components.
                        if activePlugins{k}.pluginDef.needs_matlab_gui == 1
                            %for k=1:length(activePlugins)
                            %if activePlugins{k}.pluginDef.type == 2 %TT
                            
                            if ~dataTransferedOfWorker
                                GUIDataOfWorkerTmp = dataTransferGUI{workerID};
                                dataTransferedOfWorker=1;
                            end
                            
                            activePlugins{k}.pluginDef.updateGUIFunc( CSCChanNr, GUIDataOfWorkerTmp{chanID}{k}, activePlugins{k}.handlesGUI, handles );
                            %end
                        end
                    end
                    
                    %trialDataOfWorker{chanIDForGlobal}.updatePlotPending=0;
                    trialDataUpdatedOnWorker = 1;
                end
                
                %% matlab-plot all continuous plugins
                for k=handles.activePluginsCont
                    % check if this plugin does need to update any matlab
                    % components.
                    if activePlugins{k}.pluginDef.needs_matlab_gui == 1
                        if ~dataTransferedOfWorker
                            % very expensive! ~ 5 seconds for 1200 runs
                            GUIDataOfWorkerTmp = dataTransferGUI{workerID};
                            dataTransferedOfWorker=1;
                        end
                        if iscell(GUIDataOfWorkerTmp)
                            %if activePlugins{k}.pluginDef.type == 1 %continuous
                            % i.e.: pContinuousOpenGL_updateGUI
                            activePlugins{k}.pluginDef.updateGUIFunc( CSCChanNr, GUIDataOfWorkerTmp{chanID}{k}, activePlugins{k}.handlesGUI, handles );
                        end
                    end
                    %end
                end
            end % end if activePlugins
            
        end %end over channels
        

    end
    
    %transfer back to worker if has been changed
    if trialDataUpdatedOnWorker
        trialDataOfWorker{chanIDForGlobal}.updatePlotPending=0;
        trialData{workerIDForGlobal} = trialDataOfWorker; %transfer modified version back
    end
    
catch E
    dispAllErrors(E);
    error('abort - ');
end

labRefs.trialData = trialData;

%set(  handles.lineHandles.plotLine1_axesCSC1_title, 'String', [' sd=' num2str(sd_spikesBand) 'uV'] );
%drawnow;

