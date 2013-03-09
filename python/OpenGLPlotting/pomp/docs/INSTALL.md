QUICK INSTALL (experts): 
  - python 2.7
  - numpy
  - pyglet 1.1.x


STEP by STEP install:

1 - WINDOWS):
   A) if you are planning to run this program on Windows (32bit and 64 bit), make 
      sure to install the 32bit version of Python. The 64bit version of Python 
      on Windows won't work with pyglet!
      E.g.: python-2.7.3.exe

   B) install 32bit version of 'setuptools' http://pypi.python.org/pypi/setuptools
      E.g.: setuptools-0.6c11.win32-py2.7.exe

   C) install Numpy package
      $ cd c:\python27\Scripts
      $ easy_install numpy

   D) set the nvidia driver 3D settings to 'performance' if you want highest FPS

1 - LINUX):
  # on ubuntu 12.04 you can do:
  $ sudo apt-get install python-numpy pyglet

  # on ubuntu < 12.04 do:
  $ sudo apt-get install python-numpy
  # now install pyglet by hand as described in 2B)

2) Installing a recent version of pyglet (< version 1.2):

 A) Windows
 # download from https://code.google.com/p/pyglet/downloads/list 
  E.g.: pyglet-1.1.4.msi 
 
 # or checkout from
 # repository using TortoiseHg (http://tortoisehg.bitbucket.org/de/)
 
 # d:
 # cd d:\code\pyglet
 # c:\Python27\python.exe setup.py install

 B) Mac & Linux
 $ hg clone https://pyglet.googlecode.com/hg/ pyglet
 $ sudo python setup.py install 


3) Ubuntu / Linux only: in case this applications freezes make sure the following 
   points are met:
   - Nvidia driver 280.13; I had lots of problems with version 290 & 295
   - latest pyglet dev version is installed (see point 2). I tried both pyglet-1.1.2 and 
     pyglet-1.1.4 that come with ubuntu but I get very poor performance.
