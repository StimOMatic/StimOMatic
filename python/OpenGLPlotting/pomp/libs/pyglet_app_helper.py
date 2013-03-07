import sys
import random
import numpy as np

from pyglet.gl import *

from pyglet_app_gl_helper_basic import gl_transform_list_to_GLfloat
from pyglet_app_profile import profile_code, PROFILE


''' process and use 'abs_plugin_ID' if given on command line. '''
def process_sys_argv(abs_plugin_ID):

	if len(sys.argv) > 1:
		try: # abs_ID can also be a string.
			abs_plugin_ID = sys.argv[1]
		except:
			pass

	return abs_plugin_ID

            
''' generate list of random numbers '''
@profile_code(PROFILE)
def generate_random_number_list_for_GPU(nPoints, coordinates_per_point=2, Float=True, Min=1, Max=200):
	data = generate_random_number_list(nPoints, coordinates_per_point, Float, Min, Max)
	# transform data into GLfloat pointer format for GPU
	return gl_transform_list_to_GLfloat(data)


''' generate list of random numbers '''
@profile_code(PROFILE)
def generate_random_number_list(nPoints, coordinates_per_point=2, Float=True, Min=1, Max=200):

	# create list of [1:n_COORDINATES_PER_VERTEX] values for each 'nPoints'
	data = list()

	if Float:
		rands = np.random.random(nPoints * coordinates_per_point)
	else:
		rands = np.random.randint(Min, Max, nPoints * coordinates_per_point)

	for j in range(nPoints):
		for k in range(coordinates_per_point):
			data.append(rands[j*coordinates_per_point + k])

	# return data
	return data


''' calculate colors for 'nPoints' points '''
@profile_code(PROFILE)
def calc_colors(nPoints=1, USE_UNIFORM_COLOR = True):
# < 0.1ms

	''' USE_UNIFORM_COLOR is True or False by default
		USE_UNIFORM_COLOR can also be a list defining the color to use [1, 1, 1]
	'''

	# generate well visible (not too dark) colors
	if not USE_UNIFORM_COLOR:
		while True:
			color = [random.random() for j in xrange(0, 3)]
			if sum(color) > 0.5:
				break
	else:
		# default color used for all points
		if USE_UNIFORM_COLOR is not True and len(USE_UNIFORM_COLOR) == 3 and \
			(sum([int(isinstance( j, ( int, long ) )) for j in USE_UNIFORM_COLOR]) == 3 or \
			sum([int(isinstance( j, ( float, long ) )) for j in USE_UNIFORM_COLOR]) == 3):
			color = [float(j) for j in USE_UNIFORM_COLOR]
		else:
			color = [1, 0, 0]


	n_color_coord = len(color)

	# create long list of uniform colors
	colors = []
	for j in xrange(nPoints):
		for i in range(n_color_coord):
			colors.append(color[i])

	# return array of colors for number of points, as well as the 'color' that 
	# had been generated / used.
	return gl_transform_list_to_GLfloat(colors), color


@profile_code(PROFILE)
def create_initial_colors(nPanels, nVbosPerPanel, nPoints, USE_UNIFORM_COLOR = True):

    # the color values for each point in each panel and each vbo
    colors = [ [None] * int(nVbosPerPanel) for i in xrange(nPanels) ]
    # the color used for each panel
    color_generated = [ [None] for i in xrange(nPanels) ]
    
    for panel in range(nPanels):
        for vbo in range(nVbosPerPanel):
            colors[panel][vbo], color_generated[panel] = calc_colors(nPoints, USE_UNIFORM_COLOR)
    
    return colors, color_generated


@profile_code(PROFILE)
def calc_points_zeros_None(nPoints, width_Max = 780):

	Min = 20
	return None, None, np.arange(Min, width_Max, calc_stepsize(Min, width_Max, nPoints))


@profile_code(PROFILE)
def calc_points_zeros(nPoints, width_Max = 780):

	Min = 20

	x_coords = np.arange(Min, width_Max, calc_stepsize(Min, width_Max, nPoints))
	y_values = np.zeros(nPoints)

	coords = []

	for j in range(nPoints):
		coords.append(x_coords[j])
		coords.append(y_values[j])

	return gl_transform_list_to_GLfloat(coords), coords, x_coords


@profile_code(PROFILE)
def calc_points_equal_dist(nPoints=1, width_Max = 780, height_Max = 780, interleaved = True):

	# create list of x & y coordinates; x is followed by y. y is a random number.
	Min = 20

	x_coords = np.arange(Min, width_Max, calc_stepsize(Min, width_Max, nPoints))
	y_values = np.random.randint(Min, height_Max, nPoints)

	coords = []

	# interleaved mode: x1y1 x2y2 x3y3
	if interleaved:

		# slow:
		#for i, j in zip(x_coords, y_values):
		#    coords.append(i)
		#    coords.append(j)

		# fast:
		for j in range(nPoints):
			coords.append(x_coords[j])
			coords.append(y_values[j])

	# non-interleaved mode: x1x2x3 y1y2y3
	else:
		# all x coordinates first
		for j in range(nPoints):
			coords.append(x_coords[j])

		# now all y coordinates
		for j in range(nPoints):
			coords.append(random.randint(Min, height_Max))
		
	return gl_transform_list_to_GLfloat(coords), coords, x_coords


