function  updateFeedbackChannelPopup( channelList, popopH )
activeChanList = get( channelList, 'String' );
set(popopH,  'String', {'none', activeChanList{:} } );
set(popopH,  'Value', 1);
