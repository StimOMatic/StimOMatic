
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

%% EOF
