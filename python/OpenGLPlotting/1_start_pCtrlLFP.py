''' start-up script for pCtrlLFP plugin - please fill out the next few line '''

# set the 'abs_plugin_ID' to the value you see in Matlab (ID=x)
abs_plugin_ID = 2



''' do not change anything below this point! '''
plugin_name = 'pCtrlLFP.py'

from pomp.pomp_app_starter import run_app
run_app(plugin_name, abs_plugin_ID)
