function CSCChannelInfo = Netcom_initCSCChannel( CSCSel )

[metaStr, ADBits] = Netcom_getChannelMetaData_All(CSCSel );

CSCChannelInfo.channelStr = CSCSel;
CSCChannelInfo.channelInt = str2num( CSCSel(4:end) );
CSCChannelInfo.metaStr = metaStr;
CSCChannelInfo.ADBits = ADBits;
