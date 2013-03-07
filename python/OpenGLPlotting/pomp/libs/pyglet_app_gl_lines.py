from pyglet.gl import *
from pyglet.window import key
from ctypes import sizeof

from pyglet_app_gl_helper import gl_transform_list_to_GLfloat, gl_setup_intial_data_and_color_vbos, set_glColorPointer_default, gl_on_draw_default, gl_calc_x_y_extend_from_current_glOrthoMatrix
from pyglet_app_input_dialogs import one_input

# offset that needs to be added to 'key.MOD_*' in order to match the 
# 'modifiers' value
mod_offset = 16

class gl_line(object):

    # Definitions for 'glColorPointer' and 'glVertexPointer'
    n_COORDINATES_PER_COLOR = 3
    n_COORDINATES_PER_VERTEX = 2

    # each float value has size 4;
    BYTES_PER_COORDINATE = 4

    # since one point is made of 2 values, each point has size 8 bytes.
    BYTES_PER_POINT = 2 * BYTES_PER_COORDINATE

    LINE_WIDTH = 1.5

    # current position of the line
    curr_pos = 0

    # delta increment of line (if it is moveable)
    delta = 1

    x_coords = []
    y_coords = []

    def __init__(self, mainapp, *args, **kwargs):
        self.mainapp = mainapp
        pass


    def setup_line(self, color, data, n_COORDINATES_PER_COLOR):
        colors = gl_transform_list_to_GLfloat(color * 2)    
        self.vbo_id, self.color_id, self.colors = gl_setup_intial_data_and_color_vbos(data, colors, n_COORDINATES_PER_COLOR)


    def setup_horizontal_line(self, MIN_x, MAX_x, y, color, n_COORDINATES_PER_COLOR = n_COORDINATES_PER_COLOR):
        data = gl_transform_list_to_GLfloat([MIN_x, y, MAX_x, y])
        self.setup_line(color, data, n_COORDINATES_PER_COLOR)


    def setup_vertical_line(self, MIN_y, MAX_y, x, color, n_COORDINATES_PER_COLOR = n_COORDINATES_PER_COLOR):
        data = gl_transform_list_to_GLfloat([x, MIN_y, x, MAX_y])
        self.setup_line(color, data, n_COORDINATES_PER_COLOR)


    def gl_update_line_value(self, value, offsets):

        glBindBuffer(GL_ARRAY_BUFFER, self.vbo_id)
        new_value = gl_transform_list_to_GLfloat([value])
        size_value = sizeof(new_value)
        for i in range(len(offsets)):
            glBufferSubData(GL_ARRAY_BUFFER, offsets[i], size_value, new_value)


    def gl_update_line_x_value(self, new_value):

        # offsets for first and second x value
        offsets = [0, self.BYTES_PER_POINT]

        if len(self.x_coords) > 0:
            new_value = self.x_coords[new_value]

        self.gl_update_line_value(new_value, offsets)
    

    def gl_update_line_y_value(self, new_value):

        # offsets for first and second y value
        offsets = [self.BYTES_PER_COORDINATE, self.BYTES_PER_COORDINATE + self.BYTES_PER_POINT]

        if len(self.y_coords) > 0:
            new_value = self.y_coords[new_value]

        self.gl_update_line_value(new_value, offsets)


    def draw(self):
        ''' draw horizontal line - which is made off 2 points only '''
        glLineWidth(self.LINE_WIDTH)
        glBindBuffer(GL_ARRAY_BUFFER, self.color_id)
        set_glColorPointer_default(self.n_COORDINATES_PER_COLOR)   
        gl_on_draw_default(self.vbo_id, self.n_COORDINATES_PER_VERTEX, 2, GL_LINE_STRIP)


    def set_position_horizontal_line(self, SETTINGS, label_strg = 'pleave provide input', cmd_line_string = 'please provide input and press ENTER', window_title = 'window'):

        got_value, new_value = one_input(SETTINGS, label_strg, cmd_line_string, window_title)

        # nothing given - return.
        if not got_value:
            return

        # save the new value
        self.write_position_horizontal_line(new_value)


    def write_position_horizontal_line(self, new_value):

        # cast to integer
        try:
            new_pos = int(new_value)
        except:
            pass
            print "non numeric value given - will ignore and keep old threshold."
            return

        # save new values.
        self.curr_pos = new_pos
        self.gl_update_line_y_value(new_pos)


    def move_horizontal_line_up(self, SETTINGS, modifiers, key, mod_offset):
        if modifiers == key.MOD_SHIFT + mod_offset:
            offset = 5 * self.delta
        else:
            offset = self.delta

        # save the new value
        # self.write_position_horizontal_line(min([self.curr_pos + offset, SETTINGS.WINDOW_HEIGHT_DEFAULT]))
        # don't enforce maximum boundary
        self.write_position_horizontal_line(self.curr_pos + offset)


    def move_horizontal_line_down(self, SETTINGS, modifiers, key, mod_offset):
        if modifiers == key.MOD_SHIFT + mod_offset:
            offset = 5 * self.delta
        else:
            offset = self.delta

        # save the new value
        # self.write_position_horizontal_line(max([self.curr_pos - offset, 0]))
        # don't enforce a lower boundary	
        self.write_position_horizontal_line(self.curr_pos - offset)		


    def kpf_change_horizontal_line(self, symbol, modifiers):

        # indicate whether we found a matching key
        key_matched = False

        if symbol == key.T: # set new position for horizontal line
            key_matched = True

            # toggle display of horizontal line.
            if modifiers == key.MOD_CTRL + mod_offset:
                if not self.mainapp.SHOW_HORIZONTAL_LINE:
                    # check if an old horizontal line is still here and extract
                    # its threshold.
                    previous_value = False
                    if self.mainapp.line_hor is not None:
                        # remove the old handler once we are about to setup a new horizontal line. Don't remove
                        # the handler before, otherwise we won't be able to setup the new line (no listener)
                        self.mainapp.window.remove_handlers(on_key_press = self.mainapp.line_hor.kpf_change_horizontal_line)
                        previous_value = self.mainapp.line_hor.curr_pos

                    # create new horizontal line and bind it to the 'mainapp'
                    self.mainapp.line_hor = line_default_horizontal(self.mainapp)

                    # set threshold to previously saved value (if found above)
                    if previous_value:
                        self.mainapp.line_hor.write_position_horizontal_line(previous_value)

                # invert the SHOW value
                self.mainapp.SHOW_HORIZONTAL_LINE = not self.mainapp.SHOW_HORIZONTAL_LINE

            elif modifiers == key.MOD_SHIFT + mod_offset:
                if self.mainapp.SHOW_HORIZONTAL_LINE:
                    print "current threshold = %d" % self.mainapp.line_hor.curr_pos

            else:
                if self.mainapp.SHOW_HORIZONTAL_LINE:
                    self.mainapp.line_hor.set_position_horizontal_line(self.mainapp.SETTINGS, 'Threshold (currently %d) ' % self.mainapp.line_hor.curr_pos, 'Please provide new threshold and press ENTER: ', 'Set new threshold')

        elif symbol == key.UP: # move horizontal line up
            key_matched = True
            self.mainapp.line_hor.move_horizontal_line_up(self.mainapp.SETTINGS, modifiers, key, mod_offset)

        elif symbol == key.DOWN: # move horizontal line down
            key_matched = True
            self.mainapp.line_hor.move_horizontal_line_down(self.mainapp.SETTINGS, modifiers, key, mod_offset)

        if key_matched:
            return pyglet.event.EVENT_HANDLED


    def kpf_vertical_line(self, symbol, modifiers):

        if symbol == key.V: # show / hide vertical line (toggle display of vertical line)

            if modifiers == key.MOD_CTRL + mod_offset:
                if not self.mainapp.SHOW_VERTICAL_LINE:
                    if self.mainapp.line_ver is not None:
                        # remove the old handler once we are about to setup a new vertical line. Don't remove
                        # the handler before, otherwise we won't be able to setup the new line (no listener)
                        self.mainapp.window.remove_handlers(on_key_press = self.mainapp.line_ver.kpf_vertical_line)

                    # create new vertical line and bind it to the 'mainapp'
                    self.mainapp.line_ver = line_default_vertical(self.mainapp)

                self.mainapp.SHOW_VERTICAL_LINE = not self.mainapp.SHOW_VERTICAL_LINE

            return pyglet.event.EVENT_HANDLED


