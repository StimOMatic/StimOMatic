import pyglet
from pyglet.gl import *
from ctypes import pointer, sizeof
import numpy as np
import random
from time import time
from math import ceil, floor


''' mmap stuff '''
import os, sys
import mmap
from datetime import datetime
from struct import unpack, pack


DO_PROFILE = False

################## dependent parameters / settings

''' decorator to quickly switch between profiling and no profiling '''
def do_profile(cond):
    def resdec(f):
        if not cond:
            return f
        return profile(f)
    return resdec


@do_profile(DO_PROFILE)
def generate_line_segment_zeros(x_shift=SHIFT_X_BY, min_x=X_MIN, max_x=X_MAX, step_size=STEPSIZE_X):
    ''' same as 'generate_line_segment' but will generate zero y-values '''

    zeros = True
    x, y = generate_points(min_x, max_x, x_shift, step_size, zeros)
    return create_2dim_list_from_arrays(x, y)


@do_profile(DO_PROFILE)
def generate_line_segment(x_shift=SHIFT_X_BY, min_x=X_MIN, max_x=X_MAX, step_size=STEPSIZE_X):
# ~ 1ms
    x, y = generate_points(min_x, max_x, x_shift, step_size)
    return create_2dim_list_from_arrays(x, y)
    

@do_profile(DO_PROFILE)
def generate_numbers_for_x_vector(x, zeros = False):
    
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
        y_scale = np.random.randint(1, NOISE_SIZE_NP, nbr_elements)
    
        # generate a spike every 'GENERATE_SPIKE_EVERY_N_POINTS' data points
        # generate an intial offset so that spikes don't occur at same position.
        y_scale_offset = np.random.randint(1, GENERATE_SPIKE_EVERY_N_POINTS)
        y_scale[GENERATE_SPIKE_EVERY_N_POINTS - 1 + y_scale_offset::GENERATE_SPIKE_EVERY_N_POINTS] = SPIKE_SIZE
    
        # rescale each data point accordingly
        y = (y * y_scale) + SHIFT_Y_BY + Y_OFFSET_PANEL
    
    return y
        

@do_profile(DO_PROFILE)
def generate_points(min_x=X_MIN, max_x=X_MAX, x_shift=SHIFT_X_BY, step_size = STEPSIZE_X, zeros = False):
# < 0.1ms

    # 'range' can only generate integer arrays
    # x = np.array(range(min_x, max_x), int)
    # use 'arrange' from numpy to generate a float array
    x = np.arange(min_x, max_x, step_size)
    x = x + x_shift

    y = generate_numbers_for_x_vector(x, zeros)

    return x, y


@do_profile(DO_PROFILE)
def create_2dim_list_from_arrays(x, y):
    
    data = []
    for i, j in zip(x, y):
        data.extend([i, j])
        
    return data
    

@do_profile(DO_PROFILE)
def transform_line_points_to_data_format_for_GPU(line_points):
# ~ 0.2ms
    #print "nbr data points generated: " + str(len(line_points) / 2)
    return (GLfloat*len(line_points))(*line_points)


@do_profile(DO_PROFILE)
def generate_color_for_segment():
# < 0.1ms
    # generate well visible (not too dark) colors
    if not USE_UNIFORM_COLOR:
        while True:
            color = [random.random() for j in xrange(0, 3)]
            if sum(color) > 0.5:
                break
    else:
        color = [1, 0, 0]

    return color


@do_profile(DO_PROFILE)
def create_VBO():
# < 0.1ms

    vbo_id = GLuint()
    
    # generates 1 buffer object names, which are stored in pointer(vbo_id)
    glGenBuffers(1, pointer(vbo_id))

    return vbo_id


@do_profile(DO_PROFILE)
def create_VBO_send_data_to_VBO(data):
# < 0.1ms

    vbo_id = create_VBO()
    send_data_to_VBO(vbo_id, data)

    return vbo_id


