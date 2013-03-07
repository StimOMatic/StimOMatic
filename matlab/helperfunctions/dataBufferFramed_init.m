%
%initialize a data buffer that uses frames;
%this is a very fast way of implementing a rolling FIFO buffer of fixed size
%
%also see dataBufferFramed_retrieve, dataBufferFramed_addNewFrames
%
%
%urut/feb12/MPI
function [data,frameOrder] = dataBufferFramed_init(framesize,nrFrames)


data = zeros(framesize, nrFrames );
frameOrder = 1:nrFrames;