import pyglet
from pyglet.window import key

from pyglet_app_gl_helper import set_gl_defaults, gl_enable_line_smoothing
from pyglet_app_gl_axes import check_y_lims

''' abstract Screen class '''
class BasicScreen(object):
    
    def __init__(self, mainapp):
        self.mainapp = mainapp
        pass

    def start(self):
        pass

    def clear(self):
        pass

    def on_key_press(self, symbol, modifiers):
        pass

    def on_draw(self):
        pass

    def on_resize(self, w, h):
        pass

    def update(self, dt):
        pass


''' Screen class that we use for all plugins '''
class ExtendedScreen(BasicScreen):
    
    # every 'ExtendedScreen' class can have different modes to choose from.
    mode = None

    def clear(self):
        # remove handler set in 'start()'
        self.mainapp.window.remove_handlers(on_key_press = self.kpf_change_y_lims)
        # remove 'fps_display' setup in 'start()'
        self.mainapp.fps_display.unschedule()


    ''' start() function '''
    def start(self):
        # set default gl modes
        set_gl_defaults(self.mainapp.POINT_SIZE)

        # try to render a smooth line (if supported by driver)
        gl_enable_line_smoothing()

        # hide mouse - disabled.
        # self.set_mouse_visible(False)

        # Create a font for our FPS clock
        ft = pyglet.font.load('Arial', 28)
        self.mainapp.fps_display = pyglet.clock.ClockDisplay(font = ft, interval=0.125, format='FPS %(fps).2f')

        self.mainapp.window.push_handlers(on_key_press = self.kpf_change_y_lims)


    ''' on_resize function '''
    def on_resize(self, w, h):

        # Prevent a divide by zero, when window is too short
        # (you cant make a window of zero width).
        if h == 0:
            h = 1

        # see http://profs.sci.univr.it/~colombar/html_openGL_tutorial/en/04viewports_011.html
        # on how-to lock aspect ratio.

        self.mainapp.SETTINGS.WINDOW_WIDTH_CURRENT = w
        self.mainapp.SETTINGS.WINDOW_HEIGHT_CURRENT = h

        aspect = float(w) / float(h)

        ''' make sure the window goes from [0, self.SETTINGS.WINDOW_WIDTH_DEFAULT] in the
           smallest dimension  '''

        left = 0
        right = self.mainapp.SETTINGS.WINDOW_WIDTH_DEFAULT
        bottom = self.mainapp.Y_LIMS[0]

        #print "aspect = %f " %aspect
        if aspect < 1.0:
            top = self.mainapp.Y_LIMS[1] * ( 1.0 / aspect )
        else:
            top = self.mainapp.Y_LIMS[1]

        self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX = [left + self.mainapp.RESIZE_OFFSET_X, right, bottom + self.mainapp.RESIZE_OFFSET_Y, top]


    ''' key press function for changing y limits '''
    def kpf_change_y_lims(self, symbol, modifiers):

        mod_offset = self.mainapp.mod_offset
        do_resize = 0
        key_matched = False

        if symbol == key.Y: # set y lims explicitly 
            key_matched = True
            lower = False # upper limit is default.

            if modifiers == key.MOD_CTRL + mod_offset: # upper limit (y + ctrl)
                lower = False
                do_resize = self.change_y_value_cmd_line(lower)

            elif modifiers == key.MOD_SHIFT + mod_offset: # lower limit?  (y + shift)
                lower = True
                do_resize = self.change_y_value_cmd_line(lower)

            else: # GUI to change both values (y)
                do_resize = self.change_y_values_GUI()

        elif symbol == key._1: # decrease upper y lim
            self.mainapp.Y_LIMS = check_y_lims(self.mainapp.Y_LIMS, self.mainapp.Y_LIMS[1] - 10, 1)
            # left, right, bottom, top
            do_resize = 1

        elif symbol == key._2: # increase upper y lim
            self.mainapp.Y_LIMS = check_y_lims(self.mainapp.Y_LIMS, self.mainapp.Y_LIMS[1] + 10, 1)
            do_resize = 1

        elif symbol == key._3: # decrease lower y lim
            self.mainapp.Y_LIMS = check_y_lims(self.mainapp.Y_LIMS, self.mainapp.Y_LIMS[0] - 10, 0)
            do_resize = 1

        elif symbol == key._4: # increase lower y lim
            self.mainapp.Y_LIMS = check_y_lims(self.mainapp.Y_LIMS, self.mainapp.Y_LIMS[0] + 10, 0)
            do_resize = 1

        elif symbol == key._0: # restore original y lims.
            do_resize = 2


        if do_resize == 1: # resize according to y-lims.
            key_matched = True
            # left, right, bottom, top
            self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX = [self.mainapp.RESIZE_OFFSET_X, self.mainapp.SETTINGS.WINDOW_WIDTH_DEFAULT, self.mainapp.Y_LIMS[0] + self.mainapp.RESIZE_OFFSET_Y, self.mainapp.Y_LIMS[1]]

        elif do_resize == 2: # resize according to original startup resolution.
            key_matched = True
            # left, right, bottom, top
            self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX = [self.mainapp.RESIZE_OFFSET_X, self.mainapp.SETTINGS.WINDOW_WIDTH_DEFAULT, self.mainapp.RESIZE_OFFSET_Y, self.mainapp.SETTINGS.WINDOW_HEIGHT_DEFAULT]

        if key_matched:
            return pyglet.event.EVENT_HANDLED


    ''' set upper or lower Y-LIM on command line '''
    def change_y_value_cmd_line(self, lower):

        do_resize = 0

        while 1:
            if lower:
                strg = 'lower'
                index = 0
            else:
                strg = 'upper'
                index = 1

            t = raw_input('Please provide %s y limit (currently %s) and press ENTER: ' % (strg, self.mainapp.Y_LIMS[index]) )
            if len(t) == 0:
                break

            try:
                new_value = float(t)
                self.mainapp.Y_LIMS = check_y_lims(self.mainapp.Y_LIMS, new_value, index)
                do_resize = 1
            except Exception, e:
                # print "Error in 'kpf_change_y_lims()': ", e
                pass
                print "non numeric value given - will ignore and keep old threshold"
            break

        return do_resize


    ''' set upper and lower Y-LIMs through GUI '''
    def change_y_values_GUI(self):

        do_resize = 0

        if not self.mainapp.SETTINGS.TKINTER_AVAILABLE:
            print "GUI is not working on your machine."
        else:
            try:
                from pyglet_app_tkinter_dialogs import get_two_inputs
                a = get_two_inputs()
                a.run('change y limits', 'y min', 'y max', self.mainapp.Y_LIMS[0], self.mainapp.Y_LIMS[1])
                # user submitting at least one new value.
                if a.dialog.result:
                    self.mainapp.Y_LIMS = check_y_lims(self.mainapp.Y_LIMS, a.dialog.result[0], 0)
                    self.mainapp.Y_LIMS = check_y_lims(self.mainapp.Y_LIMS, a.dialog.result[1], 1)
                    self.mainapp.Y_LIMS = sorted(self.mainapp.Y_LIMS)
                    do_resize = 1
            except Exception, e:
                pass
                print "An error occurred:"
                print e

        return do_resize


