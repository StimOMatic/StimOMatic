%
function pluginData = pContinuousOpenGL_processData( newDataReceived, newTimestampsReceived, pluginData, CSCBufferData, CSCTimestampData )
%disp('pSpikes_processedData called');

% do you want to transfer the rawdata (unfiltered?) set to 1 if you want to
% compare plot-output with Cheetah's plotting.
PLOT_RAWDATA = 0;

% debugging mode - will generate data inside this function.
DO_DEBUG = 0;

% offsets and multipliers for individual channels.
offset_spikes = 500;
offset_lfp = 500;
multiplier_spikes = 2.5;
multiplier_lfp = 0.8;

framesize = 512;

%% setup memory mapping for incoming data the first time that this 
% function is called for the current channel.
if pluginData.mmap_initialized == 0
    % identifier = 'pluginName-pluginID-channelNbr'
    string_id = [num2str(pluginData.mmap_abs_ID) '-' num2str(pluginData.channelInfo_caller.channelInt)];
    identifier = ['pContinuousOpenGL-' string_id];
    disp(identifier);
    % setup the mmap stuff.
    pluginData = setup_mmap_infrastructure(pluginData.StimOMaticConstants, pluginData, identifier);
    pluginData.mmap_initialized = 1;
    % this is how we could in theory start the GUIs right here, but there
    % are quite some problems:
    % system(['c:\Python27\python.exe D:\andreas\code\code\realtime\OpenGLPlotting\pContinuousOpenGL.py ' string_id ' &']);
    % problem1: is there a way to also close this process afterwards?
    % problem2: if we open & close the GUI after every single start / stop,
    % then user will have to reconfigure thresholds & limits etc. quite
    % annoying.
    % potential-todo: provide config file where user specifies 'python.exe' file
    % potential-todo: extract location of 'realtime' folder automatically.
end

%% debugging - see end of file for real data modes
%bla = memmapfile('c:\temp\bla', 'Format', 'double', 'Writable', true);
%bla.Data = newDataReceived;

% 'pluginData' specific to this worker:
    % StimOMaticConstants: [1x1 struct]
    % filteredDataLFP: [1x1 struct]
    % filteredDataSpikes: [1x1 struct]
    % mmap_data: [1x1 memmapfile]
    % chanID_caller: 1
    % channelInfo_caller: [1x1 struct]

% 'pluginData.channelInfo_caller':
    % channelStr: 'CSC50'
    % channelInt: 50
    % metaStr: 'R:1000uV; Fs=32556Hz; Low-High:0.1-9000 filtOn:1/1'
    % ADBits: 3.0500e-008
    
if DO_DEBUG == 1
    % using while loop to test how quickly data transfer can be.
    while 1
        framesize = 512;
        nbr_samples = 2048;
        nbr_buffer = nbr_samples / framesize;
        MOD_VALUE = 2;
        newDataReceived = zeros(nbr_samples, 1);
        
        if mod(pluginData.tmp1, MOD_VALUE) == 0
            newDataReceived(1:nbr_samples, 1) = nbr_samples/2:-0.5:0.5;
        elseif mod(pluginData.tmp1, MOD_VALUE) == 1
            newDataReceived(1:nbr_samples, 1) = 0.5:0.5:nbr_samples/2;
        end
        
        pluginData.tmp1 = pluginData.tmp1 + 1;
        
        % enqueue new data
        c = 1;
        for j = 1 : nbr_buffer % number of new buffers
            pluginData.queue1.add(newDataReceived(((c-1)*framesize) + 1 : c * framesize, 1));
            c = c + 1;
        end
        
        % transfer data
        max_nbr_buffers_transmitted = pluginData.mmap_stats.Data(2);
        [pluginData.queue1, transmitted, nbr_buffers_transmitted] = send_databuffers_over_mmap(max_nbr_buffers_transmitted, framesize, pluginData.mmap_data1, pluginData.queue1, pluginData.mmap_stats);
        
        % overwrite number of transmitted buffers only if transmission
        % occoured. otherwise the remote side might be still picking up data
        % and we don't want to accidently set 'nbr_buffers == 0'.
        if transmitted
            % tell receiver how many buffers we transmitted.
            pluginData.mmap_stats.Data(3) = nbr_buffers_transmitted;
        end
        
        pluginData.mmap_stats.Data(1:3)
        % use different pause values to evaluate pick-up performance.
        pause(0.02);
        
    end
    
