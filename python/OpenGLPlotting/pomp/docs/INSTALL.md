# POMP (Python OpenGL mmap plotter) install instructions #
## Quick install (experts) ##
  make sure you have the following installed:
  - Python 2.7.x
  - NumPy
  - pyglet 1.1.x

## Step by Step install ##

### 1) Windows: ###

   **A)** if you are planning to run this program on Windows (32bit and 64 bit), make sure to install the 32bit version of Python. The 64bit version of Python on Windows won't work with pyglet! 
   
      E.g.: python-2.7.3.exe

   **B)** install 32bit version of *setuptools* http://pypi.python.org/pypi/setuptools  
   
      E.g.: setuptools-0.6c11.win32-py2.7.exe

   **C)** install Numpy package  
   
      $ cd c:\python27\Scripts   
      $ easy_install numpy

   **D)** set the Nvidia driver 3D settings to *performance* if you want highest FPS

### 1) Linux: ###
  on ubuntu 12.04 you can do:  
  
    $ sudo apt-get install python-numpy pyglet

  on ubuntu < 12.04 do:  
  
    $ sudo apt-get install python-numpy
    
  now install pyglet by hand as described in 2B)

### 2) Installing a recent version of pyglet (< version 1.2): ###

 **A)** Windows

 download from https://code.google.com/p/pyglet/downloads/list 
 
    E.g.: pyglet-1.1.4.msi 
 
 or checkout from repository using TortoiseHg (http://tortoisehg.bitbucket.org)
 
    d:
    cd d:\code\pyglet
    c:\Python27\python.exe setup.py install

 **B)** Mac & Linux
 
    $ hg clone https://pyglet.googlecode.com/hg/ pyglet  
    $ sudo python setup.py install 


### 3) Ubuntu / Linux only: in case the application does freeze, make sure the following requirements are met: ###
   - Nvidia driver version 280.13; we experienced lot's of problems with versions 290 & 295.
   - latest pyglet dev version is installed (see point 2). We experienced very poor performance with both pyglet-1.1.2 and pyglet-1.1.4 that ship with Ubuntu.
