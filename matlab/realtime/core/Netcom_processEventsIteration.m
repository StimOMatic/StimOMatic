function [storedEvents,updateAv,tOff] = Netcom_processEventsIteration(TTLStream, verbose, storedEvents, updateAv, tOff, eventStringArrayPtr)
verbose=1;
[eventsReceived,nrReceived] = Netcom_pollEvents( TTLStream, verbose, eventStringArrayPtr );

if nrReceived>0
    tOff=[];
    ind=find( eventsReceived(:,2)==1 | eventsReceived(:,2)==2) ;   %stim ON/OFF events
    if ~isempty( ind )
        
        disp( [ 'Stim on/off detected at ' num2str(eventsReceived(ind(1),1)) ] );
        storedEvents = [ storedEvents; eventsReceived(ind,:)];
        newOffsetInd = find( eventsReceived(:,2)==2 );
        
        if ~isempty(newOffsetInd)
            disp( [ 'Stim offset detected, update the average ' ] );
            newOffsetInd = newOffsetInd(end); %only consider one trial
            
            %get the last X samples before this
            tOff = eventsReceived(newOffsetInd,1);
            updateAv=1;
        end
    end
end
