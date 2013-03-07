%
% request meta data for all subscribed channels
%
% channelList: cell array of strings, to be subscribed channels
%
function OSortData = requestMetaDataForSelChannels( channelList, OSortConstants )

%for each channel 
nrActiveChannels = length(channelList);
OSortData.nrActiveChannels = nrActiveChannels;

for k=1:nrActiveChannels
    CSCSel = channelList{k};
    
    CSCChannelInfo = Netcom_initCSCChannel( CSCSel );

    OSortData.CSCChannels{k} = CSCChannelInfo;
%    OSortData.CSCBuffers{k} = zeros(1, OSortConstants.bufferSizeCSC);
%    OSortData.CSCTimestampBuffer = zeros(1, OSortConstants.bufferSizeCSC);
end

