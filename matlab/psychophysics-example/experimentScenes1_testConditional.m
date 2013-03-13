%
% experimentScenes1_testConditional
%
% conditional visual stimulation, controlled by the closed-loop triggering system that sends control messages over a shared variable
% and the RTMatSync server-client system.
%
%urut/MPI/2012

%%

% adjust these paths accordingly
basepathImgs = 'C:\Users\rutishauseru\Documents\GitHub\StimOMatic\matlab\psychophysics-example\stimuli\';
basepathLogs='c:\logs\';

stimOnTime = 2;
blankTime  = 15;   % + 0.5 on av uniform random
blankTimeRandMultiplier = 4;   % +- so many secs randomization
colorToBlank = [127 127 127];

colorToFlash = [255 255 255];  % which color to flash
screens = 1;  %can use both screens (background) and only update one at the same time
turtleTTLs; %import common TTL markers

RTCtrlMode = 3;  %1 events, 2 shared variable immediate (power onset), 3 shared variable delay (phase stim)

sequencePresentationMode  = 1;  %1 enabled, 0 disabled.  if enabled, a first and second stimulus are shown in sequence; 
sequencePresentationState = 0;

% system delay built in
%sysDelayToUse = 15 + 4;       % for TTL phase stim  
sysDelayToUse = 15 + 3 + 11.8 ;       % for visual stim 20Hz

beamposDelayEnabled = 0;   %to put in additional waits to reduce variance
targetTime = 0.015;  % tradeoff between variance and delay. best would 2*ifi

if beamposDelayEnabled
    sysDelayToUse = 15 + 4 + (15-5);    % for visual phase stim .   second 15==target time,minus some for internal processing time.    
    bRegressModel=[];
end

%minTimeToWait = 0; %as fast as possible
minTimeToWait = 8;  % min time in secs between trials that is enforced (trigger signals before are ignored)
screensToUpdate = [1]; %1 is left side of turtle, 2 right side

%probabilityRandomizeStimPres = 1;  %always show

probabilityRandomizeStimPres = 0.5;   %For RtCtrlMode=2&3. if <1, the probability that a stimulus is shown when one is triggered is randomized with this probability. for control purposes. a different ON TTL is sent to mark them.
% 65percent of all should be shown, 35% are controls
%probabilityRandomizeStimPres = 0.65;   %For RtCtrlMode=2&3. if <1, the probability that a stimulus is shown when one is triggered is randomized with this probability. for control purposes. a different ON TTL is sent to mark them.

lowThreshFraction = 0.3; %Only used for RtCtrlMode=2. Only for secondary low threshold. max fraction of total trials that are allowed to be low-thresh triggered.
maxWaitForSecondInSequence = 1.0;  % if sequence mode, how long to wait max (secs) till the second image is triggered; if not,trial is aborted.

nrShown = [0 0 0 0]; % how many trials were shown so far. order: Stim-normal, Stim-Empty, Stim-lowTriggeredSecondary, Stim-Sequence-Second
pickRandomImgSecondary = 1;   % if sequence mode, randomize the second image yes/no
pickRandomImgPrimary   = 1;   % if sequence mode, randomize the first image yes/no. 

%% init MatRTSync
defineSharedVarName;
% 'writeMode' must be true if python server is started up first.
writeMode=true;
createFile=0;
nrVals=100;

if ~exist('memFileHandle', 'file')
    memFileHandle = initMemSharedVariable( fVarStore, nrVals, createFile, writeMode );
end
  
if RTCtrlMode==1
    hostnameRouter='141.5.4.159';
    succeeded = NlxConnectToServer(hostnameRouter);
    NlxSetApplicationName( ['PsychPhys Exp Client Direct'] );
    succeededEvents = NlxOpenStream( 'Events' );
    if ~succeededEvents
        warning('could not subscribe to events,realtime will not work');
    else
        disp('successfully subscribed to events stream');
    end
end

