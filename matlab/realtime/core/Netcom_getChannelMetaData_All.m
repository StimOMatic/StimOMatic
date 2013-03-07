%
%prep a string of channel metadata for later display
%
%urut/nov11
function [metaStr, ADBits] = Netcom_getChannelMetaData_All(ChannelStr, reqModes)

ADBits = Netcom_getChannelMetaData( ChannelStr, 1 );

range = Netcom_getChannelMetaData( ChannelStr, 2 );
fs = Netcom_getChannelMetaData( ChannelStr, 3 );

flow = Netcom_getChannelMetaData( ChannelStr, 5 );
fhigh = Netcom_getChannelMetaData( ChannelStr, 4 );

lowOn = Netcom_getChannelMetaData( ChannelStr, 7 );
highOn = Netcom_getChannelMetaData( ChannelStr, 6 );

metaStr = ['R:' num2str(range) 'uV; Fs=' num2str(fs) 'Hz; Low-High:' num2str(flow) '-' num2str(fhigh) ' filtOn:' num2str(lowOn) '/' num2str(highOn) ];