'''

TODO (29.05.2012):
 1) show 1x, 2x, 3x threshold (as line)
 2) auto scale in y axis? (calc and save min & max values of buffer)
 3) draw y axis?
 4) 'max_nbr_buffers_transmitted' must be 1 and 'framesize' must be 512 otherwise we get in trouble in RT mode.
 5) set 'SHIFT_VIEW' in update() and dequeue in 'do_draw'? does this get rid of the shift / lag? --> IT DOES NOT! 
 6) how do I connect points across VBOs? currently only points inside a VBO are connected.
 7) make code modular so that I don't have keep to versions up-to-date.


0) WINDOWS only:
   A) if you are planning to run this program on Windows (32bit and 64 bit), make 
      sure to install python 32bit - 64bit python on Windows won't work with pyglet!

   B) install 32bit installer of 'setuptools' http://pypi.python.org/pypi/setuptools 

   C) $ cd c:\python27\Scripts
      $ easy_install numpy

   D) set the nvidia driver 3D settings to 'performance' if you want highest FPS

1) you need to install a recent version of pyglet to run this program:

 $ hg clone https://pyglet.googlecode.com/hg/ pyglet
 $ sudo python setup.py install
 
 # on windows do:
 # d:
 # cd d:\code\pyglet
 # c:\Python27\python.exe setup.py install

2) you also need numpy to be installed; on ubuntu do:
   $ sudo apt-get install python-numpy

3) Ubuntu / Linux only: in case this applications freezes make sure the following 
   points are met:
   - Nvidia driver 280.13; I had lots of problems with version 290 & 295
   - latest pyglet dev version is installed (see point 1). I tried both pyglet-1.1.2 and 
     pyglet-1.1.4 that come with ubuntu but I get very poor performance.

4) check remaining 'TODO' sections

Profiling) 

    A) per function
    $ python -m cProfile pyglet_vbo_test7.py

    B) per line
    $ sudo /usr/bin/easy_install line_profiler

    # add decorator '@profile' in front of each function
    $ kernprof.py  -l pyglet_vbo_test7.py
    $ python /usr/local/lib/python2.7/dist-packages/line_profiler-1.0b3-py2.7-linux-x86_64.egg/line_profiler.py pyglet_vbo_test7.py.lprof  > prof.txt
    $ python /usr/local/lib/python2.7/dist-packages/RunSnakeRun-2.0.2a1-py2.7.egg/runsnakerun/runsnake.py prof.txt

    C) with runsnakerun GUI - not compatible with method B) 
    $ sudo /usr/bin/easy_install RunSnakeRun
    $ python -m cProfile -o pyglet_vbo_test7.profile pyglet_vbo_test7.py
    $ python /usr/local/lib/python2.7/dist-packages/RunSnakeRun-2.0.2a1-py2.7.egg/runsnakerun/runsnake.py pyglet_vbo_test7.profile

'''


''' turn on debugger if necessary
import pdb
pdb.set_trace()
'''

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

# switch between drawing modes. all modes render ~ the same amount of data points.
# mode = 0; few segments  -> high FPS since not many gl* calls
# mode = 1; many segments -> low  FPS since gl* calls are executed many more times.
MODE = 1

# default window dimensions
WIN_HEIGHT_DEFAULT = 800
WIN_WIDTH_DEFAULT = 800

# 512 is neuralynx specific.
NBR_DATA_POINTS_PER_BUFFER = 1.0
NBR_DATA_POINTS_PER_BUFFER_INT = int(NBR_DATA_POINTS_PER_BUFFER)
SCANRATE = 1
SECONDS_TO_VISUALIZE_PER_PANEL = 1.0

# approximate number of data point per VBO. will change and be adjusted so that 
# this number is a multiple of NBR_DATA_POINTS_PER_BUFFER
NBR_DATA_POINTS_PER_VBO = 200

# how many times per second should we call the update function?
#CALL_UPDATE_X_TIMES_PER_SECOND = 67.0
# TODO: check what a reasonable value for 'CALL_UPDATE_X_TIMES_PER_SECOND' is.
# going from 67.0 to 60.0 gives me a huge performance improvement.
CALL_UPDATE_X_TIMES_PER_SECOND = 60.0

# into how many data panels should we split up the window?
NBR_PANELS = 1

