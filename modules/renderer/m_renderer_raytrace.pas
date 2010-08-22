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
      fAAShader: TShader;
      fChunkMap: Array of Integer;
      ResX, ResY: Integer;
      PixelData: Array of DWord;
    public
      procedure PostInit;
      procedure Sync;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist;

const
  SAMPLES = 1;

procedure TModuleRendererRaytrace.Sync;
var
  i: Integer;
begin
  for i := 0 to high(fRenderThreads) do
    while fRenderThreads[i].Working do
      sleep(1);
end;

procedure TModuleRendererRaytrace.PostInit;
var
  i: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  fAAShader := TShader.Create('rendererraytrace/glsl/aa.vs', 'rendererraytrace/glsl/aa.fs');
  fAAShader.UniformI('Size', ResX, ResY);
  fAAShader.UniformI('Samples', SAMPLES);
  fAAShader.UniformI('Image', 0);
  fAAShader.Unbind;
  ResX := ResX * SAMPLES;
  ResY := ResY * SAMPLES;
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
    end;
  fContentTexture := TTexture.Create;
  fContentTexture.CreateNew(20 * Ceil(ResX / 20), 20 * Ceil(ResY / 20), GL_RGBA);
  fContentTexture.SetFilter(GL_NEAREST, GL_NEAREST);
end;

procedure TModuleRendererRaytrace.Unload;
var
  i: Integer;
begin
  fContentTexture.Free;
  Sync;
  for i := 0 to high(fRenderThreads) do
    begin
    fRenderThreads[i].Unload;
    fRenderThreads[i].Free;
    end;
  SetLength(fRenderThreads, 0);
  fAAShader.Free;
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

  fAAShader.Bind;

  glBegin(GL_QUADS);
    glVertex3f(-1, -1, -1);
    glVertex3f( 1, -1, -1);
    glVertex3f( 1,  1, -1);
    glVertex3f(-1,  1, -1);
  glEnd;

  fAAShader.UnBind;

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
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('depthoffield', '1');
    SetConfVal('globallight', '1');
    SetConfVal('3dmode', '0');
    SetConfVal('threads', '2');
    end;
end;

constructor TModuleRendererRaytrace.Create;
begin
end;

destructor TModuleRendererRaytrace.Free;
begin
end;

end.