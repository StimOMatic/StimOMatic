%
% evaluate for one block of data whether a phase-conditional stimulation should be initiated
%
% sigBlockRaw: raw data, at high sampling rate
% Q : downsampling factor
% b/a: filter constants
% detectThreshold: min power or =0 if predict in any case (if only called when power is high in the first place)
% step: stepsize at downsampled rate
% lenToUse: how many datapoints (in ms) to use for the power detection. mean
%  power over this time used
%
%urut/april2012
function [powerAtEnd, delayTillStim,peaks,estFreqUsed] = evalPhaseStimForBlock( sigBlockRaw, Q, b,a, detectThreshold, methodPeakDetectNr, step, avSizePeakDetect, sysDelay, wantPhase, lenToUse )
delayTillStim=0;
estFreqUsed=0;
peaks=[];

sigDownBlock = downsample( sigBlockRaw , Q); % downsample

blockFiltered = filtfilt(b,a, sigDownBlock ); % bandpass filter

%timestamps for debug plotting
%tBlockFilteredRaw = indsRaw./Fs*1000;
%tBlockFilteredDown = tBlockFilteredRaw(1:Q:end);

% hilbert to estimate power/phase
hSig = hilbert(blockFiltered);
powerEstimateBlock = abs(hSig);
angleEstimateBlock = atan2( imag(hSig), real(hSig) );

powerAtEnd = mean(powerEstimateBlock(end-lenToUse));

usedRandPhase=0;
if wantPhase==99    %if requested phase is 99, randomize every time (control condition)
    wantPhase = 2*pi*(rand-0.5);
    usedRandPhase=1;
end

%decide if stimulation should be turned on for this oscillation
if powerAtEnd >= detectThreshold | detectThreshold==0

    %disp([ 'power detected: ' num2str(powerAtEnd)]);

    %freq estimate; find the peaks in the bandpass filtered signal
    threshPeakDetect=std(blockFiltered)/2;   %TODO -- can be made more efficient?
    [instF,peaks] = getInstFreqEstimate( methodPeakDetectNr, blockFiltered, step, threshPeakDetect, avSizePeakDetect);

    %test here if freq estimate is robust/usable, otherwise skip
    if length(instF)<2
        return;
    end
    
    
    estFreq = instF(end);       
    currentPhase = angleEstimateBlock(end);

    % want and currentPhase is in notation 0...pi/2...pi...3/4pi...2pi system; anti-clockwise
    phaseDiff = circDiffAnticlockwise(currentPhase,wantPhase);
        
%     if usedRandPhase
%         disp(['rand phase was ' num2str(wantPhase)]);
%     end
    %phaseDiff = wantPhase - currentPhase; % how long, in terms of phase, till the requested stimulation should be initiated

    %how long till this phase occurs at the current freq, in ms
       
    % 1/estFreq   so long for one rad=2pi
    delayTillStim = (1/estFreq) * (phaseDiff/(2*pi));
    %   delayTillStim
    % X cycles later if it takes too long till then
    maxRun=1;
    while delayTillStim<sysDelay & maxRun<5
        maxRun=maxRun+1;
       delayTillStim = delayTillStim + (1/estFreq);
    end
              
    estFreqUsed = estFreq;
    
    %absStimNew = ( tBlockFilteredDown(end) + delayTillStim*1000);       
end
