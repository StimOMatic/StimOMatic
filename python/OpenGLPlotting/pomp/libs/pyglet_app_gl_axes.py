from pyglet.gl import *
from pyglet_app_gl_helper import gl_transform_list_to_GLfloat, gl_calc_x_y_extend_from_current_glOrthoMatrix
from pyglet_app_profile import profile_code, PROFILE

import numpy as np
from numpy import diff, arange
from copy import deepcopy

class pyglet_axis(object):

	def __init__(self, *args, **kwargs):
		pass


	@profile_code(PROFILE)
	def setup(self, window_width, window_height, zero_offset = 0):
		# where should the origin of our coordinate system be placed?
		# ORG = gl_transform_list_to_GLfloat([zero_offset, zero_offset, 0])

		# we draw the axes from [-value : +value]
		self.XP_minus = gl_transform_list_to_GLfloat([-window_width, zero_offset, 0])
		self.YP_minus = gl_transform_list_to_GLfloat([zero_offset, -window_height, 0])

		self.XP = gl_transform_list_to_GLfloat([window_width, zero_offset, 0])
		self.YP = gl_transform_list_to_GLfloat([zero_offset, window_height, 0])

		# 'win_height' and 'win_width' are more panel heights and widths.
		self.win_height = window_height
		self.win_width = window_width
		self.zero_offset = zero_offset


	@profile_code(PROFILE)
	def draw(self):

		# check if the current 'glOrtho' Matrix has changed - compare to our 
		# previously used values.
		curr_height = self.settings_main_app.CURRENT_glOrtho_MATRIX[3]
		curr_width = self.settings_main_app.CURRENT_glOrtho_MATRIX[1]
		if self.win_height != curr_height or self.win_width != curr_width:
			self.setup(curr_width, curr_height, self.zero_offset)

		glPushMatrix()
		glLineWidth(5.0)

		glBegin(GL_LINES)
		glColor3f(1, 1, 1); glVertex3fv(self.XP_minus); glVertex3fv(self.XP); # x axis
		glColor3f(1, 1, 1); glVertex3fv(self.YP_minus); glVertex3fv(self.YP); # y axis
		glEnd()

		glPopMatrix()



