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


################## function needed to calculate dependent parameters

def calc_VOB_numbers(nbr_data_points_per_vbo, nbr_data_points_per_buffer, seconds_to_visualize_per_panel, scanrate):
    
    nbr_data_points_per_vbo = ceil(nbr_data_points_per_vbo / nbr_data_points_per_buffer) * nbr_data_points_per_buffer
    
    # calculate the number of VBOs that are need to display all data
    NBR_VBOS_PER_PANEL = ceil(seconds_to_visualize_per_panel * scanrate / nbr_data_points_per_vbo)
    
    # how many buffers of size 'nbr_data_points_per_buffer' does each panel hold?
    # NBR_BUFFERS_PER_PANEL = NBR_VBOS_PER_PANEL * nbr_data_points_per_vbo / nbr_data_points_per_buffer
    
    # update 'seconds_to_visualize_per_panel' to its true value
    seconds_to_visualize_per_panel = NBR_VBOS_PER_PANEL * nbr_data_points_per_vbo / scanrate
    
    # add one VBO to each panel since we want to smoothly add new data points.
    NBR_VBOS_PER_PANEL += 1
    
    return int(nbr_data_points_per_vbo), int(NBR_VBOS_PER_PANEL), seconds_to_visualize_per_panel





