%
% adds an additional delay with WaitSecs that depends on the current beamposition, as returned by Screen('GetWindowInfo',...)
%
% this is used to reduce the variance in the delay till the screen changes.
%
%urut/april12
function delayToAdd = beamposDelayCorrection( beampos, targetTime, b )
useDefaultMode=0;
if nargin<3
    useDefaultModel=1;
else
    if isempty(b)
        useDefaultModel=1;
    end        
end
if useDefaultModel
    %regression model, measure empirically with plotBeampos_flipTime.m
    b = [0.0167977649984874; -7.57222590097542e-006];
end

%manual corrections for out of range/otherwise strange beampositions
maxPos=1080;  % equivalent to wininfo.VBLStartline
lowerLim=200;  %very small vals are also fast (not sure why, empirical)
if beampos>maxPos
    beampos=maxPos;
end
if beampos<lowerLim
    beampos=beampos+maxPos;
end

predictedDelay = [1 beampos]*b;
delayToAdd = targetTime - predictedDelay;
if delayToAdd<0
    delayToAdd=0;
end
if delayToAdd>0  %cant add negative delay
    disp(['waiting dealyToAdd=: ' num2str(delayToAdd) ]); 
    WaitSecs( delayToAdd );
end

    