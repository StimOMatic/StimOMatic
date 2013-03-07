%
%
function MatRTSync_GUICallback( obj, event, timerCallNr, guihandles )

handles = guidata(guihandles); % get data from GUI

%poll TCP
try
    dataIn = jtcp('read',handles.jTcpObj,'timeout',2000 ); 

    if ~isempty(dataIn)
        %== write it into the shared store
        %append
        %nNewData = length(dataIn);

        %send event back to cheetah to archive
        
        
        if length(dataIn)>1
            nExistingData = length(handles.memFileHandle.Data);
            newData = [handles.memFileHandle.Data; dataIn];
            handles.memFileHandle.Data = newData(end-nExistingData+1:end) ;
        else
            disp(['1 byte only - optimize ' ' t=' num2str(GetSecs) ]);

            if handles.routerConnected==1
                %log only ON events
                %if dataIn(1)==1
                %    
                    lptwrite(888,60);
                %    NlxSendCommand(['-PostEvent "MatRTSync Server recv" 160 ' num2str(dataIn(1)) ]);
                %    WaitSecs(0.01);
                %    lptwrite(888,0);

                %end
            end

            
            handles.memFileHandle.Data(end) = dataIn ;
        end
        
        %disp('store is now');
        %handles.memFileHandle.Data

        disp(['received new data: ' num2str(dataIn) ]);
        addEntryToStatusListbox( handles.ListboxStatus, ['Data retrieved length: ' num2str(length(dataIn))  ],1,handles.maxStatusEntries);

        
        if dataIn==-1    %disconnect/close
        
              jtcp('close',handles.jTcpObj);
              addEntryToStatusListbox( handles.ListboxStatus, ['Closed Socket.'],1,handles.maxStatusEntries);

              %stop all timers
              runningTimers = timerfind;
              for j=1:length(runningTimers)
                 stop( runningTimers(j)  );
                 delete( runningTimers(j) );
              end
              
              tmp=handles.memFileHandle;
              clear tmp;
              handles.memFileHandle=0;
              
              addEntryToStatusListbox( handles.ListboxStatus, ['Stopped all timers.'],1,handles.maxStatusEntries);
            
        end
        
    end
catch err
    disp(['err retrieving TCP data']);
   
    rethrow(err);
end