@profile_code(PROFILE)
def calc_points_equal_dist_scale_y_with_x(nPoints=1, width_Max = 780, height_Max = 780, interleaved = True):
	# create list of x & y coordinates; x is followed by y. y scales with the window size.
	Min = 20
	x_coords = np.arange(Min, width_Max, calc_stepsize(Min, width_Max, nPoints))
	y_scale = float(height_Max) / nPoints
	coords = []

	# interleaved mode: x1y1 x2y2 x3y3
	if interleaved:
		for j in range(nPoints):
			coords.append(x_coords[j])
			coords.append(y_scale * (j+1))

	# non-interleaved mode: x1x2x3 y1y2y3
	else:
		# all x coordinates first
		for j in range(nPoints):
			coords.append(x_coords[j])

		# now all y coordinates
		for j in range(nPoints):
			coords.append(y_scale * (j+1))

		
	# print coords
	return gl_transform_list_to_GLfloat(coords), coords, x_coords


@profile_code(PROFILE)
def calc_points_equal_dist_zig_zag_y(nPoints=1, width_Max = 780, height_Max = 780, y_offset = 0, interleaved = True):
	# create list of x & y coordinates; x is followed by y. y scales with the window size.
	Min = 20
	y_offset = 50
	x_coords = np.arange(Min, width_Max, calc_stepsize(Min, width_Max, nPoints))
	y_scale = float(height_Max) / nPoints
	coords = []

	# show 100 zig-zags
	mod_value = int(nPoints / 100.0)

	# interleaved mode: x1y1 x2y2 x3y3
	if interleaved:
		for j in range(nPoints):
			coords.append(x_coords[j])
			if j % mod_value == 0:
				coords.append(y_offset + 0.3 * (y_scale * j))
			else:
				coords.append(y_offset + (y_scale * j))

	# non-interleaved mode: x1x2x3 y1y2y3
	else:
		# all x coordinates first
		for j in range(nPoints):
			coords.append(x_coords[j])

		# now all y coordinates
		for j in range(nPoints):
			if j % 2 == 0:
				coords.append(y_offset + (y_scale * j) - (2.0/3 * y_scale))
			else:
				coords.append(y_offset + (y_scale * j))
		
	# print coords
	return gl_transform_list_to_GLfloat(coords), coords, x_coords

		
''' calculate coordinates for 'nPointsToUpdate' points '''
@profile_code(PROFILE)
def calc_points_random(n_COORDINATES_PER_VERTEX, nPoints=1):
	# create list of x & y coordinates; x is followed by y.
	return generate_random_number_list_for_GPU(nPoints, n_COORDINATES_PER_VERTEX, False, 100, 700)


@profile_code(PROFILE)
def calc_stepsize(MIN, MAX, nPoints):
	return float(MAX - MIN) / nPoints


''' generate initial positions & colors '''
@profile_code(PROFILE)
def initial_points(nPoints, SETTINGS, GENERATE_INITIAL = 0):

	WINDOW_WIDTH_DEFAULT = SETTINGS.WINDOW_WIDTH_DEFAULT
	WINDOW_HEIGHT_DEFAULT = SETTINGS.WINDOW_HEIGHT_DEFAULT
	make_win_dimensions_smaller_by_px = 20

	# generate color vector for all points.	
	colors, color_used = calc_colors(nPoints)

	if GENERATE_INITIAL == 0: # zeros.
		data, coords, x_coords = calc_points_zeros(nPoints, WINDOW_WIDTH_DEFAULT - make_win_dimensions_smaller_by_px)

	elif GENERATE_INITIAL == 1: # data whose range is inside the current window dimensions.
		data, coords, x_coords = calc_points_equal_dist(nPoints, WINDOW_WIDTH_DEFAULT - make_win_dimensions_smaller_by_px, WINDOW_HEIGHT_DEFAULT - make_win_dimensions_smaller_by_px)

	elif GENERATE_INITIAL == 2: # linearly increasing y values. 
		data, coords, x_coords = calc_points_equal_dist_scale_y_with_x(nPoints, WINDOW_WIDTH_DEFAULT - make_win_dimensions_smaller_by_px, WINDOW_HEIGHT_DEFAULT - make_win_dimensions_smaller_by_px)

	elif GENERATE_INITIAL == 3: # line going up and down in a zig-zag fashion.
		data, coords, x_coords = calc_points_equal_dist_zig_zag_y(nPoints, WINDOW_WIDTH_DEFAULT - make_win_dimensions_smaller_by_px, WINDOW_HEIGHT_DEFAULT/2)

	elif GENERATE_INITIAL == 4: # use 'None'
		data, coords, x_coords = calc_points_zeros_None(nPoints, WINDOW_WIDTH_DEFAULT - make_win_dimensions_smaller_by_px)

	
	return data, colors, x_coords


''' combines x & y values into a list of pairs '''
@profile_code(PROFILE)
def create_2dim_list_from_arrays(x, y):
    
    data = []
    for i, j in zip(x, y):
        data.extend([i, j])
        
    return data


