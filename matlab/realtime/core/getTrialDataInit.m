%
%initialize the trial-by-trial averages
%
function trialDataInit = getTrialDataInit
trialDataInit.updatePlotPending = 0;  

%trialDataInit.nTrialsLFP=0;   %LFP trials
%trialDataInit.LFPtrials=[];
%trialDataInit.LFPav=[];

%trialDataInit.nTrialsRaster = 0;  %raster
%trialDataInit.spikeTimepoints=struct('times',[]);   %structure, (x) is list of timestamps relative offset for every trial x