@do_profile(DO_PROFILE)
def send_data_to_VBO(vbo_id, data):
# < 0.1ms

    # binds the named buffer object
    glBindBuffer(GL_ARRAY_BUFFER, vbo_id)

    # creates and initializes a buffer object's data store -> transfers data 
    # from the CPU to the GPU.
    # TODO: check whether GL_DYNAMIC_DRAW or GL_STREAM_DRAW is faster.
    # GL_STREAM_DRAW should be faster when updating the buffer @ every frame?
    # see redbook page 95 & 96.
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_DYNAMIC_DRAW)


@do_profile(DO_PROFILE)
def overwrite_line_segment_on_GPU(x_shift=SHIFT_X_BY, line_points=False, vbo_to_update=False):
# ~ 0.3ms
    if not vbo_to_update:
        print "!! no vbo pointer found - aborting !!"
        print "update_counter: %d " % update_counter
        return

    if not line_points:
        if DEBUG:
            print "overwrite_line_segment_on_GPU: need to generate points"
        line_points = generate_line_segment(x_shift)

    data = transform_line_points_to_data_format_for_GPU(line_points)
    color = generate_color_for_segment()
    nbr_points = len(line_points)/2

    # update data on VBO
    send_data_to_VBO(vbo_to_update, data)

    return nbr_points, color


@do_profile(DO_PROFILE)
def create_vbos(NBR_PANELS, NBR_VBOS_PER_PANEL):

    vbos = [ [None] * int(NBR_VBOS_PER_PANEL) for i in xrange(NBR_PANELS) ]
    
    for panel in range(NBR_PANELS):
        for vbo in range(NBR_VBOS_PER_PANEL):
            vbos[panel][vbo] = create_VBO()

    return vbos


@do_profile(DO_PROFILE)
def create_initial_data(nPanels, nVbosPerPanel, nDataPointsPerVbo):

    data = [ [None] * int(nVbosPerPanel) for i in xrange(nPanels) ]
    
    for panel in range(nPanels):
        for vbo in range(nVbosPerPanel):
            curr_x_offset = (vbo * SHIFT_X_BY) + X_OFFSET_PANEL
            #print "vbo %d, offset %d " % (vbo, curr_x_offset)
            
            if (vbo + 1) == nVbosPerPanel:
                tmp = generate_line_segment_zeros(x_shift=curr_x_offset)
            else:
                tmp = generate_line_segment(x_shift=curr_x_offset)
                
            data[panel][vbo] = transform_line_points_to_data_format_for_GPU(tmp)
    
    return data, curr_x_offset


@do_profile(DO_PROFILE)
def create_initial_colors(nPanels, nVbosPerPanel):

    colors = [ [None] * int(nVbosPerPanel) for i in xrange(nPanels) ]
    
    for panel in range(nPanels):
        for vbo in range(nVbosPerPanel):
            colors[panel][vbo] = generate_color_for_segment()
    
    return colors


@do_profile(DO_PROFILE)
def initialize_vbos_with_start_data(NBR_PANELS, NBR_VBOS_PER_PANEL, vbos, data):
    
    for panel in range(NBR_PANELS):
        for vbo in range(NBR_VBOS_PER_PANEL):
            send_data_to_VBO(vbos[panel][vbo], data[panel][vbo])


@do_profile(DO_PROFILE)
def setup_vbo_stuff(NBR_PANELS, NBR_VBOS_PER_PANEL, NBR_DATA_POINTS_PER_VBO):
    
    t0 = time()
    
    vbos = create_vbos(NBR_PANELS, NBR_VBOS_PER_PANEL)
    data, curr_x_offset = create_initial_data(NBR_PANELS, NBR_VBOS_PER_PANEL, NBR_DATA_POINTS_PER_VBO)
    initialize_vbos_with_start_data(NBR_PANELS, NBR_VBOS_PER_PANEL, vbos, data)
    colors = create_initial_colors(NBR_PANELS, NBR_VBOS_PER_PANEL)
    
    print 'initial setup time was %f seconds.' %(time() - t0)
    
    return vbos, colors, curr_x_offset

    
