from struct import pack

# indicator values used to confirm that data is received.
DATA_RECEIVED_ACK_NUM = 3.14159265
DATA_RECEIVED_ACK_STR = pack('d', DATA_RECEIVED_ACK_NUM)
NBR_BUFFERS_ZERO_STR = pack('d', 0)

''' internal definitions '''
# each float value has size 4;
BYTES_PER_COORDINATE = 4
# since one point is made of 2 values, each point has size 8 bytes.
BYTES_PER_POINT = 2 * BYTES_PER_COORDINATE

# Definitions for 'glColorPointer' and 'glVertexPointer'
n_COORDINATES_PER_COLOR = 3
n_COORDINATES_PER_VERTEX = 2
