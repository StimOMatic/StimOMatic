# pyglet imports
import pyglet
# disable opengGL debugging - this will give us a speedup. We need to set this 
# option right here and not later in the code.
pyglet.options['debug_gl'] = False
from pyglet.gl import *
from pyglet.window import key

# system imports
import sys
import os
from datetime import datetime

# our libraries
from pyglet_app_basic_screens import BasicScreen
from pyglet_app_gl_helper import gl_setup_initial_data_and_color_and_vbos
from pyglet_app_data_management import setup_plotting_queue, setup_incoming_data_interface, request_new_data, append_data_to_plot_queue


from pyglet_app_gl_axes import axes_default_with_y_ticks
from pyglet_app_gl_lines import line_default_horizontal, line_default_vertical
from pyglet_app_tkinter_helper import tkinter_register_with_settings
from pyglet_app_input_dialogs import one_input

from pyglet_app_consts import n_COORDINATES_PER_COLOR
from pyglet_app_settings import settings
from pyglet_app_profile import profile_code, PROFILE


" Class representing the Application API"
class ApplicationTemplate(object):

    # settings that can be accessed by other objects.
    SETTINGS = settings()
  
    ''' default __init__() function - sets the window dimensions and creates a BasicScreen '''
    def __init__(self, WIN_HEIGHT_DEFAULT, WIN_WIDTH_DEFAULT):

        # save window height and width that we started out with.
        if WIN_HEIGHT_DEFAULT is not None:
            self.SETTINGS.WINDOW_HEIGHT_DEFAULT = WIN_HEIGHT_DEFAULT

        if WIN_WIDTH_DEFAULT is not None:
            self.SETTINGS.WIN_WIDTH_DEFAULT = WIN_WIDTH_DEFAULT

        # always initialize with 'BasicScreen' config.
        self.current_screen = BasicScreen(self)


    ''' startCurrentScreen() will start the currently configured Screen. '''
    def startCurrentScreen(self):

        # register 'current_screen' handlers.
        self.window.push_handlers("on_key_press", self.current_screen.on_key_press)
        self.window.push_handlers("on_draw", self.current_screen.on_draw)
        self.window.push_handlers("on_resize", self.current_screen.on_resize)

        # schedule the 'current_screen.update()' method to be called each 'update_interval'
        pyglet.clock.schedule_interval(self.current_screen.update, self.update_interval)

        # call start of the current scene / screen - will create additional handlers.
        self.current_screen.start()


    ''' run 'clearCurrentScreen' in case you want to switch between Screens '''
    def clearCurrentScreen(self):
        # undo most of the stuff that had been done in 'startCurrentScreen'
        pyglet.clock.unschedule(self.current_screen.update)
        self.current_screen.clear()
        self.window.remove_handlers("on_key_press", self.current_screen.on_key_press)
        self.window.remove_handlers("on_draw", self.current_screen.on_draw)
        self.window.remove_handlers("on_resize", self.current_screen.on_resize)


    ''' sets the current screen by passing the current Application to it '''
    def set_current_screen(self, current_screen):
        self.current_screen = current_screen(self)


    ''' default key press function '''
    def on_key_press(self, symbol, modifiers):
        pass


    ''' default setup_window() function which builds a pyglet window 
        this function should not depend on any parameters that are being set in 
        'setup()'!
     '''
    def setup_window(self):
        # setup the pyglet window.
        self.window = pyglet.window.Window(width=self.SETTINGS.WINDOW_WIDTH_DEFAULT, height=self.SETTINGS.WINDOW_HEIGHT_DEFAULT, resizable=True)

        # try to load our icon (if present)
        try:
            self.window.set_icon(pyglet.resource.image('icon.png'))
        except:
            pass


    ''' setup() function for all custom stuff that your application will need / do '''
    def setup(self):
        pass


    ''' run function invoked by the user - starts everything in the right order '''
    def run(self):
        # setup window first, because some of the objects in 'setup()' need a window.
        self.setup_window()
        self.setup()
        self.startCurrentScreen()
        pyglet.app.run()




