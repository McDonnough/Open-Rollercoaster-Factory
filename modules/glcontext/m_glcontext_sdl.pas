unit m_glcontext_sdl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, m_glcontext_class, SDL, dglOpenGL;

type
  TModuleGLContextSDL = class(TModuleGLContextClass)
    protected
      fSurface: PSDL_Surface;
      fVInfo: PSDL_VideoInfo;
      fVFlags: DWord;
      Second: Boolean;
      function CreateSurface(w, h, flag: Integer): Boolean;
    public
      constructor Create;
      destructor Free;
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
  m_varlist, main;

function TModuleGLContextSDL.CreateSurface(w, h, flag: Integer): Boolean;
begin
  fSurface := SDL_SetVideoMode(w, h, 32, fVFlags or flag);
  result := fSurface <> nil;
  if not result then
    ModuleManager.ModLog.AddWarning('Could not create surface: ' + SDL_GetError, 'm_glcontext_sdl.pas', 36);
end;

constructor TModuleGLContextSDL.Create;
begin
  fModName := 'GLContextSDL';
  fModType := 'GLContext';
  CheckModConf;

  AdditionalContextOptions := 0;

  // Init SDL
  if SDL_Init(SDL_INIT_VIDEO) < 0 then
    ModuleManager.ModLog.AddError('Initialization of SDL failed: ' + SDL_GetError, 'm_glcontext_sdl.pas', 35);

  // Poll video card
  fVInfo := SDL_GetVideoInfo;
  if fVInfo = nil then
    ModuleManager.ModLog.AddError('Initialization of graphics hardware failed: ' + SDL_GetError, 'm_glcontext_sdl.pas', 38);

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
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_ACCUM_RED_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_ACCUM_GREEN_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_ACCUM_BLUE_SIZE), 8);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_DEPTH_SIZE), 24);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_DOUBLEBUFFER), 1);
  SDL_GL_SetAttribute(PtrUInt(SDL_GL_STENCIL_SIZE), 8);

  SetResolution(StrToInt(GetConfVal('ResX')), StrToInt(GetConfVal('ResY')));
  SetFullscreenState(GetConfVal('Fullscreen') = '1');
end;

destructor TModuleGLContextSDL.Free;
begin
  SDL_FreeSurface(fSurface);
  SDL_Quit;
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
end;

procedure TModuleGLContextSDL.ChangeWindowTitle(Text: String);
begin
  SDL_WM_SetCaption(PChar(Text), nil);
end;

procedure TModuleGLContextSDL.GetResolution(var ResX: Integer; var ResY: Integer);
begin
  ResX := StrToInt(GetConfVal('ResX'));
  ResY := StrToInt(GetConfVal('ResY'));
end;

procedure TModuleGLContextSDL.SwapBuffers;
begin
  SDL_GL_SwapBuffers;
end;

procedure TModuleGLContextSDL.StartMainLoop;
begin
  while not ModuleManager.ModInputHandler.QuitRequest do
    MainLoop;
end;

procedure TModuleGLContextSDL.EndMainLoop;
begin
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
      ModuleManager.ModLog.AddError('Could not create surface: ' + SDL_GetError, 'm_glcontext_sdl.pas', 132);
    end;
end;

function TModuleGLContextSDL.IsFullscreen: Boolean;
begin
  Result := GetConfVal('Fullscreen') = '1';
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
        ModuleManager.ModLog.AddError('Could not create surface: ' + SDL_GetError, 'm_glcontext_sdl.pas', 153);
    end
  else
    begin
    SetConfVal('Fullscreen', '0');
    if not CreateSurface(ResX, ResY, 0) then
      if not CreateSurface(ResX, ResY, SDL_FULLSCREEN) then
        ModuleManager.ModLog.AddError('Could not create surface: ' + SDL_GetError, 'm_glcontext_sdl.pas', 160);
    end;
end;

end.

