%
% request meta data for all subscribed channels
%
% channelList: cell array of strings, to be subscribed channels
%
function StimOMaticData = requestMetaDataForSelChannels( channelList, StimOMaticConstants )

%for each channel 
nrActiveChannels = length(channelList);
StimOMaticData.nrActiveChannels = nrActiveChannels;

for k=1:nrActiveChannels
    CSCSel = channelList{k};
    
    CSCChannelInfo = Netcom_initCSCChannel( CSCSel );

    StimOMaticData.CSCChannels{k} = CSCChannelInfo;
%    StimOMaticData.CSCBuffers{k} = zeros(1, StimOMaticConstants.bufferSizeCSC);
%    StimOMaticData.CSCTimestampBuffer = zeros(1, StimOMaticConstants.bufferSizeCSC);
end

