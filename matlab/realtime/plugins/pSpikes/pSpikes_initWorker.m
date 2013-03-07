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

handlesParent.OSortConstants.OSortParams.extractionThreshold = detectionThreshold;

disp(['Spike detection threshold is: ' num2str(detectionThreshold) ]);

paramStrDisplay=['Th=' num2str(handlesParent.OSortConstants.OSortParams.extractionThreshold) ...
    ' detectMethod=' num2str(handlesParent.OSortConstants.OSortParams.detectionMethod) ...
    ' alignMethod=' num2str(handlesParent.OSortConstants.OSortParams.peakAlignMethod) ... 
    ' alignParam=' num2str(handlesParent.OSortConstants.OSortParams.alignMethod) ...
    ' nrWavesPlot=' num2str(handlesParent.OSortConstants.maxNrWaveformsToPlot) ...
    ];

set(handles.labelSpikeDetectParams, 'String',paramStrDisplay);


pluginData.OSortConstants = handlesParent.OSortConstants;


%% data structures neededed
pluginData.waveforms =[];
pluginData.timestamps =[];
pluginData.lastPlottedInfo = [];