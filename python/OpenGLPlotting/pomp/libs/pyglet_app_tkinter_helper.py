''' Tkinter helper functions '''

def tkinter_check_if_found_and_running():
	found_and_ok = True
	try:
		# in order to check whether Tkinter is working, we try to import 
  		# one of our own dialogs.
		from pyglet_app_tkinter_dialogs import get_two_inputs
		# print "Tkinter found!"
	except Exception, e:
		pass
		found_and_ok = False
		print "There was a problem initializing the Tkinter interface:"
		print e

	return found_and_ok


def tkinter_register_with_settings(settings):
	settings.TKINTER_AVAILABLE = tkinter_check_if_found_and_running()
	return settings


