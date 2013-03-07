function pluginData = setup_mmap_infrastructure(OSortConstants, pluginData, pluginname)
%% memory mapping for incoming data

%% these directory definitions must be in-sync with the python code.
TMP_DIR = '/tmp';
if ispc() == 1
    TMP_DIR = 'c:\temp';
end
    
dd = filesep();

TMP_DIR = [TMP_DIR dd pluginname];
if ~exist(TMP_DIR, 'dir')
    mkdir(TMP_DIR);
end

stats_file = [TMP_DIR dd 'bla_stats'];
spike_file = [TMP_DIR dd 'bla1'];
lfp_file = [TMP_DIR dd 'bla2'];

memmapfiles = {stats_file, spike_file, lfp_file};

%%

max_nbr_buffers_transmitted = 100;

if ~exist('OSortConstants', 'var')
    OSortConstants.frameSize = 512;
end

% size of stats, spike, and lfp file.
memmapsizes = [10, max_nbr_buffers_transmitted*OSortConstants.frameSize, max_nbr_buffers_transmitted*OSortConstants.frameSize];

% TODO: determine where we create non-existing shared memory files. on the
% windows or the python side?

% we can only write to this file, if the python program is not running.
% if file exists, skip.
for j = 1 : numel(memmapfiles)
    filename = memmapfiles{j};
    if exist(filename, 'file')
        continue;
    end
    file_1 = fopen(filename, 'wb');
    fwrite(file_1, zeros(memmapsizes(j), 1), 'double');
    fclose(file_1);
end

% stats to transmit between programs.
pluginData.mmap_stats = memmapfile(stats_file, 'Format', 'double', 'Writable', true);
% spikes
pluginData.mmap_data1 = memmapfile(spike_file, 'Format', 'double', 'Writable', true);
% lfp
pluginData.mmap_data2 = memmapfile(lfp_file, 'Format', 'double', 'Writable', true);

% setup initial value so that we can start transmitting new data.
DATA_RECEIVED_ACK_NUM = 3.14159265;
pluginData.mmap_data1.Data(1) = DATA_RECEIVED_ACK_NUM;
pluginData.mmap_data2.Data(1) = DATA_RECEIVED_ACK_NUM;


% -1 == indicates that value has only be initialized with dummy default.

% number of channels. TOOD: how do I access this parameter inside this function?
% TODO: see 'pContinuousOpenGL_initGUI' and add channels there.
pluginData.mmap_stats.Data(1) = -1;
% max number of buffers written 
pluginData.mmap_stats.Data(2) = max_nbr_buffers_transmitted;
% number of new buffers written
pluginData.mmap_stats.Data(3) = -1;


%% data queues
% LinkedList used as queue - does not support size limit.
% import java.util.LinkedList;
% pluginData.queue1 = LinkedList();
% pluginData.queue2 = LinkedList();

% CircularFifoBuffer used as queue - supports size limit. Without size
% limit we might run into 'out of memory' problems.
import org.apache.commons.collections.buffer.CircularFifoBuffer
max_size = 1000;
pluginData.queue1 = CircularFifoBuffer(max_size);
pluginData.queue2 = CircularFifoBuffer(max_size);

% temporary data storage for debugging, etc. TODO: remove if not needed
% anymore.
pluginData.tmp1 = 0;
pluginData.tmp2 = [];

pluginData.trial_start = tic();

end