# use same color for all segments?
USE_UNIFORM_COLOR = True
# default color to be used by 'USE_UNIFORM_COLOR'
DEFAULT_COLOR = [1, 0, 0]

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
Y_OFFSET_PANEL = 200

# update counter used to determine when to generate a new segment of data.
update_counter = 1;
SHIFT_VIEW = False

# enable debug 'print' statements?
DEBUG = 0

# number of independent data streams? 
# e.g., 'StimOMatic' feeds in one spike and one LFP channel
NBR_INDEPENDENT_CHANNELS = 2 

# should we use multiprocessing if possible? this might speed things up.
USE_MULTIPROCESSING = False
MULTIPROCESSING_NBR_PROCESSES = 12


DO_PROFILE = False


PLUGIN_NAME = 'pCtrlLFP'

# where's your temporary directory? mmap will write into it.
TMP_DIR = '/tmp'
if os.name == 'nt': # windows systems
    # make sure you use double '\\' to separate directories 
    TMP_DIR = 'c:\\temp'
else: # unix systems
    TMP_DIR = '/tmp'

TMP_DIR = TMP_DIR + os.sep + PLUGIN_NAME

# should we use mmap to receive data from matlab?
USE_MMAP = 1
MMAP_BYTES_PER_FLOAT = 8

MMAP_stats_file = TMP_DIR + os.sep + 'bla_stats'

# location of shared file(s)
MMAP_FILENAME = []
for j in range(NBR_INDEPENDENT_CHANNELS):
    MMAP_FILENAME.append(TMP_DIR + os.sep + 'bla' + str(j+1))

# number of elements to store in memory
MMAP_STORE_LENGTH = MMAP_BYTES_PER_FLOAT * int(NBR_DATA_POINTS_PER_BUFFER)

# null string used to initalize memory
MMAP_NULL_HEX = '\x00'


################## function needed to calculate dependent parameters

def calc_VOB_numbers(NBR_DATA_POINTS_PER_VBO, NBR_DATA_POINTS_PER_BUFFER, SECONDS_TO_VISUALIZE_PER_PANEL):
    
    NBR_DATA_POINTS_PER_VBO = ceil(NBR_DATA_POINTS_PER_VBO / NBR_DATA_POINTS_PER_BUFFER) * NBR_DATA_POINTS_PER_BUFFER
    
    # calculate the number of VBOs that are need to display all data
    NBR_VBOS_PER_PANEL = ceil(SECONDS_TO_VISUALIZE_PER_PANEL * SCANRATE / NBR_DATA_POINTS_PER_VBO)
    
    # how many buffers of size 'NBR_DATA_POINTS_PER_BUFFER' does each panel hold?
    # NBR_BUFFERS_PER_PANEL = NBR_VBOS_PER_PANEL * NBR_DATA_POINTS_PER_VBO / NBR_DATA_POINTS_PER_BUFFER
    
    # update 'SECONDS_TO_VISUALIZE_PER_PANEL' to its true value
    SECONDS_TO_VISUALIZE_PER_PANEL = NBR_VBOS_PER_PANEL * NBR_DATA_POINTS_PER_VBO / SCANRATE
    
    # add one VBO to each panel since we want to smoothly add new data points.
    NBR_VBOS_PER_PANEL += 1
    
    return int(NBR_DATA_POINTS_PER_VBO), int(NBR_VBOS_PER_PANEL), SECONDS_TO_VISUALIZE_PER_PANEL


################## dependent parameters / settings

output = calc_VOB_numbers(NBR_DATA_POINTS_PER_VBO, NBR_DATA_POINTS_PER_BUFFER, SECONDS_TO_VISUALIZE_PER_PANEL)
NBR_DATA_POINTS_PER_VBO, NBR_VBOS_PER_PANEL, SECONDS_TO_VISUALIZE_PER_PANEL = output

# default X values
X_MIN = 0
X_MAX = float(WIN_WIDTH_DEFAULT) - X_OFFSET_PANEL

# shift each VBO by how much in X & Y direction, relative to the previous VBO?
SHIFT_Y_BY = 0
SHIFT_X_BY = abs(X_MIN) + abs(X_MAX)

