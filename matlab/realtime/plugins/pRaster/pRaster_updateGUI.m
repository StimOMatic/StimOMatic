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
        
        
        
        colInd = mod( CSCChanNr, length( handlesParent.StimOMaticConstants.colorOrder) ) + 1;
        
        colToUse = handlesParent.StimOMaticConstants.colorOrder{colInd};
        
        
        plot( spikesForRaster(:,2), spikesForRaster(:,1), [ colToUse '.'] );
        hold off
        
        
        channelStr = handlesParent.StimOMaticData.CSCChannels{CSCChanNr}.channelStr;
        text( 100, spikesForRaster(1,1), [channelStr] );
    
    
    end
end



%avLengthRaw = round(StimOMaticConstants.LFPAverageLength/1000*StimOMaticConstants.Fs);
%plotOffset = StimOMaticConstants.plotOffsetLFPAverage;

%x = [1:avLengthRaw]/StimOMaticConstants.Fs*1000;
%x = x-StimOMaticConstants.LFPAverageBeforeOffset;   %line is relative to offset


%set(gca,'xlim',[0 handlesParent.StimOMaticConstants.RasterBeforeOffset]
            
%set( handles.TextBoxTrialAv, 'String', ['n=' num2str(transferedGUIData.nTrialsLFP)  ] );

