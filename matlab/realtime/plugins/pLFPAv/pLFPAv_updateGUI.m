%
%update the GUI with new information. called once for each channel
%
%
%
function pLFPAv_updateGUI( CSCChanNr, transferedGUIData, handlesPlugin, handlesParent )
if isstruct(transferedGUIData)
    %== write directly into the GUI
    appdata = getappdata( handlesPlugin.figHandle);
    handles = appdata.UsedByGUIData_m;
    set( handles.TextBoxTrialAv, 'String', ['n=' num2str(transferedGUIData.nTrialsLFP)  ] );
    
    if transferedGUIData.nTrialsLFP > 0
        % left panel, LFP per channel.
        set( handlesPlugin.lineHandles.plotLine_axesAvAll(CSCChanNr), 'ydata', transferedGUIData.LFPav+(CSCChanNr-1)*handlesParent.StimOMaticConstants.plotOffsetLFPAverage );
    
    
        
        %plot the average single-trial spectra of the first channel
        if CSCChanNr==1
            
            % middle panel, 2D spectrogram.
            set(0,'CurrentFigure',handlesPlugin.figHandle)
            
            %==== normalized spectra
            set(gcf,'CurrentAxes', handles.axesSpectra)
            
            toPlot2D = transferedGUIData.avSpectra;
            imagesc( transferedGUIData.xAxisColorPlot, transferedGUIData.fLabels, toPlot2D ) ;
            
            xlabel(['time [ms]']);
            ylabel('freq [hz]');
            %title([descrStr ' ' condsStrs{condNr} ' Ch=' num2str(chanToPlot) ]);
            
            colorbar;
            
            title([ handlesParent.StimOMaticData.CSCChannels{CSCChanNr}.channelStr ]);
            
            %==== raw spectra - right panel
            if ~isempty(transferedGUIData.rawSpectra)
                set(gcf,'CurrentAxes', handles.axesSpectra2)
                
                toPlot2D = transferedGUIData.rawSpectra;
                
                timeSlicesToPlot=[500 1200];
                h=[];
                for jj=1:length(timeSlicesToPlot)
                    indToPlot=find( transferedGUIData.xAxisColorPlot>=timeSlicesToPlot(jj));
                    if jj>1
                        hold on;
                    end
                    plot( transferedGUIData.fLabels, log(toPlot2D( :, indToPlot(1) )), rotatingColorCode(jj) );
                    
                end
                hold off
                legend({'before', 'after'});
                ylabel(['power [log]']);
                xlabel('freq [hz]');
                
            end
        end
        
    end
    
    
end