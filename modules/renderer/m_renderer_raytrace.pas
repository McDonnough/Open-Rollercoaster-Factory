unit m_renderer_raytrace;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors, u_geometry, u_functions, m_renderer_raytrace_thread, u_arrays,
  m_texmng_class, m_shdmng_class;

type
  TModuleRendererRaytrace = class(TModuleRendererClass)
    protected
      fRenderThreads: Array of TRendererRaytraceThread;
      fContentTexture: TTexture;
      fChunkMap: Array of Integer;
      ResX, ResY: Integer;
      PixelData: Array of DWord;
      procedure Display(Event: String; Data, Result: Pointer);
    public
      procedure PostInit;
      procedure Sync;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      constructor Create;
    end;

implementation

uses
  m_varlist, u_events;

procedure TModuleRendererRaytrace.Sync;
var
  i: Integer;
begin
  for i := 0 to high(fRenderThreads) do
    begin
    fRenderThreads[i].Working := false;
    while fRenderThreads[i].Working do
      sleep(1);
    end;
end;

procedure TModuleRendererRaytrace.PostInit;
var
  i: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  SetLength(fChunkMap, Ceil(ResX / 20) * Ceil(ResY / 20));
  SetLength(PixelData, 20 * 20 * length(fChunkMap));
  SetLength(fRenderThreads, StrToIntWD(GetConfVal('threads'), 2));
  for i := 0 to high(fRenderThreads) do
    begin
    fRenderThreads[i] := TRendererRaytraceThread.Create;
    fRenderThreads[i].ID := i;
    fRenderThreads[i].ChunkCount := Length(fChunkMap);
    fRenderThreads[i].ChunkMap := @fChunkMap[0];
    fRenderThreads[i].PixelMap := @PixelData[0];
    fRenderThreads[i].ResX := 20 * Ceil(ResX / 20);
    fRenderThreads[i].ResY := 20 * Ceil(ResY / 20);
    fRenderThreads[i].Samples := StrToIntWD(GetConfVal('samples'), 1);
    end;
  fContentTexture := TTexture.Create;
  fContentTexture.CreateNew(20 * Ceil(ResX / 20), 20 * Ceil(ResY / 20), GL_RGBA);
  fContentTexture.SetFilter(GL_NEAREST, GL_NEAREST);
  EventManager.AddCallback('TPark.Render', @Display);
end;

procedure TModuleRendererRaytrace.Unload;
var
  i: Integer;
begin
  EventManager.RemoveCallback(@Display);
  fContentTexture.Free;
  Sync;
  for i := 0 to high(fRenderThreads) do
    begin
    fRenderThreads[i].Unload;
    fRenderThreads[i].Free;
    end;
  SetLength(fRenderThreads, 0);
end;

procedure TModuleRendererRaytrace.RenderScene;
var
  i, j: Integer;
begin
  for i := 0 to high(fChunkMap) do
    fChunkMap[i] := 0;

  j := 0;

  for i := 0 to high(fRenderThreads) do
    begin
    fRenderThreads[i].Working := True;
    while not fRenderThreads[i].Working do inc(j);
    end;
end;

procedure TModuleRendererRaytrace.Display(Event: String; Data, Result: Pointer);
begin
  Sync;

  glMatrixMode(GL_PROJECTION);
  glPushMatrix;
  glLoadIdentity;
  glMatrixMode(GL_MODELVIEW);
  glPushMatrix;
  glLoadIdentity;

  fContentTexture.Bind(0);
  fContentTexture.Fill(@PixelData[0], GL_RGBA);

  glDisable(GL_ALPHA_TEST);

  glBegin(GL_QUADS);
    glTexCoord2f(0, 0); glVertex3f(-1, -1, -1);
    glTexCoord2f(1, 0); glVertex3f( 1, -1, -1);
    glTexCoord2f(1, 1); glVertex3f( 1,  1, -1);
    glTexCoord2f(0, 1); glVertex3f(-1,  1, -1);
  glEnd;

  glDisable(GL_BLEND);
  glEnable(GL_ALPHA_TEST);

  glPopMatrix;
  glMatrixMode(GL_PROJECTION);
  glPopMatrix;
  glMatrixMode(GL_MODELVIEW);
end;

procedure TModuleRendererRaytrace.CheckModConf;
begin
  fModName := 'RendererRT';
  fModType := 'Renderer';
  if GetConfVal('used') <> '1' then
    begin
    SetConfVal('used', '1');
    SetConfVal('depthoffield', '1');
    SetConfVal('globallight', '1');
    SetConfVal('3dmode', '0');
    SetConfVal('threads', '2');
    SetConfVal('samples', '1');
    end;
end;

constructor TModuleRendererRaytrace.Create;
begin
end;

end.