%
%
% filter a signal blockwise, such that at any point t, only data up to this point has been considered
% this is to simulate causal filtering in a realtime system that only has access to the past and not the future
%
%urut/april12
function [filtSig, hilbertPowerSig, hilbertAngleSig] = filterSignal_blocked(sig, b,a, winSize)

N=length(sig);

filtSig=zeros(1,N);
hilbertPowerSig=zeros(1,N);
hilbertAngleSig=zeros(1,N);

stepsize = 1;

for t = winSize+1:stepsize:N
    
    
   blockFiltered = filtfilt(b,a, sig(t-winSize:t) );
   
   filtSig(t) = blockFiltered(end);
   
   hSig = hilbert(blockFiltered);
   
   hilbP = abs(hSig);
   
   angleEstimate=atan2( imag(hSig), real(hSig) );
   
   hilbertPowerSig(t)=hilbP(end);
   
   hilbertAngleSig(t)=angleEstimate(end);
end