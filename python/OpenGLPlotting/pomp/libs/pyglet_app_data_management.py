# data management stuff & data generation stuff

from pyglet_app_consts import DATA_RECEIVED_ACK_NUM
from pyglet_app_helper2 import setup_tmp_directory, calc_VBO_numbers
from pyglet_app_profile import profile_code, PROFILE

import numpy as np

class random_data_interface(object):

	# switch between drawing modes. all modes render ~ the same amount of data points.
	# mode = 0; few segments  -> high FPS since not many gl* calls
	# mode = 1; many segments -> low  FPS since gl* calls are executed many more times.
	MODE = 1

	# default number of channels
	NBR_INDEPENDENT_CHANNELS = 1

	# set data points per buffer. ideally this would be a per channel configuration.
	NBR_DATA_POINTS_PER_BUFFER_INT = 512

	# y scaling factors for spike and noise values.
	SPIKE_SIZE = 200
	NOISE_SIZE = 100
	# numpy's randint is exclusive, therefore we need to add one.
	NOISE_SIZE_NP = NOISE_SIZE + 1

	# generate spike every N points
	if MODE == 0:
		GENERATE_SPIKE_EVERY_N_POINTS = 10000
	elif MODE == 1:
		GENERATE_SPIKE_EVERY_N_POINTS = 128

	# where to put the 0/0 point of the data points.
	X_OFFSET_PANEL = 20
	Y_OFFSET_PANEL = 0

	def __init__(self, *args, **kwargs):
		pass

	def set_NOISE_SIZE_NP(self, value):
		self._NOISE_SIZE_NP = value

	def get_NOISE_SIZE_NP(self):
		return self.NOISE_SIZE + 1

	NOISE_SIZE_NP = property(get_NOISE_SIZE_NP, set_NOISE_SIZE_NP)


	@profile_code(PROFILE)
	def setup(self, WIN_WIDTH_DEFAULT, NBR_DATA_POINTS_PER_VBO, NBR_DATA_POINTS_PER_BUFFER, SECONDS_TO_VISUALIZE_PER_PANEL, scanrate):


		output = calc_VBO_numbers(NBR_DATA_POINTS_PER_VBO, NBR_DATA_POINTS_PER_BUFFER, SECONDS_TO_VISUALIZE_PER_PANEL, scanrate)
		self.NBR_DATA_POINTS_PER_VBO, self.NBR_VBOS_PER_PANEL, self.SECONDS_TO_VISUALIZE_PER_PANEL = output
		self.NBR_DATA_POINTS_PER_BUFFER = NBR_DATA_POINTS_PER_BUFFER

		# default X values
		X_MIN = 0
		X_MAX = float(WIN_WIDTH_DEFAULT) / (self.NBR_VBOS_PER_PANEL + 1)
		# print X_MAX

		# shift each VBO by how much in X & Y direction, relative to the previous VBO?
		self.SHIFT_Y_BY = 0
		self.SHIFT_X_BY = abs(X_MIN) + abs(X_MAX)

		# while generating the fake data, what is the stepsize between individual x data 
		# points?
		self.STEPSIZE_X = float(self.SHIFT_X_BY) / self.NBR_DATA_POINTS_PER_VBO

		# how much distance do 'NBR_DATA_POINTS_PER_BUFFER' points cover in x direction?
		self.SHIFT_X_SINGLE_BUFFER = self.STEPSIZE_X * self.NBR_DATA_POINTS_PER_BUFFER


	@profile_code(PROFILE)
	def calc_x_values_single_buffer(self):
		x_values = np.arange(0, self.SHIFT_X_SINGLE_BUFFER, self.STEPSIZE_X)
		return x_values


	@profile_code(PROFILE)
	def generate_numbers_for_x_vector(self, x, zeros = False):
		
		nbr_elements = len(x)
		
		if zeros: # generate zeros
		    # TODO: check whether we need to add offset (Y_OFFSET_PANEL + 1)
		    y = np.zeros(nbr_elements)# + Y_OFFSET_PANEL + 1
		
		else: # generate random values.
		    # generate a vector of random numbers in range [0, 1] 
		    # y = [random.random() for i in range(nbr_elements)]
		    y = np.random.random(nbr_elements)
		
		    # generate a scaling vector of random numbers in range [1, NOISE_SIZE]
		    # this vector will scale each data point
		    # y_scale = [random.randint(1, NOISE_SIZE) for i in range(nbr_elements)]
		    y_scale = np.random.randint(1, self.NOISE_SIZE_NP, nbr_elements)
		
		    # generate a spike every 'GENERATE_SPIKE_EVERY_N_POINTS' data points
		    # generate an intial offset so that spikes don't occur at same position.
		    y_scale_offset = np.random.randint(1, self.GENERATE_SPIKE_EVERY_N_POINTS)
		    y_scale[self.GENERATE_SPIKE_EVERY_N_POINTS - 1 + y_scale_offset::self.GENERATE_SPIKE_EVERY_N_POINTS] = self.SPIKE_SIZE
		
		    # rescale each data point accordingly
		    y = (y * y_scale) + self.SHIFT_Y_BY + self.Y_OFFSET_PANEL
		
		return y


