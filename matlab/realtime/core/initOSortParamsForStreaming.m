function OSortConstants = initOSortParamsForStreaming( )

OSortConstants.versionStr = 'v122212-urut-ak';

Fs = 32556;
OSortConstants.Fs = Fs;

% how much to display and buffer
OSortConstants.nrFramesToBuffer = 635;
OSortConstants.frameSize = 512;
OSortConstants.bufferSizeCSC = OSortConstants.nrFramesToBuffer * OSortConstants.frameSize;   %needs to be a multiple of 512, ca 10s

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

OSortConstants.filters.HdLFP = Hd;
OSortConstants.filters.HdSpikes = HdSpikes;

%GUI offsets
OSortConstants.plotOffsetRawband = 500;  %uV
OSortConstants.plotOffsetSpikeband = 100;%uV
OSortConstants.plotOffsetLFPAverage = 300;

%averaging of LFP across trials
OSortConstants.LFPAverageAfterOffset = 500; %ms, how much to keep after offset
OSortConstants.LFPAverageBeforeOffset = 3000; %ms, how much to keep before offset
OSortConstants.LFPAverageLength   = OSortConstants.LFPAverageAfterOffset + OSortConstants.LFPAverageBeforeOffset;

%Rasters
OSortConstants.RasterBeforeOffset = 5000;

OSortConstants.maxTrialsPerChannel = 50;

%TTL Stream
OSortConstants.TTLStream = 'Events'; %Cheetah object name for the TTLs

OSortConstants.colorOrder={'r','g','b','y','m','k','c'};

%waveforms plotting
OSortConstants.nrPointsPerWaveform = 84;
OSortConstants.maxNrWaveformsToPlot = 200;
OSortConstants.plotOffsetWaveforms = 200;

%=== spike detection parameters (OSort parameters)
OSortParams = [];
OSortParams.samplingFreq = Fs;
OSortParams.detectionMethod = 1; %1 power, 2 T pos, 3 T min, 3 T abs, 4 wavelet
OSortParams.alignMethod = 1;  %only used if peak finding method is "findPeak". 1=max, 2=min, 3=mixed
OSortParams.extractionThreshold = 5;
OSortParams.prewhiten = 0;
OSortParams.peakAlignMethod = 1; %1 find Peak, 2 none, 3 peak of power, 4 MTEO peak
OSortParams.rawFileVersion=2; %neuralynx digital
OSortParams.doGroundNormalization=0;

[~, limit, ~] = defineFileFormat(OSortParams.rawFileVersion, OSortParams.samplingFreq );
OSortParams.limit = limit;  % max value possible for it not to be out of band

OSortConstants.OSortParams = OSortParams;