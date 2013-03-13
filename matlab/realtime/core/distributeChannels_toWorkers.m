% decides which channel is processed on which worker
%
%urut/feb12
function [workerChannelMapping, nrWorkers] = distributeChannels_toWorkers( nrWorkersToUseMax, nrActiveChannels, StimOMaticData )

% if there are fewer or equal nr workers than channels - 1:1 mapping
if nrActiveChannels <= nrWorkersToUseMax
    nrWorkers = nrActiveChannels;
    
    for j=1:nrWorkers
        channelIDReal = str2num(StimOMaticData.CSCChannels{j}.channelStr(4:end));        
        workerChannelMapping(j,:) = [ j 1 j channelIDReal];
    end
end

% if there are more channels than workers - distribute
if nrActiveChannels > nrWorkersToUseMax
   
    nrWorkers = nrWorkersToUseMax;
    
    %distribute
   nrChannelsPerWorker = ceil ( nrActiveChannels/nrWorkersToUseMax );
   
   workerChannelMapping=[];  % workerID channelIDLocal channelIDGlobal channelIDReal
   for channelID = 1:nrActiveChannels 
       channelIDReal = str2num(StimOMaticData.CSCChannels{channelID}.channelStr(4:end));
       
       workerID = 1 + fix( (channelID-1)/nrChannelsPerWorker);       
       channelIDLocal = 1+mod(channelID-1,nrChannelsPerWorker);
       workerChannelMapping(channelID,:) = [ workerID channelIDLocal channelID channelIDReal  ];
   end
   
   %how many workers were actually used?
   
   nrWorkers = workerID;
end