% This function is a modified pause function that provides more
%accruate
% time delays than PAUSE.
%
% SYNTAX: pauser(delay[,t0,sys_delay]);
%
% DELAY - a time duration in seconds.
% t0 - the cpu clocktime from which the delay should becounted.
% sys_delay - a measured systematic delay that is used to obtain more accurate pause durations
%
%from http://www.mathworks.com/matlabcentral/newsreader/view_thread/82662
%
% DBE 12/06/04

function pauser(delay,t0,sys_delay)
if nargin==1
  t0=clock;
  sys_delay=0;
elseif nargin==2
  sys_delay=0;
end

while etime(clock,t0)+sys_delay<delay
  % Do nothing...
end

return