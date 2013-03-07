%
%tcpClientMat
%
%MEX file to send commands via TCP to the MatRTSync server
%
%Ueli Rutishauser/Andreas Kotowicz, MPI 2012
%
%compile with
%mex tcpClientMat.c wsock32.lib
%
%before, add to mexopts.bat "C:\Program Files (x86)\Microsoft SDKs\Windows\v7.0A\Include" to INCLUDE
%needs Visual Studio 8 installed
%
%return 1 if cmd was sent successfully, -1 otherwise.
%
%