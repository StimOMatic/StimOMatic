from ctypes import pointer, sizeof
# 'time' is needed by 'gl_setup_data_and_color_vbos' below
#from time import time
import numpy as np

from pyglet.gl import *
from pyglet_app_gl_helper_basic import gl_transform_list_to_GLfloat
from pyglet_app_helper2 import replicate_data_for_panel_and_vbo
from pyglet_app_helper import create_initial_colors, initial_points, create_2dim_list_from_arrays
from pyglet_app_consts import BYTES_PER_POINT, n_COORDINATES_PER_VERTEX
from pyglet_app_profile import profile_code, PROFILE


@profile_code(PROFILE)
def gl_enable_line_smoothing():
    # try to render a smooth line (if supported by driver)
    glEnable(GL_LINE_SMOOTH)
    glEnable(GL_BLEND)
    # alternative blend values.
    # glBlendFunc(GL_SRC_ALPHA_SATURATE, GL_ONE)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST)


''' setup points '''
@profile_code(PROFILE)
def gl_setup_intial_data_and_color_vbos(data, colors, n_COORDINATES_PER_COLOR):
    
    ''' create VBO for coordinates for each point, and upload initial values '''
    # create VBO for data
    vbo_id = gl_VBO_create()        
    # upload initial data to GPU
    gl_Bind_Buffer_data(vbo_id, data, GL_DYNAMIC_DRAW)

    ''' create VBO for colors for each point, and upload colors '''
    # create VBO for color
    color_id = gl_VBO_create()
    gl_Bind_Buffer_data(color_id, colors, GL_STATIC_DRAW)

    ''' set colors for each point '''  
    set_glColorPointer_default(n_COORDINATES_PER_COLOR)   
    
    ''' return '''
    return vbo_id, color_id, colors


@profile_code(PROFILE)
def gl_setup_data_and_color_vbos(SETTINGS, n_COORDINATES_PER_COLOR, NBR_PANELS, nPoints, GENERATE_INITIAL):
    
    #t0 = time()

    '''
    output = calc_VBO_numbers(NBR_DATA_POINTS_PER_VBO, NBR_DATA_POINTS_PER_BUFFER, SECONDS_TO_VISUALIZE_PER_PANEL, scanrate)
    NBR_DATA_POINTS_PER_VBO, NBR_VBOS_PER_PANEL, SECONDS_TO_VISUALIZE_PER_PANEL = output
    NBR_DATA_POINTS_PER_BUFFER = NBR_DATA_POINTS_PER_BUFFER
    '''

    upload_None = False
    if GENERATE_INITIAL == 4:
        upload_None = True

    # TODO: this is a temporary situation with one VBO per panel!
    NBR_VBOS_PER_PANEL = 1
    USE_UNIFORM_COLOR = SETTINGS.COLOR_TO_USE

    # generate data & colors for a single VBO
    data_single, colors_single, x_coords_entire_range = initial_points(nPoints, SETTINGS, GENERATE_INITIAL)

    # copy same data and color into each panel and each VBO.
    data = []
    if not upload_None:
        data = replicate_data_for_panel_and_vbo(NBR_VBOS_PER_PANEL, NBR_PANELS, data_single)

    colors, color_generated = create_initial_colors(NBR_PANELS, NBR_VBOS_PER_PANEL, nPoints, USE_UNIFORM_COLOR)
    # we can also just replicate the colors previously generated.
    # colors = replicate_data_for_panel_and_vbo(NBR_VBOS_PER_PANEL, NBR_PANELS, colors_single)

    vbos_data = gl_create_vbos(NBR_PANELS, NBR_VBOS_PER_PANEL)
    vbos_colors = gl_create_vbos(NBR_PANELS, NBR_VBOS_PER_PANEL)

    # old, original code.
    # data, curr_x_offset = create_initial_data(NBR_PANELS, NBR_VBOS_PER_PANEL, NBR_DATA_POINTS_PER_VBO)
    # colors, color_generated = create_initial_colors(NBR_PANELS, NBR_VBOS_PER_PANEL)

    gl_initialize_vbos_with_start_data(NBR_PANELS, NBR_VBOS_PER_PANEL, vbos_data, data, GL_DYNAMIC_DRAW, upload_None, nPoints * n_COORDINATES_PER_VERTEX * BYTES_PER_POINT)
    gl_initialize_vbos_with_start_data(NBR_PANELS, NBR_VBOS_PER_PANEL, vbos_colors, colors, GL_STATIC_DRAW)

    
    #print 'gl_setup_data_and_color_vbos(): initial setup time was %f seconds.' %(time() - t0)
    
    return vbos_data, vbos_colors, colors, x_coords_entire_range, color_generated


