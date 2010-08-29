############################################
        Open RollerCoaster Factory
            Build instructions
############################################

1. Library requirements
2. Preparing build environment
3. Configure the modules
4. Compile it
5. Make it run



############################################

1. Library requirements

The most important library is - of course - the one that
creates the OpenGL context. INSTALL ONE OF
 * GLFW
 * SDL 1.2
 * GLUT

NOTE: On Linux and Windows, the SDL backend works best, on Mac OS X, try GLFW.

To have working sound output, choose one of the following libs:
 * OpenAL

You will also need a native graphics driver (Mesa3D or so may not work)
and a powerful graphics card (The game still runs slow even on my GeForce 9800GT)


The game will compile with FreePascal 2.2 and up.




############################################

2. Preparing build environment

###   LINUX   ###

Just install FPC and the required libraries.
Development headers are NOT needed as they are written for C whereas ORCF is written in Pascal.

###   WINDOWS   ###

 * Download missing libraries (I'm too lazy to search download links for you) and
   copy the DLL files to C:\Windows\System32
 * Install the newest version of Lazarus and FPC
 * Open compile.bat in an editor
 * The first path is the path to FPC's executable. Change it to wherever your FPC is located
   (normally, only the version number needs to be changed).

###   MAC OS X   ###

Ask BlackMambaFan how he did it




############################################

3. Configure the modules

There are a few modules that can be replaced by others, for example the OpenGL context module or
the font renderer. Some are platform-dependant.

The default modules seem to work well enough on every OS.

###   LINUX & MAC OS X   ###

 * Change to the root directory of ORCF
 * ./configure

If you want to change a module, you have to know the type of the module and the name of your replacement.
E.G. to compile orcf with GLUT, type

 * ./configure --module TModuleGLContext GLUT --module TModuleInputHandler GLUT

Don't forget the spaces.

###   WINDOWS   ###

 * Open modules\typedef_windows.inc
 * Change the type definitionss manually :P





############################################

4. Compile it

###   LINUX   ###

This is easy:

 * make

###   WINDOWS   ###

 * Open a command line
 * cd orcf
 * .\compile.bat
 * Watch the nice messages scroll down

###   MAC OS X   ###

Almost as easy as the Linux way:

 * make
 * ./bundle_orcf.sh






############################################

5. Make it run

###   LINUX & MAC OS X   ###

 * ./orcf

###   WINDOWS   ###

 * Create a directory 'config' in the game's root directory
 * Run orcf.exe

