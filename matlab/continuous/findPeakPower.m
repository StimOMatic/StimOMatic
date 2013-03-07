%
% determine peak location of spike using power signal
%
%urut/may07
function peakInd=findPeakPower(spikeSignal, powerSignal)

%differential
dP = diff(powerSignal);
minPos = find( dP == min(dP) );
minPos = minPos(end); %in case multiple points are min, take the last one.
tollerance=5; %0.4ms

indsFrom=max(1,minPos-tollerance(1));
indsTo=min(length(spikeSignal), minPos+tollerance(2));

spikePeak = abs( spikeSignal(indsFrom:indsTo) );
peakPos = find( spikePeak == max(spikePeak) );
peakPos = peakPos(1);

peakInd = indsFrom + peakPos -1;

%% below: for debugging purposes
% 
% if peakInd>40
% figure(20);
% subplot(2,2,1)
% plot(1:length(spikeSignal), spikeSignal, 'b', indsFrom:indsTo, spikeSignal(indsFrom:indsTo),'r');
% hold on
% plot( peakInd, max(spikeSignal), 'dk');
% hold off
% xlim([1 64]);
% title(['peak is ' num2str(peakInd)]);
% 
% subplot(2,2,2)
% plot(dP);
% xlim([1 64]);
% title('diff');
% 
% subplot(2,2,3)
% plot(diff(spikeSignal));
% xlim([1 63]);
% 
% subplot(2,2,4)
% plot(powerSignal);
% xlim([1 64]);
% title('raw');
% 
% end