%NLXSENDCOMMAND   Sends a command to Cheetah
%
%   [SUCCEEDED, CHEETAHREPLY] = NLXSENDCOMMAND(COMMANDSTRING) 
%
%   Example:  [succeeded, cheetahReply] = NlxSendCommand('-StartAcquisition');
%	
%
%	succeeded:	1 means the operation completed successfully
%				0 means the operation failed
%
%	cheetahReply: This cell string will be filled with the reply from Cheetah.
%				  You will need to convert this reply to the appropriate numeric
%				  type for the data you requested before using the reply value in
%				  Matlab.
%


function [succeeded, cheetahReply] = NlxSendCommand(commandString)  

	MAX_REPLY_LENGTH = 1000; %number of chars to allocate for a reply
	STRING_PLACEHOLDER = blanks(MAX_REPLY_LENGTH);  %ensures enough space is allocated for the return value
	
	cheetahReply = 0;
	succeeded = libisloaded('MatlabNetComClient');
	if succeeded == 0
		disp 'Not Connected'
		return;
	end
	
	cheetahReplyPointer = libpointer('stringPtrPtr', {STRING_PLACEHOLDER});
	if succeeded == 1
		[succeeded, commandString, cheetahReply, replyLength] = calllib('MatlabNetComClient', 'SendCommand', commandString, cheetahReplyPointer, MAX_REPLY_LENGTH);
    end;
        
end