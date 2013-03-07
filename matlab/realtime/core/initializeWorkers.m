function initializeWorkers( nrWorkers )

if matlabpool('size') ~= nrWorkers
    
    disp(['Nr active workers is not equal requested nr workers - shutdown all and re-start. req:' num2str(nrWorkers) ' current size ' num2str(matlabpool('size')) ]);
    
    if matlabpool('size')>0
        matlabpool close
    end
    matlabpool(nrWorkers)
end
