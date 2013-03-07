from pyglet.gl import *
from pyglet.window import key
from pyglet import event


# pyglet_app_* imports
from pyglet_app_gl_helper import gl_on_draw_default, set_glColorPointer_default, gl_ortho_projection, gl_update_two_coordinates_in_VBO_static_view

from pyglet_app_data_management import get_data_from_plot_queue
from pyglet_app_consts import BYTES_PER_COORDINATE, BYTES_PER_POINT, n_COORDINATES_PER_COLOR, n_COORDINATES_PER_VERTEX
from pyglet_app_profile import profile_code, PROFILE


# definitions needed for dequeueing of plot buffers & writting into memory.
MAX_NBR_BUFFERS_TO_UPDATE = 10
MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE = 2

from pyglet_app_basic_screens import ExtendedScreen

class StaticLineUpdateScreen(ExtendedScreen):

    # what update mode do you want to use?
    # 0 = fill screen, leave old data and overwrite with new one.
    # 1 = fill screen, then clear screen and start writting new data again (to empty screen)
    mode = 0

    # update counter for this 'update()' mode.
    _c = 0

    # needed during startup of application - we don't want to draw 
    # non-initialized parts of the data. needed in calc_nbr_points_to_draw().
    _full_cycle_drawn = False
    
    # did we run update() at least once? needed in calc_nbr_points_to_draw().
    _update_executed = False

    # how many points (out of the total self.mainapp.nPoints) did we currently 
    # (after the latest update() call) render?
    _nPoints_currently_rendered = 0


    ''' 
        update() function which specifically overwrittes only parts of the memory.
        This is were most of the drawing-speed-up-magic happens.
    '''
    @profile_code(PROFILE)
    def update(self, dt):

        # updates nPointsToUpdate points per `update()` call
        # TODO: handle cases where 'nPoints' is not a multiple of 'nPointsToUpdate'
        # (need to wrap around at the end of the list)

        # 1. handle the incoming data - we always do this step, regardless of whether we
        # are plotting or not.
        self.mainapp.poll_and_enqueue_data()

        # 2. Quit here if we are not supposed to draw anything new. This way the queue
        # keeps growing and we don't miss anything.
        if not self.mainapp.DO_DRAW:
            return

        # 3. don't purge entire queue - keep at least 'MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE' elements in queue.
        # this will give us a smoother plotting experience.
        queue_length = len(self.mainapp.plot_queue)
        if queue_length < MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE:
            return    

        # indicate that 'update()' did run the first time.
        self._update_executed = True

        ''' 4. START  'dequeue buffers and prepare them for plotting'  '''
        # plot ALL buffers currently in queue.
        # don't got through all elements in the queue, otherwise the memory updating
        # and the drawing might go out of sync. This can happen if the plugin had been
        # turned off and data accumlated on the matlab side. 
        for j in xrange(min(queue_length, MAX_NBR_BUFFERS_TO_UPDATE)):

            # dequeue buffers and update VBOs
            # raw_data is an array of channels containing the data per channel.
            raw_data = get_data_from_plot_queue(self.mainapp.plot_queue)
            #print raw_data
        
            # update y values in main VBO - do this for each channel!
            nbr_points_rendered_in_previous_loop = gl_update_two_coordinates_in_VBO_static_view(raw_data, self.mainapp.vbo_data, self._c, self.mainapp.nPoints, self.mainapp.nPointsToUpdate, BYTES_PER_POINT, BYTES_PER_COORDINATE, self.mainapp.NBR_CHANNELS, self.mainapp.x_coords)

            # Update position of vertical line - move it one 'nPointsToUpdate' 
            # buffer ahead of currently updated position. calc modulo 'nPoints', 
            # so that the position is in the range from 0 to nPoints.
            self.mainapp.line_ver.curr_pos = (nbr_points_rendered_in_previous_loop + 2 * self.mainapp.nPointsToUpdate) % self.mainapp.nPoints
            
            # increase counter, so that 'c' doesn't grow out of bounds.
            self._c = (self._c + 1) % (self.mainapp.nPoints / self.mainapp.nPointsToUpdate)
        ''' END 'dequeue buffers and prepare them for plotting'  '''

        
        # set the resulting vertical line position.
        if self.mainapp.SHOW_VERTICAL_LINE:
            self.mainapp.line_ver.gl_update_line_x_value(self.mainapp.line_ver.curr_pos)

        # auto-purge plot queue if feature is activated and limit is reached.
        self.mainapp.purge_plot_queue_if_necessary()
        
        # update the number of currently rendered points. This is the sum of points rendered in the previous
        # loop, plus the number of points updated in the current loop.
        self._nPoints_currently_rendered = nbr_points_rendered_in_previous_loop + self.mainapp.nPointsToUpdate


    @profile_code(PROFILE)
    def on_draw(self):

        ''' clear background '''    
        glEnable(GL_NORMALIZE)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # calculate the height per panel
        height_per_panel = (self.mainapp.SETTINGS.WINDOW_HEIGHT_CURRENT / self.mainapp.NBR_CHANNELS)

        # calculate how many points we need to render
        nbr_points_to_draw = self.calc_nbr_points_to_draw()

        # loop over all panels
        for panel in range(self.mainapp.NBR_CHANNELS):

            ''' START THIS PANEL '''
            glPushMatrix()

            glViewport(0, panel * height_per_panel, self.mainapp.SETTINGS.WINDOW_WIDTH_CURRENT, height_per_panel)
            # apply current scaling (if any) to the active panel
            if self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX:
                gl_ortho_projection(self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX[0], self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX[1], self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX[2], self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX[3])

            # draw lines #
            ''' draw vertical line first '''
            if self.mainapp.SHOW_VERTICAL_LINE:
                self.mainapp.line_ver.draw()

            ''' start - panel data '''
            # TODO: make line width a parameter. Line width must be set AFTER the 
            # glPushMatrix() statement above.
            glLineWidth(3.0)

            ''' draw data plot '''
            # TODO: this is a temporary situation with one VBO per panel!
            glBindBuffer(GL_ARRAY_BUFFER, self.mainapp.vbo_colors[panel][0])
            set_glColorPointer_default(n_COORDINATES_PER_COLOR)


            # TODO: this is a temporary situation with one VBO per panel!
            gl_on_draw_default(self.mainapp.vbo_data[panel][0], n_COORDINATES_PER_VERTEX, nbr_points_to_draw, GL_LINE_STRIP)
            ''' end - panel data '''


            ''' draw horizontal line - which is made off 2 points only '''
            if self.mainapp.SHOW_HORIZONTAL_LINE:
                self.mainapp.line_hor.draw()

            glPopMatrix()
            ''' END THIS PANEL '''

            # draw axes, tics and labels #
            if self.mainapp.SHOW_AXES:
                self.mainapp.coord_axes.draw()
                self.mainapp.y_axis_tics.draw(self.mainapp.Y_LIMS)
        
        # go back to main perspective and show the FPT
        glPushMatrix()
        glViewport(0, 0, self.mainapp.SETTINGS.WINDOW_WIDTH_CURRENT, self.mainapp.SETTINGS.WINDOW_HEIGHT_CURRENT)
        gl_ortho_projection(self.mainapp.RESIZE_OFFSET_X, self.mainapp.SETTINGS.WINDOW_WIDTH_CURRENT, self.mainapp.RESIZE_OFFSET_Y, self.mainapp.SETTINGS.WINDOW_HEIGHT_CURRENT)
        # draw FPS  #
        if self.mainapp.SHOW_FPS:
            self.mainapp.fps_display.draw()
        glPopMatrix()


    ''' depending on the selected mode, this function will calculate how many 
        data points should be drawn to screen '''
    def calc_nbr_points_to_draw(self):

        # the default is to draw no points - no data - nothing to draw.
        nbr_points_to_draw = 0

        if self.mode == 0:
            # 'update()' is always called after 'on_draw()', therefore we check 
            # for the first time that 'update()' has been called and '_c' has been
            # set back to zero -> we've run through one entire cycle & can show
            # all data points now.
            if self._update_executed:
                if not self._full_cycle_drawn:
                    nbr_points_to_draw = self._nPoints_currently_rendered
                    if self._c == 0:
                        nbr_points_to_draw = self.mainapp.nPoints
                        self._full_cycle_drawn = True
                else:
                    nbr_points_to_draw = self.mainapp.nPoints

        elif self.mode == 1:
            # show only the actual data points that have been written until this point.
            nbr_points_to_draw = self._nPoints_currently_rendered

        return nbr_points_to_draw


