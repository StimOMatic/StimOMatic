Install & Usage instructions
============================

The following are install and usage instructions for the `StimOmatic` software package that will run on the analysis computer. These instructions assume that you are using a `Neuralynx` system operated by the `Cheetah` data acquisition software.

For testing, the demo version of Cheetah can be used. This can be obtained for free from www.neuralynx.com. The demo version contains a demo data file that can be used for replay and to StimOMatic this
will look just like a real system.

This version has been tested with Cheetah v5.6.3 and v5.3.1. and Neuralynx Router v1.2.0. Version of the router less than 1.2.0 are not supported nor are any version of Cheetah less than 5.3.1.

Installing StimOmatic
=====================
## 1) Install and run NetComRouter 

- download NetComRouter program [http://neuralynx.com/software/Router_v120.zip][NetComRouter] 
- run programm by double clicking on `Router.exe`
- connect to your Cheetah computer (`Network` -> `Connect to server` -> `IP address`)

## 2) Python and OpenGL plotting

- follow instructions in `python\OpenGLPlotting\pomp\docs\INSTALL.txt` file.

## 3) Matlab

- add directory  `matlab\` to your matlab path.
- open `setpath_win.m` and modify `basepath` so it points to above directory (full path).


Using StimOmatic
================
 
- run `setpath_win`
- run `OSortViewer`
- modify `Router IP` so that the IP address matches the IP of the computer where `Router.ext` is running (see 1).
- press `Connect` button
- select channel from `CSC Channels` pulldown list, and add it using the `+` sign. 
- select plugin from plugin list on right side of GUI, e.g., `Continuous LFP/Spikes plot (OpenGL)`. Press `Add Plugin` button.
- optionally: select `Yes` from `RT Ctrl Mode`
- optionally: if you plan to control a stimulus presentation system conditionally on the incoming data,
  don't forget to fill out the `PTB Sys IP` field (the `pCtrlLFP` uses this for example).
- press `Start data feed` 

you should see some output like:

    Lab 1: 
      pContinuousOpenGL-1-43
    Lab 2: 
      pContinuousOpenGL-1-45
  
This will indicated that the previously selected plugin has the absolute plugin ID 1, and that we want to visualize channels 43 and 45. We need to now configure our OpenGL plugin accordingly: 

- go to directory `python\OpenGLPlotting\`
- open the file `1_start_pContinuousOpenGL.py` for editing
- set `abs_plugin_ID = 1` and `channel_numbers = [43, 45]`
- run `1_start_pContinuousOpenGL.py` by double clicking the file


Using conditional visual displays
=================================

See the file INSTALL.txt inside the subdirectory matlab\psychophysics-example for instructions on how to run the display part of StimOmatic.


[NetComRouter]: http://neuralynx.com/software/Router_v120.zip