# while generating the fake data, what is the stepsize between individual x data 
# points?
STEPSIZE_X = float(SHIFT_X_BY) / NBR_DATA_POINTS_PER_VBO

# how much distance do 'NBR_DATA_POINTS_PER_BUFFER' points cover in x direction?
SHIFT_X_SINGLE_BUFFER = STEPSIZE_X * NBR_DATA_POINTS_PER_BUFFER

# Definitions for 'glColorPointer' and 'glVertexPointer'
n_COORDINATES_PER_VERTEX = 2

BYTES_PER_POINT = 8

# indicator values used to confirm that data is received.
DATA_RECEIVED_ACK_NUM = 3.14159265
DATA_RECEIVED_ACK_STR = pack('d', DATA_RECEIVED_ACK_NUM)
NBR_BUFFERS_ZERO_STR = pack('d', 0)

##################

# default window dimensions
WIN_HEIGHT_current = WIN_HEIGHT_DEFAULT
WIN_WIDTH_current = WIN_WIDTH_DEFAULT

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

		
prev_sum = 0
MMAP_NO_DATA_INDICATE_ZERO = False
MMAP_NO_DATA_INDICATE_NON_ZERO = True
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


''' BEGIN setup part 1 '''

if USE_MMAP:
    # initialize MMAP
    mmap_data = setup_mmap(MMAP_FILENAME)
    if not mmap_data:
        print "Could not read mmap-file. Aborting."
        sys.exit(1)

    if not os.path.isfile(MMAP_stats_file):
        create_mmap_file_on_disk(MMAP_stats_file)

    f = open(MMAP_stats_file, "r+b")
    mmap_stats = mmap.mmap(f.fileno(), 0)

vbos, colors, x_shift_current = setup_vbo_stuff(NBR_PANELS, NBR_VBOS_PER_PANEL, NBR_DATA_POINTS_PER_VBO)
# TODO: clarify difference between 'x_shift_single_buffer_current' and 'x_shift_current'
x_shift_single_buffer_current = x_shift_current
plot_queue = setup_plotting_queue()


info_str = "%d panels; %d segments per panel; %d number of points per segment." % ( NBR_PANELS, NBR_VBOS_PER_PANEL, NBR_DATA_POINTS_PER_VBO )
print info_str

# setup window
window = pyglet.window.Window(width=WIN_WIDTH_DEFAULT, height=WIN_HEIGHT_DEFAULT, resizable=True)
window.set_caption(info_str)

# initialize FPS display
fps_display = pyglet.clock.ClockDisplay(interval=0.125, format='FPS %(fps).2f')

''' END setup part 1 '''


''' BEGIN periodic event function - check whether we need to replace a VBO '''

# variables needed while updating the VBOs
pointer_shift = 0
pointer_offset = 0
nbr_points_rendered_in_last_vbo = 0
c_vbo = 0

# definitions needed for dequeueing of plot buffers.
NBR_BUFFERS_TO_UPDATE = 1
MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE = NBR_BUFFERS_TO_UPDATE

@do_profile(DO_PROFILE)
def update(dt):
# ~ 24 ms, generating new data set for each panel
# ~ 6 ms, generating only one new data set and re-using it.
# ~ 0.4 ms, without 'generate_line_segment' and 'overwrite_line_segment_on_GPU'

    if not DO_ANIMATE:
        # quit right away if animation is disabled. Ideally we would want to still 
        # compute at least the next set of 'tmp_points', however we need to make sure that
        # 'x_shift_current' doesn't get updated more than once (or 'SHIFT_X_BY' is updated
        # accordingly).        
        return
        
    if DO_NEXT_STEP:
        raw_input('please press key to continue ')

    if DEBUG:
        print "update_counter in 'update()' %d " % update_counter
        t0 = time()        
  
    ''' START  'DATA MANAGEMENT'  '''
    # pick up new data from mmap or other system (i.e. generated)
    new_data, new_data_is_empty, nbr_buffers_per_mmap_file = request_new_data()

    # don't add empty data to the queue    
    # don't use 'NBR_INDEPENDENT_CHANNELS' here, because we might be skipping this channel
    if sum(new_data_is_empty) != len(new_data):    
        append_data_to_plot_queue(new_data, nbr_buffers_per_mmap_file)
    ''' END  'DATA MANAGEMENT'  '''


    ''' START  'dequeue enough buffers and prepare them for plotting'  '''    
    # don't purge entire queue - keep at least one element in queue.
    if len(plot_queue) < MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE:
        return	
    
	# dequeue buffers and update VBOs
    update_vbo_with_data_from_plot_queue()
    ''' END 'dequeue enough buffers and prepare them for plotting' '''
	
    # indicate that view needs to be shifted 
    global SHIFT_VIEW
    SHIFT_VIEW = True
	
    if DEBUG:
        t1 = time()
        print 'update() takes %f seconds' %(t1-t0)    


