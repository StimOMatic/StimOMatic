%
%provide new as client for Mat2RTSync
%
%urut/MPI/jan12
function Mat2RTSync_sendData( jTcpObj, dataToSend )

jtcp('write',jTcpObj, dataToSend );