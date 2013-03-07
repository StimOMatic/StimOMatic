
''' import statements. '''
import pyglet
pyglet.options['debug_gl'] = False
from pyglet_app_line_update_cheetah_with_mmap import PygletApp
from pyglet_app_helper import process_sys_argv


''' user config options. '''
# set the 'abs_plugin_ID' to the value you see in Matlab - or provide a value on
# the command line. with 'pContinousOpenGL' you also need to append the channel number that you want
# to visualize. E.g. '4-131' means: plugin ID 4, channel number 131.
abs_plugin_ID = '2-131'

# set this variable to zero if you want to generate random data.
receive_data_from_matlab = 1

# what is the name of this plugin? must match definition on matlab side.
PLUGIN_NAME = 'pContinuousOpenGL'

# number of panels that this plugin is displaying.
NBR_PANELS = 2

# number of points to render
nPoints = 512*100

# how many points should be updated during every 'update()' call?
# 'nPoints' must be a multiple of 'nPointsToUpdate', because we don't handle
# wrapping around cases.
nPointsToUpdate = 512



''' startup the application. '''
if __name__ == "__main__":

	# process 'abs_plugin_ID' if given on command line.
	abs_plugin_ID = process_sys_argv(abs_plugin_ID)

	# default window height and width of this plugin.
	# performance decreases (factor of 10!), if WIN_HEIGHT_DEFAULT > 100 and 
	# axes are turned on (SHOW_AXES == True).
	WIN_HEIGHT_DEFAULT = 1500
	WIN_WIDTH_DEFAULT = 1000

	# instantiate our application & run setup() method.
	my_app = PygletApp(width=WIN_WIDTH_DEFAULT, height=WIN_HEIGHT_DEFAULT, abs_plugin_ID=abs_plugin_ID, receive_data_from_matlab=receive_data_from_matlab, resizable=True)

	# overwrite default values with our custom settings.
	my_app.PLUGIN_NAME = PLUGIN_NAME
	my_app.NBR_CHANNELS = NBR_PANELS
	my_app.nPoints = nPoints
	my_app.nPointsToUpdate = nPointsToUpdate

	# don't show the axes - this will slow down rendering.
	my_app.SHOW_AXES = False
	my_app.SHOW_HORIZONTAL_LINE = False

	# finish settings things up.
	my_app.setup()

	# run program.
	pyglet.app.run()


