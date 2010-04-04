unit m_renderer_opengl;

interface

uses
  Classes, SysUtils, m_renderer_class, DGLOpenGL, g_park, u_math, u_vectors,
  m_renderer_opengl_camera, m_renderer_opengl_terrain, math, m_texmng_class,
  m_shdmng_class, m_renderer_opengl_plugins, u_functions;

type
  TModuleRendererOpenGL = class(TModuleRendererClass)
    protected
      RCamera: TRCamera;
      RTerrain: TRTerrain;

      RenderEffectManager: TRenderEffectManager;
    public
      procedure PostInit;
      procedure Unload;
      procedure RenderScene;
      procedure CheckModConf;
      procedure Render(EyeMode: Single = 0; EyeFocus: Single = 10);
      constructor Create;
      destructor Free;
    end;

implementation

uses
  m_varlist, u_events;

procedure TModuleRendererOpenGL.PostInit;
var
  s: AString;
  i: INteger;
begin
  RCamera := TRCamera.Create;
  RTerrain := TRTerrain.Create;
  RenderEffectManager := TRenderEffectManager.Create;
  s := Explode(',', GetConfVal('effects'));
  for i := 0 to high(s) do
    RenderEffectManager.LoadEffect(StrToInt(S[i]));
end;

procedure TModuleRendererOpenGL.Unload;
begin
  RenderEffectManager.Free;
  RTerrain.Free;
  RCamera.Free;
end;

procedure TModuleRendererOpenGL.Render(EyeMode: Single = 0; EyeFocus: Single = 10);
begin
  glClear(GL_DEPTH_BUFFER_BIT);
  glLoadIdentity;
  glRotatef(RadToDeg(arctan(EyeMode / EyeFocus)), 0, 1, 0);
  glTranslatef(EyeMode, 0, 0);
  RCamera.ApplyRotation(Vector(1, 1, 1));
  RCamera.ApplyTransformation(Vector(1, 1, 1));
  RTerrain.Render;
end;

procedure TModuleRendererOpenGL.RenderScene;
var
  ResX, ResY, i: Integer;
begin
  ModuleManager.ModGLContext.GetResolution(ResX, ResY);
  // Just a test
  glMatrixMode(GL_PROJECTION);
  ModuleManager.ModGLMng.SetUp3DMatrix;
  glMatrixMode(GL_MODELVIEW);

  glEnable(GL_DEPTH_TEST);
  glDepthMask(true);

  glEnable(GL_BLEND);

  EventManager.CallEvent('TModuleRenderer.Render', nil, nil);
  EventManager.CallEvent('TModuleRenderer.PostRender', nil, nil);
end;

procedure TModuleRendererOpenGL.CheckModConf;
begin
  if GetConfVal('used') = '' then
    begin
    SetConfVal('used', '1');
    SetConfVal('effects', IntToStr(RE_NORMAL) + ',' + IntToStr(RE_2D_FOCUS) + ',' + IntToStr(RE_BLOOM) + ',' + IntToStr(RE_MOTIONBLUR));
    end;
end;

constructor TModuleRendererOpenGL.Create;
begin
  fModName := 'RendererGL';
  fModType := 'Renderer';
end;

destructor TModuleRendererOpenGL.Free;
begin
end;

end.