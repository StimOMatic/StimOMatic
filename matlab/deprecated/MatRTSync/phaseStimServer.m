%
% phase-specific stimulation server
% receives the triggers and executes them after the assigned delay
%

%%

defineSharedVarName;
% 'writeMode' must be true if python server is started up first.
writeMode=true;
createFile=0;
nrVals=100;

if ~exist('memFileHandle', 'file')
    memFileHandle = initMemSharedVariable( fVarStore, nrVals, createFile, writeMode );
end
lptAddress=888;   %sends a TTL to this port as soon as interrupt arrives

turtleTTLs; %import common TTL markers

% blocksize + sys transmission delays   (measured)
sysDelayToUse = 15 + 4;   %to cancel transmition/detection delays

%%
lptwrite(lptAddress,  TTLs.EXPERIMENT_ON);

lastVal = 0;
running =1;
nrTrials=0;
newValRange=[10 100];

TTLValSigReceived = 90;
TTLValStimOn = 1; %STIM_ON

try
    disp(['running....']);
    while (running)
        
        if memFileHandle.Data(end) ~= lastVal
            
            [lastVal,wasProcessed] = phaseStimServer_processNewDelayValue( memFileHandle.Data(end), newValRange, sysDelayToUse, lptAddress, TTLValSigReceived, TTLValStimOn );
            
            nrTrials=nrTrials+1;
            
            %ignore things that arrived in the course of this and a while after
            WaitSecs(2);
            lptwrite(lptAddress, 2); %STIM OFF

            lastVal = memFileHandle.Data(end);
        end
    end
    
catch exception
    lptwrite(lptAddress,  TTLs.EXPERIMENT_OFF);
    disp('experiment ended');
end

%%
lptwrite(lptAddress,  TTLs.EXPERIMENT_OFF);
