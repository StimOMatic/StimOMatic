%
%receive CSC stream
%
%urut/oct11
function [dataArray, timeStampArray, timeStampArrayConv, numValidSamplesArray,numRecordsReturned,samplingFreqArray,stepsize] = Netcom_pollCSC( CSCStream, verbose, Fs, dataArrayPreAlloc, dataArrayPtr )
timeStampArrayConv=[];
blocksize=512;
stepsize=1e6/Fs;

bufferSizeForNetcom=1000;

%dataArrayPreAlloc = nan(1,(blocksize * bufferSizeForNetcom) );  %faster



[succeeded,dataArray, timeStampArray, ~, samplingFreqArray, numValidSamplesArray, numRecordsReturned, ...
    numRecordsDropped ] = NlxGetNewCSCData_optimized(CSCStream,bufferSizeForNetcom, blocksize,dataArrayPtr);

if numRecordsReturned==0 && verbose
    disp([num2str(labindex) ' ' CSCStream ' success ' num2str(succeeded) ' received ' num2str(numRecordsReturned) ' dropped=' num2str(numRecordsDropped) ]);
end

if numRecordsReturned>0
    
    if verbose && ( numRecordsReturned || numRecordsDropped)
        
        disp([num2str(labindex) ' ' CSCStream ' success ' num2str(succeeded) ' received ' num2str(numRecordsReturned) ' dropped=' num2str(numRecordsDropped) ]);
    end
    
    if numRecordsDropped
        disp(['warning records dropped ' num2str(numRecordsDropped)]);
    end
    
    %process them
    if numRecordsReturned>0
        
        nTimes=length(timeStampArray)*blocksize;
        nData=length(dataArray);
        %disp(['length  ' num2str([ nTimes nData])]);
        
        if nData==nTimes & nData>blocksize
            [timeStampArrayConv] = interpolateTimestamps_optimized( double(timeStampArray),Fs );
        else if nData==blocksize
                
                %only 1 block
                T=double(timeStampArray(1));
                timeStampArrayConv = [T:stepsize:T+blocksize*stepsize]';
            else
                %problem
                disp(['length missmatch ' num2str([ nTimes nData])]);
            end
        end
    end
end

