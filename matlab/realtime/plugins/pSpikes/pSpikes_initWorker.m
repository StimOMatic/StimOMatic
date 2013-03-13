%
% data structures to be transfered to each worker where this plugin should be running
%
%
function pluginData = pSpikes_initWorker( handlesParent, handlesPlugin )

appdata = getappdata( handlesPlugin.figHandle);
handles = appdata.UsedByGUIData_m;

%% get settings from the GUI
%update detection threshold

detectionThreshold = str2num(get( handles.fieldDetectionThreshold, 'String'));

handlesParent.StimOMaticConstants.StimOMaticParams.extractionThreshold = detectionThreshold;

disp(['Spike detection threshold is: ' num2str(detectionThreshold) ]);

paramStrDisplay=['Th=' num2str(handlesParent.StimOMaticConstants.StimOMaticParams.extractionThreshold) ...
    ' detectMethod=' num2str(handlesParent.StimOMaticConstants.StimOMaticParams.detectionMethod) ...
    ' alignMethod=' num2str(handlesParent.StimOMaticConstants.StimOMaticParams.peakAlignMethod) ... 
    ' alignParam=' num2str(handlesParent.StimOMaticConstants.StimOMaticParams.alignMethod) ...
    ' nrWavesPlot=' num2str(handlesParent.StimOMaticConstants.maxNrWaveformsToPlot) ...
    ];

set(handles.labelSpikeDetectParams, 'String',paramStrDisplay);


pluginData.StimOMaticConstants = handlesParent.StimOMaticConstants;


%% data structures neededed
pluginData.waveforms =[];
pluginData.timestamps =[];
pluginData.lastPlottedInfo = [];