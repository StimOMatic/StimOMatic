%send TTL to parallel port and write it to logfile (together with optional
%string value logValue).
%
%urut/aug10
function sendTTLwithLog( fidLog, TTLvalue, logValue) 
portAddress=888;
if nargin<3
    logValue='';
end

lptwrite(portAddress, TTLvalue);
writeLog(fidLog, TTLvalue, logValue);

