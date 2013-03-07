%
%receive events in realtime
%
%urut/oct11
function [eventsReceived,numRecordsReturned] = Netcom_pollEvents( TTLStream, verbose, eventStringArrayPtr )

eventsReceived=[];
[succeeded, timeStampArray, eventIDArray, ttlValueArray, eventStringArray, numRecordsReturned, numRecordsDropped ] = NlxGetNewEventData_optimized( TTLStream,eventStringArrayPtr );

% disp([TTLStream ' success ' num2str(succeeded) ' received ' num2str(numRecordsReturned) ' dropped=' num2str(numRecordsDropped) ]);


if numRecordsReturned>0
    
    if verbose
        disp([TTLStream ' success ' num2str(succeeded) ' received ' num2str(numRecordsReturned) ' dropped=' num2str(numRecordsDropped) ]);
    end
    
    %process them
    for j=1:length( ttlValueArray )
        eventsReceived(j,:) = [int64(timeStampArray(j)) int64(ttlValueArray(j))];
    end
end