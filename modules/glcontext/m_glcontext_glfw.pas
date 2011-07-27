unit m_glcontext_glfw;

{$mode objfpc}{$H+}
{$linklib libglfw}

interface

uses
  Classes, SysUtils, m_glcontext_class, glfw, dglOpenGL, m_gui_class, m_settings_class, m_gui_label_class, m_gui_edit_class,
  m_gui_checkbox_class, m_texmng_class;

type
  TModuleGLContextGLFW = class(TModuleGLContextClass)
    protected
      sResX, sResY: TEdit;
      cFullscreen: TCheckBox;
      fConfigInterface: TConfigurationInterfaceBase;
      fResX, fResY: Integer;
      fCursorTextures: Array[TMouseCursor] of TTexture;
      fCursorTextureNames: Array[TMouseCursor] of String;
      procedure ChangeCursor(Cursor: TMouseCursor); override;
    public
      constructor Create;
      destructor Free;
      procedure LoadCursors;
      procedure ApplyChanges(Event: String; Data, Result: Pointer);
      procedure CreateConfigInterface(Event: String; Data, Result: Pointer);
      procedure DestroyConfigInterface(Event: String; Data, Result: Pointer);
      procedure CheckModConf;
      procedure ChangeWindowTitle(Text: String);
      procedure GetResolution(var ResX: Integer; var ResY: Integer);
      procedure SwapBuffers;
      procedure StartMainLoop;
      procedure EndMainLoop;
      procedure InitGL;
      function SetResolution(ResX, ResY: Integer): Boolean;
      function IsFullscreen: Boolean;
      function SetFullscreenState(Fullscreen: Boolean): Boolean;
    end;

implementation

uses
  m_varlist, main, u_events, u_functions;

procedure TModuleGLContextGLFW.LoadCursors;
var
  i: TMouseCursor;
begin
  for i := low(TMouseCursor) to high(TMouseCursor) do
    begin
    fCursorTextures[i] := TTexture.Create;
    fCursorTextures[i].FromFile(fCursorTextureNames[i]);
    end;
end;

procedure TModuleGLContextGLFW.ChangeCursor(Cursor: TMouseCursor);
begin
  fCurrentCursor := Cursor;
end;

constructor TModuleGLContextGLFW.Create;
begin
  fModName := 'GLContextGLFW';
  fModType := 'GLContext';
  CheckModConf;

  EventManager.AddCallback('TSettings.CreateConfigurationInterface', @CreateConfigInterface);
  EventManager.AddCallback('TSettings.DestroyConfigurationInterface', @DestroyConfigInterface);
  EventManager.AddCallback('TSettings.ApplyConfigurationChanges', @ApplyChanges);

  //Init GLFW
  glfwInit;
  glfwSwapInterval(0);
  glfwOpenWindowHint(GLFW_OPENGL_VERSION_MAJOR, 2);
  glfwOpenWindowHint(GLFW_OPENGL_VERSION_MINOR, 1);
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
  EventManager.RemoveCallback(@CreateConfigInterface);
  EventManager.RemoveCallback(@DestroyConfigInterface);
  EventManager.RemoveCallback(@ApplyChanges);
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
  fResX := StrToIntWD(GetConfVal('ResX'), 800);
  fResY := StrToIntWD(GetConfVal('ResY'), 600);

  fCursorTextureNames[mcDefault] := 'general/cursor-default.tga';
  fCursorTextureNames[mcCaret] := 'general/cursor-caret.tga';

  MouseCursor := mcDefault;
end;

procedure TModuleGLContextGLFW.ChangeWindowTitle(Text: String);
begin
  glfwSetWindowTitle(PChar(Text));
end;

procedure TModuleGLContextGLFW.GetResolution(var ResX: Integer; var ResY: Integer);
begin
  ResX := fResX;
  ResY := fResY
end;

