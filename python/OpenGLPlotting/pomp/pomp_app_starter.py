import os, sys

# path to python executable
path_to_python = sys.executable

# the name of our module
module_name = 'pomp' 

def build_path_names(plugin_name):
	# extract the filename without the '.py' extension
	plugin_filename_no_ext = plugin_name[:plugin_name.find('.py')]
	
	# build application string
	app_path = path_to_python + ' -m ' + module_name + '.' + 'apps' + '.' + plugin_filename_no_ext

	return app_path


def run_app(plugin_name, abs_plugin_ID, channel_numbers = None):

	app_path = build_path_names(plugin_name)

	# we are calling 'start', which is a windows command to fork a new process.
	# the '/B' option forces 'start' to not open a new command window.
	if channel_numbers:
		for j in channel_numbers:
			os.system('start /B %s %s-%s' %(app_path, abs_plugin_ID, j))

	else:
		os.system('start /B %s %s' %(app_path, abs_plugin_ID))
		