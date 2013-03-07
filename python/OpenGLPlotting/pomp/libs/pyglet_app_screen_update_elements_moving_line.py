from pyglet.gl import *

# pyglet_app_* imports
from pyglet_app_gl_helper import set_glColorPointer_default, gl_ortho_projection, gl_transform_vector_of_buffers_to_GPU_format, gl_Bind_Buffer_SubData
from pyglet_app_data_management import get_data_from_plot_queue
from pyglet_app_consts import BYTES_PER_POINT, n_COORDINATES_PER_COLOR
from pyglet_app_profile import profile_code, PROFILE


# definitions needed for dequeueing of plot buffers & writting into memory.
MAX_NBR_BUFFERS_TO_UPDATE = 10
MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE = 2

from pyglet_app_basic_screens import ExtendedScreen

# TODO: 
# fix the number of points to be rendered given the amount of data uploaded to 
# the GPU. Currently we always render ALL points, even if that part of the memory
# hasn't been filled yet. This leads to an artifact.
class MovingLineUpdateScreen(ExtendedScreen):

    # should we render the connection between the end of the line and the beginning
    # of the line?
    show_wrap_around_line = True

    # update counter for this 'update()' mode.
    _c = 0

    # coordinates of line connecting the end and beginning of the data plot
    _end_of_line_coordinates = [None, None]
    _beginning_of_line_coordinates = [None, None]


    ''' override 'start' and fix channel dependent properties '''
    def start(self):
        super(MovingLineUpdateScreen, self).start()
        
        # populate end of line and beginning of line lists with Nones for each channel.
        self._end_of_line_coordinates = [[None, None] for j in xrange(self.mainapp.NBR_CHANNELS)]
        self._beginning_of_line_coordinates = [[None, None] for j in xrange(self.mainapp.NBR_CHANNELS)]

        # calculate the x-coordinate offset between first point and the (first + nPointsToUpdate) point.
        self._x_spacing = self.mainapp.x_coords[self.mainapp.nPointsToUpdate] - self.mainapp.x_coords[0]

    ''' 
        update() function which specifically overwrittes only parts of the memory.
        This is were most of the drawing-speed-up-magic happens.
    '''
    @profile_code(PROFILE)
    def update(self, dt):

        # updates self.mainapp.nPointsToUpdate points per `update()` call
        # TODO: handle cases where 'nPoints' is not a multiple of 'self.mainapp.nPointsToUpdate'
        # (need to wrap around at the end of the list)

        # 1. handle the incoming data - we always do this step, regardless of whether we
        # are plotting or not.
        self.mainapp.poll_and_enqueue_data()

        # 2. don't purge entire queue - keep at least 'MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE' elements in queue.
        # this will give us a smoother plotting experience.
        queue_length = len(self.mainapp.plot_queue)
        if queue_length < MIN_NBR_BUFFERS_NECESSARY_FOR_UPDATE:
            return    

        ''' 3. START  'dequeue buffers and prepare them for plotting'  '''
        # plot ALL buffers currently in queue.
        # don't got through all elements in the queue, otherwise the memory updating
        # and the drawing might go out of sync. This can happen if the plugin had been
        # turned off and data accumlated on the matlab side. 
        for j in xrange(min(queue_length, MAX_NBR_BUFFERS_TO_UPDATE)):

            # dequeue buffers and update VBOs
            # raw_data is an array of channels containing the data per channel.
            raw_data = get_data_from_plot_queue(self.mainapp.plot_queue)

            # update y values in main VBO - do this for each channel!
            self.update_data_for_wrapped_buffer(self.mainapp.vbo_data, raw_data)

            # increase counter, so that 'c' doesn't grow out of bounds.
            self._c = (self._c + 1) % (self.mainapp.nPoints / self.mainapp.nPointsToUpdate)

        # auto-purge plot queue if feature is activated and limit is reached.
        self.mainapp.purge_plot_queue_if_necessary()


    @profile_code(PROFILE)
    def update_data_for_wrapped_buffer(self, vbos, raw_data):

        update_end_of_line_coordinates = False
        update_beginning_of_line_coordinates = False

        # we want to overwrite the positiont that is left to the current pointer c.
        d = self._c - 1 
        if d < 0:
            # loop around detected !!'
            d = (self.mainapp.nPoints / self.mainapp.nPointsToUpdate) - 1
            update_end_of_line_coordinates = True

        if d == 0:
            update_beginning_of_line_coordinates = True

        offset_to_start_from = d % (self.mainapp.nPoints / self.mainapp.nPointsToUpdate)
        nbr_points_rendered_in_previous_loop = int(offset_to_start_from * self.mainapp.nPointsToUpdate)
        offset_bytes = (nbr_points_rendered_in_previous_loop * BYTES_PER_POINT)

        # extract the x values of the corresponding buffers that we are updating.
        last_x_points = self.mainapp.x_coords[nbr_points_rendered_in_previous_loop:]
        last_x_points = last_x_points[0 : self.mainapp.nPointsToUpdate]

        # create x / y pairs per channel
        data = gl_transform_vector_of_buffers_to_GPU_format(raw_data, last_x_points)

        # bind and write to GPU
        for channel in range(self.mainapp.NBR_CHANNELS):
            # TODO: this is a temporary situation with one VBO per panel!
            gl_Bind_Buffer_SubData(vbos[channel][0], offset_bytes, data[channel])

        # update x & y values for interconnecting line.
        if update_end_of_line_coordinates or update_beginning_of_line_coordinates:

            for panel in range(self.mainapp.NBR_CHANNELS):

                if update_end_of_line_coordinates:
                    self._end_of_line_coordinates[panel] = [last_x_points[-1], raw_data[panel][-1]]

                if update_beginning_of_line_coordinates:
                    self._beginning_of_line_coordinates[panel] = [last_x_points[0], raw_data[panel][0]]


    @profile_code(PROFILE)
    def on_draw(self):

        # 1. Quit here if we are not supposed to draw anything new. This way the queue
        # keeps growing and we don't miss anything.
        if not self.mainapp.DO_DRAW:
            return

        ''' clear background '''    
        glEnable(GL_NORMALIZE)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

        # calculate the height per panel
        height_per_panel = (self.mainapp.SETTINGS.WINDOW_HEIGHT_CURRENT / self.mainapp.NBR_CHANNELS)

        # loop over all panels
        for panel in range(self.mainapp.NBR_CHANNELS):


            ''' START THIS PANEL '''
            glPushMatrix()

            glViewport(0, panel * height_per_panel, self.mainapp.SETTINGS.WINDOW_WIDTH_CURRENT, height_per_panel)
            # apply current scaling (if any) to the active panel
            if self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX:
                gl_ortho_projection(self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX[0], self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX[1], self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX[2], self.mainapp.SETTINGS.CURRENT_glOrtho_MATRIX[3])


            ''' start - panel data '''
            # TODO: make line width a parameter. Line width must be set AFTER the 
            # glPushMatrix() statement above.
            glLineWidth(3.0)

            # set the color for this VBO
            # TODO: this is a temporary situation with one VBO per panel!
            glBindBuffer(GL_ARRAY_BUFFER, self.mainapp.vbo_colors[panel][0])
            set_glColorPointer_default(n_COORDINATES_PER_COLOR)

            # TODO: this is a temporary situation with one VBO per panel!
            self.render_moving_line(self.mainapp.vbo_data[panel][0], GL_LINE_STRIP, panel)
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



    ''' render the line moving to the left '''
    @profile_code(PROFILE)
    def render_moving_line(self, vbo_id, draw_mode, panel):


        # bind buffer
        glBindBuffer(GL_ARRAY_BUFFER, vbo_id)

        # set line width
        glLineWidth(3.0)


        ''' START first part of the line + INTERCONNECT'''
        glPushMatrix()

        # move "c" steps to the left.
        move_to = -1 * (self._x_spacing * self._c)
        glTranslatef(move_to, 0, 0)


        # calculate the offset into the Vertex, we start at the "c-th point"
        offset_to_start_from = self._c % (self.mainapp.nPoints / self.mainapp.nPointsToUpdate)
        nbr_points_rendered_in_previous_loop = int(offset_to_start_from * self.mainapp.nPointsToUpdate)
        offset_bytes = (nbr_points_rendered_in_previous_loop * BYTES_PER_POINT)
        stride = 0
        glVertexPointer(2, GL_FLOAT, stride, offset_bytes)	

        # format of glDrawArrays: (mode, Specifies the starting index in the enabled arrays, nbr of points).
        nbr_points_to_render_first_part = (self.mainapp.nPoints - nbr_points_rendered_in_previous_loop)
        starting_point_in_above_selected_Vertex = 0
        glDrawArrays(draw_mode, starting_point_in_above_selected_Vertex, nbr_points_to_render_first_part)

        ''' draw interconnecting line '''
        # draw line connecting the end with the beginning of the plot, 
        # if we've moved away at least one step from c = 0.
        if self._c > 0 and self.show_wrap_around_line:
            glBegin(GL_LINES)
            glColor3f(self.mainapp.SETTINGS.COLOR_USED[panel][0], self.mainapp.SETTINGS.COLOR_USED[panel][1], self.mainapp.SETTINGS.COLOR_USED[panel][2])
            # coordinates of last point
            glVertex3f(self._end_of_line_coordinates[panel][0], self._end_of_line_coordinates[panel][1], 0)
            # coordinates of first point - use the last point's x-coordinate and go
            # 'self._x_spacing/self.mainapp.nPointsToUpdate' to the right of that point.
            glVertex3f(self._end_of_line_coordinates[panel][0] + (self._x_spacing/self.mainapp.nPointsToUpdate), self._beginning_of_line_coordinates[panel][1], 0)
            glEnd()


        glPopMatrix()

        ''' END first part of the line + INTERCONNECT'''


        ''' START second part of the line '''

        glPushMatrix()

        # move to the right.
        move_to = ((self.mainapp.nPoints / self.mainapp.nPointsToUpdate) - self._c ) * self._x_spacing
        glTranslatef(move_to, 0, 0)

        # select the VertexPointer and start from zero offset.
        offset_bytes = 0
        stride = 0
        glVertexPointer(2, GL_FLOAT, stride, offset_bytes)

        # draw the line
        nbr_points_to_render_second_part = (self.mainapp.nPoints - nbr_points_to_render_first_part)
        starting_point_in_above_selected_Vertex = 0
        glDrawArrays(draw_mode, starting_point_in_above_selected_Vertex, nbr_points_to_render_second_part)	

        glPopMatrix()

        ''' END second part of the line '''