class pyglet_axis_tic_lines(object):

	def __init__(self, *args, **kwargs):
		pass


	@profile_code(PROFILE)
	def setup(self, window_width, window_height, y_lims, spacing = 10, length = 15, direction = 1, major_tick_every_x = 5, zero_offset = 0):

		# need to deepcopy here, otherwise we end up with a pointer to the original values.
		self.y_lims = deepcopy(y_lims)
		self.direction = direction # 1 == y axis, 0 == x axis.
		self.spacing = spacing

		self.length = length
		self.major_tick_every_x = major_tick_every_x
		self.zero_offset = zero_offset

		self.win_height = window_height
		self.win_width = window_width

		# initialize tics automatically.
		self.re_init_axis_tics(y_lims)


	@profile_code(PROFILE)
	def draw_axis_tics(self, y_lims, spacing, length):

		axis_span = int(max(y_lims))

		# spacing can't be zero.
		if spacing == 0:
			spacing = 0.1

		# where to put the tick marks (along the axis)
		tick_locations = get_range_through_zero(axis_span, spacing)
		# tick_locations = arange(-axis_span, axis_span + spacing, spacing)

		# what is the extend of the tick marks
		minor_length_position = length / 2
		major_length_position = length

		self.tick_locations = tick_locations
		self.minor_length_position = minor_length_position
		self.major_length_position = major_length_position

		self.labels = []
		if self.direction == 1: # y axis ticks
			pos_ticks, neg_ticks = self.return_pos_and_neg_tick_locations()
			self.add_tick_label(pos_ticks)
			self.add_tick_label(neg_ticks)

		else:
			print "axis direction %s is not defined" % self.direction


	@profile_code(PROFILE)
	def return_pos_and_neg_tick_locations(self):
		# start the tics with zero and go up to increasing (pos) and decreasing (neg) values.
		pos_ticks = np.concatenate((np.array([0]), self.tick_locations[self.tick_locations > 0]))
		neg_ticks = np.concatenate((np.array([0]), self.tick_locations[self.tick_locations < 0][::-1]))
		return pos_ticks, neg_ticks


	@profile_code(PROFILE)
	def add_tick_label(self, tics):

		# font_size = int(spacing / 10.0) - fonts are still distorted!
		font_size = 12

		for j, tic in enumerate(tics):
			# skip zero tic - it will collide with the x-axis
			if tic == 0:
				continue
			if j % self.major_tick_every_x == 0: # major tick, every 'x-th' step.
				# place label to the left of the y-axis
				self.labels.append(pyglet.text.Label(str(tic),
                      font_name = 'Times New Roman',
                      font_size = font_size,
                      x = -1 * (self.major_length_position + 10), y = tic,
                      anchor_x = 'right', anchor_y = 'center'))


	@profile_code(PROFILE)
	def clear_axis_tics(self):
		self.labels = []
		self.tick_locations = []


	@profile_code(PROFILE)
	def re_init_axis_tics(self, y_lims):

		self.clear_axis_tics()

		# calculate the new tic spacing, assume a 10% step size, and go to up to
		# 90% of the scale.
		axis_span = diff(y_lims)[0];
		spacing = int(float(axis_span) * 0.9 * 0.10)

		# save new y_lims - deepcopy them!
		self.y_lims = deepcopy(y_lims)
		self.draw_axis_tics(y_lims, spacing, self.length)


	@profile_code(PROFILE)
	def draw_tic_lines(self, tics):
		for j, tic in enumerate(tics):
			if j % self.major_tick_every_x == 0: # major tick
				glVertex3fv(gl_transform_list_to_GLfloat([-self.major_length_position, tic, 0]))
				glVertex3fv(gl_transform_list_to_GLfloat([ self.major_length_position, tic, 0]))
			else: # minor tick
				glVertex3fv(gl_transform_list_to_GLfloat([-self.minor_length_position, tic, 0]))
				glVertex3fv(gl_transform_list_to_GLfloat([ self.minor_length_position, tic, 0]))


	@profile_code(PROFILE)
	def draw(self, current_y_lims):

		if (self.y_lims != current_y_lims):
			self.re_init_axis_tics(current_y_lims)

		glPushMatrix()

		glLineWidth(2.0)
		glBegin(GL_LINES)
		glColor3f(1, 1, 1)

		if self.direction == 1: # y axis ticks
			pos_ticks, neg_ticks = self.return_pos_and_neg_tick_locations()
			self.draw_tic_lines(pos_ticks)
			self.draw_tic_lines(neg_ticks)

		glEnd()

		glPopMatrix()

		# TODO: this is a little messy, but I need to do this so that the axex
		# labels don't get distorted.

		# the size of the current window
		win_height = float(self.settings_main_app.WINDOW_HEIGHT_CURRENT)
		win_width = float(self.settings_main_app.WINDOW_WIDTH_CURRENT)
		
		# the abs size of the current projection view
		x_diff_abs, y_diff_abs = gl_calc_x_y_extend_from_current_glOrthoMatrix(self.settings_main_app)

		# draw the labels
		for j in range(len(self.labels)):
			glPushMatrix()
			# scale text in x & y direction. with x-scaling we will have to also move the label away from the tic marks.
			# glScalef(x_diff_abs/win_width, y_diff_abs/win_height, 1)
			# scale text in y direction only.
			glScalef(1, y_diff_abs/win_height, 1)
			# move text
			y_translate = float(self.labels[j].y) * ((win_height/y_diff_abs) - 1.0)
			glTranslatef(0, y_translate, 0)
			#print 'moving %s by %s' % (self.labels[j].text, y_translate)
			self.labels[j].draw()
			glPopMatrix()


@profile_code(PROFILE)
def get_range_through_zero(max_value, step_size):
    start = -1 * max_value
    return arange(start- (start % step_size), max_value + step_size, step_size)


@profile_code(PROFILE)
def check_y_lims(Y_LIMS, new_value, index):

	# 'new_value' might be None
	if not new_value:
		return Y_LIMS

	# check if we were given a string
	if isinstance(new_value, str):
		try:
			new_value = int(new_value)
		except:
			pass
			return Y_LIMS

	# make sure that the other y_lim value is not the same as the new one.
	other_index = (index + 1) % 2 
	if Y_LIMS[other_index] != new_value:
		Y_LIMS[index] = new_value
	else:
		print "Overlapping y limits are not allowed."

	return Y_LIMS


@profile_code(PROFILE)
def axes_default_with_y_ticks(mainapp):

	py_axis = pyglet_axis()
	py_axis.settings_main_app = mainapp.SETTINGS
	py_axis.setup(mainapp.SETTINGS.WINDOW_WIDTH_CURRENT, mainapp.SETTINGS.WINDOW_HEIGHT_CURRENT)

	py_tics = pyglet_axis_tic_lines()
	py_tics.settings_main_app = mainapp.SETTINGS
	py_tics.setup(mainapp.SETTINGS.WINDOW_WIDTH_CURRENT, mainapp.SETTINGS.WINDOW_HEIGHT_CURRENT, mainapp.Y_LIMS, spacing = 10, length = 15, direction = 1, major_tick_every_x = 4)

	return py_axis, py_tics


''' poor man's diff 
def diff(a):
	# returns the diff between all consecutive elements in list.
	return [ x-y for (x, y) in zip(a[1:], a[:-1]) ]
'''
