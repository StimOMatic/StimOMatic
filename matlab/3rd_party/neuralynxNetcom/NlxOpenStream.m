%NLXOPENSTREAM   Opens a data stream to a specified Cheetah object
%
%   	Function takes a string containing the name of the object whos
%	data you wish to stream.
%
%	NLXOPENSTREAM(CHEETAHOBJECTNAME,)
%
%	Once a data stream is opened, Cheetah will begin streaming data
%	for that stream.  You will then need to call the appropriate
%	NLXGETNEW<type>DATA function for the type of object whos stream was
%	opened to retrieve streaming data.  Data may be lost if the 
%	opened stream is not serviced regularly by calling one of the 
%	following commands:
%
%	NLXGETNEWCSCDATA(AENAME)
%	NLXGETNEWSEDATA(AENAME)
%	NLXGETNEWSTDATA(AENAME)
%	NLXGETNEWTTDATA(AENAME)
%	NLXGETNEWEVENTDATA(AENAME)
%	NLXGETNEWVTDATA(AENAME)
%
%
%   Example:  NlxOpenStream('SE1');
%	Opens a data stream for the single electrode named SE1.
%
%	Returns: 1 means the stream was successfully opened.
%			 0 means the stream was not opened.
%
%

function succeeded = NlxOpenStream(cheetahObjectName)  

    succeeded = libisloaded('MatlabNetComClient');

    if succeeded == 1
        disp(['==== connecting to ' char(cheetahObjectName) ]);
        succeeded = calllib('MatlabNetComClient', 'OpenStream', char(cheetahObjectName));
        if succeeded == 0
            error('Loading "MatlabNetComClient" works, but can not execute "OpenStream".');
        end        
    else
        disp 'Not Connected'
    end;
	
end
%% 
