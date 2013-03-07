%
%setup PTB3
%
%urut/aug10
function [win,win2,w,h] = setupPTBWindow( screens )
win=[];
win2=[];

AssertOpenGL;

%screenid = max(Screen('Screens'));
screenid1=1;
screenid2=2;

win = Screen('OpenWindow', screenid1, 0);

[w, h]=WindowSize(win);

if screens >= 2
    win2 = Screen('OpenWindow', screenid2, 0);
    HideCursor;
end
