''' mmap stuff '''
import os
import mmap
from datetime import datetime
from struct import unpack

from pyglet_app_data_management import create_empty_data_buffer
from pyglet_app_consts import DATA_RECEIVED_ACK_STR, DATA_RECEIVED_ACK_NUM, NBR_BUFFERS_ZERO_STR
from pyglet_app_profile import profile_code, PROFILE

import numpy as np

class mmap_interface(object):

	MMAP_BYTES_PER_FLOAT = 8

	# number of elements to store in memory
	# MMAP_STORE_LENGTH = MMAP_BYTES_PER_FLOAT * int(NBR_DATA_POINTS_PER_BUFFER)

	# null string used to initalize memory
	MMAP_NULL_HEX = '\x00'


	prev_sum = 0
	MMAP_NO_DATA_INDICATE_ZERO = False
	MMAP_NO_DATA_INDICATE_NON_ZERO = True


	# default number of channels
	NBR_INDEPENDENT_CHANNELS = 1

	# set data points per buffer. ideally this would be a per channel configuration.
	NBR_DATA_POINTS_PER_BUFFER_INT = 512

	# did the object initalize ok? did 'setup()' run ok?
	INITIALIZED = False

	def __init__(self, *args, **kwargs):
		pass


	@profile_code(PROFILE)
	def setup(self):

		MMAP_FILENAME, MMAP_stats_file = self.setup_mmap_filenames(self.TMP_DIR)

		# initialize MMAP
		self.mmap_data = self.setup_mmap(MMAP_FILENAME)
		if not self.mmap_data:
			print "Could not read mmap-file. Aborting."
			return

		if not os.path.isfile(MMAP_stats_file):
			self.create_mmap_file_on_disk(MMAP_stats_file)

		f = open(MMAP_stats_file, "r+b")
		self.mmap_stats = mmap.mmap(f.fileno(), 0)

		self.INITIALIZED = True


	@profile_code(PROFILE)
	def get_data_from_mmap(self, mmap_stats, mmap_data):
		# 
		#t0 = time()    
		
		nbr_buffers_received = self.get_nbr_received_buffers_from_mmap(mmap_stats)

		nbr_mmap_files = len(mmap_data)
		zeros = np.zeros(self.NBR_DATA_POINTS_PER_BUFFER_INT)
		
		''' no new buffers - generate one empty dummy buffer and return '''
		if nbr_buffers_received == 0 or nbr_buffers_received == -1:
		    return create_empty_data_buffer(nbr_mmap_files, zeros)


		nbr_buffers_received = int(nbr_buffers_received)
		nbr_elements = nbr_buffers_received * self.NBR_DATA_POINTS_PER_BUFFER_INT
		range_nbr_mmap_files = range(nbr_mmap_files)

		# check if there's any data that's ready for pickup.
		new_data_found = np.zeros(nbr_mmap_files)
		for mmap_file_index in range_nbr_mmap_files:
		# go to beginning of memory mapped area 
		    mmap_data[mmap_file_index].seek(0)
		    
		    # quit right away if no new data has been written yet.
		    this_element = mmap_data[mmap_file_index].read(self.MMAP_BYTES_PER_FLOAT)
		    this_element = unpack('d', this_element)[0]
		    if round(this_element, 8) != DATA_RECEIVED_ACK_NUM:
		        new_data_found[mmap_file_index] = 1
		
		# none of the files contain new data
		if sum(new_data_found) == 0:
		    return create_empty_data_buffer(nbr_mmap_files, zeros, nbr_buffers_received)

		''' read out transferred data '''
		data = []
		# this is ~ 10ms slower.
		#data = np.zeros((nbr_mmap_files, nbr_buffers_received, NBR_DATA_POINTS_PER_BUFFER_INT))	
		
		# at least one new buffer has arrived.
		for mmap_file_index in range_nbr_mmap_files:
		    
		    #'''        
		    # pre-allocate each buffer
		    buffers = []
		    for buffer_index in xrange(nbr_buffers_received):
		        # DONE: find out what the problem here is:
		        # there seems to be a bug in python on windows, or I don't understand the way things work:
		        # if I create 'zeros' outside this loop, the second time that 'zeros' gets called, 
		        # it will contain all values found in data[mmap_file_index][buffer][j]. Therefore I have to re-generate
		        # the 'zeros' for each mmap_file_index'th loop.
		        # SOLUTION:
		        # We need to make a 'deep-copy' of zeros, otherwise we are just 
		        # passing a reference to the same object (which is a np.array object).
		        zero_copy = zeros.copy()
		        buffers.append(zero_copy)
		        
		    # add all buffers to mmap_file_index'th data stream.
		    data.append(buffers)
		    #'''
		    
		    # go to beginning of memory mapped area & read out all elements
		    mmap_data[mmap_file_index].seek(0)
		    all_values_string = mmap_data[mmap_file_index].read(nbr_elements * self.MMAP_BYTES_PER_FLOAT)

		    # 0.1632 per call in debugger
		    # grab sub-list so we avoid having to call this list by its index.
		    this_data = data[mmap_file_index]

		    # unpack all values at once
		    unpacked_values = unpack("d" * nbr_elements, all_values_string)

		    # using list comprehension is better than a regular loop with random array access
		    this_data = [unpacked_values[i:i+self.NBR_DATA_POINTS_PER_BUFFER_INT] for i in xrange(0, nbr_elements, self.NBR_DATA_POINTS_PER_BUFFER_INT)]
		    
		    # slower version of above line.
		    #for abs_idx in range(nbr_elements):
		    #    this_data[abs_idx / NBR_DATA_POINTS_PER_BUFFER_INT][abs_idx % NBR_DATA_POINTS_PER_BUFFER_INT] = unpacked_values[abs_idx]

		    # write-back sub-list
		    data[mmap_file_index] = this_data
		    

		    ''' original version.
		    # these next few lines are responsible for 90% of the time spent in this function.
		    # 0.4974s per call in debugger
		    element_values_list = list(splitIterator(all_values_string, MMAP_BYTES_PER_FLOAT))
		    for abs_element_index in range(nbr_elements):
		        this_element = element_values_list[abs_element_index]
		        this_element = unpack('d', this_element)[0]
		        buffer_nbr = abs_element_index / NBR_DATA_POINTS_PER_BUFFER_INT
		        index_in_buffer = abs_element_index % NBR_DATA_POINTS_PER_BUFFER_INT
		        data[mmap_file_index][buffer_nbr][index_in_buffer] = this_element
		    '''


		    ''' useless alternatives

		    # even worse: -> ~ 0.0063 secs per call
		    unpacked_values = [unpack('d', element_values_list[j])[0] for j in range(nbr_elements)]
		    # worst: ~0.0160 secs per call
		    buffer_ids = np.arange(nbr_elements) / NBR_DATA_POINTS_PER_BUFFER_INT
		    index_in_buffer_id = np.arange(nbr_elements) % NBR_DATA_POINTS_PER_BUFFER_INT
		    
		    for abs_element_index in range(nbr_elements):
		        data[mmap_file_index][buffer_ids[abs_element_index]][index_in_buffer_id[abs_element_index]] = unpacked_values[abs_element_index]
		    '''

		#t1 = time()
		#print 'get_data_from_mmap() takes %f seconds' %(t1-t0)  			

		# go to beginning of memory mapped area and overwrite first value with
		# ACK string so that the sender knows that it is safe to overwrite the 
		# previous data (== send new data). 
		for mmap_file_index in range_nbr_mmap_files:
		    mmap_data[mmap_file_index].seek(0)
		    mmap_data[mmap_file_index].write(DATA_RECEIVED_ACK_STR)   

		# overwrite the 'number of buffers received' field with zero, so that we don't
		# keep reading in this very same data.
		self.mmap_stats_go_to_nbr_received_buffers_pos(mmap_stats)
		mmap_stats.write(NBR_BUFFERS_ZERO_STR)

		return data


	@profile_code(PROFILE)
	def get_nbr_received_buffers_from_mmap(self, mmap_stats):
		# go to position where 'number of new buffers' is stored
		self.mmap_stats_go_to_nbr_received_buffers_pos(mmap_stats)
		# read-in the string value
		nbr_buffers_received = mmap_stats.read(self.MMAP_BYTES_PER_FLOAT)
		# convert into decimal value
		nbr_buffers_received = unpack('d', nbr_buffers_received)[0]
		# debugging:
		#print str(nbr_buffers_received) + ' number buffers received'
		return nbr_buffers_received


	@profile_code(PROFILE)
	def mmap_stats_go_to_nbr_received_buffers_pos(self, mmap_stats):
		# go to 2nd position relative to 0.    
		mmap_stats.seek(self.MMAP_BYTES_PER_FLOAT * 2, 0) 


	@profile_code(PROFILE)
	def update_data_stream_status(self, data):

		# check if new data has arrived and tell user
		# we only check for the first data stream - I'm assuming here that either 
		# all channels or no channels with fail.
		nbr_mmap_files = 0
		buffer_to_check = 0
		current_sum = sum(data[nbr_mmap_files][buffer_to_check])
		if current_sum == self.prev_sum:
		    if self.prev_sum == 0:
		        # indicate zero state only once
		        if not self.MMAP_NO_DATA_INDICATE_ZERO:
		            print datetime.now(), ' - No new data received (sum(data) == zero)'
		            self.MMAP_NO_DATA_INDICATE_ZERO = True
		    else:
		        if not self.MMAP_NO_DATA_INDICATE_NON_ZERO:
		            print datetime.now(), ' - No new data received (sum(data) != zero)'
		            self.MMAP_NO_DATA_INDICATE_NON_ZERO = True
		else:
		    if self.MMAP_NO_DATA_INDICATE_ZERO:
		        self.MMAP_NO_DATA_INDICATE_ZERO = False
		        print datetime.now(), ' - New data received!'
		    if self.MMAP_NO_DATA_INDICATE_NON_ZERO:
		        self.MMAP_NO_DATA_INDICATE_NON_ZERO = False
		        print datetime.now(), ' - New data received!'            

		self.prev_sum = current_sum
		# t1 = time()
		# print 'get_data_from_mmap() takes %f seconds' %(t1-t0)     

	
	@profile_code(PROFILE)
	def create_mmap_file_on_disk(self, fname, MMAP_STORE_LENGTH = MMAP_BYTES_PER_FLOAT * 512):
		# (over-) write file
		fd = os.open(fname, os.O_CREAT | os.O_TRUNC | os.O_RDWR)
		assert os.write(fd, self.MMAP_NULL_HEX * MMAP_STORE_LENGTH)
		os.close(fd)	

	
	@profile_code(PROFILE)
	def setup_mmap(self, filenames):
		
		# matlab:
		# m = memmapfile('/tmp/bla', 'Format', 'double', 'Writable', true)
		# m.Data = sin(linspace(200, 203, 512))*100
		# m.Data = linspace(200, 300, 512);
		# t = timer('TimerFcn', 'm.Data=sin(linspace(200, 203, 512)) * rand(1)*512;', 'Period', 0.015, 'ExecutionMode', 'fixedRate');
		# start(t)
		
		mmap_data = []

		try:
		
			for i in range(len(filenames)):
		
			  fname = filenames[i]
			  # check if file exists
			  if not os.path.isfile(fname):
				  # check if directory exists
				  path_to_file = os.path.dirname(fname)
				  if not os.path.isdir(path_to_file):
				      print "Directory '" + path_to_file + "' not found - creating it."
				      os.makedirs(path_to_file)
					  
				  self.create_mmap_file_on_disk(fname)
			  
			  # initialize the memory map
			  f = open(fname, "r+b")
			  mmap_data.append(mmap.mmap(f.fileno(), 0))
			  
			  # initialize memory with default value
			  for j in range(len(mmap_data)):
				  mmap_data[i][j] = self.MMAP_NULL_HEX

		except Exception, e:
			print "Error in 'setup_mmap()': ", e
			pass
		
		return mmap_data


	@profile_code(PROFILE)
	def setup_mmap_filenames(self, TMP_DIR):
		# location of shared file(s)
		MMAP_FILENAME = []
		for j in range(self.NBR_INDEPENDENT_CHANNELS):
			MMAP_FILENAME.append(TMP_DIR + os.sep + 'bla' + str(j+1))

		MMAP_stats_file = TMP_DIR + os.sep + 'bla_stats'

		return MMAP_FILENAME, MMAP_stats_file