@profile_code(PROFILE)
def gl_initialize_vbos_with_start_data(NBR_PANELS, NBR_VBOS_PER_PANEL, vbos, data, mode = GL_DYNAMIC_DRAW, upload_None = False, memory_size = None):
    
    for panel in range(NBR_PANELS):
        for vbo in range(NBR_VBOS_PER_PANEL):
            if upload_None: # initialize empty memory (with None == NULL)
                glBindBuffer(GL_ARRAY_BUFFER, vbos[panel][vbo])
                glBufferData(GL_ARRAY_BUFFER, memory_size, None, mode)
            else:
                gl_Bind_Buffer_data(vbos[panel][vbo], data[panel][vbo], mode)


@profile_code(PROFILE)
def gl_create_vbos(NBR_PANELS, NBR_VBOS_PER_PANEL):

    vbos = [ [None] * int(NBR_VBOS_PER_PANEL) for i in xrange(NBR_PANELS) ]
    
    for panel in range(NBR_PANELS):
        for vbo in range(NBR_VBOS_PER_PANEL):
            vbos[panel][vbo] = gl_VBO_create()

    return vbos


@profile_code(PROFILE)
def gl_VBO_create():
    # create VBO for data
    vbo_id = GLuint()
    glGenBuffers(1, pointer(vbo_id))
    return vbo_id


@profile_code(PROFILE)
def gl_Bind_Buffer_data(vbo_id, data, mode=GL_DYNAMIC_DRAW):
    glBindBuffer(GL_ARRAY_BUFFER, vbo_id)
    glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, mode)


@profile_code(PROFILE)
def gl_Bind_Buffer_SubData(vbo_id, pointer_offset, data):
    
    # bind buffer and overwrite position with offset 'pos_to_overwrite*BYTES_PER_POINT'
    #try:
    glBindBuffer(GL_ARRAY_BUFFER, vbo_id)
    glBufferSubData(GL_ARRAY_BUFFER, pointer_offset, sizeof(data), data)
    #except:
        #print "pointer_offset: ", pointer_offset
        #print "sizeof(data): ", sizeof(data)
        #pass


@profile_code(PROFILE)
def set_glColorPointer_default(n_COORDINATES_PER_COLOR = 3, offset_between_colors = 0, offset_to_first_color = 0):
    ''' set colors for each point '''  
    ''' you need to run: 

        color_id = gl_VBO_create()
        gl_Bind_Buffer_data(color_id, colors, GL_STATIC_DRAW)

        before. Or:

        glBindBuffer(GL_ARRAY_BUFFER, color_id)

    '''
    glColorPointer(n_COORDINATES_PER_COLOR, GL_FLOAT, offset_between_colors, offset_to_first_color)


@profile_code(PROFILE)
def set_gl_defaults(POINT_SIZE):
    glClearColor(0, 0, 0, 1.0)
    glPointSize(POINT_SIZE)

    # enable GL_VERTEX_ARRAY & GL_COLOR_ARRAY state 
    glEnableClientState(GL_VERTEX_ARRAY)
    glEnableClientState(GL_COLOR_ARRAY)


@profile_code(PROFILE)
def gl_on_draw_default(vbo_id, n_COORDINATES_PER_VERTEX, nPoints, mode):
    
    ''' colors are defined and setup in 'setup_initial_points()'! '''
  

    ''' setup point rendering '''
    # bind data VBO    
    glBindBuffer(GL_ARRAY_BUFFER, vbo_id)
    
    offset_between_vertices = 0
    offset_to_first_vertex = 0
    glVertexPointer(n_COORDINATES_PER_VERTEX, GL_FLOAT, offset_between_vertices, offset_to_first_vertex)

    ''' render points '''
    offset_to_first_vertex = 0    
    nbr_vertices_to_render = nPoints
    glDrawArrays(mode, offset_to_first_vertex, nbr_vertices_to_render)


@profile_code(PROFILE)
def gl_Normalize_PushMATRIX_ClearBackground():

    glEnable(GL_NORMALIZE)
    glPushMatrix()

    ''' clear background '''
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)


@profile_code(PROFILE)
def gl_ortho_projection(left, right, bottom, top):

    glMatrixMode(GL_PROJECTION)
    # Reset world coordinates first 
    glLoadIdentity()

    # TODO: try / except here, so that we don't crash if bottom == top (or similar cases)
    try:
        # Then set them to what we want based on the new aspect ratio
        glOrtho(left, right, bottom, top, -1.0, 1.0)
    except Exception, e:
            print "Error in 'gl_ortho_projection()': ", e
            print "left %s, right %s, bottom %s, top %s" %(left, right, bottom, top)
            pass
    glMatrixMode(GL_MODELVIEW)


''' pair each y coordinate with the corresponding x coordinate and transform data into GLFloat. '''
@profile_code(PROFILE)
def gl_transform_vector_of_buffers_to_GPU_format(raw_data, x_values):

    #import pdb; pdb.set_trace()

    # number channel to loop over.
    nbr_channels = len(raw_data)

    data = []
    for j in range(nbr_channels):
        data.append(gl_transform_list_to_GLfloat(create_2dim_list_from_arrays(x_values, raw_data[j])))

    return data


