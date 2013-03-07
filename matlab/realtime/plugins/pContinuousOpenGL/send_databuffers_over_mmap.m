function [queue_handle, transmitted, nbr_buffers_transmitted] = send_databuffers_over_mmap(max_nbr_buffers_transmitted, framesize, data_handle, queue_handle, stats_handle)
    
    % default return values
    transmitted = false;
    nbr_buffers_transmitted = 0;
    
    %% quit if there's nothing to transfer
    if queue_handle.size() == 0
        % warning('nothing to deliver');
        return;
    end

    %% quit if receiver side doesn't indicate that all previous data has been delivered.
    DATA_RECEIVED_ACK_NUM = 3.14159265;
    if data_handle.Data(1) ~= DATA_RECEIVED_ACK_NUM && stats_handle.Data(3) > 0
        % uncomment if you want to debug for possible data transmission
        % bottlenecks.
        % disp([ datestr(now) ': can''t transmit data - data has not been picked up yet on receiver side.']);
        return;
    end
    
    %% get ready for data transmission.    
    % 'max_nbr_samples' must have the same size as 'data_handle.Data'
    max_nbr_samples = max_nbr_buffers_transmitted * framesize;
    data_to_transmit = zeros(size(data_handle.Data));
    
    % if the python side takes too long processing (unpacking) the data,
    % consider limiting the number of transferred items (by setting
    % 'max_nbr_buffers_transmitted' to a lower value here).
    
    c = 0;
    % go through all buffers and prepare them for sending.
    while queue_handle.size() > 0
        c = c + 1;
        tmp_data = queue_handle.remove();
        data_to_transmit(((c-1)*framesize) + 1 : c * framesize, 1) = tmp_data;

        % we can't transmit more buffers then 'data_handle.Data' is long.
        if c >= max_nbr_buffers_transmitted
            break;
        end

    end
    
    %     disp('handle size');
    %     size(data_handle.Data)
    %     disp('data to transmit size');
    %     size(data_to_transmit)
    % write data to mmap - no need to return.
    data_handle.Data = data_to_transmit;

    % overwrite default return values
    nbr_buffers_transmitted = c;
    transmitted = true;    
    
end
%% EOF