''' helper functions independent of object '''

@profile_code(PROFILE)
def append_data_to_plot_queue(plot_queue, new_data, nbr_buffers_per_mmap_file):
    
    # reformat data so that the buffers from 'j' mmap files
    # are paired together.
    for j in range(int(min(nbr_buffers_per_mmap_file))):
        data_to_add = []
        for k in range(len(new_data)):
            data_to_add.append(new_data[k][j])
        
        # append 'data_to_add' to end (right side) of queue
        plot_queue.append(data_to_add)


@profile_code(PROFILE)
def setup_plotting_queue():
	return setup_queue(max_nbr_buffers = 20000)


@profile_code(PROFILE)
def setup_queue(max_nbr_buffers = 20000):
    # setup plotting queue
    import collections
    plot_queue = collections.deque([], max_nbr_buffers)
    return plot_queue


@profile_code(PROFILE)
def create_empty_data_buffer(nbr_mmap_files, zeros, nbr_buffers = 1):
    # pre-allocate each buffer
    buffers = []
    for buffer_index in xrange(nbr_buffers):
        # create deep copy of zeros, otherwise we create multiple references to 
        # the same object.
        zeros_copy = zeros.copy()
        buffers.append(zeros_copy)

    data = []
    for mmap_file_index in xrange(nbr_mmap_files):
        # put data into zero-th buffer
        data.append(buffers)

    return data

'''
def update_vbo_with_data_from_plot_queue():
    global x_shift_current, x_shift_single_buffer_current
    global pointer_shift
    global vbos, colors
    global c_vbo # counter needed for VBO positioning
    global pointer_offset, nbr_points_rendered_in_last_vbo
	
    for j in xrange(NBR_BUFFERS_TO_UPDATE):
		# grab 'raw_data' from beginning of plot queue.
		raw_data = get_data_from_plot_queue()
		data = transform_vector_of_buffers_to_GPU_format(raw_data, x_shift_single_buffer_current)

		### VBO POSITIONING
		pos_to_overwrite = c_vbo % (NBR_DATA_POINTS_PER_VBO / NBR_DATA_POINTS_PER_BUFFER)
		nbr_points_rendered_in_last_vbo = int(NBR_DATA_POINTS_PER_BUFFER * pos_to_overwrite)

		# at which location in the memory (in bytes) of the VBO should we replace the data?
		# also needed for plotting.
		pointer_offset = nbr_points_rendered_in_last_vbo * BYTES_PER_POINT

		nbr_data_streams = len(data)
		for panel in range(NBR_PANELS):
			update_line_segment_on_GPU(vbos[panel][-1], pointer_offset, data[panel % nbr_data_streams])

		c_vbo += 1
		x_shift_single_buffer_current += SHIFT_X_SINGLE_BUFFER
		pointer_shift += NBR_DATA_POINTS_PER_BUFFER    

		# check whether we reached the end of the VBO and thus need to rotate it.
		if pointer_shift == NBR_DATA_POINTS_PER_VBO:
			pointer_shift, pointer_offset, x_shift_current, vbos, colors, c_vbo = rotate_vbos_clear_last_vbo(pointer_shift, pointer_offset, x_shift_current, vbos, colors, c_vbo)
'''           


