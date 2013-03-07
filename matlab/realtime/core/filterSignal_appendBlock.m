%
% append a new block of raw data to a stream of filtered data. filter the new block and add it, 
% resolving edge effects
%
%rawData is the raw data buffer of fixed length (FIFO)
%filteredData is the filtered data buffer of fixed length (FIFO)
%newDataOrig are new datapoints (raw) that arrived and should be appended
%nrOverlap is nr of datapoints (in frames) overlap to be used
%
%this function is written for optimal speed,not readability
%
% filteredData in/out is buffered, i.e. it is a structure with fields data and frameOrder.
% rawData is buffered also
% nrOverlap is in nr frames
%
%urut/jan12/MPI
function filteredData = filterSignal_appendBlock( hd, rawData, filteredData, newDataOrig, nrOverlap, framesize )


dataForOverlap = dataBufferFramed_retrieve(rawData.data, rawData.frameOrder, framesize, nrOverlap/framesize);

newDataFiltered = filtfilt(hd{1}, hd{2}, [ dataForOverlap' newDataOrig] );
    
% Could use the function called below, but for efficiency reasons implement direct (below)    
%[filteredData.data,filteredData.frameOrder] = dataBufferFramed_addNewFrames( filteredData.data, filteredData.frameOrder, ...
%    newDataFiltered((nrOverlap/2)+1:end), framesize);

%filteredData.frameOrder
newDataFramed = buffer( newDataFiltered((nrOverlap/2)+1:end), framesize);
nrNewFrames=size(newDataFramed,2);

filteredData.data(:, filteredData.frameOrder(1:nrNewFrames) ) = newDataFramed;
filteredData.frameOrder =  [ filteredData.frameOrder(nrNewFrames+1:end) filteredData.frameOrder(1:nrNewFrames) ];

   