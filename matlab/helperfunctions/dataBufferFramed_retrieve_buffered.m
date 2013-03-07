%
% retrieves the newest nrFramesToRetrieve from the buffer, and keeps buffer
% structure.
%
function [dataBuffered] = dataBufferFramed_retrieve_buffered(data, frameOrder, nrFramesToRetrieve)

    dataBuffered = data(:, frameOrder(end-nrFramesToRetrieve+1:end));

end