pyglet.clock.schedule_interval(update, 1.0/CALL_UPDATE_X_TIMES_PER_SECOND)
''' END periodic event function '''

from pyglet.window import key

KEYPRESS_STEPSIZE = 10
zoom = 0
currentScale = 1
@window.event
@do_profile(DO_PROFILE)
def on_key_press(symbol, modifiers):
    
    global DO_ANIMATE, DO_NEXT_STEP, KEYPRESS_STEPSIZE, zoom, currentScale
    global x_shift_single_buffer_current
    global plot_queue
    # turn animation on / off.     
    if symbol == key.A:
        DO_ANIMATE = not DO_ANIMATE
        if DO_ANIMATE:
            print 'animation on'
        else:
            print 'animation off'
    elif symbol == key.C:
        plot_queue = setup_plotting_queue()
        print "Cleared Plot-Queue"
    elif symbol == key.Q:
        print "Plot-Queue size: %d" % (len(plot_queue))
    # zero the plot along the x axis. in case of drifting, this should get the
    # back onto the screen.
    elif symbol == key.Z:
        glTranslatef(+x_shift_single_buffer_current, 0.0, 0.0)
        fps_display.label.x = fps_display.label.x - x_shift_single_buffer_current
        x_shift_single_buffer_current = 0
        x_shift_current = 0
    elif symbol == key.S:
        DO_NEXT_STEP = not DO_NEXT_STEP
    elif symbol == key.LEFT:
        glTranslatef(-KEYPRESS_STEPSIZE, 0.0, 0.0)
    elif symbol == key.RIGHT:
        glTranslatef(KEYPRESS_STEPSIZE, 0.0, 0.0)
    elif (symbol == key.PLUS or symbol == key.NUM_ADD):
        KEYPRESS_STEPSIZE += 10
        print 'step size is now %d ' % KEYPRESS_STEPSIZE
    elif (symbol == key.MINUS or symbol == key.NUM_SUBTRACT):
        KEYPRESS_STEPSIZE -= 10
        KEYPRESS_STEPSIZE = max(10, KEYPRESS_STEPSIZE)
        print 'step size is now %d ' % KEYPRESS_STEPSIZE
    else:
        print '%s key, %s modifier was pressed' % (symbol, modifiers)        
        
    ''' zooming
    elif symbol == key.Z:
        if modifiers == key.MOD_ALT + 16:
            #zoom -= 0.5;
            #glOrtho(+1.5 + zoom, 1.0 + zoom, +2.0 + zoom, 0.5 + zoom, +1.0, -3.5)
            #currentScale -= 0.1
            #glScaled(currentScale, currentScale, 1);    
        elif modifiers == key.MOD_SHIFT + 16:
            #zoom += 0.5;            
            #glOrtho(-1.5 + zoom, 1.0 - zoom, -2.0 + zoom, 0.5 - zoom, -1.0, 3.5)
            #currentScale += 0.1
            #glScaled(currentScale, currentScale, 1);
    '''

        
    ''' rotations
    elif symbol == key.PAGEDOWN:
        # we need to move objects into center, before rotating
        #glRotatef(0.5, 1, 0, 0)
        # need to move object back to original position
    elif symbol == key.PAGEUP:
        # we need to move objects into center, before rotating
        #glRotatef(-0.5, 1, 0, 0)
        # need to move object back to original position
    '''



''' 
    BEGIN 'on_resize' function - can only be defined once 'window' exists 
'''

@window.event
@do_profile(DO_PROFILE)
def on_resize(width, height):
    global WIN_HEIGHT_current, WIN_WIDTH_current
    WIN_HEIGHT_current = height
    WIN_WIDTH_current = width
    # TODO: currently we only rescale the Y dimension. Add X-Scaling!
    if DEBUG:
        print "new height %d " %(height)
        print "new width %d " %(width)

