function [cheetahObjects, cheetahTypes, succeeded] = initializeNetcomclient( serverName, appName )

    cheetahObjects=[];
    cheetahTypes=[];

    fprintf('Connecting to %s...\n', serverName);

    % 'NlxConnectToServer' might not be in path
    try
        succeeded = NlxConnectToServer(serverName);
    catch me
        warning(me.message);
        succeeded = 0;
    end

    if succeeded ~= 1
        warning('FAILED "connect to %s". Exiting script. Is Router connected to Cheetah?', serverName);
        return;
    else
        fprintf('Connected to %s.\n', serverName);
    end

    %Identify this program to the server we're connected to.
    succeeded = NlxSetApplicationName( appName );
    if succeeded ~= 1
        warning('FAILED "set the application name".');
        return;
    else
        disp('PASSED "set the application name".');
    end

    %get a list of all objects in Cheetah, along with their types.
    [succeeded, cheetahObjects, cheetahTypes] = NlxGetCheetahObjectsAndTypes;
    if succeeded == 0
        warning('FAILED "get cheetah objects and types".');
        return;
    else
        disp('PASSED "get cheetah objects and types".');
    end

end
%% EOF
