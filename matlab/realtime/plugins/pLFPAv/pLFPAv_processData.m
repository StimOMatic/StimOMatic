%
%
function pluginData = pLFPAv_processData( newDataReceived, newTimestampsReceived, pluginData, CSCBufferData, CSCTimestampData, t, tFrom )
disp('pLFPAv_processData called');

Fs = pluginData.OSortConstants.Fs;

%=== prepare average LFP across all trials
%find index of this timestamp
d=(CSCTimestampData-t);
offsetInd = find( abs(d) == min(abs(d)) );

onsetInd = round(offsetInd - (tFrom/1000)*Fs )+1;

%[onsetInd offsetInd length(CSCBufferData)]

if onsetInd>0 & offsetInd>0 & offsetInd<=length(CSCBufferData)
    %valid event, take the data
    singleTrialTrace = CSCBufferData( onsetInd:offsetInd );
    
    pluginData.nTrialsLFP = pluginData.nTrialsLFP +1;
    pluginData.LFPtrials(pluginData.nTrialsLFP,:) = singleTrialTrace;
    
    %update the across-trial average if there are at least 2 trials
    if pluginData.nTrialsLFP > 0
        
        % average per channel, see left panel.
        if pluginData.nTrialsLFP>1
            pluginData.LFPav = mean(pluginData.LFPtrials);
        else
            pluginData.LFPav = pluginData.LFPtrials;
        end
        
        %update the spectra
        
        %pluginData.singleTrialSpectra = [];
        %pluginData.avSpectra = [];
        
        %parameters for spectra estimation
        FsDown=1000; P=20; Q=651;
        paramsIn.fpass=[0.5 100];
        paramsIn.tapers=[2 3];
        paramsIn.err=[0 0.05];
        paramsIn.pad=-1;
        paramsIn.Fs=FsDown;
        windowSize = 400;
        stepSize  = 50;
        rangeBaseline = [500 1000]; %use the 500 ms prior to stim onset to normalize
        %Whalf = getHalfWidthOfTapers( paramsIn, windowSize); %freq resolution?
        
        singleTrialTraceDown = downsampleRawTrace( singleTrialTrace, P, Q ); %FS now 1000Hz
        
        [S2D,f2,windowOnsets] = calcWindowedSpect( singleTrialTraceDown, paramsIn, FsDown, windowSize, stepSize );
        
        pluginData.xAxisColorPlot = [windowOnsets+windowSize/2];
       
        pluginData.singleTrialSpectra(:,:,pluginData.nTrialsLFP) = S2D;
        
        size(pluginData.singleTrialSpectra)
        
        pluginData.fLabels = f2;
        
        %average in 2D
        if  pluginData.nTrialsLFP>1
            mSpect2D = mean( pluginData.singleTrialSpectra, 3);
            %mSpect2DNormAfter = baselineNormalizeSpectra( mSpect2D, indsBaseline ); %normalize the average spectrum
            
            indsBaseline = find( windowOnsets>=rangeBaseline(1) & windowOnsets+windowSize<rangeBaseline(2) ); %find which moving-windows are entirely out of the stim onset
            
            pluginData.avSpectra =  baselineNormalizeSpectra( mSpect2D, indsBaseline );
            
            %without norm
            %pluginData.avSpectra = mean( pluginData.singleTrialSpectra, 3) ;

            % raw av spectra at certain times
           
            pluginData.rawSpectra = mSpect2D;
            
        else
            pluginData.avSpectra =  pluginData.singleTrialSpectra ;

        end


        disp(['Average updated,plotting pending...' num2str(size( pluginData.LFPav )) '-' num2str(size(pluginData.LFPtrials)) ]);
    end
    
    
    %[S,f1] = calcSTAAvSpect( trace, paramsIn, FsDown);
    
    
end