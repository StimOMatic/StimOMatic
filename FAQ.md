# FAQ #

## Running StimOmatic ##

**Q**: After pressing the `Start data feed` button, I get an `Error streaming` message. What's wrong?  
**A**: Most likely, the NetComRouter can not connect to Cheetah, or the local UDP port for the NetComRouter is in use. Try restarting the computer(s).

## Installing StimOmatic ##

**Q**: Running the `pyglet-1.1.x.msi` installer fails with an error `requires Python 2.4 or later`. But I've just installed Python 2.7! What's wrong?  
**A**: Most likely, Windows does not have Python in the Environment Variable path. Reboot Windows and try again. Otherwise install from the sources (described [here][pyglet_install]). For more information see also the pyglet [bug report][pyglet_install_bug].

[pyglet_install]: https://github.com/kotowicz/StimOmatic/blob/master/python/OpenGLPlotting/pomp/docs/INSTALL.txt
[pyglet_install_bug]: https://code.google.com/p/pyglet/issues/detail?id=488
