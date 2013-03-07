

port = 22480;
timeToWait = 5000;

try
    jTcpObj = jtcp('accept', port, 'timeout', timeToWait);
    
catch err
   %
   %
   disp('problem');
   keyboard
   
   if ~isempty(strfind(err.message,'Accept timed out'))
      
       
   else
       rethrow(err);        
   end
end