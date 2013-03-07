%receive signals from realtime analysis to interupt waiting if appropriate
%signal arrives. Signals can either be received via Netcom events or
%MatRTSync shared memory variables.
%
%Also check if e or s was pressed to interrupt the waiting.
%
%This code polls constantly, thus only use on dedicated psychophysics
%machine as it will fully utilize the CPU.
%
%Input parameters:
%
%RT mode : 
%1 = read events directly, 
%2 = use MatRTSync shared mem variable(on/off)
%3 = use MatRTSync shared mem variable (phase delays / phase locking)
%
%sysDelayToUse: only for mode=3
%nrShown: how many trials have been shown so far of each category. this can be less than the total nr trials if it is randomized (some trials are not shown randomly as a control)
%lowThreshFraction: only for RtMode=2 and if secondary threshold is used in RT Ctrl plugin. Allow maximally this fraction of other trials to be low-threshold triggered
%sequencePresentationMode: yes/no
%sequencePresentationState: 0 wait for first stim, 1 wait for second stim, -1 abort (first shown, second not reached)
%
%
%returns:
%stopped: manually stopped by keyboard yes/no
%RTctrlValReceived : returns the value that was received that caused the abort of the wait (from shared mem)
%isSecondaryThreshold: yes/no, did the secondary threshold trigger interruption
%sequencePresentationState: only used if sequencePresentationMode==1.
%maxWaitForSecondInSequence: only for sequencePresentationMode==1. How many secs to wait max till showing the second stimulus, otherwise abort.
%
%urut/aug10 initial
%urut/april12 added delay/phase sync
%
function [stopped,RTctrlValReceived, isSecondaryThreshold, sequencePresentationState] = checkIfStopped_conditional( waitForSecs, memFileHandle, mode, minTimeToWait,sysDelayToUse, nrShown, lowThreshFraction, sequencePresentationMode, sequencePresentationState, maxWaitForSecondInSequence )

if nargin<1
    waitForSecs=0;
end
lptAddress=888;   %sends a TTL to this port as soon as interrupt arrives
TTLvalue=90;
RTctrlValReceived=0;
isSecondaryThreshold=0;

MARKER_SECONDARY_LOW_THRESHOLD = 199;  % this marker is sent to distinguish the primary from the secondary threshold
MARKER_PRIMARY_HIGH_THRESHOLD = 1;


% for phase stim
newValRange=[10 100];  % permitted range of delays that will be processed,others are ignored

%waitUnit=0.001;  % ms
waitUnit=0;  % ms

stopped=0;
keyStop1 = KbName('s');
keyStop2 = KbName('e');

if mode == 1
   %clean event cue to make sure no old events are processed that arrived
   %while stimuli were displayed.
   [~, ~, ~, ttlValueArray, ~, numRecordsReturned, ~] = NlxGetNewEventData('Events');
   disp(['discarded nr old entries ' num2str(numRecordsReturned)]);
end

infosPrinted = [0 0];  %only print some output once

if waitForSecs == 0
    stopped = checkKeysInt( keyStop1,keyStop2 );