def setup_plotting_queue():
    # setup plotting queue
    import collections
    max_nbr_buffers = 20000
    plot_queue = collections.deque([], max_nbr_buffers)
    return plot_queue    
    

@do_profile(DO_PROFILE)
def update_line_segment_on_GPU(vbo_id, pointer_offset, data):
    
    # bind buffer and overwrite position with offset 'pos_to_overwrite*BYTES_PER_POINT'
    #try:
    glBindBuffer(GL_ARRAY_BUFFER, vbo_id)
    glBufferSubData(GL_ARRAY_BUFFER, pointer_offset, sizeof(data), data)
    #except:
        #print "pointer_offset: ", pointer_offset
        #print "sizeof(data): ", sizeof(data)
        #pass


@do_profile(DO_PROFILE)
def calc_x_values_single_buffer():
    x_values = np.arange(0, SHIFT_X_SINGLE_BUFFER, STEPSIZE_X)
    return x_values

	
@do_profile(DO_PROFILE)
def append_data_to_plot_queue(new_data, nbr_buffers_per_mmap_file):
    
    # reformat data so that the buffers from 'j' mmap files
    # are paired together.
    for j in range(int(min(nbr_buffers_per_mmap_file))):
        data_to_add = []
        for k in range(len(new_data)):
            data_to_add.append(new_data[k][j])
        
        # append 'data_to_add' to end (right side) of queue
        plot_queue.append(data_to_add)

	
@do_profile(DO_PROFILE)
def get_data_from_plot_queue():
    # remove & return left most element from queue
    data = []
    if len(plot_queue) > 0:
        data = plot_queue.popleft()
    return data

    
@do_profile(DO_PROFILE)
def request_new_data():
    ''' generates new raw data or grabs new data from MMAP '''
    
    if USE_MMAP == 1:
        new_data = get_data_from_mmap()
        #update_data_stream_status(new_data)
        #print new_data
    else:
        new_data = []
        # get the x-spacing right
        x_values = calc_x_values_single_buffer()
        for j in xrange(NBR_INDEPENDENT_CHANNELS):
            # put data into zero-th buffer
            new_data.append([generate_numbers_for_x_vector(x_values)])

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
            

def transform_vector_of_buffers_to_GPU_format(raw_data, x_shift_single_buffer_current):
    
    # calc correct x_value
    x_values = calc_x_values_single_buffer() + x_shift_single_buffer_current

    nbr_mmap_files = len(raw_data)
    
    data = []
    for j in range(nbr_mmap_files):
        line_points = create_2dim_list_from_arrays(x_values, raw_data[j])
        data.append(transform_line_points_to_data_format_for_GPU(line_points))

    return data


def mmap_stats_go_to_nbr_received_buffers_pos():
    # go to 2nd position relative to 0.    
    mmap_stats.seek(MMAP_BYTES_PER_FLOAT * 2, 0) 

    
@do_profile(DO_PROFILE)
def get_nbr_received_buffers_from_mmap():
    # go to position where 'number of new buffers' is stored
    mmap_stats_go_to_nbr_received_buffers_pos()
    # read-in the string value
    nbr_buffers_received = mmap_stats.read(MMAP_BYTES_PER_FLOAT)
    # convert into decimal value
    nbr_buffers_received = unpack('d', nbr_buffers_received)[0]
    # debugging:
    #print str(nbr_buffers_received) + ' number buffers received'
    return nbr_buffers_received
   

def create_empty_data_buffer(nbr_mmap_files, zeros, nbr_buffers = 1):
    # pre-allocate each buffer
    buffers = []
    for buffer_index in xrange(nbr_buffers):
        # create deep copy of zeros, otherwise we create multiple references to 
        # the same object.
        zeros_copy = zeros.copy()
        buffers.append(zeros)

    data = []
    for mmap_file_index in xrange(nbr_mmap_files):
        # put data into zero-th buffer
        data.append(buffers)

    return data

	
