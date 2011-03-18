unit m_glcontext_glfw;

{$mode objfpc}{$H+}
{$linklib libglfw}

interface

uses
  Classes, SysUtils, m_glcontext_class, glfw, dglOpenGL;

type
  TModuleGLContextGLFW = class(TModuleGLContextClass)
    protected
    public
      constructor Create;
      destructor Free;
      procedure CheckModConf; override;
      procedure ChangeWindowTitle(Text: String); override;
      procedure GetResolution(var ResX: Integer; var ResY: Integer); override;
      procedure SwapBuffers; override;
      procedure StartMainLoop; override;
      procedure EndMainLoop; override;
      procedure InitGL; override;
      function SetResolution(ResX, ResY: Integer): Boolean; override;
      function IsFullscreen: Boolean; override;
      function SetFullscreenState(Fullscreen: Boolean): Boolean; override;
    end;

implementation

uses
  m_varlist, main;

constructor TModuleGLContextGLFW.Create;
begin
  fModName := 'GLContextGLFW';
  fModType := 'GLContext';
  CheckModConf;

  //Init GLFW
  glfwInit;
  glfwSwapInterval(0);
  if GetConfVal('Fullscreen') = '1' then
  begin
    if glfwOpenWindow(StrToInt(GetConfVal('ResX')), StrToInt(GetConfVal('ResY')), 8, 8, 8, 0, 24, 0, GLFW_FULLSCREEN) <> 1 then
    begin
      glfwTerminate;
      Exit;
    end;
  end
  else
  begin
    if glfwOpenWindow(StrToInt(GetConfVal('ResX')), StrToInt(GetConfVal('ResY')), 8, 8, 8, 0, 24, 0, GLFW_WINDOW) <> 1 then
    begin
      glfwTerminate;
      Exit;
    end;
  end;
end;

destructor TModuleGLContextGLFW.Free;
begin
  glfwCloseWindow;
end;

procedure TModuleGLContextGLFW.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('ResX', '800');
    SetConfVal('ResY', '600');
    SetConfVal('Fullscreen', '0');
    SetConfVal('used', '1');
    end;
end;

procedure TModuleGLContextGLFW.ChangeWindowTitle(Text: String);
begin
  glfwSetWindowTitle(PChar(Text));
end;

procedure TModuleGLContextGLFW.GetResolution(var ResX: Integer; var ResY: Integer);
begin
  ResX := StrToInt(GetConfVal('ResX'));
  ResY := StrToInt(GetConfVal('ResY'));
end;

procedure TModuleGLContextGLFW.SwapBuffers;
begin
  glfwSwapBuffers;
end;

procedure TModuleGLContextGLFW.StartMainLoop;
begin
  while not ModuleManager.ModInputHandler.QuitRequest do
    MainLoop;
end;

procedure TModuleGLContextGLFW.EndMainLoop;
begin
  glfwTerminate;
end;

procedure TModuleGLContextGLFW.InitGL;
begin
  InitOpenGL;
  ReadOpenGLCore;
  ReadExtensions;
  ReadImplementationProperties;
end;

function TModuleGLContextGLFW.SetResolution(ResX, ResY: Integer): Boolean;
begin
  glfwSetWindowSize(ResX, ResY);
  SetConfVal('ResX', IntToStr(ResX));
  SetConfVal('ResY', IntToStr(ResY));
  result := true;
end;

function TModuleGLContextGLFW.IsFullscreen: Boolean;
begin
  result := GetConfVal('Fullscreen') = '1';
end;

function TModuleGLContextGLFW.SetFullscreenState(Fullscreen: Boolean): Boolean;
begin
  glfwCloseWindow;
  if Fullscreen then
  begin
    if glfwOpenWindow(StrToInt(GetConfVal('ResX')), StrToInt(GetConfVal('ResY')), 8, 8, 8, 0, 24, 0, GLFW_FULLSCREEN) <> 1 then
    begin
      glfwTerminate;
      Exit;
    end;
    glfwEnable(GLFW_MOUSE_CURSOR);
    SetConfVal('Fullscreen', '1');
  end
  else
  begin
    if glfwOpenWindow(StrToInt(GetConfVal('ResX')), StrToInt(GetConfVal('ResY')), 8, 8, 8, 0, 24, 0, GLFW_WINDOW) <> 1 then
    begin
      glfwTerminate;
      Exit;
    end;
    SetConfVal('Fullscreen', '0');
  end;
end;

end.