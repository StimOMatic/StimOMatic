%
% 
%
%get numeric values for header values for a CSC channel
%
%urut/nov11
function retNumVal = Netcom_getChannelMetaData( ChannelStr, reqMode )
retNumVal=-1;

switch(reqMode)
    case 1
        cmdStr = [' -GetADBitVolts ' ChannelStr];
    case 2
        cmdStr = [' -GetInputRange ' ChannelStr];
    case 3
        cmdStr = [' -GetSampleFrequency ' ChannelStr];
    case 4
        cmdStr = [' -GetDspHighCutFrequency ' ChannelStr];
    case 5
        cmdStr = [' -GetDspLowCutFrequency ' ChannelStr];
    case 6
        cmdStr = [' -GetDspHighCutFilterEnabled ' ChannelStr];
    case 7
        cmdStr = [' -GetDspLowCutFilterEnabled ' ChannelStr];
        
    case 8
        cmdStr = [' -GetSpikeThreshold ' ChannelStr];
        
     case 9
        cmdStr = [' -GetChannelNumber ' ChannelStr];
       
        
        
         
    otherwise
        error('unknown reqMode');
        
end
        [succeeded, cheetahReply] = NlxSendCommand( cmdStr );

        if succeeded
            retNumVal = str2double(cheetahReply{1});
            
            if isnan(retNumVal)
                %check if true/false
                if strfind( cheetahReply{1}, 'True')
                    retNumVal=1;
                else
                    if strfind(cheetahReply{1}, 'False')
                        retNumVal=0;
                    end
                end
            end
        end

%GetDspHighCutFrequency 
%GetDspLowCutFrequency 
%GetInputRange 
%GetSampleFrequency 
%GetDspLowCutFilterEnabled 
%GetDspHighCutFilterEnabled 



%[succeeded, cheetahReply] = NlxSendCommand( '-GetDspLowCutFilterEnabled SE13' )