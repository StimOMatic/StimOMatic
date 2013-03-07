%check if e or s was pressed to interrupt prog
%
%either just check for keypress or wait specific time while continuously
%checking
%
%urut/aug10
function stopped = checkIfStopped( waitForSecs )
if nargin<1
    waitForSecs=0;
end

stopped=0;
keyStop1 = KbName('s');
keyStop2 = KbName('e');

if waitForSecs == 0
    stopped = checkKeysInt( keyStop1,keyStop2 );
else
    waitUnit=0.05;  %50ms
    
    nrBlocks=waitForSecs/waitUnit;
    
    for k=1:nrBlocks
       WaitSecs( waitUnit );
       stopped = checkKeysInt( keyStop1,keyStop2 );
        
       if stopped
           disp(['wait of ' num2str(waitForSecs) ' aborted early']);
           break;
       end
    end    
end

%==internal funct
function stopped = checkKeysInt( keyStop1,keyStop2 )
stopped=0;
[keyIsDown, t, keyCode ] = KbCheck;
    if keyCode(keyStop1) || keyCode(keyStop2)
        stopped=1;
    end
    
    while KbCheck;
    end % make sure all keys are released
    