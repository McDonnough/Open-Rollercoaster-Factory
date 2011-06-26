unit m_glcontext_sdl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_glcontext_class, SDL, dglOpenGL, m_gui_class, m_settings_class, m_gui_label_class, m_gui_edit_class,
  m_gui_checkbox_class, m_texmng_class;

type
  TModuleGLContextSDL = class(TModuleGLContextClass)
    protected
      sResX, sResY: TEdit;
      cFullscreen: TCheckBox;
      fConfigInterface: TConfigurationInterfaceBase;
    
      fSurface: PSDL_Surface;
      fVInfo: PSDL_VideoInfo;
      fVFlags: DWord;
      Second: Boolean;
      fResX, fResY: Integer;

      fCursorTextures: Array[TMouseCursor] of TTexture;
      fCursorTextureNames: Array[TMouseCursor] of String;
      function CreateSurface(w, h, flag: Integer): Boolean;
      procedure ChangeCursor(Cursor: TMouseCursor); override;
    public
      constructor Create;
      destructor Free;
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
      procedure LoadCursors;
      function SetResolution(ResX, ResY: Integer): Boolean;
      function IsFullscreen: Boolean;
      function SetFullscreenState(Fullscreen: Boolean): Boolean;
    end;

implementation

uses
  m_varlist, main, u_functions, u_events, g_park;

procedure TModuleGLContextSDL.ChangeCursor(Cursor: TMouseCursor);
begin
  fCurrentCursor := Cursor;
end;

function TModuleGLContextSDL.CreateSurface(w, h, flag: Integer): Boolean;
begin
  fSurface := SDL_SetVideoMode(w, h, 32, fVFlags or flag);
  result := fSurface <> nil;
  if not result then
    ModuleManager.ModLog.AddWarning('Could not create surface: ' + SDL_GetError);
end;

constructor TModuleGLContextSDL.Create;
begin
  fModName := 'GLContextSDL';
  fModType := 'GLContext';
  CheckModConf;

  EventManager.AddCallback('TSettings.CreateConfigurationInterface', @CreateConfigInterface);
  EventManager.AddCallback('TSettings.DestroyConfigurationInterface', @DestroyConfigInterface);
  EventManager.AddCallback('TSettings.ApplyConfigurationChanges', @ApplyChanges);

  AdditionalContextOptions := 0;

  // Init SDL
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
    ModuleManager.ModLog.AddError('Initialization of SDL failed: ' + SDL_GetError);

  // Poll video card
  fVInfo := SDL_GetVideoInfo;
  if fVInfo = nil then
    ModuleManager.ModLog.AddError('Initialization of graphics hardware failed: ' + SDL_GetError);

  // Set initial flags
  fVFlags := SDL_OPENGL or
             SDL_DOUBLEBUF or
             SDL_HWPALETTE;

  if fVInfo^.hw_available <> 0 then
    fVFlags := fVFlags or SDL_HWSURFACE
  else
    fVFlags := fVFlags or SDL_SWSURFACE;

  if fVInfo^.blit_hw <> 0 then
    fVFlags := fVFlags or SDL_HWACCEL;

  SDL_GL_SetAttribute(PtrUInt(SDL_GL_RED_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_GREEN_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_BLUE_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_ALPHA_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_BUFFER_SIZE), 32);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_ACCUM_RED_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_ACCUM_GREEN_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_ACCUM_BLUE_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_ACCUM_ALPHA_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_DEPTH_SIZE), 24);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_DOUBLEBUFFER), 1);

  SetResolution(StrToInt(GetConfVal('ResX')), StrToInt(GetConfVal('ResY')));
  SetFullscreenState(GetConfVal('Fullscreen') = '1');
end;

destructor TModuleGLContextSDL.Free;
begin
  EventManager.RemoveCallback(@CreateConfigInterface);
  EventManager.RemoveCallback(@DestroyConfigInterface);
  EventManager.RemoveCallback(@ApplyChanges);

  SDL_FreeSurface(fSurface);
  SDL_Quit;
end;

procedure TModuleGLContextSDL.ApplyChanges(Event: String; Data, Result: Pointer);
begin
  SetConfVal('ResX', StrToIntWD(sResX.Text, 800));
  SetConfVal('ResY', StrToIntWD(sResY.Text, 600));
  SetConfVal('Fullscreen', cFullscreen.Checked);
end;

procedure TModuleGLContextSDL.CreateConfigInterface(Event: String; Data, Result: Pointer);
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

