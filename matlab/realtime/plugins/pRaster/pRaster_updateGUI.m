%
%update the GUI with new information. called once for each channel
%
%
%
function pRaster_updateGUI( CSCChanNr, transferedGUIData, handlesPlugin, handlesParent )


%== write directly into the GUI
appdata = getappdata( handlesPlugin.figHandle);
handles = appdata.UsedByGUIData_m;


%raster
spikesForRaster = transferedGUIData.rasterPointsToPlot;

if ~isempty(spikesForRaster)
    if size(spikesForRaster,2)==2 & size(spikesForRaster,1)>0
        set(0,'CurrentFigure',handlesPlugin.figHandle)
        set(gcf,'CurrentAxes', handles.axesRaster)
        
        if CSCChanNr>1
            hold on;
        end
        
        
        
        colInd = mod( CSCChanNr, length( handlesParent.OSortConstants.colorOrder) ) + 1;
        
        colToUse = handlesParent.OSortConstants.colorOrder{colInd};
        
        
        plot( spikesForRaster(:,2), spikesForRaster(:,1), [ colToUse '.'] );
        hold off
        
        
        channelStr = handlesParent.OSortData.CSCChannels{CSCChanNr}.channelStr;
        text( 100, spikesForRaster(1,1), [channelStr] );
    
    
    end
end



%avLengthRaw = round(OSortConstants.LFPAverageLength/1000*OSortConstants.Fs);
%plotOffset = OSortConstants.plotOffsetLFPAverage;

%x = [1:avLengthRaw]/OSortConstants.Fs*1000;
%x = x-OSortConstants.LFPAverageBeforeOffset;   %line is relative to offset


%set(gca,'xlim',[0 handlesParent.OSortConstants.RasterBeforeOffset]
            
%set( handles.TextBoxTrialAv, 'String', ['n=' num2str(transferedGUIData.nTrialsLFP)  ] );

