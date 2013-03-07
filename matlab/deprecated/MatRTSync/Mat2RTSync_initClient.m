%
%initialize the data providing client for Mat2RTSync
%
%urut/MPI/jan12
function jTcpObj = Mat2RTSync_initClient( hostname,port,timeout )
if nargin<1
    hostname=[];
end
if nargin<2
    port=[];
end
if nargin<3
    timeout=[];
end


if isempty(hostname)
    hostname='127.0.0.1';
end
if isempty(port)
    port=22480;
end
if isempty(timeout)
    timeout=2000;
end

try
    jTcpObj = jtcp('request', hostname, port, 'timeout', 2000);
catch err
    warning('Connection failed ');
    disp( err.message );
    jTcpObj=[]; 
end