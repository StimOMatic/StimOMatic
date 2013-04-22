#
# TCP Server (ver 0.1) to synchronize matlab instances
#
# listens on port 9999 and writes values received into a shared memory variable
# this shared memory variable can then be read by matlab.
#
# The shared memory variable needs to be opened in matlab with 'Writeable' = 1,
# otherwise matlab won't be able to access the file. Alternatively, you can
# open the file in matlab first, before running this server.
# memFileHandle = memmapfile(filename, 'Offset', 0,'Format', 'uint8', 'Writable', 1);
#
# Ueli Rutishauser and Andreas Kotowicz, MPI 2012.


import mmap
import os
import sys
import SocketServer
import socket

# location of shared file
fname = "c:/temp/varstoreNew.dat"
#fname = '/tmp/file'
# Set the IP address here if you have multiple network interfaces. Leave empty
# and program will use first network interface.
SERVERIP = ''
# port number to listen to
PORT = 9999
# number of elements to store in memory
STORE_LENGTH = 100
# index of the last item - so we don't recompute it during every single loop
LAST_ITEM_INDEX = STORE_LENGTH - 1
# maximum number of bytes to send and receive - arbitrarily chosen. must be power 
# of two.
MAX_BYTES_TO_SEND_RECEIVE = 10
# this string can't consist of more characters then 'MAX_BYTES_TO_SEND_RECEIVE'
STOP_SERVER_STRING = 'STOPSERVER'
# null string used to initalize memory
NULL_HEX = '\x00'

############# TCP SERVER CODE
# overwrite TCPServer so that we can re-use the address immediately after quitting.
# we can't do 'server.allow_reuse_address = 1' because bind() has already been called at that moment.
class TCPServer(SocketServer.TCPServer): 
    allow_reuse_address = True 


# handle for server connection
class MyTCPHandler(SocketServer.BaseRequestHandler):
    def handle(self):
        # self.request is the TCP socket connected to the client
        self.data = self.request.recv(MAX_BYTES_TO_SEND_RECEIVE).strip()
    
        # check whether data is numberic, otherwise ignore
        if self.data.isdigit():
            # shift elements by one
            mmap_data[0:-1] = mmap_data[1:]
            # store value in one-character string whose ASCII code is the integer data
            # you can 'unpack' this value with 'ord()'
            mmap_data[LAST_ITEM_INDEX] = chr(int(self.data))
            #print "wrote data:", self.data


        # send feedback back
        self.request.sendall("OK\0")
        
        # check whether we have to stop the server
        if self.data == STOP_SERVER_STRING:
            self.stopServer()
            return

        # give feedback to user at the very end in case 'print' is slowing things down.
        print "received data:", self.data
            
    def stopServer(self):
        self.server.socket.close()


# routine to startup server
def setup_server():
    # get current IP address of default network card
    myIP = SERVERIP
    if SERVERIP == '':
        # TODO: what if someone has multiple cards?    
        myIP = socket.gethostbyname(socket.gethostname())
        try:
            # Create the server
            server = TCPServer((myIP, PORT), MyTCPHandler)

            # disable the 'Nagle algorithm'
            # it makes no difference whether we use 'socket.SOL_TCP' or 'socket.IPPROTO_TCP'
            # but make sure we are consistent with the client!
            server.socket.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, True)
    
            print "Started server on IP: " + myIP + " Port: " + str(PORT)
    
        except:
            pass
            print "Failed to create server on " + myIP
            server = False
    return server

    
############# MMAP CODE
def setup_mmap(fname):
    # create the file if it doesn't exist 
    if not os.path.isfile(fname):
        path_to_file = os.path.dirname(fname)
        if not os.path.isdir(path_to_file):
            mmap_data = False
            print "Directory '" + path_to_file + "' not found - aborting."
            return mmap_data
        fd = os.open(fname, os.O_CREAT | os.O_TRUNC | os.O_RDWR)
        assert os.write(fd, NULL_HEX * STORE_LENGTH)
        os.close(fd)

    # initialize the memory map
    f = open(fname, "r+b")
    mmap_data = mmap.mmap(f.fileno(), STORE_LENGTH)
    
    # initialize memory with default value
    for j in range(len(mmap_data)):
        mmap_data[j] = NULL_HEX
    
    return mmap_data


############# MAIN
# main routine 
def run_server(server, mmap_data):    

    try:
        # 'main'
        print "Ready to receive data ..."
        server.serve_forever()
    except KeyboardInterrupt:
        # user stopped server from command line
        print "^C detected"
        server.socket.close()
        pass
    except:
        # user stopped server by sending STOP_SERVER_STRING
        pass
    finally:
        # either way, close the mapped file @ the end.
        print "Shutting down server"
        mmap_data.close()
        
        
if __name__ == "__main__":
    print "------------------ Server starting up; press ctrl-c to stop. "

    # setup shared memory file
    mmap_data = setup_mmap(fname)
    if not mmap_data:
        sys.exit(1)
    
    # last chance to stop the server from starting up
    try:
        raw_input('press any key to start TCP listening')
    except KeyboardInterrupt:
        sys.exit(1)
        pass
    
    # setup & run server
    server = setup_server()
    # quit in case 'setup_server()' failed.
    if not server:
        sys.exit(1)

    print "python mmap tcp server using file '" + fname + "'"

    run_server(server, mmap_data)

