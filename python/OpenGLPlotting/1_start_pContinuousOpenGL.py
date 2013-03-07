''' start-up script for pContinuousOpenGL plugin - please fill out the next few line '''

# set the 'abs_plugin_ID' to the value you see in Matlab (ID=x)
abs_plugin_ID = 1

# these are the channels that you've configured in Matlab ('CSC Channels')
channel_numbers = [43, 45]



''' do not change anything below this point! '''
plugin_name = 'pContinuousOpenGL.py'

from pomp.pomp_app_starter import run_app
run_app(plugin_name, abs_plugin_ID, channel_numbers)