else
    tStart=GetSecs;

    c=0;
    lastVal = memFileHandle.Data(end); % start at current value, so update is only done if a new value is received
    
    while ( GetSecs-tStart<=waitForSecs)
        c=c+1;

        if waitUnit>0
            WaitSecs( waitUnit );
        end

        if mod(c,100)==0
            stopped = checkKeysInt( keyStop1,keyStop2 );
        end
        
        %manual stop
        if stopped
            disp(['wait of ' num2str(waitForSecs) ' aborted early ' num2str(c)]);
            break;
        end
        
        %see if remote analysis has initiated a stop (start trial)
        abortLoop=0;
        switch(mode)
            case 1
                %trigger stim if appropriate event was received (TTL 150)
                [~, ~, ~, ttlValueArray, ~, numRecordsReturned, ~] = NlxGetNewEventData('Events');
                if numRecordsReturned>0
                    disp(['numret= ' num2str(numRecordsReturned) ' Events num recs ret >0 ' num2str(ttlValueArray(1)) ]);
                    for jj=1:numRecordsReturned
                        if ttlValueArray(jj)==150
                            lptwrite(lptAddress, TTLvalue);   % TTL 90 =
                            disp(['MatRTSync - NLX Event - indicated premature stop. ' ' counter ' num2str(c) ' t=' num2str(GetSecs) ] );
                            
                            if GetSecs-tStart >minTimeToWait
                                abortLoop=1;
                            else
                                disp(['min time to wait not fullfilled, ignore ' num2str(minTimeToWait) ]);
                            end
                            break;
                        end
                    end
                end
                
            case 2
                %trigger stim immediately if received >0 in shared mem
                %wait at least minTimeToWait, unless in sequence mode and waiting for secondary
                if memFileHandle.Data(end) ~= 0 && ( (sequencePresentationMode && sequencePresentationState ) || (GetSecs-tStart >minTimeToWait) ) 
                    RTctrlValReceived = memFileHandle.Data(end);
                    %disp(['received: ' num2str(RTctrlValReceived) ]);
                    
                    %only allow a limited number low-tresh trials if they are triggered by the secondary threshold (==2)
                    if RTctrlValReceived == MARKER_SECONDARY_LOW_THRESHOLD && ~sequencePresentationMode
                        fractShownEmpty = nrShown(3)/sum(nrShown(1:3));   % fraction of trials shown so far that were empty trials secondary threshold
                        if  fractShownEmpty>lowThreshFraction
                            if ~infosPrinted(1)
                                disp(['skip low thresh trial -- too many. fraction so far: ' num2str(fractShownEmpty) ' allowed ' num2str(lowThreshFraction) ]);
                                infosPrinted(1)=1;
                            end
                            continue;
                        end
                        disp(['isSecondaryThreshold=1 low thresh triggered trial']);
                        isSecondaryThreshold = 1;                        
                    end
                    
                    if sequencePresentationMode
                        % if state=0 , only react to secondary threshold (initiate)
                        % if state=1, only react to primary threshold (show second stimulus)
                        if sequencePresentationState==0
                            if (RTctrlValReceived == MARKER_SECONDARY_LOW_THRESHOLD) 
                                % Show the first image in the sequence
                                sequencePresentationState = 1;  % show the first, then wait for second
                                disp(['Sequence -- show first stimulus triggered']);
                            else
                                %ignore, continue wait for the first image in sequence
                                if ~infosPrinted(2)
                                    disp(['skip -- waiting for low threshold (sequence)']);
                                    infosPrinted(2)=1;
                                end
                                continue;
                            end
                        else
                            
                            if sequencePresentationState==1
                                % see if too much time has elapsed,then abort wait for second,otherwise continue waiting
                                if (GetSecs-tStart)> maxWaitForSecondInSequence
                                    sequencePresentationState = -1;  % abort
                                    disp(['Time expired - abort wait for second']);
                                else
                                    
                                    %time has not expired, see if it is the correct trigger
                                    if RTctrlValReceived == MARKER_PRIMARY_HIGH_THRESHOLD
                                        %show the second image
                                        sequencePresentationState = 0; % show the second, go back to wait for first
                                        disp(['show second stimulus in sequence (threshold crossed)']);
                                    else
                                        %not the correct signal, wait more
                                        continue;
                                    end
                                end
                            end
                        end
                    end %end sequencePresentationMode==1
                    
                    lptwrite(lptAddress, TTLvalue);
                    disp(['MatRTSync - shared mem var - indicated premature stop. ' ' counter ' num2str(c) ' t=' num2str(GetSecs) ] );
                    abortLoop=1;
                end
                
            case 3
                %phase triggering - value sent by MatRTSync is a delay
                %TTLValStimOn = -1; %dont send any, done later after Flip
                TTLValStimOn = 91; %special marker so variance purely caused by the display can be measured
                if memFileHandle.Data(end) ~= lastVal
                    RTctrlValReceived = memFileHandle.Data(end);
                    lastVal=RTctrlValReceived;
                    
                    if RTctrlValReceived==0
                        continue;
                    end
                    
                    if sequencePresentationMode
                        if sequencePresentationState==0
                            % waiting for low-threshold trigger
                            if RTctrlValReceived == MARKER_SECONDARY_LOW_THRESHOLD && (GetSecs-tStart >minTimeToWait)
                                % Show the first image in the sequence
                                sequencePresentationState = 1;  % show the first, then wait for second
                                disp(['Sequence -- show first stimulus triggered']);
                                abortLoop=1;
                                processPhaseStim=0;
                            else
                                %ignore, continue wait for the first image in sequence
                                if ~infosPrinted(2)
                                    disp(['skip -- waiting for low threshold (sequence)']);
                                    infosPrinted(2)=1;
                                end
                                continue;
                            end
                        else
                            if sequencePresentationState==1
                                % see if too much time has elapsed,then abort wait for second,otherwise continue waiting
                                if (GetSecs-tStart)> maxWaitForSecondInSequence
                                    sequencePresentationState = -1;  % abort
                                    disp(['Time expired - abort wait for second']);
                                    abortLoop=1;
                                    processPhaseStim=0;
                                else
                                     if RTctrlValReceived ~= MARKER_SECONDARY_LOW_THRESHOLD
                                            %show the second image
                                            disp(['show second stimulus in sequence (threshold crossed)']);
                                            processPhaseStim = 1;
                                     else
                                         continue; %ignore this value
                                     end
                                end
                            end
                        end
                    else
                        %if not in sequencePresentationMode, run phase-conditional in any case
                        processPhaseStim = 1;
                    end %sequencePresentationMode
                    
                    if processPhaseStim  % execute phase-delay triggered stim
                        [lastVal,wasProcessed] = phaseStimServer_processNewDelayValue( RTctrlValReceived, newValRange, ...
                            sysDelayToUse, lptAddress, TTLvalue, TTLValStimOn );
                        if wasProcessed
                            abortLoop=1;
                            
                            %reset state if it was executed
                            sequencePresentationState = 0; % show the second, go back to wait for first
                        end
                    end
                end %end new value received
                
                
                
        end %end switch
        
        if abortLoop
            break;
        end
    end
end

%== internal funct
function stopped = checkKeysInt( keyStop1,keyStop2 )
stopped=0;
[keyIsDown, t, keyCode ] = KbCheck;
if keyCode(keyStop1) || keyCode(keyStop2)
    stopped=1;
end
while KbCheck;
end % make sure all keys are released