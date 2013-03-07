
''' import statements. '''
from pomp.libs.pyglet_app_basicapp import MainApp
from pomp.libs.pyglet_app_screen_update_elements_static_line import StaticLineUpdateScreen
from pomp.libs.pyglet_app_helper import process_sys_argv


''' user config options. '''
# set the 'abs_plugin_ID' to the value you see in Matlab - or provide a value on
# the command line.
abs_plugin_ID = 3

# set this variable to zero if you want to generate random data.
receive_data_from_matlab = 1

# what is the name of this plugin? must match definition on matlab side.
PLUGIN_NAME = 'pCtrlLFP'

# what color should we use? set to 'False' for random color
COLOR_TO_USE = [1, 0, 0]

''' startup the application. '''
if __name__ == "__main__":

	# process 'abs_plugin_ID' if given on command line.
	abs_plugin_ID = process_sys_argv(abs_plugin_ID)

	# default window height and width of this plugin.
	# performance decreases (factor of 10!), if WIN_HEIGHT_DEFAULT > 100 and 
	# axes are turned on (SHOW_AXES == True).
	WIN_HEIGHT_DEFAULT = 80
	WIN_WIDTH_DEFAULT = 1000

	# instantiate our application & run setup() method.
	my_app = MainApp(WIN_HEIGHT_DEFAULT, WIN_WIDTH_DEFAULT)
	my_app.set_current_screen(StaticLineUpdateScreen)

	# overwrite default values with our custom settings.
	my_app.PLUGIN_NAME = PLUGIN_NAME
	my_app.abs_plugin_ID = abs_plugin_ID
	my_app.receive_data_from_matlab = receive_data_from_matlab
	my_app.COLOR_TO_USE = COLOR_TO_USE

	# run program.
	my_app.run()


