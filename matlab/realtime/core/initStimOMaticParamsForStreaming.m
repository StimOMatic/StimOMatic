function StimOMaticConstants = initStimOMaticParamsForStreaming( )

StimOMaticConstants.versionStr = 'v130313-urut-ak';

Fs = 32556;
StimOMaticConstants.Fs = Fs;

% how much to display and buffer
StimOMaticConstants.nrFramesToBuffer = 635;
StimOMaticConstants.frameSize = 512;
StimOMaticConstants.bufferSizeCSC = StimOMaticConstants.nrFramesToBuffer * StimOMaticConstants.frameSize;   %needs to be a multiple of 512, ca 10s

%filter for LFP
Wn=120;
n=4;
[b,a]=butter(n,Wn/(Fs/2),'low');
Hd{1}=b;
Hd{2}=a;

%filter for spikes
WnSpikes=[300 3000];
[b,a]=butter(n,WnSpikes/(Fs/2));
HdSpikes{1}=b;
HdSpikes{2}=a;

StimOMaticConstants.filters.HdLFP = Hd;
StimOMaticConstants.filters.HdSpikes = HdSpikes;

%GUI offsets
StimOMaticConstants.plotOffsetRawband = 500;  %uV
StimOMaticConstants.plotOffsetSpikeband = 100;%uV
StimOMaticConstants.plotOffsetLFPAverage = 300;

%averaging of LFP across trials
StimOMaticConstants.LFPAverageAfterOffset = 500; %ms, how much to keep after offset
StimOMaticConstants.LFPAverageBeforeOffset = 3000; %ms, how much to keep before offset
StimOMaticConstants.LFPAverageLength   = StimOMaticConstants.LFPAverageAfterOffset + StimOMaticConstants.LFPAverageBeforeOffset;

%Rasters
StimOMaticConstants.RasterBeforeOffset = 5000;

StimOMaticConstants.maxTrialsPerChannel = 50;

%TTL Stream
StimOMaticConstants.TTLStream = 'Events'; %Cheetah object name for the TTLs

StimOMaticConstants.colorOrder={'r','g','b','y','m','k','c'};

%waveforms plotting
StimOMaticConstants.nrPointsPerWaveform = 84;
StimOMaticConstants.maxNrWaveformsToPlot = 200;
StimOMaticConstants.plotOffsetWaveforms = 200;

%=== spike detection parameters (StimOMatic parameters)
StimOMaticParams = [];
StimOMaticParams.samplingFreq = Fs;
StimOMaticParams.detectionMethod = 1; %1 power, 2 T pos, 3 T min, 3 T abs, 4 wavelet
StimOMaticParams.alignMethod = 1;  %only used if peak finding method is "findPeak". 1=max, 2=min, 3=mixed
StimOMaticParams.extractionThreshold = 5;
StimOMaticParams.prewhiten = 0;
StimOMaticParams.peakAlignMethod = 1; %1 find Peak, 2 none, 3 peak of power, 4 MTEO peak
StimOMaticParams.rawFileVersion=2; %neuralynx digital
StimOMaticParams.doGroundNormalization=0;

[~, limit, ~] = defineFileFormat(StimOMaticParams.rawFileVersion, StimOMaticParams.samplingFreq );
StimOMaticParams.limit = limit;  % max value possible for it not to be out of band

StimOMaticConstants.StimOMaticParams = StimOMaticParams;