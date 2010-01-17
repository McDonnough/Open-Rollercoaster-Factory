unit m_glcontext_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module;

type
  TModuleGLContextClass = class(TBasicModule)
    public
      (**
        * Set the text on the window
        *@param The text...
        *)
      procedure ChangeWindowTitle(Text: String); virtual abstract;

      (**
        * Get window resolution
        *@param x resolution storage
        *@param y resolution storage
        *)
      procedure GetResolution(var ResX: Integer; var ResY: Integer); virtual abstract;

      (**
        * Make the redered image appear on the screen!
        *)
      procedure SwapBuffers; virtual abstract;

      (**
        * Starts the main function of the program
        *)
      procedure StartMainLoop; virtual abstract;

      (**
        * Do something to stop main loop
        *)
      procedure EndMainLoop; virtual abstract;

      (**
        * Init OpenGL
        *)
      procedure InitGL; virtual abstract;

      (**
        * Change window resolution
        *@param window width
        *@param window height
        *@return true on success, otherwise false
        *)
      function SetResolution(ResX, ResY: Integer): Boolean; virtual abstract;

      (**
        * Get fullscreen state
        *@return True if it is, false if not
        *)
      function IsFullscreen: Boolean; virtual abstract;

      (**
        * Set fullscreen state
        *@param True will toggle into fullscreen, false will toggle out
        *@return True on success, otherwise false
        *)
      function SetFullscreenState(Fullscreen: Boolean): Boolean; virtual abstract;
    end;

implementation

end.

