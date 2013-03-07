%
% note that the new data received, contained in newDataReceived/newTimestampsReceived
% is not yet part of CSCBufferData at the time this routine is called !
% the plugin can thus know which of the data is new.
%
function pluginData = pCtrlLFP_processData( newDataReceived, newTimestampsReceived, pluginData, CSCBufferData, CSCTimestampData )
MARKER_SECONDARY_LOW_THRESHOLD=199;
%check for which channel(s) the plugin is active currently (set in the GUI)
if pluginData.enabledOnChannelInt == pluginData.channelInfo_caller.channelInt
    Fs = pluginData.OSortConstants.Fs;
    
    %if it exists on this channel
    methodNr = pluginData.methodNr;

    %disp(['run ctrl plugin ' num2str(pluginData.channelInfo_caller.channelInt) ]);
    
    framesize=512;
    switch(methodNr)

        %===============================
        case 1 %mean amplitude

            nrDatapointsToRetrieve = floor( (pluginData.params(2)*1e-3*Fs)-framesize );     % less one frame since that is provided by newDataReceived
            nrFramesToRetrieve = ceil( nrDatapointsToRetrieve/framesize );

            
            %dataRaw = dataBufferFramed_retrieve(CSCBufferData.data, CSCBufferData.frameOrder, framesize, round(nrFramesToRetrieve) );
            
            %speed-opt
            m=0;
            if nrDatapointsToRetrieve<framesize    % if smaller than 1 frame, subsample
                %dataRaw = dataBufferFramed_retrieve(CSCBufferData.data, CSCBufferData.frameOrder, framesize, round(nrFramesToRetrieve),nrDatapointsToRetrieve );
                %m = mean( dataRaw(end-nrDatapointsToRetrieve+1:end) );
                m = mean( [ dataBufferFramed_retrieve(CSCBufferData.data, CSCBufferData.frameOrder, framesize, round(nrFramesToRetrieve),nrDatapointsToRetrieve ) newDataReceived ]   );
                
                
            else
                m = mean( [ dataBufferFramed_retrieve(CSCBufferData.data, CSCBufferData.frameOrder, framesize, round(nrFramesToRetrieve) ) newDataReceived ]);
                
            end
            
            %cmdToSend=0;
            %if mean(abs(dataRaw)) > pluginData.params(1)
            if m > pluginData.params(1)
                %disp(['Control plugin action: threshold crossed. params:' num2str(pluginData.params)]);
                pCtrlLFP_sendCommand( pluginData.hostname, 1, pluginData.previousCmdSent);
                cmdToSend=1;
            else
                pCtrlLFP_sendCommand( pluginData.hostname, 0, pluginData.previousCmdSent);
                cmdToSend=0;
                
            end
            
            %pCtrlLFP_sendCommand( pluginData.hostname, cmdToSend, pluginData.previousCmdSent);
            pluginData.previousCmdSent = cmdToSend;
                
        %===============================
        case 2
            % mean power in a band, multitaper method
            % everything here assumes 250Hz Fs
            P=1;
            Q=130;   % 32556/130 = 250.43 Hz

            params.Fs = 250; % sampling frequency
            params.fpass = [1 100];
            params.tapers = [2 3];
            params.err = 0;
            params.pad= -1;

            nrDatapointsToRetrieve = floor(pluginData.params(2)*1e-3*Fs);
            nrFramesToRetrieve = ceil( nrDatapointsToRetrieve/framesize );
            dataRaw = dataBufferFramed_retrieve(CSCBufferData.data, CSCBufferData.frameOrder, framesize, round(nrFramesToRetrieve) );

            % need to add newDataReceived because it is not part of the CSCBufferData yet when this function is called
            
            dataRawDown = downsample([dataRaw; newDataReceived], Q); % faster, but will alias since no lowpass filtering done
            %dataRawDown = downsampleRawTrace( dataRaw, P, Q );
            
            [Smean,f]=mtspectrumc( dataRawDown, params);  
            
            indToUse = find(f>=pluginData.params(3) ); % find the freq closest to the one requested



            % Decide, apply the threshold
            cmdToSend=0;
            if Smean(indToUse(1) )> pluginData.params(1) && pluginData.params(1)>0    %above threshold
                cmdToSend=1;
            end
            if Smean(indToUse(1) )< -1*pluginData.params(1) && pluginData.params(1)<0  %below threshold
                cmdToSend=1;
            end
            
            pCtrlLFP_sendCommand( pluginData.hostname, cmdToSend, pluginData.previousCmdSent);
            pluginData.previousCmdSent = cmdToSend;
            
            %plot info == do this last
            if pluginData.plotModeOn > 1 % 'Plot Mode' field
                first_value = abs(pluginData.params(1));   % set first value to threshold to illustrate setting
                last_value = Smean(indToUse(1));
                %disp(['freq used is: ' num2str( f(indToUse(1)) ) ' nrFreqs=' num2str(length(f)) ' spacing freq=' num2str(mean(diff(f))) ' power val is ' num2str(Smean(indToUse(1))) ' #data=' num2str(length(dataRaw)) ]);
            end            
            
        case 3
            % mean power in a band, hilbert method
            Q=130;   % 32556/130 = 250.43 Hz

           % tOn=tic;
            
            nrDatapointsToRetrieve = floor(pluginData.params(2)*1e-3*Fs);
            nrFramesToRetrieve = ceil( nrDatapointsToRetrieve/framesize );
            dataRaw = [ dataBufferFramed_retrieve(CSCBufferData.data, CSCBufferData.frameOrder, framesize, round(nrFramesToRetrieve) ) ];

            
            dataRawDown = downsample([dataRaw; newDataReceived], Q); % faster, but will alias since no lowpass filtering done
           
            dataBlockFiltered = filtfilt(pluginData.bandFilter_b, pluginData.bandFilter_a, dataRawDown );  
            powerEst = abs( hilbert( dataBlockFiltered ));

            indsToUse = length(powerEst)-pluginData.params(4)+1:length(powerEst);  % if window length = 1, only use the very last datapoint
            
            criteria = mean ( powerEst(indsToUse) );
            
            %criteria = max ( powerEst(indsToUse) );
            
            % Decide, apply the threshold
            cmdToSend=0;
            if criteria> pluginData.params(1) && pluginData.params(1)>0    %above threshold
                cmdToSend=1;
            %tocWithMsg('Block processed',tOn,1);
            end
            if criteria< -1*pluginData.params(1) && pluginData.params(1)<0  %below threshold
                cmdToSend=1;
            end
            
            if ~cmdToSend & criteria< -1*pluginData.params(5) && pluginData.params(5)<0 %a second below-value threshold can also be active. only test it if first threshold was not a hit
                cmdToSend = MARKER_SECONDARY_LOW_THRESHOLD; %secondary sends a special nr to distinguish
            end

            currTimestamp = newTimestampsReceived(end);
            pCtrlLFP_sendCommand( pluginData.hostname, cmdToSend, pluginData.previousCmdSent, currTimestamp);
            pluginData.previousCmdSent = cmdToSend;

            %plot info == do this last        
            if pluginData.plotModeOn > 1 % 'Plot Mode' field
                last_value = powerEst(indsToUse(end));
                first_value = abs(pluginData.params(1));   % set first value to threshold to illustrate setting
            end            
        
        case 4
            
            %tic
            %phase-dependent stimulation
            Q=130;   % 32556/130 = 250.43 Hz

            %retrieve appropriate amounts of data from the history buffer, and append the new data in newDataReceived
            nrDatapointsToRetrieve = floor(pluginData.params(2)*1e-3*Fs);
            nrFramesToRetrieve = ceil( nrDatapointsToRetrieve/framesize );
            dataRaw = [ dataBufferFramed_retrieve(CSCBufferData.data, CSCBufferData.frameOrder, framesize, round(nrFramesToRetrieve) ) ; newDataReceived];

            methodPeakDetectNr = 2; %1 is inst freq as derivative of inst phase, 2 is peak detect
            avSizePeakDetect=1; %how many past peaks to use to estimate (if method=2)

            %sysDelay=0.001;   % if very small,let receiving system discard; for 20Hz

            %sysDelay=0.015;   % if delay less than this,skip to next cycle  in sec
            sysDelay=0.027;   % if delay less than this,skip to next cycle  in sec; adjust according to value in presentation program.
          
            [powerAtEnd, delayTillStim,peaks,estFreqUsed] = evalPhaseStimForBlock( dataRaw, Q, pluginData.bandFilter_b, pluginData.bandFilter_a, ...
                pluginData.params(1), methodPeakDetectNr, 1/250, avSizePeakDetect, sysDelay, pluginData.params(5), pluginData.params(4) );

            %toc
            if delayTillStim<0 
                warning('phase value negative -- not possible');
            end

            freqBandAcc=3;
            if delayTillStim>0 & pluginData.params(3)-freqBandAcc< estFreqUsed<pluginData.params(3)+freqBandAcc % a phase value was delivered and the freq estimate is within our band
                cmdToSend=round( delayTillStim*1000 );
                if cmdToSend>255
                    warning('cmd to send too large');
                end
                
                pCtrlLFP_sendCommand_noTTL( pluginData.hostname, cmdToSend, pluginData.previousCmdSent);
                pluginData.previousCmdSent = cmdToSend;

                %disp(['freq est used ' num2str(estFreqUsed) ]);
                %estFreqUsed
            else
                % if no phase value was detected, see if threshold is below
                % the low-thres (absence of oscillations) detecotr
                if pluginData.params(6)<0
                    if powerAtEnd<-1*pluginData.params(6)
                        cmdToSend=MARKER_SECONDARY_LOW_THRESHOLD;
                    else
                        cmdToSend=0;
                    end
                    pCtrlLFP_sendCommand_noTTL( pluginData.hostname, cmdToSend, pluginData.previousCmdSent);
                   pluginData.previousCmdSent = cmdToSend;
                end
            end
            
            %plot info == do this last        
            if pluginData.plotModeOn > 1 % 'Plot Mode' field
                % add 'powerAtEnd' to plot - or just transmit 'powerAtEnd'
                % to other side.
                last_value = powerAtEnd;
                first_value =[ abs(pluginData.params(1)) abs(pluginData.params(6))];   % set first value to threshold to illustrate setting
            end            
            
    end
    
    
    %% POSSIBLE PLOTTING
    
    % if plotting is 'Off', return here.
    if pluginData.plotModeOn == 1
        return;
    end
    
    % size(pluginData.dataBuffer) ==  [1  200]
    if pluginData.plotModeOn == 2 % 'On (matlab)'
        pluginData.dataBuffer = [ pluginData.dataBuffer(2:end) last_value ];
        pluginData.dataBuffer(1) = first_value(1); % set first value to threshold to illustrate setting
        if length(first_value)>1
            pluginData.dataBuffer(2) = first_value(2); % set first value to threshold to illustrate setting
        end
        return;
    end
    
    if pluginData.plotModeOn == 3 % 'OpenGL'
        first_value=first_value(1);