%%
[win,win2,w,h] = setupPTBWindow( screens );
Screen('Preference', 'VBLTimestampingMode', 1)

stimcenter = [w/2 h/2];
if screens==2
    screensToUse = [win win2];   % both screens
else
    screensToUse = [win];   %only one scrsseen
end 
%initialize the log file
[fidLog, fnameLog] = openLogfile(basepathLogs, 'ScenesTestConditional');

disp(['Logfile used:' fnameLog]);
%save( [ fnameLog '.mat'], 'expStimsUseAll', 'fNamesScenes', 'colorToBlank','screensToUpdate'  );  %save whisch stims were used.

disp(['Press any key to start...']);
[keyCode] = waitForKeypressPTB(); 
disp(['Starting now!']);

%paramStr = [ num2str(stimOnTime) ';' num2str(blankTime) ';' num2str(blankTimeBetweenBlocks) ';' num2str(blockSize) ';' basepathImgs ';' basepathImgs2 ';' num2str(stimsetToUse) ';' stimsetFile ';' num2str(colorToBlank) ];

paramStr=['experimentScenes1_testConditional ' num2str(minTimeToWait) ' ' num2str(probabilityRandomizeStimPres) ' ' num2str(colorToBlank) ' ' num2str(screensToUpdate) num2str(maxWaitForSecondInSequence) ',' num2str(lowThreshFraction) ',' num2str(sequencePresentationMode) ',' num2str(sysDelayToUse) ',' num2str(pickRandomImgSecondary) ',' num2str(pickRandomImgPrimary)  ];
sendTTLwithLog( fidLog, 0, paramStr ); % write the parameters to the log file.
sendTTLwithLog( fidLog, TTLs.EXPERIMENT_ON   );   %exp ON

stimwidth=[500 500];
srect = [stimcenter(1)-stimwidth(1) stimcenter(2)-stimwidth(2) stimcenter(1)+stimwidth(1) stimcenter(2)+stimwidth(2)];

pathImgs=basepathImgs;
imgName1='51.jpg';
imgName2='52.jpg';

imgSequence1 = imread([pathImgs imgName1]);
imgSequence2 = imread([pathImgs imgName2]);

possibleFiles= dir([pathImgs '*.jpg']);
filenamesSecondary=[];
cc=0;
for jj=1:length(possibleFiles)
    fName = possibleFiles(jj).name;
    if ~strcmp(fName,imgName1) && ~strcmp(fName,imgName2)
        cc=cc+1;
        filenamesSecondary{cc} = [ pathImgs fName ];
    end
end

imgOrig =  imread( [pathImgs imgName2]  );  

displayImage=1;
delayToUse = 10000;     %only automatically triggered stim onsets
%delayToUse = 2;     %only automatically triggered stim onsets
timingHist = [];