end
    

%% REAL DATA

% keep track of number of iterations that this plugin has been called.
pluginData.tmp1 = pluginData.tmp1 + 1;

% what is the maximum number of buffers that can be transmitted?
max_nbr_buffers_transmitted = pluginData.mmap_stats.Data(2);

if PLOT_RAWDATA == 1 %% raw data
    
    % unfiltered data - as seen in Cheetah
    newDataReceived = offset_spikes + (0.1 * newDataReceived);
    nbr_samples = size(newDataReceived, 1);
    nbr_buffer = nbr_samples / framesize;
    
    %%
    
    % enqueue new data locally.
    c = 1;
    for j = 1 : nbr_buffer % number of new buffers
        pluginData.queue1.add(newDataReceived(((c-1)*framesize) + 1 : c * framesize, 1));
        c = c + 1;
    end    
    
    % transfer data from local queue to remote queue
    [pluginData.queue1, transmitted, nbr_buffers_transmitted] = send_databuffers_over_mmap(max_nbr_buffers_transmitted, framesize, pluginData.mmap_data1, pluginData.queue1, pluginData.mmap_stats);
    
    % overwrite number of transmitted buffers only if transmission
    % occoured. otherwise the remote side might be still picking up data
    % and we don't want to accidently set 'nbr_buffers == 0'.
    if transmitted
        % tell receiver how many buffers we transmitted.
        pluginData.mmap_stats.Data(3) = nbr_buffers_transmitted;
    end

else %% filtered data
    
    % filter data (as in original plugin)
    nrOverlapLFP = 4 * framesize;
    nrOverlapSpikes = 4 * framesize;
    
    % update filter buffers before raw buffers!
    pluginData.filteredDataLFP = filterSignal_appendBlock(pluginData.StimOMaticConstants.filters.HdLFP, CSCBufferData, pluginData.filteredDataLFP, newDataReceived', nrOverlapLFP, framesize);
    pluginData.filteredDataSpikes = filterSignal_appendBlock(pluginData.StimOMaticConstants.filters.HdSpikes, CSCBufferData, pluginData.filteredDataSpikes, newDataReceived', nrOverlapSpikes, framesize);
    
    pluginData.plotState = [length(newDataReceived) pluginData.plotState(2)+length(newDataReceived)];

    nNew = pluginData.plotState(1);
    tmp1 = offset_spikes + (multiplier_spikes * dataBufferFramed_retrieve_buffered(pluginData.filteredDataSpikes.data, pluginData.filteredDataSpikes.frameOrder, nNew/framesize));
    tmp2 = offset_lfp + (multiplier_lfp * dataBufferFramed_retrieve_buffered(pluginData.filteredDataLFP.data, pluginData.filteredDataLFP.frameOrder, nNew/framesize));    

    
    %% put data into local queues    
    nbr_new_buffers_spks = size(tmp1, 2);
    for j = 1 : nbr_new_buffers_spks % number of new buffers
        pluginData.queue1.add(tmp1(:, j));
    end

    nbr_new_buffers_lfp = size(tmp2, 2);
    for j = 1 : nbr_new_buffers_lfp % number of new buffers
        pluginData.queue2.add(tmp2(:, j));
    end
    
    %% transfer data to shared memory file
    
    % spikes
    [pluginData.queue1, transmitted1, nbr_buffers_transmitted1] = send_databuffers_over_mmap(max_nbr_buffers_transmitted, framesize, pluginData.mmap_data1, pluginData.queue1, pluginData.mmap_stats);

    % lfp
    [pluginData.queue2, transmitted2, nbr_buffers_transmitted2] = send_databuffers_over_mmap(max_nbr_buffers_transmitted, framesize, pluginData.mmap_data2, pluginData.queue2, pluginData.mmap_stats);

    % overwrite number of transmitted buffers only if transmission
    % occoured. otherwise the remote side might be still picking up data
    % and we don't want to accidently set 'nbr_buffers == 0'.
    if transmitted1 && transmitted2
        % tell receiver how many buffers we transmitted.
        pluginData.mmap_stats.Data(3) = min(nbr_buffers_transmitted1, nbr_buffers_transmitted2);
    end
    
end

end
%% EOF
