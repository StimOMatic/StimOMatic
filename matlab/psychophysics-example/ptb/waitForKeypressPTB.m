%
%PTB3 helper function
%wait for a keypress, empty buffer before returning
%
%urut/aug10
function [keyCode] = waitForKeypressPTB()

KbWait;
[keyIsDown, t, keyCode ] = KbCheck;
while KbCheck; end % make sure all keys are released
