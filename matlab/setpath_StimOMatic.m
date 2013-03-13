
% path pointing to matlab directory of StimOMatic source
% code package.
basepath = 'C:\Users\rutishauseru\Documents\GitHub\StimOMatic\matlab\';
%basepath = 'C:\Users\superuser\Documents\GitHub\StimOMatic\matlab\';
%basepath = '/home/kotowicz/Documents/code/MPI/StimOMatic__kotowicz/matlab/';

%% for realtime app

dd = filesep();

path(path, basepath);

addpath(genpath([basepath ['3rd_party' dd 'chronux' dd 'sspectral_analysis']]));
path(path, [basepath ['3rd_party' dd 'neuralynxNetcom' dd '']]);
path(path, [basepath ['3rd_party' dd 'pauser' dd '']]);

path(path, [basepath 'continuous']);
path(path, [basepath 'helperfunctions']);
path(path, [basepath 'ieeg']);


path(path, [basepath 'realtime']);
path(path, [basepath ['realtime' dd 'core']]);
path(path, [basepath ['realtime' dd 'GUI']]);
path(path, [basepath ['realtime' dd 'memVarShare']]);
path(path, [basepath ['realtime' dd 'NetcomWrappers']]);
path(path, [basepath ['realtime' dd 'plugins']]);
path(path, [basepath ['realtime' dd 'plugins' dd 'pSpikes']]);
path(path, [basepath ['realtime' dd 'plugins' dd 'pContinuous']]);
path(path, [basepath ['realtime' dd 'plugins' dd 'pContinuousOpenGL']]);
path(path, [basepath ['realtime' dd 'plugins' dd 'pLFPAv']]);
path(path, [basepath ['realtime' dd 'plugins' dd 'pRaster']]);
path(path, [basepath ['realtime' dd 'plugins' dd 'pCtrlLFP']]);
path(path, [basepath ['realtime' dd 'tcpClientMat']]);

%% for PTB example

path(path, [basepath 'psychophysics-example']);
path(path, [basepath ['psychophysics-example' dd '3rdParty' dd 'lptwrite' dd '']]);
path(path, [basepath ['psychophysics-example' dd 'div' dd '']]);
path(path, [basepath ['psychophysics-example' dd 'ptb' dd '']]);

%% EOF
