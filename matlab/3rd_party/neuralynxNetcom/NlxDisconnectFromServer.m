%NLXDISCONNECTFROMSERVER   Disconnects from the current NetCom server
%						if currently connected.
%   Closes all open streams and disconnects from the current NetCom
%	server.
%
%   NLXDISCONNECTFROMSERVER() disconnects from the server
%
%   Example:  NlxDisconnectFromServer;
%
%	Returns: 1 means a successful disconnection.
%			 0 means the disconnection failed
%

function succeeded = NlxDisconnectFromServer()  
	
    succeeded = libisloaded('MatlabNetComClient');

    if succeeded == 1
        succeeded = calllib('MatlabNetComClient', 'DisconnectFromServer');
    else
        disp('Not Connected.');
        return;
    end;

    if succeeded == 1
        unloadlibrary('MatlabNetComClient');
    end;

    if libisloaded('MatlabNetComClient')
        succeeded = 0;
    end
    
end
%% EOF