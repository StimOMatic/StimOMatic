
% path pointing to matlab directory of StimOMatic source
% code package.
basepath = 'C:\Users\rutishauseru\Documents\GitHub\StimOMatic\matlab\';
%basepath = 'C:\Users\superuser\Documents\GitHub\StimOMatic\matlab\';

%% for realtime app
path(path, basepath);

addpath(genpath([basepath '3rd_party/chronux/spectral_analysis']));
path(path, [basepath '3rd_party/neuralynxNetcom/']);
path(path, [basepath '3rd_party/pauser/']);

path(path, [basepath 'continuous']);
path(path, [basepath 'helperfunctions/']);
path(path, [basepath 'ieeg/']);


path(path, [basepath 'realtime/']);
path(path, [basepath 'realtime/core']);
path(path, [basepath 'realtime/GUI']);
path(path, [basepath 'realtime/memVarShare']);
path(path, [basepath 'realtime/NetcomWrappers']);
path(path, [basepath 'realtime/plugins']);
path(path, [basepath 'realtime/plugins/pSpikes']);
path(path, [basepath 'realtime/plugins/pContinuous']);
path(path, [basepath 'realtime/plugins/pContinuousOpenGL']);
path(path, [basepath 'realtime/plugins/pLFPAv']);
path(path, [basepath 'realtime/plugins/pRaster']);
path(path, [basepath 'realtime/plugins/pCtrlLFP']);
path(path, [basepath 'realtime/tcpClientMat']);

%% for PTB example

path(path,[basepath 'psychophysics-example/']);
path(path,[basepath 'psychophysics-example/3rdParty/lptwrite/']);
path(path,[basepath 'psychophysics-example/div/']);
path(path,[basepath 'psychophysics-example/ptb/']);



% TODO: don't forget to remove these paths 
% %processing of raw continous data
% path(path,[basepath 'continuous']);
% path(path,[basepath 'continuous/neuralynx']);
% path(path,[basepath 'continuous/txt']);
% path(path,[basepath 'continuous/binLeadpoint']);
% path(path,[basepath 'GUI']);
% path(path,[basepath 'figures/']);

% 
% %learning algorithms
% path(path,[basepath 'learning/']);
% path(path,[basepath 'learning/RLSC']);
% path(path,[basepath 'learning/SVM']);
% path(path,[basepath 'learning/regression']);
% %spike sorting
% path(path,[basepath 'sortingNew/']);
% path(path,[basepath 'sortingNew/noiseRemoval']);
% path(path,[basepath 'sortingNew/projectionTest']);
% path(path,[basepath 'sortingNew/model']);
% path(path,[basepath 'sortingNew/model/detection']);
% path(path,[basepath 'sortingNew/detection']);
% path(path,[basepath 'sortingNew/evaluation']);
% path(path,[basepath 'sortingNew/klustakwik']);
% path(path,[basepath 'patients']);
% path(path,[basepath 'osortGUI']);
% %analysis of experiments
% path(path,[basepath 'events']);
% path(path,[basepath 'events/novelty']);
% path(path,[basepath 'events/novelty/population']);
% path(path,[basepath 'events/novelty/populationPool']);
% path(path,[basepath 'events/novelty/recall']);
% path(path,[basepath 'events/taskswitch']);
% path(path,[basepath 'events/novelty/ROC']);
% path(path,[basepath 'events/stroop']);
% path(path,[basepath 'events/reward']);
% path(path,[basepath 'events/reward/behavior']);
% path(path,[basepath 'events/newolddelay']);
% path(path,[basepath 'events/newolddelay/lfp']);
% path(path,[basepath 'events/newolddelay/DM']);
% path(path,[basepath 'events/newoldsrc']);
% path(path,[basepath 'events/bubbles']);
% %statistical helpers
% path(path,[basepath 'statistics']);
% %general util functions
% path(path,[basepath 'helpers']);
% %the experiments itself
% path(path,[basepath 'psychophysics']);
% path(path,[basepath 'psychophysics/bubblesu']);
% %plotting helpers
% path(path,[basepath 'plotting']);
% %lfp
% path(path,[basepath 'ieeg']);
% path(path,[basepath 'ieeg/coherence']);
% path(path,[basepath 'ieeg/ITC']);
% path(path,[basepath 'ieeg/coherence/simulations']);
% path(path,[basepath 'ieeg/ripples']);
% %analysis of mEPSC
% path(path,[basepath 'minis']);
%
% path(path,[basepath 'analysisBehavior']);
% %stuff other people wrote
% addpath(genpath([basepath '3rdParty/chronux/spectral_analysis']));
% path(path,[basepath '3rdParty/']);
% path(path,[basepath '3rdParty/gabbiani']);
% path(path,[basepath '3rdParty/cwtDetection']); %wavelet based spike detection.
% path(path,[basepath '3rdParty/neuralynxWindows']);
% path(path,[basepath '3rdParty/Kreuz']);
% path(path,[basepath '3rdParty/circStat']);
% path(path,[basepath '3rdParty/farrow']);
% path(path,[basepath '3rdParty/mexKbHit']);
% 
% %path(path,[basepath '3rdParty/Wave_clus']);
% %path(path,[basepath '3rdParty/Wave_clus/Parameters_files']);
% %path(path,[basepath '3rdParty/Wave_clus/Batch_files']);
% %path(path,[basepath '3rdParty/Wave_clus/Force_files']);
% %path(path,[basepath '3rdParty/Wave_clus/SPC']);
% %path(path,[basepath '3rdParty/m2html/']);
% 
% %STA spike metric/distance toolbox - needs to be compiled locally before it works!
% addpath('c:\code\spike')
% 
% addpath([basepath 'nic']);
