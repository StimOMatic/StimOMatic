import os
from math import ceil
from copy import deepcopy

from pyglet_app_profile import profile_code, PROFILE

@profile_code(PROFILE)
def calc_VBO_numbers(NBR_DATA_POINTS_PER_VBO, NBR_DATA_POINTS_PER_BUFFER, SECONDS_TO_VISUALIZE_PER_PANEL, scanrate):
    
    NBR_DATA_POINTS_PER_VBO = ceil(NBR_DATA_POINTS_PER_VBO / NBR_DATA_POINTS_PER_BUFFER) * NBR_DATA_POINTS_PER_BUFFER
    
    # calculate the number of VBOs that are need to display all data
    NBR_VBOS_PER_PANEL = ceil(SECONDS_TO_VISUALIZE_PER_PANEL * scanrate / NBR_DATA_POINTS_PER_VBO)
    
    # how many buffers of size 'NBR_DATA_POINTS_PER_BUFFER' does each panel hold?
    # NBR_BUFFERS_PER_PANEL = NBR_VBOS_PER_PANEL * NBR_DATA_POINTS_PER_VBO / NBR_DATA_POINTS_PER_BUFFER
    
    # update 'SECONDS_TO_VISUALIZE_PER_PANEL' to its true value
    SECONDS_TO_VISUALIZE_PER_PANEL = NBR_VBOS_PER_PANEL * NBR_DATA_POINTS_PER_VBO / scanrate
    
    # add one VBO to each panel since we want to smoothly add new data points.
    NBR_VBOS_PER_PANEL += 1
    
    return int(NBR_DATA_POINTS_PER_VBO), int(NBR_VBOS_PER_PANEL), SECONDS_TO_VISUALIZE_PER_PANEL


@profile_code(PROFILE)
def setup_tmp_directory(PLUGIN_NAME, TMP_DIR = False):

	if not TMP_DIR:
		# where's your temporary directory? mmap will write into it.
		if os.name == 'nt': # windows systems
			# make sure you use double '\\' to separate directories 
			TMP_DIR = 'c:\\temp'
		else: # unix systems
			TMP_DIR = '/tmp'

	TMP_DIR = TMP_DIR + os.sep + PLUGIN_NAME
	return TMP_DIR


@profile_code(PROFILE)
def replicate_data_for_panel_and_vbo(NBR_VBOS_PER_PANEL, NBR_PANELS, data_single):

    data = [ [None] * int(NBR_VBOS_PER_PANEL) for i in xrange(NBR_PANELS) ]
    for panel in range(NBR_PANELS):
        for vbo in range(NBR_VBOS_PER_PANEL):
            data[panel][vbo] = deepcopy(data_single)

    return data