%
try
    running=1;
    k=0;
    while running
        k=k+1;
        
        %==== blank screens to remove previous stimulus
        if sequencePresentationMode & sequencePresentationState
            %no blanking in this case
        else
            blankScreens( screensToUse, colorToBlank );
            for jj=1:length(screensToUpdate)
                Screen(screensToUse(screensToUpdate(jj)),'FillRect',colorToBlank); %,[w/2-fixs h/2-fixs w/2+fixs h/2+fixs])
                Screen('Flip', screensToUse(screensToUpdate(jj)), 0 );
            end
        end
        
        sendTTLwithLog( fidLog, TTLs.DELAY1_ON );
        disp(['wait time: ' num2str(delayToUse) ]);
        
        %==== prepare the next stimulus to be shown (flash or image)
        for j=1:length(screensToUpdate)
            if ~displayImage
                Screen( screensToUse(screensToUpdate(j)),'FillRect',colorToFlash,srect)
            else
                posImg=[0 0 1920 1080]; % scale to this size (automatic scaling)
                imgToUse = experimentScenes1_prepareImgs( imgSequence1, imgSequence2, imgOrig, sequencePresentationMode, sequencePresentationState, pickRandomImgSecondary, pickRandomImgPrimary, filenamesSecondary);
                Screen('PutImage', screensToUse(screensToUpdate(j)), imgToUse, posImg ); % pre-load the image into buffer
            end
        end

        %==== Wait till next stimulus should be shown
        % Wait for certain time, receive closed-loop signals to abort wait when appropriate
        [manualStop,RTctrlValReceived,isSecondaryThreshold,sequencePresentationState] = checkIfStopped_conditional( delayToUse, memFileHandle, RTCtrlMode, minTimeToWait,sysDelayToUse, nrShown, lowThreshFraction, sequencePresentationMode, sequencePresentationState, maxWaitForSecondInSequence );    
        if manualStop
            sendTTLwithLog( fidLog, TTLs.EXPERIMENT_OFF_ABORTED_MANUAL );
            break;
        end
        
        %==== get timestamp/VBL info for debugging / displaying timestamps
        %ifi = Screen('GetFlipInterval', screensToUse(screensToUpdate(j)));
        %wininfo = Screen('GetWindowInfo', screensToUse(screensToUpdate(j)), 0);
        %lastvbl = wininfo.LastVBLTime;
        %wininfo.VBLStartline
        %wininfo.VBLEndline
        %beampos = wininfo.BeamPosition;
        %lastvbl=0;
        %ifi
        %currTime = GetSecs();
        %disp(['last VBL is: ' num2str(lastvbl) ' ' num2str(currTime-lastvbl) ' ifi=' num2str(ifi) ' beampos=' num2str(beampos) ]);
        %tic
        %sendTTLwithLog( fidLog, TTLs.DELAY1_OFF );
        %toc
        
        %==== Decide if stimulus should be shown or skipped
        showStim = 1; %yes/no

        sequencePresentation_wasSkipped = 0;
        
        if probabilityRandomizeStimPres<1 
            if ~(RTCtrlMode==2 && isSecondaryThreshold ) % if RTMode=2 (power) and value received=2 (control conditions for low power), always show (not probabilistic)
                if rand>=probabilityRandomizeStimPres
                    
                    if sequencePresentationMode 
                        %can only skip for secondaries
                        if sequencePresentationState==0
                            showStim=0;
                            nrShown(2) = nrShown(2) + 1;  % empty trials
                           sequencePresentation_wasSkipped = 1;
                        else
                            showStim=1; %dont skip if this is the primary stimulus and we are in sequence mode
                        end
                    else
                        showStim=0;
                        nrShown(2) = nrShown(2) + 1;  % empty trials
                    end
                end
            end
        end
        
        if sequencePresentationMode && sequencePresentationState==-1   %abort the sequence, go back to beginning
            disp(['abort sequence, no stimulus show']);
            sequencePresentationState=0;
            showStim=0;
        end
        
        %==== Show the stimulus
        if showStim
            for j=1:length(screensToUpdate)
                %use the when argument (absolute time)
                %when = lastvbl + ifi*5;
                %when = GetSecs()+ 30e-3;   %want in exactly so many ms
                %[VBLTimestamp StimulusOnsetTime FlipTimestamp Missed Beampos] = Screen('Flip', screensToUse(screensToUpdate(j)), when, 0, 0, 0 );

                dontsync=0; %default, wait for stim onset to show
                %dontsync=2;
                beampos = Screen('GetWindowInfo', screensToUse(screensToUpdate(j)), 1);

                % beampos delay correction
                if beamposDelayEnabled
                    delayToAdd = beamposDelayCorrection( beampos, targetTime, bRegressModel );
                else
                    delayToAdd = 0;
                end
                tOn=tic;

                % Show the stimulus
                [VBLTimestamp StimulusOnsetTime FlipTimestamp Missed BeamposFlip] = Screen('Flip', screensToUse(screensToUpdate(j)), 0, 0, dontsync, 0 );
                %FlipTimestamp-VBLTimestamp 
            end
            timeTaken = toc(tOn);
            
            TTLToSend = [];
            if isSecondaryThreshold   % power detect onset mode, value 2 means negative threshold used; use a special stim-onset marker to indicate this
                TTLToSend = TTLs.STIMULUS_ON_SECONDARY;
                disp(['Trial type: show normal (low power triggered secondary threshold) ']);
                nrShown(3) = nrShown(3) + 1;  % normal trial                
            else
                if sequencePresentationMode 
                    if sequencePresentationState
                        TTLToSend = TTLs.STIMULUS_ON_SEQUENCE_FIRST;  %
                        nrShown(4) = nrShown(4) + 1;  % normal trial                
                        disp(['Trial type: show normal (sequence-first) tot#:' num2str(nrShown(4))]);
                    else
                        TTLToSend = TTLs.STIMULUS_ON_SEQUENCE_SECOND_SHOWN;  %
                        disp(['Trial type: show normal (sequence-second) tot#:' num2str(nrShown(1))]);
                        nrShown(1) = nrShown(1) + 1;  % normal trial                                        
                    end
                    
                else
                    TTLToSend = TTLs.STIMULUS_ON;  %
                    disp('Trial type: show normal ');
                    nrShown(1) = nrShown(1) + 1;  % normal trial                
                end
            end           
            sendTTLwithLog( fidLog, TTLToSend );
            disp(['time for flip: ' num2str(timeTaken) ' beampos was: ' num2str(beampos) ' beampos at flip ' num2str(BeamposFlip) ' missed ' num2str(Missed) ' delayAdded: ' num2str(delayToAdd) ' TTL sent:' num2str(TTLToSend) ]);
            timingHist(k,:)=[ timeTaken beampos BeamposFlip VBLTimestamp FlipTimestamp Missed];            
        else
            if sequencePresentation_wasSkipped
                %show nothing,this is a control
                sendTTLwithLog( fidLog, TTLs.STIMULUS_ON_SEQUENCE_SECOND_SKIPPED );
                disp(['Trial type: no trial (randomized - sequence secondary skipped) tot# ' num2str(nrShown(2)) ]);                
            else
                if sequencePresentationMode
                    sendTTLwithLog( fidLog, TTLs.FIXCROSS_ON );
                    disp('Trial type: secondary aborted');
                else
                    %show nothing,this is a control
                    sendTTLwithLog( fidLog, TTLs.FIXCROSS_ON );
                    disp('Trial type: no trial (randomized)');
                end
            end
        end
        disp(['trial nr ' num2str(k)  ]);
        
        %==== Wait as long as stimulus should remain on the screen
        if sequencePresentationMode & sequencePresentationState & showStim
            % no wait if sequence presentation mode is on and we just showed the first stimulus (second to follow)
        else
            if checkIfStopped( stimOnTime )    %WaitSecs with waiting for keypress
                sendTTLwithLog( fidLog, TTLs.EXPERIMENT_OFF_ABORTED_MANUAL );
                break;
            end
        end
        sendTTLwithLog( fidLog, TTLs.STIMULUS_OFF );
                
    end
    %[keyCode] = waitForKeypressPTB();
    Screen('CloseAll');
    sendTTLwithLog( fidLog, TTLs.EXPERIMENT_OFF   );   %exp ON
catch exception
    disp('MATLAB ERROR - abort and close screens');
    Screen('CloseAll');
    disp(exception.stack(1));
    error(exception.message);
    
    sendTTLwithLog( fidLog, TTLs.EXPERIMENT_OFF_ERROR   );   %exp ON
    sendTTLwithLog( fidLog, TTLs.EXPERIMENT_OFF   );   %exp ON
    disp(['tot nr trials: ' num2str(k) ' nr shown' num2str(nrShown) ' log ' fnameLog]);
end

disp(['tot nr trials: ' num2str(k) ' nr shown' num2str(nrShown) ' log ' fnameLog]);

%clear memFileHandle   %close the shared file to communicate with MatRTSync
if RTCtrlMode==1
    NlxDisconnectFromServer;
end

