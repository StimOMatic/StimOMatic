%
%retrieves the newest nrFramesToRetrieve from the buffer
%
function [dataFlat] = dataBufferFramed_retrieve(data, frameOrder, framesize, nrFramesToRetrieve, nrDatapointsToReceive)

dataFlat = data(:, frameOrder(end-nrFramesToRetrieve+1:end));
dataFlat = dataFlat(:);

if nargin==5
    dataFlat = dataFlat(end-nrDatapointsToReceive+1:end);
end
