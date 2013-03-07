function succeeded = Netcom_disconnectConn()

    try
        succeeded = NlxDisconnectFromServer();
    catch me
        warning(me.message);
        succeeded = 0;
    end
    
end
%% EOF