@do_profile(DO_PROFILE)
def splitIterator(text, size):
    # assert size > 0, "size should be > 0"
    for start in range(0, len(text), size):
        yield text[start:start + size]

		
@do_profile(DO_PROFILE)
def get_data_from_mmap():
    # 
    #t0 = time()    
    
    nbr_buffers_received = get_nbr_received_buffers_from_mmap()

    nbr_mmap_files = len(mmap_data)
    zeros = np.zeros(NBR_DATA_POINTS_PER_BUFFER_INT)
    
    ''' no new buffers - generate one empty dummy buffer and return '''
    if nbr_buffers_received == 0 or nbr_buffers_received == -1:
        return create_empty_data_buffer(nbr_mmap_files, zeros)


    nbr_buffers_received = int(nbr_buffers_received)
    nbr_elements = nbr_buffers_received * NBR_DATA_POINTS_PER_BUFFER_INT
    range_nbr_mmap_files = range(nbr_mmap_files)

    # check if there's any data that's ready for pickup.
    new_data_found = np.zeros(nbr_mmap_files)
    for mmap_file_index in range_nbr_mmap_files:
	# go to beginning of memory mapped area 
        mmap_data[mmap_file_index].seek(0)
        
        # quit right away if no new data has been written yet.
        this_element = mmap_data[mmap_file_index].read(MMAP_BYTES_PER_FLOAT)
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
        all_values_string = mmap_data[mmap_file_index].read(nbr_elements * MMAP_BYTES_PER_FLOAT)

        # 0.1632 per call in debugger
        # grab sub-list so we avoid having to call this list by its index.
        this_data = data[mmap_file_index]

        # unpack all values at once
        unpacked_values = unpack("d" * nbr_elements, all_values_string)

        # using list comprehension is better than a regular loop with random array access
        this_data = [unpacked_values[i:i+NBR_DATA_POINTS_PER_BUFFER_INT] for i in xrange(0, nbr_elements, NBR_DATA_POINTS_PER_BUFFER_INT)]
        
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
    mmap_stats_go_to_nbr_received_buffers_pos()
    mmap_stats.write(NBR_BUFFERS_ZERO_STR)

    return data

	
@do_profile(DO_PROFILE)
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
           
	
	
	
@do_profile(DO_PROFILE)
def rotate_vbos_clear_last_vbo(pointer_shift, pointer_offset, x_shift_current, vbos, colors, c_vbo):
	# reset pointer offsets / shifts
	# TODO: clean up and clarify 'pointer_shift' vs 'pointer_offset'!
	pointer_shift = 0
	pointer_offset = 0
	c_vbo = 0

	x_shift_current += SHIFT_X_BY
	
	''' this is not fast enough and will lead to jitter effects
	
	# generate new data set for each panel
	tmp_points = [ [None] for j in range(NBR_PANELS)]
	for panel in range(NBR_PANELS):
		tmp_points_panel = generate_line_segment_zeros(x_shift=x_shift_current)
		tmp_points[panel] = transform_line_points_to_data_format_for_GPU(tmp_points_panel)
		
	'''
	for panel in range(NBR_PANELS):
		
		this_vbo = vbos[panel][0]
		this_color = colors[panel][0]
		
		# Delete current vbo and replace with new one.
		# We could just re-use the current vbo, however this might lead to 'blinking' artifacts
		# with the first VBO (probably because of incorrect referencing).
		# By deleting the VBO, we make sure that this VBO is not being used for plotting.
		glDeleteBuffers(1, pointer(this_vbo))
		this_vbo = create_VBO()
		# bind VBO and allocate memory.
		glBindBuffer(GL_ARRAY_BUFFER, this_vbo)
		glBufferData(GL_ARRAY_BUFFER, n_COORDINATES_PER_VERTEX * NBR_DATA_POINTS_PER_VBO * BYTES_PER_POINT, None, GL_DYNAMIC_DRAW)
		
		# vbo pointer & color from arrays
		vbos[panel] = vbos[panel][1:]
		colors[panel] = colors[panel][1:]

		# add color and pointer to VBO
		vbos[panel].append(this_vbo)
		colors[panel].append(this_color)
	
	return pointer_shift, pointer_offset, x_shift_current, vbos, colors, c_vbo

	
