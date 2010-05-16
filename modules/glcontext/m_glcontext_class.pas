unit m_glcontext_class;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_module;

type
  TModuleGLContextClass = class(TBasicModule)
    public
      AdditionalContextOptions: Integer;
      procedure ChangeWindowTitle(Text: String); virtual abstract;
      procedure GetResolution(var ResX: Integer; var ResY: Integer); virtual abstract;
      procedure SwapBuffers; virtual abstract;
      procedure StartMainLoop; virtual abstract;
      procedure EndMainLoop; virtual abstract;
      procedure InitGL; virtual abstract;
      function SetResolution(ResX, ResY: Integer): Boolean; virtual abstract;
      function IsFullscreen: Boolean; virtual abstract;
      function SetFullscreenState(Fullscreen: Boolean): Boolean; virtual abstract;
    end;

implementation

end.

