%
%part of pollDataParallel.m, externalized to allow profiling
%
function [processedData,CSCBufferData,CSCTimestampData,currentTimeOnAcquisition,dataArray] = pollDataParallel_processNewDataBlock(chanID, dataArray, timeStampArray, timeStampArrayConv, bufferSize, CSCChannelInfo,processedData,  CSCBufferData,CSCTimestampData, currentTimeOnAcquisition, activePluginsCont )
framesize=512;

if length(dataArray)>bufferSize
    %too long,skip
    disp('Error in data processing: Skip, too much data received. Buffer overflow?');
else
    %ADBitsVal =   CSCChannelInfo{chanID}.ADBits;
    
    % check if any active plugins are present, otherwise this function will
    % crash.
    if isempty(activePluginsCont)
        return;
    end
    
    %scale the data
    
    dataArray = double(dataArray).*CSCChannelInfo{chanID}.ADBits*1e6;
    %newDataScaled =  double(dataArray).*ADBitsVal*1e6;
    
    %call all continuously receiving plugins
    for k=processedData{chanID}.activePluginsCont
            %satisfy dependencies if this plugin has any
            if ~isempty(activePluginsCont{k}.dependenceInds)
                for depNr=1:length(activePluginsCont{k}.dependenceInds)
                    processedData{chanID}.pluginData{k}.dependenceData{depNr} = processedData{chanID}.pluginData{activePluginsCont{k}.dependenceInds(depNr)};
                end
            end
            
            processedData{chanID}.pluginData{k}.chanID_caller = chanID;
            processedData{chanID}.pluginData{k}.channelInfo_caller = CSCChannelInfo{chanID};
            
            processedData{chanID}.pluginData{k} = activePluginsCont{k}.pluginDef.processDataFunc( dataArray', timeStampArray, processedData{chanID}.pluginData{k}, CSCBufferData{chanID}, CSCTimestampData{chanID} );
    end
    
    % update raw buffers (available for all plugins,generic)
    
    %CSCBufferData(chanID,:) = [ CSCBufferData(chanID, length(dataArray)+1:end) dataArray ];
    %CSCTimestampData(chanID,:) = [ CSCTimestampData(chanID, length(timeStampArrayConv)+1:end) timeStampArrayConv' ];
    
    
    % == commented out two lines do same then 4 lines below, but saves time
    %[CSCTimestampData{chanID}.data,CSCTimestampData{chanID}.frameOrder] = ...
    %dataBufferFramed_addNewFrames( CSCTimestampData{chanID}.data, CSCTimestampData{chanID}.frameOrder, timeStampArrayConv', framesize);
    newDataFramed = buffer( timeStampArrayConv', framesize);
    nrNewFrames=size(newDataFramed,2);
    CSCTimestampData{chanID}.data(:, CSCTimestampData{chanID}.frameOrder(1:nrNewFrames) ) = newDataFramed;
    CSCTimestampData{chanID}.frameOrder =  [ CSCTimestampData{chanID}.frameOrder(nrNewFrames+1:end) CSCTimestampData{chanID}.frameOrder(1:nrNewFrames) ];

    % == commented out two lines do same then 4 lines below, but saves time
    %[CSCBufferData{chanID}.data,CSCBufferData{chanID}.frameOrder] = ...
    %dataBufferFramed_addNewFrames( CSCBufferData{chanID}.data, CSCBufferData{chanID}.frameOrder, dataArray, framesize);

    newDataFramed = buffer( dataArray, framesize);
    nrNewFrames=size(newDataFramed,2);
    CSCBufferData{chanID}.data(:, CSCBufferData{chanID}.frameOrder(1:nrNewFrames) ) = newDataFramed;
    CSCBufferData{chanID}.frameOrder =  [ CSCBufferData{chanID}.frameOrder(nrNewFrames+1:end) CSCBufferData{chanID}.frameOrder(1:nrNewFrames) ];


    if chanID==1
        %time is global
        currentTimeOnAcquisition=CSCTimestampData{chanID}.data(  end, CSCTimestampData{chanID}.frameOrder(end) );   %last datapoint of newest data frame
    end
    
end %end process newly arrived data