@profile_code(PROFILE)
def get_data_from_plot_queue(plot_queue):
    # remove & return left most element from queue
    data = []
    if len(plot_queue) > 0:
        data = plot_queue.popleft()
    return data	


@profile_code(PROFILE)
def request_new_data(USE_MMAP, RANDOM_DATA, MMAP):
    ''' generates new raw data or grabs new data from MMAP '''
    
    if USE_MMAP == 1:
        new_data = MMAP.get_data_from_mmap(MMAP.mmap_stats, MMAP.mmap_data)
        # MMAP.update_data_stream_status(new_data)
        # print new_data
    else:
        new_data = []
        # get the x-spacing right
        x_values = RANDOM_DATA.calc_x_values_single_buffer()
        for j in xrange(RANDOM_DATA.NBR_INDEPENDENT_CHANNELS):
            # put data into zero-th buffer
            new_data.append([RANDOM_DATA.generate_numbers_for_x_vector(x_values)])

    nbr_mmap_files = len(new_data)
    nbr_buffers_per_mmap_file = np.zeros(nbr_mmap_files)
    empty_data = np.zeros(nbr_mmap_files)    
    for j in range(nbr_mmap_files):
    
        # update number of buffers in this 'file'. Will fail
        # if len(new_data) != NBR_INDEPENDENT_CHANNELS
        try:
            nbr_buffers_per_mmap_file[j] = len(new_data[j])
        except:
            continue
        
        # check whether the first buffer of the current mmap file is empty
        sum_data = sum(new_data[j][0])
        if sum_data == 0 or sum_data == DATA_RECEIVED_ACK_NUM:
            empty_data[j] = 1
            
    # print empty_data
    return new_data, empty_data, nbr_buffers_per_mmap_file


@profile_code(PROFILE)
def setup_incoming_data_interface(USE_MMAP, PLUGIN_NAME, NBR_CHANNELS, nPointsToUpdate, nPoints, WINDOW_WIDTH_CURRENT, WINDOW_HEIGHT_CURRENT):

	status = True
	MMAP = False
	RANDOM_DATA = False

	''' setup mmap interface '''
	if USE_MMAP == 1:
		TMP_DIR = setup_tmp_directory(PLUGIN_NAME)

		# initialize mmap interface
		from pyglet_app_mmap_helper import mmap_interface
		MMAP = mmap_interface()

		# configure parameters
		MMAP.NBR_INDEPENDENT_CHANNELS = NBR_CHANNELS
		MMAP.NBR_DATA_POINTS_PER_BUFFER_INT = nPointsToUpdate
		MMAP.TMP_DIR = TMP_DIR

		# setup everything
		MMAP.setup()

		if not MMAP.INITIALIZED:
			status = False

	else:
		''' setup data interface '''
		RANDOM_DATA = random_data_interface()
		RANDOM_DATA.NBR_INDEPENDENT_CHANNELS = NBR_CHANNELS

		nbr_data_points_per_vbo = nPoints
		nbr_data_points_per_buffer = nPointsToUpdate
		seconds_to_visualize_per_panel = 1
		scanrate = 1

		RANDOM_DATA.setup(WINDOW_WIDTH_CURRENT, nbr_data_points_per_vbo, nbr_data_points_per_buffer, seconds_to_visualize_per_panel, scanrate)

		# overwrite the size of the noise and spike levels to match the current window size
		RANDOM_DATA.SPIKE_SIZE = 0.8 * WINDOW_HEIGHT_CURRENT
		RANDOM_DATA.NOISE_SIZE = 0.2 * WINDOW_HEIGHT_CURRENT


	return status, MMAP, RANDOM_DATA