def line_default_horizontal(main_app):

        # how much to the left and right should the line extend?
        hor_min_x = -20

        # set the initial position to half of the current y extent.
        x_diff_abs, y_diff_abs = gl_calc_x_y_extend_from_current_glOrthoMatrix(main_app.SETTINGS)
        hor_line_initial_y = y_diff_abs / 2

        line_hor = gl_line(main_app)
        line_hor.setup_horizontal_line(hor_min_x, main_app.SETTINGS.WINDOW_WIDTH_DEFAULT + hor_min_x, hor_line_initial_y, [0, 1, 0])

        line_hor.curr_pos = hor_line_initial_y
        line_hor.delta = 1

        # register the key press function that is associated with the the horizontal line.
        main_app.window.push_handlers(on_key_press = line_hor.kpf_change_horizontal_line)

        return line_hor


def line_default_vertical(main_app):

        line_ver = gl_line(main_app)
        line_ver.setup_vertical_line(-main_app.SETTINGS.WINDOW_HEIGHT_CURRENT, main_app.SETTINGS.WINDOW_HEIGHT_CURRENT, 0, [0, 1, 1])

        line_ver.x_coords = main_app.x_coords
        line_ver.LINE_WIDTH = 0.2

        # register the key press function that is associated with the the vertical line.
        main_app.window.push_handlers(on_key_press = line_ver.kpf_vertical_line)

        return line_ver


