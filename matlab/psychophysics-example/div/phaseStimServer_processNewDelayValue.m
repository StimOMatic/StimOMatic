%
% process a new delay value that was received via MatRTSync
% the purpose of this function is to send TTLs/display stimuli after a
% certain delay that is determined in realtime on the data. this can be
% used to trigger the display of stimuli at an exact time in the future
% (such as in 50ms).
%
%
% newValRange([lower upper]) : only considers newVal if it is within the
% permitted range
%
%urut/april12
function [lastVal,wasProcessed] = phaseStimServer_processNewDelayValue( newVal, newValRange, sysDelayToUse, lptAddress, TTLValSigReceived, TTLValStimOn )
wasProcessed=0;

%if we like this new value,execute it
if newVal >= newValRange(1) && newVal <= newValRange(2)

    timeToWait = double(newVal)-sysDelayToUse;
    
    if timeToWait>0   % ignore if too small
        %wait so many ms and then send TTL
        lptwrite(lptAddress, TTLValSigReceived);   % TTL for received
        
        
        t1=tic;
        WaitSecs( timeToWait/1000);
        if TTLValStimOn>-1  %only send if enabled; is done later when used in combination with 'Flip' argument of Screen
            lptwrite(lptAddress, TTLValStimOn); %TTL for stim done
        end
        
        t = toc(t1);
        
        %do work first, then display things
        disp(['MatRTSync - shared mem var - wait cmd received. wait for: ' num2str(newVal) ' sys delays: ' num2str(sysDelayToUse) ' wait duration was:' num2str(t*1000) 'ms' ' timeToWait=' num2str(timeToWait) ] );
        wasProcessed = 1;
    else
        disp(['Time too small - ignore. timeToWait= ' num2str(timeToWait) ]);
    end
end

lastVal = newVal;