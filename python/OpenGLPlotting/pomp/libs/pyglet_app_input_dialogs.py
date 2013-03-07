''' 

    this module contains generic dialogs which will use the GUI is present 
    or otherwise fall back to console 

'''


''' dialog asking user to provide one new value '''
def one_input(SETTINGS, label_string, cmd_line_string, window_title = None):

    # by default we assume that the user doesn't provide a new value.
    got_value = False
    new_value = False

    # use GUI
    if SETTINGS.TKINTER_AVAILABLE:
        from pyglet_app_tkinter_dialogs import get_one_input
        a = get_one_input()
        a.run(window_title, label_string)
        if a.result:
            got_value = True
            new_value = a.result

    # use command line
    else:
        while 1:
            new_value = raw_input(cmd_line_string)
            if len(new_value) > 0:
                got_value = True
            break

    return got_value, new_value