procedure TModuleGLContextGLFW.SwapBuffers;
begin
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  ModuleManager.ModGLMng.SetUp2DMatrix;
  glMatrixMode(GL_TEXTURE);
  glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glUseProgram(0);
  fCursorTextures[MouseCursor].Bind(0);

  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

  glDisable(GL_CULL_FACE);

  glColor4f(1, 1, 1, 1);

  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex2f(ModuleManager.ModInputHandler.MouseX, ModuleManager.ModInputHandler.MouseY);
    glTexCoord2f(1, 0); glVertex2f(ModuleManager.ModInputHandler.MouseX + fCursorTextures[MouseCursor].Width, ModuleManager.ModInputHandler.MouseY);
    glTexCoord2f(1, 1); glVertex2f(ModuleManager.ModInputHandler.MouseX + fCursorTextures[MouseCursor].Width, ModuleManager.ModInputHandler.MouseY + fCursorTextures[MouseCursor].Height);
    glTexCoord2f(0, 1); glVertex2f(ModuleManager.ModInputHandler.MouseX, ModuleManager.ModInputHandler.MouseY + fCursorTextures[MouseCursor].Height);
  glEnd;

  glDisable(GL_BLEND);

  fCursorTextures[MouseCursor].Unbind;

  glfwSwapBuffers;
end;

procedure TModuleGLContextGLFW.StartMainLoop;
begin
  LoadCursors;
  glfwDisable(GLFW_MOUSE_CURSOR);

  while not ModuleManager.ModInputHandler.QuitRequest do
    MainLoop;
end;

procedure TModuleGLContextGLFW.EndMainLoop;
begin
  glfwEnable(GLFW_MOUSE_CURSOR);
  glfwTerminate;
end;

procedure TModuleGLContextGLFW.InitGL;
begin
  InitOpenGL;
  ReadOpenGLCore;
  ReadExtensions;
  ReadImplementationProperties;
  glGetError();
end;

procedure TModuleGLContextGLFW.ApplyChanges(Event: String; Data, Result: Pointer);
begin
  SetConfVal('ResX', StrToIntWD(sResX.Text, 800));
  SetConfVal('ResY', StrToIntWD(sResY.Text, 600));
  SetConfVal('Fullscreen', cFullscreen.Checked);
end;

procedure TModuleGLContextGLFW.CreateConfigInterface(Event: String; Data, Result: Pointer);
begin
  fConfigInterface := TConfigurationInterfaceBase.Create(TGUIComponent(Data));

  with TLabel.Create(fConfigInterface.Surface) do
    begin
    Top := 8;
    Left := 8;
    Height := 32;
    Size := 16;
    Width := 200;
    Caption := 'Screen width:';
    end;
  sResX := TEdit.Create(fConfigInterface.Surface);
  with sResX do
    begin
    Top := 0;
    Left := 208;
    Width := 64;
    Height := 32;
    Text := GetConfVal('ResX');
    end;

  with TLabel.Create(fConfigInterface.Surface) do
    begin
    Top := 8;
    Left := 338;
    Height := 32;
    Size := 16;
    Width := 200;
    Caption := 'Screen height:';
    end;
  sResY:= TEdit.Create(fConfigInterface.Surface);
  with sResY do
    begin
    Top := 0;
    Left := 538;
    Width := 64;
    Height := 32;
    Text := GetConfVal('ResY');
    end;

  with TLabel.Create(fConfigInterface.Surface) do
    begin
    Top := 40;
    Left := 48;
    Height := 32;
    Size := 16;
    Width := 200;
    Caption := 'Fullscreen mode';
    end;
  cFullscreen := TCheckBox.Create(fConfigInterface.Surface);
  with cFullscreen do
    begin
    Top := 32;
    Left := 8;
    Height := 32;
    Width := 32;
    Checked := GetConfVal('Fullscreen') = '1';
    end;

  TConfigurationInterfaceList(Result).Add('Screen', fConfigInterface);
end;

procedure TModuleGLContextGLFW.DestroyConfigInterface(Event: String; Data, Result: Pointer);
begin
  fConfigInterface.Free;
end;

function TModuleGLContextGLFW.SetResolution(ResX, ResY: Integer): Boolean;
begin
  fResX := ResX;
  fResY := ResY;
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