''' END 'on_resize' function - can only be defined once 'window' exists '''





''' 
    BEGIN 'draw' function - can only be defined once 'window' exists 
    The EventLoop will dispatch this event when the window should be redrawn. 
    This will happen during idle time after any window events and after any 
    scheduled functions were called. 

'''

@window.event
@do_profile(DO_PROFILE)
def on_draw():
# ~ 21ms (test6 was ~260ms)

    global SHIFT_VIEW

    # clear buffers to preset values
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    # TODO:
    # maybe we should move back to the origin and translate from there?
    # glLoadIdentity()
    # glTranslatef(-x_shift_single_buffer_current/2, 0.0, 0.0)

    if SHIFT_VIEW:
        #local_shift = (SHIFT_X_BY/CALL_UPDATE_X_TIMES_PER_SECOND)
        
        # TODO: fix 'local_shift', right now we override it to '1'
        # 'SHIFT_X_BY' needs to be an integral number, otherwise we get 
        # artifacts of single points moving up and down between shifts.
        local_shift = NBR_BUFFERS_TO_UPDATE * STEPSIZE_X * NBR_DATA_POINTS_PER_BUFFER
        #local_shift = 1
        glTranslatef(-local_shift, 0.0, 0.0)
        
        # shift location of FPS display by same amount - but in opposite direction
        # TODO: this must be because of a different reference point?
        fps_display.label.x = fps_display.label.x + local_shift
        SHIFT_VIEW = False

    if USE_UNIFORM_COLOR:
        glColor3f(DEFAULT_COLOR[0], DEFAULT_COLOR[1], DEFAULT_COLOR[2])

    height_per_panel = (WIN_HEIGHT_current / NBR_PANELS)

    for panel in range(NBR_PANELS):

        #glViewport(x, y, w, h)
        glViewport(0, panel * height_per_panel, WIN_WIDTH_current, height_per_panel)

        # plot each VBO
        for segment in range(NBR_VBOS_PER_PANEL):
            
            if not USE_UNIFORM_COLOR:
                this_color = colors[panel][segment]
                glColor3f(this_color[0], this_color[1], this_color[2])         

            # bind the named buffer object so we can work with it.
            glBindBuffer(GL_ARRAY_BUFFER, vbos[panel][segment])

            ## TODO!
            ''' hide individual buffers in first VBO so that points disappear
                smoothly in the first buffer '''
            this_pointer_offset = 0
            nbr_points_to_draw = NBR_DATA_POINTS_PER_VBO
            if segment == 0:
                this_pointer_offset = pointer_offset
                nbr_points_to_draw = NBR_DATA_POINTS_PER_VBO - (pointer_offset / BYTES_PER_POINT)
            elif segment == NBR_VBOS_PER_PANEL - 1:
                # TODO: is 'nbr_points_rendered_in_last_vbo' correct? or are we plotting too few points?
                this_pointer_offset = 0
                nbr_points_to_draw = nbr_points_rendered_in_last_vbo
            
            # specifies the location and data format of an array of vertex coordinates to use when rendering
            glVertexPointer(n_COORDINATES_PER_VERTEX, GL_FLOAT, 0, this_pointer_offset)

            # render primitives from array data
            glDrawArrays(GL_LINE_STRIP, 0, nbr_points_to_draw)

    # update the FPS display.
    glViewport(0, 0, WIN_WIDTH_current, WIN_HEIGHT_current)
    fps_display.draw()
''' END 'draw' function - can only be defined once 'window' exists '''


''' BEGIN setup part 2 '''
glClearColor(0, 0, 0, 1.0)
# enable VERTEX_ARRAY mode.
glEnableClientState(GL_VERTEX_ARRAY)

# try to render a smooth line
glEnable(GL_LINE_SMOOTH)
glEnable(GL_BLEND)
glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
glHint(GL_LINE_SMOOTH_HINT, GL_NICEST)

# start application event loop
pyglet.app.run()

'''
print "quit counter " + str(on_draw_quit_counter)
print "re-draw counter " + str(on_draw_redraw_counter)
print "update counter " + str(update_counter)
'''

''' END setup part 2 '''

