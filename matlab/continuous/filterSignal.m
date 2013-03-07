%
%
%apply bandpass filter 300...3000hz
%
function filteredSignal = filterSignal( Hd, rawSignal )


%cant filter if the signal is too short
if length(rawSignal)<20
	filteredSignal=[];
	return;
end

filteredSignal = filtfilt(Hd{1}, Hd{2}, rawSignal);


