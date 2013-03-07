%
% start/stop screaming from all requested channels
%
%urut/dec11
function [succeeded, allOK, allChs] = startStopStreaming( OSortData, mode  )
allChs='';
allOK=0;
succeeded = [];

for k=1:OSortData.nrActiveChannels
    channelStr = OSortData.CSCChannels{k}.channelStr;
    
    switch(mode)
        case 1
            succeeded(k) = NlxOpenStream( channelStr );
        case 2
            succeeded(k) = NlxCloseStream(channelStr);
        otherwise
            error('unknown mode');
    end
    
    allChs = [allChs channelStr ' '];
end

if sum(succeeded) == OSortData.nrActiveChannels
    allOK=1;
end