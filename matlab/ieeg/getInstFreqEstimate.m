%
%get instantaenous frequency from oscillating (non-stationary) signal
%
%methodNr: 1 - derivative of phase angle. dataIn=angles
%          2 - peak finding. dataIn=bandpass filtered data
%
%step: stepsize sample to sample in sec (=1/Fs)
%thresh: (only for method=2) threshold for peak finding
%avSize: (only for method=2) how many past peaks to use
%
%
%urut/april12
function [instF,peaks] = getInstFreqEstimate( methodNr, dataIn, step, thresh, avSize)
peaks=[];
switch(methodNr)
    case 1 % derivative of phase angle
        instF = diff( unwrap(dataIn) )/step/(2*pi);
    case 2
        peaks = findpeaks(dataIn, thresh);  %chronux function

        incStepSize=[];
        instF=[];
        for j=2:length(peaks.loc)
            incStepSize(j) = diff ( peaks.loc(j-1:j) );

            if j>avSize+1
                indsToUse=j-avSize:j;
            else
                indsToUse=j;
            end
            ppTimeEstimate = mean(incStepSize(indsToUse)*step); %peak-to-peak time estimate
            instF(j) = 1/ppTimeEstimate;
        end
end

end