% debugging
%        c = 0;
%        adder = + 1;
%        while 1
%         last_value = 100 + c;
%         c = c + adder;
%         if c == 256
%             adder = adder * -1;
%         elseif c == 0
%             adder = adder * -1;
%         end
        first_value = 1;
        y_offset = 0;
        value_to_send = y_offset + (last_value);
        threshold_to_send = y_offset + first_value;

        % compare OpenGL and matlab output:
        % pluginData.dataBuffer = [ pluginData.dataBuffer(2:end) value_to_send ];
        % pluginData.dataBuffer(1) = threshold_to_send; % set first value to threshold to illustrate setting                
        %
        % value_to_send
        % what is the maximum number of buffers that can be transmitted?
        %max_nbr_buffers_transmitted = pluginData.mmap_stats.Data(2);
        
        % I'm setting framesize to 1 here. This should work now.
        max_nbr_buffers_transmitted = 10;
        framesize = 1;

        % quick fix for cases where matlab queue is growing too fast which
        % will lead to a laged display of data on the python side.
        %if pluginData.queue1.size() > 1
        %    pluginData.queue1.clear()
        %end
        % pluginData.queue1.size()
        
        
        % enqueue new data locally.
        pluginData.queue1.add(value_to_send);

        
        % transfer data from local queue to remote queue
        [pluginData.queue1, transmitted, nbr_buffers_transmitted] = send_databuffers_over_mmap(max_nbr_buffers_transmitted, framesize, pluginData.mmap_data1, pluginData.queue1, pluginData.mmap_stats);
        
        % overwrite number of transmitted buffers only if transmission
        % occoured. otherwise the remote side might be still picking up data
        % and we don't want to accidently set 'nbr_buffers == 0'.
        if transmitted
            % tell receiver how many buffers we transmitted.
            pluginData.mmap_stats.Data(3) = nbr_buffers_transmitted;

        end
       % pause(0.02);
       % end
        return;
    end
    
    
end


function pCtrlLFP_sendCommand(hostname, Cmd, previousCmdSet,currTimestamp)
if previousCmdSet~=Cmd
    if tcpClientMat(num2str(Cmd), hostname, 9999, 0)==-1
        warning('could not send RT cmd');
        warning(['Cmd = ' num2str(Cmd)]);
        warning(['previousCmdSet = ' num2str(previousCmdSet)]);
    end
    
    if nargin==4
        NlxSendCommand(['-PostEvent "pCtrLFP Trigger at t=' num2str(currTimestamp) '" 150 10']);   %also send to the event log
    else
        NlxSendCommand('-PostEvent "pCtrLFP Trigger" 150 10');   %also send to the event log
    end
end

function pCtrlLFP_sendCommand_noTTL(hostname, Cmd, previousCmdSet)
if previousCmdSet~=Cmd
    if tcpClientMat(num2str(Cmd), hostname, 9999, 0)==-1
        warning('could not send RT cmd (noTTL)');
        disp(['Cmd = ' num2str(Cmd)]);
        disp(['previousCmdSet = ' num2str(previousCmdSet)]);
    end
end
