# system imports
import sys

# pyglet imports
import pyglet
from pyglet.gl import *
from pyglet.window import key

# pyglet_app_* imports
from pyglet_app_gl_helper import set_gl_defaults, gl_enable_line_smoothing, gl_on_draw_default, set_glColorPointer_default, gl_Normalize_PushMATRIX_ClearBackground, gl_ortho_projection, gl_update_two_coordinates_in_VBO_static_view, gl_setup_data_and_color_vbos, gl_setup_initial_data_and_color_and_vbos, gl_update_single_coordinate_in_VOB_static_view

from pyglet_app_gl_axes import axes_default_with_y_ticks, check_y_lims
from pyglet_app_gl_lines import line_default_horizontal, line_default_vertical
from pyglet_app_data_management import request_new_data, append_data_to_plot_queue, setup_plotting_queue, setup_queue, get_data_from_plot_queue, setup_incoming_data_interface
from pyglet_app_settings import pyglet_app_settings
from pyglet_app_consts import BYTES_PER_COORDINATE, BYTES_PER_POINT, n_COORDINATES_PER_COLOR, n_COORDINATES_PER_VERTEX
from pyglet_app_profile import profile_code, PROFILE
from pyglet_app_tkinter_helper import tkinter_register_with_settings


# definitions needed for dequeueing of plot buffers.
MAX_NBR_BUFFERS_TO_UPDATE = 2
MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE = MAX_NBR_BUFFERS_TO_UPDATE

