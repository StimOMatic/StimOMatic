%
%
% get a list of channel IDs (global) that are assigned to worker workerID
%
%urut/feb12
function [channelsOnWorker, nrChannelsOnWorker, inds] = distributeChannels_getChannelsForWorker( workerChannelMapping, workerID )

inds=find( workerChannelMapping(:,1)==workerID );
channelsOnWorker = workerChannelMapping( inds, 3);

nrChannelsOnWorker = length(channelsOnWorker);