procedure TModuleGLContextSDL.DestroyConfigInterface(Event: String; Data, Result: Pointer);
begin
  fConfigInterface.Free;
end;

procedure TModuleGLContextSDL.CheckModConf;
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

procedure TModuleGLContextSDL.ChangeWindowTitle(Text: String);
begin
  SDL_WM_SetCaption(PChar(Text), nil);
end;

procedure TModuleGLContextSDL.GetResolution(var ResX: Integer; var ResY: Integer);
begin
  ResX := fResX;
  ResY := fResY
end;

procedure TModuleGLContextSDL.SwapBuffers;
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

  if not ModuleManager.ModInputHandler.Locked then
    begin
    glBegin(GL_QUADS);
      glTexCoord2f(0, 0); glVertex2f(ModuleManager.ModInputHandler.MouseX, ModuleManager.ModInputHandler.MouseY);
      glTexCoord2f(1, 0); glVertex2f(ModuleManager.ModInputHandler.MouseX + fCursorTextures[MouseCursor].Width, ModuleManager.ModInputHandler.MouseY);
      glTexCoord2f(1, 1); glVertex2f(ModuleManager.ModInputHandler.MouseX + fCursorTextures[MouseCursor].Width, ModuleManager.ModInputHandler.MouseY + fCursorTextures[MouseCursor].Height);
      glTexCoord2f(0, 1); glVertex2f(ModuleManager.ModInputHandler.MouseX, ModuleManager.ModInputHandler.MouseY + fCursorTextures[MouseCursor].Height);
    glEnd;
    end;

  glDisable(GL_BLEND);

  fCursorTextures[MouseCursor].Unbind;

  if (ModuleManager.ModRenderer.CaptureNextFrame) and (Park.ScreenCaptureTool.WithUI) then
    begin
    ModuleManager.ModRenderer.CaptureNextFrame := False;
    EventManager.CallEvent('TRenderer.CaptureNow', self, nil);
    end;

  SDL_GL_SwapBuffers;
end;

procedure TModuleGLContextSDL.StartMainLoop;
begin
  LoadCursors;
  SDL_ShowCursor(0);
  
  while not ModuleManager.ModInputHandler.QuitRequest do
    MainLoop;
end;

procedure TModuleGLContextSDL.EndMainLoop;
begin
  SDL_ShowCursor(1);
end;

procedure TModuleGLContextSDL.InitGL;
begin
  InitOpenGL;
  ReadExtensions;
  ReadImplementationProperties;
end;

function TModuleGLContextSDL.SetResolution(ResX, ResY: Integer): Boolean;
var
  FullscreenFlag: Integer;
begin
  fResX := ResX;
  fResY := ResY;

  FullscreenFlag := 0;
  if IsFullscreen then
    FullscreenFlag := SDL_FULLSCREEN;
  if CreateSurface(ResX, ResY, FullscreenFlag) then
    begin
    SetConfVal('ResX', IntToStr(ResX));
    SetConfVal('ResY', IntToStr(ResY));
    end
  else
    begin
    GetResolution(ResX, ResY);
    if not CreateSurface(ResX, ResY, FullscreenFlag) then
      ModuleManager.ModLog.AddError('Could not create surface: ' + SDL_GetError);
    end;
end;

function TModuleGLContextSDL.IsFullscreen: Boolean;
begin
  Result := GetConfVal('Fullscreen') = '1';
end;

procedure TModuleGLContextSDL.LoadCursors;
var
  i: TMouseCursor;
begin
  for i := low(TMouseCursor) to high(TMouseCursor) do
    begin
    fCursorTextures[i] := TTexture.Create;
    fCursorTextures[i].FromFile(fCursorTextureNames[i]);
    end;
end;

function TModuleGLContextSDL.SetFullscreenState(Fullscreen: Boolean): Boolean;
var
  ResX, ResY: Integer;
begin
  if Fullscreen = IsFullscreen then
    exit;
  GetResolution(ResX, ResY);
  if Fullscreen then
    begin
    SetConfVal('Fullscreen', '1');
    if not CreateSurface(ResX, ResY, SDL_FULLSCREEN) then
      if not CreateSurface(ResX, ResY, 0) then
        ModuleManager.ModLog.AddError('Could not create surface: ' + SDL_GetError);
    end
  else
    begin
    SetConfVal('Fullscreen', '0');
    if not CreateSurface(ResX, ResY, 0) then
      if not CreateSurface(ResX, ResY, SDL_FULLSCREEN) then
        ModuleManager.ModLog.AddError('Could not create surface: ' + SDL_GetError);
    end;
end;

end.

