''' this class is keeping track of all application settings, so that
    we can pass them to interacting objects (as a reference since objects are 
    mutable in Python '''

class settings(object):

    # default and current window dimensions.
    WINDOW_WIDTH_DEFAULT = 800
    WINDOW_HEIGHT_DEFAULT = 800
    WINDOW_WIDTH_CURRENT = False
    WINDOW_HEIGHT_CURRENT = False

    # current glOrtho projection matrix - ideally we have one for each panel.
    CURRENT_glOrtho_MATRIX = False

    # did we find Tkinter on the system and does it run ok?
    TKINTER_AVAILABLE = False

    # where should we save the screenshot? will be 'pwd' by default.
    SCREENSHOT_PATH = None 

    # what color should we use for plotting the data?
    # TODO: this should be a per-panel configuration
    # if you set this value to 'False', a random value will be generated.
    COLOR_TO_USE = False

    # the actual color that we ended up using, per-panel. 
    COLOR_USED = False


    def __init__(self, *args, **kwargs):
        pass