prev_sum = 0
MMAP_NO_DATA_INDICATE_ZERO = False
MMAP_NO_DATA_INDICATE_NON_ZERO = True	
@do_profile(DO_PROFILE)
def update_data_stream_status(data):

    global prev_sum, MMAP_NO_DATA_INDICATE_ZERO, MMAP_NO_DATA_INDICATE_NON_ZERO

    # check if new data has arrived and tell user
    # we only check for the first data stream - I'm assuming here that either 
    # all channels or no channels with fail.
    nbr_mmap_files = 0
    buffer_to_check = 0
    current_sum = sum(data[nbr_mmap_files][buffer_to_check])
    if current_sum == prev_sum:
        if prev_sum == 0:
            # indicate zero state only once
            if not MMAP_NO_DATA_INDICATE_ZERO:
                print datetime.now(), ' - No new data received (sum(data) == zero)'
                MMAP_NO_DATA_INDICATE_ZERO = True
        else:
            if not MMAP_NO_DATA_INDICATE_NON_ZERO:
                print datetime.now(), ' - No new data received (sum(data) != zero)'
                MMAP_NO_DATA_INDICATE_NON_ZERO = True
    else:
        if MMAP_NO_DATA_INDICATE_ZERO:
            MMAP_NO_DATA_INDICATE_ZERO = False
            print datetime.now(), ' - New data received!'
        if MMAP_NO_DATA_INDICATE_NON_ZERO:
            MMAP_NO_DATA_INDICATE_NON_ZERO = False
            print datetime.now(), ' - New data received!'            

    prev_sum = current_sum
    # t1 = time()
    # print 'get_data_from_mmap() takes %f seconds' %(t1-t0)     

	
@do_profile(DO_PROFILE)
def create_mmap_file_on_disk(fname):
	# (over-) write file
	fd = os.open(fname, os.O_CREAT | os.O_TRUNC | os.O_RDWR)
	assert os.write(fd, MMAP_NULL_HEX * MMAP_STORE_LENGTH)
	os.close(fd)	

	
@do_profile(DO_PROFILE)
def setup_mmap(filenames):
    
    # matlab:
    # m = memmapfile('/tmp/bla', 'Format', 'double', 'Writable', true)
    # m.Data = sin(linspace(200, 203, 512))*100
    # m.Data = linspace(200, 300, 512);
    # t = timer('TimerFcn', 'm.Data=sin(linspace(200, 203, 512)) * rand(1)*512;', 'Period', 0.015, 'ExecutionMode', 'fixedRate');
    # start(t)
    
    mmap_false = False
    mmap_data = []
    
    for i in range(len(filenames)):
    
      fname = filenames[i]
      # check if file exists
      if not os.path.isfile(fname):
          # check if directory exists
          path_to_file = os.path.dirname(fname)
          if not os.path.isdir(path_to_file):
              print "Directory '" + path_to_file + "' not found - creating it."
              os.makedirs(path_to_file)
			  
          create_mmap_file_on_disk(fname)
      
      # initialize the memory map
      f = open(fname, "r+b")
      mmap_data.append(mmap.mmap(f.fileno(), 0))
      
      # initialize memory with default value
      for j in range(len(mmap_data)):
          mmap_data[i][j] = MMAP_NULL_HEX
    
    return mmap_data


##################### MAIN #####################################################

# animation is enabled by default. you can pause / resume it by pressing 'a'
DO_ANIMATE = True
DO_NEXT_STEP = False