@profile_code(PROFILE)
def gl_update_two_coordinates_in_VBO_static_view(raw_data, vbo_id, c, nPoints, nPointsToUpdate, BYTES_PER_POINT, BYTES_PER_COORDINATE, NBR_CHANNELS, x_coords):

    ''' Updates x & y values in a single VBO.
        Works with multiple channels and one VBO only (05.07.2012).'''
    
    offset_to_start_from = c % (nPoints / nPointsToUpdate)
    nbr_points_rendered_in_previous_loop = int(offset_to_start_from * nPointsToUpdate)

    # pointer to x3y3 coordinate pair (pointing at location of x3).
    pointer_offset = (nbr_points_rendered_in_previous_loop * BYTES_PER_POINT)

    # calculate the x coordinates
    x_values = x_coords[nbr_points_rendered_in_previous_loop:nbr_points_rendered_in_previous_loop+nPointsToUpdate]

    # pair each y coordinate with the corresponding x coordinate and transform data into GLFloat.
    data = gl_transform_vector_of_buffers_to_GPU_format(raw_data, x_values)

    # TODO: this will work with multiple channels, but only one VBO per channel right now.
    for channel in range(NBR_CHANNELS):
        # bind the VBO & overwrite the data.
        # TODO: this is a temporary situation with one VBO per panel!
        gl_Bind_Buffer_SubData(vbo_id[channel][0], pointer_offset, data[channel])

    return nbr_points_rendered_in_previous_loop


@profile_code(PROFILE)
def gl_update_single_coordinate_in_VOB_static_view(raw_data, vbo_id, c, nPoints, nPointsToUpdate, BYTES_PER_POINT, BYTES_PER_COORDINATE, NBR_CHANNELS, x_coords):

    ''' Updates y coordinates in a single VBO.
        Works with multiple channels and one VBO only (04.07.2012).'''
    
    offset_to_start_from = c % (nPoints / nPointsToUpdate)
    nbr_points_rendered_in_previous_loop = int(offset_to_start_from * nPointsToUpdate)

    # offset to Y coordinate, assuming memory layout x1y1 x2y2
    pointer_offset_orig = (nbr_points_rendered_in_previous_loop * BYTES_PER_POINT) + BYTES_PER_COORDINATE

    # TODO: this will work with multiple channels, but only one VBO per channel right now.
    for channel in range(NBR_CHANNELS):

        # grab the data for this channel
        data = raw_data[channel]

        # reset the pointer offset
        pointer_offset = pointer_offset_orig

        # bind the VBO once
        # TODO: this is a temporary situation with one VBO per panel!
        glBindBuffer(GL_ARRAY_BUFFER, vbo_id[channel][0])

        # go through list of points that have to be updated.
        for j in range(nPointsToUpdate):
            # add the 'per-point' offset for each iteration, except the first one, 
            # which is already at the correct position.
            if j > 0:
                pointer_offset = pointer_offset + BYTES_PER_POINT

            # grab data point from list, make it a list again ([]), and transfer into 
            # GLfloat
            this_data = gl_transform_list_to_GLfloat([data[j]])
    
            # bind buffer and overwrite position with offset 'pointer_offset',
            # which points to the y coordinate only.
            glBufferSubData(GL_ARRAY_BUFFER, pointer_offset, sizeof(this_data), this_data)    

    return offset_to_start_from


@profile_code(PROFILE)
def gl_setup_initial_data_and_color_and_vbos(nPoints, n_COORDINATES_PER_COLOR, NBR_CHANNELS, SETTINGS):

    # we can generate very different initial data - see 'pyglet_app_helper.initial_points'
    GENERATE_INITIAL = 4 # pre-allocate with 'None'

    # single channel solution.
    # data_single_vbo, colors_single_vbo, x_coords_entire_range = initial_points(nPoints, SETTINGS, GENERATE_INITIAL)
    # self.vbo_data, self.vbo_colors, self.colors = gl_setup_intial_data_and_color_vbos(data_single_vbo, colors_single_vbo, n_COORDINATES_PER_COLOR)

    # multiple channels solution.
    vbo_data, vbo_colors, colors, x_coords_entire_range, color_generated = gl_setup_data_and_color_vbos(SETTINGS, n_COORDINATES_PER_COLOR, NBR_CHANNELS, nPoints, GENERATE_INITIAL)

    return vbo_data, vbo_colors, x_coords_entire_range, color_generated


def gl_calc_x_y_extend_from_current_glOrthoMatrix(settings):

    # the abs size of the current projection view
    if settings.CURRENT_glOrtho_MATRIX:
        y_diff_abs = abs(np.diff([float(settings.CURRENT_glOrtho_MATRIX[3]), float(settings.CURRENT_glOrtho_MATRIX[2])]))
        x_diff_abs = abs(np.diff([float(settings.CURRENT_glOrtho_MATRIX[1]), float(settings.CURRENT_glOrtho_MATRIX[0])]))
    # projection matrix is not initalized yet, use window dimensions.
    else:
        y_diff_abs = settings.WINDOW_HEIGHT_CURRENT
        x_diff_abs = settings.WINDOW_WIDTH_CURRENT

    return x_diff_abs, y_diff_abs




