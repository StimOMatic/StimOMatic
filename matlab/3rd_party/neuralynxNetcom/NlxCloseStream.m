%NLXCLOSESTREAM   Closes a data stream to a specified Cheetah object
%
%   Function takes a string containing the name of the object whos
%	data stream you wish to close,.
%
%	NLXCLOSETREAM(CHEETAHOBJECTNAME,)
%
%	Once a data stream is closed, Cheetah will no longer stream data
%	for the specified object.  All calls to the GETNEW<type>DATA 
%	functions will fail.
%
%   Example:  NlxCloseStream('SE1');
%	Closes a data stream for the single electrode named SE1.
%
%	Returns: 1 means the stream was successfully opened.
%			 0 means the stream was not opened.
%
%

function succeeded = NlxCloseStream(cheetahObjectName)  

	succeeded = libisloaded('MatlabNetComClient');
	
	if succeeded == 1
		succeeded = calllib('MatlabNetComClient', 'CloseStream', char(cheetahObjectName));
	else
		disp 'Not Connected'
    end;
	
end