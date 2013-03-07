''' basic opengl functions that are needed all over the place '''

from pyglet.gl import GLfloat
from pyglet_app_profile import profile_code, PROFILE

@profile_code(PROFILE)
def gl_transform_list_to_GLfloat(data):
	# transform data into GLfloat pointer format for GPU
	list_length = len(data)
	return (GLfloat *list_length)(*data)