class PygletApp(pyglet.window.Window):

	# what is the name of this plugin? must match definition on matlab side.
	PLUGIN_NAME = 'pCtrlLFP'
	# default 'abs_plugin_ID' is one. 
	abs_plugin_ID = 1

	# get new data from MMAP? 1 = yes, 0 = generate random data.
	USE_MMAP = 1

	''' parameters '''
	# number of points to render
	nPoints = 200

	# how many points should be updated during every 'update()' call?
	# 'nPoints' must be a multiple of 'nPointsToUpdate', because we don't handle
	# wrapping around cases.
	nPointsToUpdate = 1

	# how often should the 'update()' function get called? use (1.0 / many_times)
	update_interval = 1.0 / 60
	
	# should we automatically purge the plot queue if a certain amount of elements is reached?
	plot_queue_size_limit = 10
	plot_queue_purge_if_size_limit_reached = False
	

	# number of channels to visualize
	NBR_CHANNELS = 1

	# size of a single data point (in pixels)
	POINT_SIZE = 10


	''' internal (private) data & settings '''
	
	# dummy mmap & random_data_interface
	MMAP = False
	DATA = False

	# offset used while resizing / zooming. this will make sure that we see more then just
	# the area from 0 -> width, and 0 -> height, namely: 
	# RESIZE_OFFSET_X -> width
	# RESIZE_OFFSET_Y -> height
	RESIZE_OFFSET_Y = 0 # no y offset
	RESIZE_OFFSET_X = -50 # x offset so that we see the axis labels to the left
	
	# show the frames per second by default
	SHOW_FPS = True

	# start drawing by default
	DO_DRAW = True

	# show axes by default
	SHOW_AXES = True

	# show horizontal line by default
	SHOW_HORIZONTAL_LINE = True
	
	# show vertical line by default
	SHOW_VERTICAL_LINE = True

	# settings that can be accessed by other objects.
	SETTINGS = pyglet_app_settings()

	# update counter
	c = 0

	def __init__(self, *args, **kwargs):

		# remove kwargs that are specific for my app - can't pass them to the 
		# __init__() method of the superclass below.
		kwargs = self.extract_kwargs(kwargs)

		# Let all of the standard stuff pass through __init__() of the super class
		pyglet.window.Window.__init__(self, *args, **kwargs)

		#self.SETTINGS = pyglet_app_settings()

		# save window height and width that we started out with.
		self.SETTINGS.WINDOW_WIDTH_DEFAULT = kwargs.get('width')
		self.SETTINGS.WINDOW_HEIGHT_DEFAULT = kwargs.get('height')


	def extract_kwargs(self, kwargs):
		# remove kwargs that are specific for my app - can't pass them to the 
		# __init__() method of the superclass.
		abs_plugin_ID = kwargs.pop('abs_plugin_ID', None)
		if abs_plugin_ID is not None:
			self.abs_plugin_ID = abs_plugin_ID

		receive_data_from_matlab = kwargs.pop('receive_data_from_matlab', None)
		if receive_data_from_matlab is not None:
			self.USE_MMAP = receive_data_from_matlab

		return kwargs


	@profile_code(PROFILE)
	def setup(self):

		''' set variables based on init() values. '''
		self.Y_LIMS = [0, self.SETTINGS.WINDOW_HEIGHT_DEFAULT]
		self.SETTINGS.WINDOW_WIDTH_CURRENT = self.SETTINGS.WINDOW_WIDTH_DEFAULT
		self.SETTINGS.WINDOW_HEIGHT_CURRENT = self.SETTINGS.WINDOW_HEIGHT_DEFAULT

		# add 'abs_plugin_ID' to plugin name.
		self.PLUGIN_NAME = self.PLUGIN_NAME + '-' + str(self.abs_plugin_ID)


		''' setup mmap or random data interface '''
		status, self.MMAP, self.DATA = setup_incoming_data_interface(self.USE_MMAP, self.PLUGIN_NAME, self.NBR_CHANNELS, self.nPointsToUpdate, self.nPoints, self.SETTINGS.WINDOW_WIDTH_CURRENT, self.SETTINGS.WINDOW_HEIGHT_CURRENT)
		if not status:
 			sys.exit(1)


		''' setup plot queue '''
		self.plot_queue = setup_plotting_queue()


		''' generate initial positions & colors, and setup VOBs '''
		self.vbo_data, self.vbo_colors, self.x_coords = \
			gl_setup_initial_data_and_color_and_vbos(self.nPoints, n_COORDINATES_PER_COLOR, self.NBR_CHANNELS, self.SETTINGS.WINDOW_WIDTH_DEFAULT, self.SETTINGS.WINDOW_HEIGHT_DEFAULT)


		''' horizontal and vertical lines '''
		# horizontal line showing the threshold 
		if self.SHOW_HORIZONTAL_LINE:
			self.line_hor = line_default_horizontal(self)

		# vertical line showing which data point is going to be update next 
		if self.SHOW_VERTICAL_LINE:
			self.line_ver = line_default_vertical(self)


		''' axes '''
		if self.SHOW_AXES:
			self.coord_axes, self.y_axis_tics = axes_default_with_y_ticks(self)


		''' other stuff '''
		# is Tkinter installed and running?
		self.SETTINGS = tkinter_register_with_settings(self.SETTINGS)

		# set default gl modes
		set_gl_defaults(self.POINT_SIZE)

		# try to render a smooth line (if supported by driver)
		gl_enable_line_smoothing()

		# set window title
		win_title = 'generating random data'
		if self.USE_MMAP:
			win_title = 'receiving data from matlab'
		nbr_points_shown = ' -- showing %s points per panel.' % self.nPoints
		self.set_caption(self.PLUGIN_NAME + ' -- ' + win_title + nbr_points_shown)

		# hide mouse - disabled.
		# self.set_mouse_visible(False)

		# schedule the 'update()' method to be called each 'update_interval'
		pyglet.clock.schedule_interval(self.update, self.update_interval)

		# Create a font for our FPS clock
		ft = pyglet.font.load('Arial', 28)
		self.fps_display = pyglet.clock.ClockDisplay(font = ft, interval=0.125, format='FPS %(fps).2f')


	@profile_code(PROFILE)
	def update(self, dt):

		# update nPointsToUpdate points per `update()` call
		# TODO: handle cases where 'nPoints' is not a multiple of 'nPointsToUpdate'
		# (need to wrap around at the end of the list)


		''' START  'DATA MANAGEMENT'  '''
		# pick up new data from mmap or other system (i.e. generated)
		new_data, new_data_is_empty, nbr_buffers_per_mmap_file = request_new_data(self.USE_MMAP, self.DATA, self.MMAP)

		# don't add empty data to the queue    
		# don't use 'NBR_INDEPENDENT_CHANNELS' here, because we might be skipping this channel
		if sum(new_data_is_empty) != len(new_data):
			#print len(new_data[0][0])
			#print new_data[1][0]
			append_data_to_plot_queue(self.plot_queue, new_data, nbr_buffers_per_mmap_file)
		''' END  'DATA MANAGEMENT'  '''


		''' debugging
		if new_data_is_empty[0] == 1:
			print 'new data is empty!'
		else: 
			print ' NOT EMPTY!'

		'''

		# Quit here if we are not supposed to draw anything new. This way the queue
		# keeps growing and we don't miss anything.
		if not self.DO_DRAW:
			return

		# don't purge entire queue - keep at least 'MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE' elements in queue.
		# this will give us a smoother plotting experience.
		queue_length = len(self.plot_queue)
		if queue_length < MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE:
			return	


		''' START  'dequeue buffers and prepare them for plotting'  '''
		# plot ALL buffers currently in queue.
		for j in xrange(queue_length):

			# dequeue buffers and update VBOs
			# raw_data is an array of channels containing the data per channel.
			raw_data = get_data_from_plot_queue(self.plot_queue)
			#print raw_data
		
			# update y values in main VBO - do this for each channel!
			current_pos_in_memory = gl_update_two_coordinates_in_VBO_static_view(raw_data, self.vbo_data, self.c, self.nPoints, self.nPointsToUpdate, BYTES_PER_POINT, BYTES_PER_COORDINATE, self.NBR_CHANNELS, self.x_coords)

			# Update position of vertical line - move it one 'nPointsToUpdate' 
			# buffer ahead of currently updated position. calc modulo 'nPoints', 
			# so that the position is in the range from 0 to nPoints.
			self.line_ver.curr_pos = (current_pos_in_memory + self.nPointsToUpdate) % self.nPoints
			
			# increase counter and modulo 'nPoints', so that 'c' doesn't grow out of bounds.
			self.c = (self.c + 1) % self.nPoints
		''' END 'dequeue buffers and prepare them for plotting'  '''

		
		# set the resulting vertical line position.
		if self.SHOW_VERTICAL_LINE:
			self.line_ver.gl_update_line_x_value(self.line_ver.curr_pos)

		# auto-purge plot queue if feature is activated and limit is reached.
		if self.plot_queue_purge_if_size_limit_reached and len(self.plot_queue) > self.plot_queue_size_limit:
			self.plot_queue = setup_plotting_queue()


	@profile_code(PROFILE)
	def on_draw(self):

		''' clear background '''	
		glEnable(GL_NORMALIZE)
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)


		height_per_panel = (self.SETTINGS.WINDOW_HEIGHT_CURRENT / self.NBR_CHANNELS)
		for panel in range(self.NBR_CHANNELS):

			''' start - panel data '''
			glPushMatrix()

			glViewport(0, panel * height_per_panel, self.SETTINGS.WINDOW_WIDTH_CURRENT, height_per_panel)
			# apply current scaling (if any) to the active panel
			if self.SETTINGS.CURRENT_glOrtho_MATRIX:
				gl_ortho_projection(self.SETTINGS.CURRENT_glOrtho_MATRIX[0], self.SETTINGS.CURRENT_glOrtho_MATRIX[1], self.SETTINGS.CURRENT_glOrtho_MATRIX[2], self.SETTINGS.CURRENT_glOrtho_MATRIX[3])

			# draw lines #
			''' draw vertical line first '''
			if self.SHOW_VERTICAL_LINE:
				self.line_ver.draw()


			''' draw data plot '''
			glLineWidth(3.0)
			# TODO: this is a temporary situation with one VBO per panel!
			glBindBuffer(GL_ARRAY_BUFFER, self.vbo_colors[panel][0])
			set_glColorPointer_default(n_COORDINATES_PER_COLOR)
			# TODO: this is a temporary situation with one VBO per panel!  
			gl_on_draw_default(self.vbo_data[panel][0], n_COORDINATES_PER_VERTEX, self.nPoints, GL_LINE_STRIP)

			''' draw horizontal line - which is made off 2 points only '''
			if self.SHOW_HORIZONTAL_LINE:
				self.line_hor.draw()

			glPopMatrix()
			''' end - panel data '''

			# draw axes, tics and labels #
			if self.SHOW_AXES:
				self.coord_axes.draw()
				self.y_axis_tics.draw(self.Y_LIMS)




		
		# go back to main perspective and show the FPT
		glPushMatrix()
		glViewport(0, 0, self.SETTINGS.WINDOW_WIDTH_CURRENT, self.SETTINGS.WINDOW_HEIGHT_CURRENT)
		gl_ortho_projection(self.RESIZE_OFFSET_X, self.SETTINGS.WINDOW_WIDTH_CURRENT, self.RESIZE_OFFSET_Y, self.SETTINGS.WINDOW_HEIGHT_CURRENT)
		# draw FPS  #
		if self.SHOW_FPS:
			self.fps_display.draw()
		glPopMatrix()


	def kpf_change_y_lims(self, symbol, modifiers, mod_offset):

		do_resize = 0
		key_matched = False

		if symbol == key.Y: # set y lims explicitly 
			key_matched = True
			lower = False # upper limit is default.

			if modifiers == key.MOD_CTRL + mod_offset: # GUI to change both values
				if not self.SETTINGS.TKINTER_AVAILABLE:
					print "GUI is not working on your machine."
				else:
					try:
						from pyglet_app_tkinter_dialogs import get_two_inputs
						a = get_two_inputs()
						a.run('change y limits', 'y min', 'y max', self.Y_LIMS[0], self.Y_LIMS[1])
						# user submitting at least one new value.
						if a.dialog.result:
							self.Y_LIMS = check_y_lims(self.Y_LIMS, a.dialog.result[0], 0)
							self.Y_LIMS = check_y_lims(self.Y_LIMS, a.dialog.result[1], 1)
							do_resize = 1
					except Exception, e:
						pass
						print "An error occurred:"
						print e

			elif modifiers == key.MOD_SHIFT + mod_offset: # lower limit? 
				lower = True

			# 'y' and 'Y' cases.
			if not (modifiers == key.MOD_CTRL + mod_offset):

				while 1:
					if lower:
						strg = 'lower'
						index = 0
					else:
						strg = 'upper'
						index = 1

					t = raw_input('Please provide %s y limit (currently %s) and press ENTER: ' % (strg, self.Y_LIMS[index]) )
					if len(t) == 0:
						break

					try:
						new_value = float(t)
						self.Y_LIMS = check_y_lims(self.Y_LIMS, new_value, index)
						do_resize = 1
					except Exception, e:
						# print "Error in 'kpf_change_y_lims()': ", e
						pass
						print "non numeric value given - will ignore and keep old threshold"
					break

		elif symbol == key._1: # decrease upper y lim
			self.Y_LIMS = check_y_lims(self.Y_LIMS, self.Y_LIMS[1] - 10, 1)
			# left, right, bottom, top
			do_resize = 1

		elif symbol == key._2: # increase upper y lim
			self.Y_LIMS = check_y_lims(self.Y_LIMS, self.Y_LIMS[1] + 10, 1)
			do_resize = 1

		elif symbol == key._3: # decrease lower y lim
			self.Y_LIMS = check_y_lims(self.Y_LIMS, self.Y_LIMS[0] - 10, 0)
			do_resize = 1

		elif symbol == key._4: # increase lower y lim
			self.Y_LIMS = check_y_lims(self.Y_LIMS, self.Y_LIMS[0] + 10, 0)
			do_resize = 1

		elif symbol == key._0: # restore original y lims.
			do_resize = 2


		if do_resize == 1: # resize according to y-lims.
			key_matched = True
			# left, right, bottom, top
			self.SETTINGS.CURRENT_glOrtho_MATRIX = [self.RESIZE_OFFSET_X, self.SETTINGS.WINDOW_WIDTH_DEFAULT, self.Y_LIMS[0] + self.RESIZE_OFFSET_Y, self.Y_LIMS[1]]

		elif do_resize == 2: # resize according to original startup resolution.
			key_matched = True
			# left, right, bottom, top
			self.SETTINGS.CURRENT_glOrtho_MATRIX = [self.RESIZE_OFFSET_X, self.SETTINGS.WINDOW_WIDTH_DEFAULT, self.RESIZE_OFFSET_Y, self.SETTINGS.WINDOW_HEIGHT_DEFAULT]

		return key_matched


	def kpf_change_horizontal_line(self, symbol, modifiers, mod_offset):

		key_matched = False

		if symbol == key.T: # set new position for horizontal line
			key_matched = True
			if modifiers == key.MOD_CTRL + mod_offset:
				# toggle display of horizontal line.
				if not self.SHOW_HORIZONTAL_LINE:
					self.line_hor = line_default_horizontal(self.SETTINGS)
				self.SHOW_HORIZONTAL_LINE = not self.SHOW_HORIZONTAL_LINE
			elif modifiers == key.MOD_SHIFT + mod_offset:
				if self.SHOW_HORIZONTAL_LINE:
					print "current threshold = %d" % self.line_hor.curr_pos
			else:
				if self.SHOW_HORIZONTAL_LINE:
					self.line_hor.set_position_horizontal_line(self.SETTINGS, 'Set new threshold', 'Threshold (currently %d) ' % self.line_hor.curr_pos)

		elif symbol == key.UP: # move horizontal line up
			key_matched = True
			self.line_hor.move_horizontal_line_up(self.SETTINGS, modifiers, key, mod_offset)

		elif symbol == key.DOWN: # move horizontal line down
			key_matched = True
			self.line_hor.move_horizontal_line_down(self.SETTINGS, modifiers, key, mod_offset)

		return key_matched


	def on_key_press(self, symbol, modifiers):

		# offset that needs to be added to 'key.MOD_*' in order to match the 
		# 'modifiers' value
		mod_offset = 16

		''' key press function for y limits '''
		key_matched = self.kpf_change_y_lims(symbol, modifiers, mod_offset)
		# skip remainder of key press function in case 'kpf_change_y_lims' had a hit.
		if key_matched:
			return

		''' key press function for horizontal line '''
		key_matched = self.kpf_change_horizontal_line(symbol, modifiers, mod_offset)
		# skip remainder of key press function in case 'kpf_change_horizontal_line' had a hit.
		if key_matched:
			return

		''' remaining keys '''
		if symbol == key.A:
			if modifiers == key.MOD_CTRL + mod_offset:
				if self.SHOW_AXES:
					self.coord_axes, self.y_axis_tics, self.SHOW_AXES = False, False, False
				else:
					self.SHOW_AXES = True
					self.coord_axes, self.y_axis_tics = axes_default_with_y_ticks(self.SETTINGS, self.Y_LIMS)

		elif symbol == key.C:
			self.plot_queue = setup_plotting_queue()
			print "Cleared Plot-Queue"		

		elif symbol == key.F: # show / hide FPS display
			self.SHOW_FPS = not self.SHOW_FPS

		elif symbol == key.H: # show help menu
			print " "
			print "      *** HELP ***"
			print " "
			print "\t 0: \t\t\trestore original y-lims"
			print "\t 1: \t\t\tdecrease upper y-lim"
			print "\t 2: \t\t\tincrease upper y-lim"
			print "\t 3: \t\t\tdecrease lower y-lim"
			print "\t 4: \t\t\tincrease lower y-lim"
			print "\t a + ctrl: \t\tshow / hide axes"
			print "\t f: \t\t\tshow / hide FPS display"
			print "\t q: \t\t\tshow number of elements in plot queue"
			print "\t t: \t\t\tset position of horizontal line"
			print "\t t + shift: \t\tprint out current position of horizontal line"
			print "\t t + ctrl: \t\tshow / hide horizontal line"
			print "\t v + ctrl: \t\tshow / hide vertical line"
			print "\t y: \t\t\tset upper y-lim to value from command line"
			print "\t y + shift: \t\tset lower y-lim to value from command line"
			print "\t y + ctrl: \t\tset upper and lower y limits through GUI"
			print "\t arrow up: \t\tmove horizontal line up by one"
			print "\t arrow down: \t\tmove horizontal line down by one"
			print "\t arrow up + shift: \tmove horizontal line up by five"
			print "\t arrow down + shift: \tmove horizontal line down by five"
			print "\t space bar: \t\tpause / resume screen update"
			print " "

		elif symbol == key.Q: # show number of elements in plot queue
			print "Plot-Queue size: %d" % (len(self.plot_queue))

		elif symbol == key.V: # show / hide vertical line (toggle display of vertical line)
			if modifiers == key.MOD_CTRL + mod_offset:
				if not self.SHOW_VERTICAL_LINE:
					self.line_ver = line_default_vertical(self.SETTINGS.WINDOW_HEIGHT_CURRENT, self.x_coords)
				self.SHOW_VERTICAL_LINE = not self.SHOW_VERTICAL_LINE

		elif symbol == key.ESCAPE: # quit program
			sys.exit()

		elif symbol == key.SPACE: # freeze / resume plotting
			self.DO_DRAW = not self.DO_DRAW

		# uncomment for debugging purposes.
		#else:
		#	print '%s key, %s modifier was pressed' % (symbol, modifiers)


	def on_resize(self, w, h):

		# TODO: don't rescale labels - not sure this is working.
		if self.SHOW_AXES:
			for label in self.y_axis_tics.labels:
				label.begin_update()

		# Prevent a divide by zero, when window is too short
		# (you cant make a window of zero width).
		if h == 0:
		    h = 1

		# see http://profs.sci.univr.it/~colombar/html_openGL_tutorial/en/04viewports_011.html
		# on how-to lock aspect ratio.

		self.SETTINGS.WINDOW_WIDTH_CURRENT = w
		self.SETTINGS.WINDOW_HEIGHT_CURRENT = h

		aspect = float(w) / float(h)

		''' make sure the window goes from [0, self.SETTINGS.WINDOW_WIDTH_DEFAULT] in the
		   smallest dimension  '''

		left = 0
		right = self.SETTINGS.WINDOW_WIDTH_DEFAULT
		bottom = self.Y_LIMS[0]

		#print "aspect = %f " %aspect
		if aspect < 1.0:
			top = self.Y_LIMS[1] * ( 1.0 / aspect )
		else:
			top = self.Y_LIMS[1]

		self.SETTINGS.CURRENT_glOrtho_MATRIX = [left + self.RESIZE_OFFSET_X, right, bottom + self.RESIZE_OFFSET_Y, top]

		# TODO: don't rescale labels - not sure this is working.
		if self.SHOW_AXES:
			for label in self.y_axis_tics.labels:
				label.end_update()


if __name__ == "__main__":
	# startup the application
	WIN_HEIGHT_DEFAULT = 120
	WIN_WIDTH_DEFAULT = 1000
	my_app = PygletApp(width=WIN_WIDTH_DEFAULT, height=WIN_HEIGHT_DEFAULT, resizable=True)
	my_app.setup()
	pyglet.app.run()