"Class managing our Main application, which handles both MMAP and random data input"
class MainApp(ApplicationTemplate):

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
    RANDOM_DATA = False

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

    # offset that needs to be added to 'key.MOD_*' in order to match the 
    # 'modifiers' value
    mod_offset = 16

    # switch between different screen update modes using 'm'
    _screen_update_mode = 0

    @profile_code(PROFILE)
    def setup(self):

        ''' 
            process custom settings that might have been set after initializing
            the object.  
        '''
        # check if these parameters / properties / attributes were actually set!
        self.USE_MMAP = getattr(self, 'receive_data_from_matlab', self.USE_MMAP)
        self.SETTINGS.COLOR_TO_USE = getattr(self, 'COLOR_TO_USE', self.SETTINGS.COLOR_TO_USE)

        # add 'abs_plugin_ID' to plugin name.
        self.PLUGIN_NAME = self.PLUGIN_NAME + '-' + str(self.abs_plugin_ID)


        ''' set variables based on init() values. '''
        self.Y_LIMS = [0, self.SETTINGS.WINDOW_HEIGHT_DEFAULT]
        self.SETTINGS.WINDOW_WIDTH_CURRENT = self.SETTINGS.WINDOW_WIDTH_DEFAULT
        self.SETTINGS.WINDOW_HEIGHT_CURRENT = self.SETTINGS.WINDOW_HEIGHT_DEFAULT

        ''' setup mmap or random data interface '''
        status, self.MMAP, self.RANDOM_DATA = setup_incoming_data_interface(self.USE_MMAP, self.PLUGIN_NAME, self.NBR_CHANNELS, self.nPointsToUpdate, self.nPoints, self.SETTINGS.WINDOW_WIDTH_CURRENT, self.SETTINGS.WINDOW_HEIGHT_CURRENT)
        if not status:
             sys.exit(1)


        ''' setup plot queue '''
        self.plot_queue = setup_plotting_queue()


        ''' generate initial positions & colors, and setup VOBs '''
        self.vbo_data, self.vbo_colors, self.x_coords, self.SETTINGS.COLOR_USED = \
            gl_setup_initial_data_and_color_and_vbos(self.nPoints, n_COORDINATES_PER_COLOR, self.NBR_CHANNELS, self.SETTINGS)


        ''' horizontal and vertical lines - setup even if user doesn't want 
            to see them, because we setup key press functions to en-/disable them. '''
        # horizontal line showing the threshold 
        self.line_hor = line_default_horizontal(self)

        # vertical line showing which data point is going to be update next 
        self.line_ver = line_default_vertical(self)

        ''' axes - setup even it user doesn't want to see it, because of kpf. '''
        self.coord_axes, self.y_axis_tics = axes_default_with_y_ticks(self)


        ''' other stuff '''
        # is Tkinter installed and running?
        self.SETTINGS = tkinter_register_with_settings(self.SETTINGS)

        # set the window caption. Can't do it in 'setup_window' because some parameters
        # are not processed there yet.
        self.setup_window_caption()


    ''' our main key press function '''
    def on_key_press(self, symbol, modifiers):

        ''' basic kpf '''
        if symbol == key.A: # show / hide axes
            if modifiers == key.MOD_CTRL + self.mod_offset:
                if self.SHOW_AXES:
                    self.coord_axes, self.y_axis_tics, self.SHOW_AXES = False, False, False
                else:
                    self.SHOW_AXES = True
                    self.coord_axes, self.y_axis_tics = axes_default_with_y_ticks(self)

        elif symbol == key.C:
            self.plot_queue = setup_plotting_queue()
            print "Cleared Plot-Queue"        

        elif symbol == key.F: # show / hide FPS display
            self.SHOW_FPS = not self.SHOW_FPS

        elif symbol == key.H: # show help menu
            from pyglet_app_strings import main_help_menu
            # the tkinterface is currently buggy - show console output by default.
            if self.SETTINGS.TKINTER_AVAILABLE and (modifiers == key.MOD_CTRL + self.mod_offset):
                from pyglet_app_tkinter_dialogs import text_info
                help_win = text_info()
                help_win.run('help', main_help_menu)
            else:
                print main_help_menu

        elif symbol == key.P: # switch between plotting modes
            from pyglet_app_screen_update_elements_static_line import StaticLineUpdateScreen
            from pyglet_app_screen_update_elements_moving_line import MovingLineUpdateScreen

            # we have three different modes currently that we can choose from.
            self._screen_update_mode = (self._screen_update_mode + 1) % 3

            if self._screen_update_mode == 0:
                current_screen = StaticLineUpdateScreen
                mode = 0
            elif self._screen_update_mode == 1: 
                current_screen = StaticLineUpdateScreen
                mode = 1
            elif self._screen_update_mode == 2:
                current_screen = MovingLineUpdateScreen
                mode = None

            self.clearCurrentScreen()
            self.set_current_screen(current_screen)
            self.current_screen.mode = mode
            self.startCurrentScreen()

        elif symbol == key.Q: # show number of elements in plot queue
            print "Plot-Queue size: %d" % (len(self.plot_queue))

        elif symbol == key.S: # take screenshot of current screen content
            if (modifiers == key.MOD_SHIFT + self.mod_offset): # set screenshot path
                label_strg = 'Screenshot path '
                if self.SETTINGS.SCREENSHOT_PATH is not None:
                    label_strg = label_strg + '(currently %s) '%self.SETTINGS.SCREENSHOT_PATH
                got_value, new_value = one_input(self.SETTINGS, label_strg, 'Please provide new Screenshot path and press ENTER: ', 'Screenshot path')
                # nothing given - return.
                if not got_value:
                    return
                # replace '\' with '/' because path.join() transforms everything to '/' notation.
                self.SETTINGS.SCREENSHOT_PATH = new_value.replace('\\', '/')
            elif not (modifiers == key.MOD_CTRL + self.mod_offset):
                try:
                    now = datetime.now().strftime("%Y-%m-%d--%H-%M-%S")
                    filename = 'Screenshot-from-%s---%s.png' %(now, self.PLUGIN_NAME)
                    if self.SETTINGS.SCREENSHOT_PATH is not None:
                        filename = os.path.join(self.SETTINGS.SCREENSHOT_PATH, filename)
                    pyglet.image.get_buffer_manager().get_color_buffer().save(filename)
                    print 'File "%s" saved.' % filename
                except Exception, e:
                    print "An error occurred while saving the screenshot: "
                    print e
                    pass

        elif symbol == key.ESCAPE: # quit program
            sys.exit()

        elif symbol == key.SPACE: # freeze / resume plotting
            self.DO_DRAW = not self.DO_DRAW

        # uncomment for debugging purposes.
        #else:
        #    print '%s key, %s modifier was pressed' % (symbol, modifiers)


    ''' setup our window '''
    @profile_code(PROFILE)
    def setup_window(self):
        # run 'setup_window' of the parent class first.
        super(MainApp, self).setup_window()

        # register generic key press function in 'MainApp' class.
        self.window.push_handlers("on_key_press", self.on_key_press)


    ''' sets the window caption according to the preconfigure mode '''
    def setup_window_caption(self):
        # set window caption
        win_title = 'generating random data'
        if self.USE_MMAP:
            win_title = 'receiving data from matlab'
        nbr_points_shown = ' -- showing %s points per panel.' % self.nPoints
        self.window.set_caption(self.PLUGIN_NAME + ' -- ' + win_title + nbr_points_shown)


    ''' gets new data from the appropriate source and enqueues it to the plot queue'''
    @profile_code(PROFILE)
    def poll_and_enqueue_data(self):

        ''' START  'DATA MANAGEMENT'  '''
        # pick up new data from mmap or other system (i.e. generated)
        new_data, new_data_is_empty, nbr_buffers_per_mmap_file = request_new_data(self.USE_MMAP, self.RANDOM_DATA, self.MMAP)

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

	''' auto-purge plot queue if feature is activated and limit is reached. '''
    def purge_plot_queue_if_necessary(self):

		if self.plot_queue_purge_if_size_limit_reached and len(self.plot_queue) > self.plot_queue_size_limit:
			self.plot_queue = setup_plotting_queue()





